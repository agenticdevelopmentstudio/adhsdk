import Foundation
import GRDB

/// What one `EventStore.trim` call deleted.
public struct EventStoreTrimResult: Sendable, Equatable {
    public var events: Int
    public var messages: Int
    public var turns: Int
    public var sessions: Int
    /// False when the call stopped on its deadline with rows still to delete; call again.
    public var finished: Bool

    public init(events: Int = 0, messages: Int = 0, turns: Int = 0, sessions: Int = 0, finished: Bool) {
        self.events = events
        self.messages = messages
        self.turns = turns
        self.sessions = sessions
        self.finished = finished
    }
}

/// The size and page accounting of one SQLite file.
public struct StoreFileStats: Sendable, Equatable, Codable {
    public var path: String
    /// The main file plus its `-wal` and `-shm`, as they are on disk.
    public var bytes: Int64
    public var pageSize: Int
    public var pageCount: Int
    public var freelistCount: Int
    /// `PRAGMA auto_vacuum`: 0 none, 1 full, 2 incremental.
    public var autoVacuum: Int

    public init(path: String, bytes: Int64, pageSize: Int, pageCount: Int, freelistCount: Int, autoVacuum: Int) {
        self.path = path
        self.bytes = bytes
        self.pageSize = pageSize
        self.pageCount = pageCount
        self.freelistCount = freelistCount
        self.autoVacuum = autoVacuum
    }

    /// Reads the pragmas on `conn` and sizes the files at `path`.
    static func read(path: String, _ conn: Database) throws -> StoreFileStats {
        func pragma(_ name: String) throws -> Int { try Int.fetchOne(conn, sql: "PRAGMA \(name)") ?? 0 }
        return StoreFileStats(
            path: path, bytes: diskBytes(path: path), pageSize: try pragma("page_size"),
            pageCount: try pragma("page_count"), freelistCount: try pragma("freelist_count"),
            autoVacuum: try pragma("auto_vacuum"))
    }

    /// The main file plus `-wal` and `-shm`; a file that is not there counts 0.
    static func diskBytes(path: String) -> Int64 {
        ["", "-wal", "-shm"].reduce(Int64(0)) { total, suffix in
            let attributes = try? FileManager.default.attributesOfItem(atPath: path + suffix)
            return total + ((attributes?[.size] as? NSNumber)?.int64Value ?? 0)
        }
    }
}

public enum SQLiteFileStatsError: Error, Equatable {
    case missingFile(path: String)
    /// The file does not start with the SQLite header.
    case notSQLite(path: String)
}

/// Stats for a SQLite file the toolkit owns no store for (the main database, a raw
/// archive). Never creates the file or any sidecar:
///
/// - With both `-wal` and `-shm` present (a database some process has open, or
///   one left by a crash), it opens the file read-only. The sidecars already
///   exist, so the open creates nothing, and the values include the WAL's frames.
/// - Otherwise it reads the 100-byte header with `FileHandle` and never opens
///   SQLite: a read-only SQLite open of a WAL-mode file creates missing `-wal` and
///   `-shm` files and cannot delete them again. With no WAL to apply, the header
///   holds every value (a `-wal` without `-shm` is a crash leftover whose frames
///   are not counted).
public enum SQLiteFileStats {
    public static func stats(path: String) throws -> StoreFileStats {
        let manager = FileManager.default
        guard manager.fileExists(atPath: path) else { throw SQLiteFileStatsError.missingFile(path: path) }
        guard manager.fileExists(atPath: path + "-wal"), manager.fileExists(atPath: path + "-shm") else {
            return try headerStats(path: path)
        }
        var configuration = Configuration()
        configuration.readonly = true
        let queue = try DatabaseQueue(path: path, configuration: configuration)
        defer { try? queue.close() }
        return try queue.read { conn in try StoreFileStats.read(path: path, conn) }
    }

    /// Reads the database header (https://sqlite.org/fileformat.html §1.3).
    static func headerStats(path: String) throws -> StoreFileStats {
        let handle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
        defer { try? handle.close() }
        let header = [UInt8](try handle.read(upToCount: 100) ?? Data())
        let bytes = StoreFileStats.diskBytes(path: path)
        // A zero-length file is a valid, empty database.
        if header.isEmpty {
            return StoreFileStats(path: path, bytes: bytes, pageSize: 0, pageCount: 0, freelistCount: 0, autoVacuum: 0)
        }
        guard header.count == 100, header.prefix(16).elementsEqual(Array("SQLite format 3\0".utf8)) else {
            throw SQLiteFileStatsError.notSQLite(path: path)
        }
        func u16(_ offset: Int) -> Int { Int(header[offset]) << 8 | Int(header[offset + 1]) }
        func u32(_ offset: Int) -> Int { u16(offset) << 16 | u16(offset + 2) }
        let rawPageSize = u16(16)
        let pageSize = rawPageSize == 1 ? 65_536 : rawPageSize
        // The in-header size is valid only when the change counter matches
        // version-valid-for; older writers left it stale, so fall back to the size.
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        let inHeaderPages = u32(28)
        let pageCount = inHeaderPages > 0 && u32(24) == u32(92)
            ? inHeaderPages
            : (pageSize > 0 ? Int(fileSize / Int64(pageSize)) : 0)
        // Largest root page 0: auto_vacuum NONE; else the incremental flag picks 2 or 1.
        let autoVacuum = u32(52) == 0 ? 0 : (u32(64) != 0 ? 2 : 1)
        return StoreFileStats(
            path: path, bytes: bytes, pageSize: pageSize, pageCount: pageCount,
            freelistCount: u32(36), autoVacuum: autoVacuum)
    }
}

/// A `trim` batch failed after earlier batches had committed: `partial` counts what
/// those batches deleted (rows that are gone), `underlying` is the batch's error.
public struct EventStoreTrimFailure: Error {
    public let partial: EventStoreTrimResult
    public let underlying: any Error
}

extension EventStore {

    /// Turns a wall-clock deadline into a monotonic one once, so an NTP step or a
    /// sleep/wake cannot stretch or end the window (as in `BoundedDatabase`).
    private static func monotonic(_ deadline: Date) -> ContinuousClock.Instant {
        ContinuousClock.now + .seconds(deadline.timeIntervalSinceNow)
    }

    /// Holds the store for a maintenance pass the way a drainer does, so
    /// `beginBulkLoad` is refused while it runs, and refuses the pass during a bulk
    /// load: in this process (`bulkActive`) or left on disk by a crashed one (the
    /// `bulk_load` flag). Without its indexes every batch would be a full scan.
    private func withMaintenance<T>(_ body: () throws -> T) throws -> T {
        try attachLiveWriter()
        defer { detachLiveWriter() }
        if try isInBulkLoad() { throw EventStoreError.bulkLoadInProgress }
        return try body()
    }

    /// Deletes rows with `0 < time < cutoff`, oldest first, `batch` rows per write
    /// transaction (the writer is released between batches): events, then
    /// messages, then turns; then the untimed rows (`time <= 0`, age unknown) of
    /// sessions that qualify for removal; then the `sessions` rows of this file that are ended
    /// (`status = 'ended'` or `ended_at IS NOT NULL`), not `active`, last observed
    /// before the cutoff (the later of `ended_at` and `as_of`, so a resumed session
    /// with a stale `ended_at` stays), and have no events, messages or turns left.
    /// Never touches any other database. Trimmed turns are folded into
    /// `trimmed_turns` in the transaction that deletes them
    /// (`foldAndDeleteTurns`), so a session's totals still count them.
    ///
    /// The first batch always runs, so every call makes progress; before each later
    /// one, a passed `deadline` stops the call with `finished = false`. A rerun with
    /// the same cutoff continues where this one stopped.
    ///
    /// Throws `EventStoreError.bulkLoadInProgress` during a bulk load, before any
    /// delete. A batch that fails throws `EventStoreTrimFailure` carrying what the
    /// committed batches before it deleted.
    ///
    /// `maxTurnId` bounds the timed turns stage to `turns.id <= maxTurnId`: a
    /// caller whose summaries have read the turns only up to some id passes it,
    /// so a turn stored after that read stays until the summaries count it. nil
    /// is unbounded. Untimed turns are never summarised by day and are not bounded.
    public func trim(olderThan cutoff: Double, maxTurnId: Int64? = nil, batch: Int = 500,
                     deadline: Date) throws -> EventStoreTrimResult {
        try withMaintenance {
            try trimRows(olderThan: cutoff, maxTurnId: maxTurnId, batch: batch, until: Self.monotonic(deadline))
        }
    }

    private func trimRows(olderThan cutoff: Double, maxTurnId: Int64?, batch: Int,
                          until end: ContinuousClock.Instant) throws -> EventStoreTrimResult {
        var limit = max(1, batch)
        var result = EventStoreTrimResult(finished: false)
        var ranBatch = false

        /// Runs `sql` (bound to `arguments` + the limit) until a batch deletes fewer
        /// than `limit` rows; false when the deadline stopped it first. With `batchWork`,
        /// that runs instead of `sql`, given the batch size, and returns the rows it deleted.
        func drain(_ sql: String, _ arguments: StatementArguments,
                   into field: WritableKeyPath<EventStoreTrimResult, Int>,
                   batchWork: ((Database, Int) throws -> Int)? = nil) throws -> Bool {
            while true {
                if ranBatch && ContinuousClock.now >= end { return false }
                let deleted: Int
                do {
                    deleted = try Self.shrinkingOnDeadline(&limit) { size in
                        try pool.write(deadline: nil) { conn -> Int in
                            if let batchWork { return try batchWork(conn, size) }
                            try conn.execute(sql: sql, arguments: arguments + [size])
                            return conn.changesCount
                        }
                    }
                } catch {
                    throw EventStoreTrimFailure(partial: result, underlying: error)
                }
                ranBatch = true
                result[keyPath: field] += deleted
                if deleted < limit { return true }
            }
        }

        // A row with no time (`time <= 0`: the line carried no timestamp) has an
        // unknown age, not an old one: the time stages skip it, and it goes only
        // with its session, once that session has ended before the cutoff.
        guard try drain("""
            DELETE FROM events WHERE id IN (
                SELECT id FROM events WHERE time > 0 AND time < ? ORDER BY time LIMIT ?)
            """, [cutoff], into: \.events) else { return result }

        // `messages_time` leads with provider, so trim one provider at a time.
        let providers: [String]
        do {
            providers = try messageProviders()
        } catch {
            throw EventStoreTrimFailure(partial: result, underlying: error)
        }
        for provider in providers {
            guard try drain("""
                DELETE FROM messages WHERE id IN (
                    SELECT id FROM messages WHERE provider = ? AND time > 0 AND time < ? ORDER BY time LIMIT ?)
                """, [provider, cutoff], into: \.messages) else { return result }
        }

        guard try drain("", [], into: \.turns, batchWork: { conn, size in
            try Self.foldAndDeleteTurns(olderThan: cutoff, maxTurnId: maxTurnId, limit: size, conn)
        }) else { return result }

        // The untimed rows of sessions that ended before the cutoff.
        guard try drain("""
            DELETE FROM events WHERE id IN (
                SELECT e.id FROM events e JOIN sessions s
                  ON s.provider = e.provider AND s.session_id = e.session_id
                WHERE e.time <= 0 AND \(Self.endedBefore) LIMIT ?)
            """, [cutoff], into: \.events) else { return result }
        guard try drain("""
            DELETE FROM messages WHERE id IN (
                SELECT m.id FROM messages m JOIN sessions s
                  ON s.provider = m.provider AND s.session_id = m.session_id
                WHERE m.time <= 0 AND \(Self.endedBefore) LIMIT ?)
            """, [cutoff], into: \.messages) else { return result }
        guard try drain("", [], into: \.turns, batchWork: { conn, size in
            try Self.foldAndDeleteTurns(untimedOfSessionsEndedBefore: cutoff, limit: size, conn)
        }) else { return result }

        guard try drain("""
            DELETE FROM sessions WHERE (provider, session_id) IN (
                SELECT s.provider, s.session_id FROM sessions s
                WHERE \(Self.endedBefore)
                  AND NOT EXISTS (SELECT 1 FROM events e
                                  WHERE e.provider = s.provider AND e.session_id = s.session_id)
                  AND NOT EXISTS (SELECT 1 FROM messages m
                                  WHERE m.provider = s.provider AND m.session_id = s.session_id)
                  AND NOT EXISTS (SELECT 1 FROM turns t
                                  WHERE t.provider = s.provider AND t.session_id = s.session_id)
                LIMIT ?)
            """, [cutoff], into: \.sessions) else { return result }

        result.finished = true
        return result
    }

    /// The smallest batch `shrinkingOnDeadline` halves down to.
    static let minimumTrimBatch = 25

    /// Runs one batch of `limit` rows; a batch ejected by the write deadline rolled
    /// back whole, so it is run again at half the size, down to
    /// ``minimumTrimBatch``, and `limit` keeps the size that went through for the
    /// rest of the pass. Every deleted row updates each of the table's indexes, and
    /// on a slow disk that a replay is also writing, 500 of them could run past the
    /// deadline, which failed the stage and left the pass unfinished. A batch at the
    /// minimum that still runs out throws the deadline error.
    static func shrinkingOnDeadline(_ limit: inout Int, _ body: (Int) throws -> Int) throws -> Int {
        while true {
            do {
                return try body(limit)
            } catch BoundedDatabaseError.deadlineExceeded where limit > minimumTrimBatch {
                limit = max(minimumTrimBatch, limit / 2)
            }
        }
    }

    /// One batch of the turns stage, inside the caller's write transaction: picks the
    /// oldest `limit` turns before `cutoff`, adds their sums to `trimmed_turns` (per
    /// provider, session and model), records their keys in `trimmed_turn_keys`, then
    /// deletes them. The fold and the delete commit together or not at all, so a
    /// crash between them cannot count a turn twice or lose it; a turn whose key is
    /// already recorded (stored again by a replay into this file) is deleted without
    /// being added again. Returns the turns deleted. `maxTurnId` keeps every turn
    /// with a larger id (nil: no bound).
    static func foldAndDeleteTurns(olderThan cutoff: Double, maxTurnId: Int64? = nil, limit: Int,
                                   _ conn: Database) throws -> Int {
        try foldAndDeleteTurns(selecting: """
            SELECT id FROM turns WHERE time > 0 AND time < ? AND id <= ? ORDER BY time, id LIMIT ?
            """, arguments: [cutoff, maxTurnId ?? Int64.max, limit], conn)
    }

    /// One batch of untimed turns (`time <= 0`) of sessions that ended before
    /// `cutoff` (``endedBefore``), folded and deleted like any other.
    static func foldAndDeleteTurns(untimedOfSessionsEndedBefore cutoff: Double, limit: Int,
                                   _ conn: Database) throws -> Int {
        try foldAndDeleteTurns(selecting: """
            SELECT t.id FROM turns t JOIN sessions s ON s.provider = t.provider AND s.session_id = t.session_id
            WHERE t.time <= 0 AND \(endedBefore) LIMIT ?
            """, arguments: [cutoff, limit], conn)
    }

    /// A session the trim may remove (its rows first): ended (`status = 'ended'`
    /// or `ended_at IS NOT NULL`), not `active`, last observed before the bound
    /// cutoff. Alias `s`; one `?`.
    static let endedBefore = """
        (s.status = 'ended' OR s.ended_at IS NOT NULL)
          AND s.status IS NOT 'active'
          AND MAX(COALESCE(s.ended_at, s.as_of), s.as_of) < ?
        """

    private static func foldAndDeleteTurns(selecting selection: String, arguments: StatementArguments,
                                           _ conn: Database) throws -> Int {
        try conn.execute(sql: "CREATE TEMP TABLE IF NOT EXISTS trim_turn_batch (id INTEGER PRIMARY KEY)")
        try conn.execute(sql: "DELETE FROM temp.trim_turn_batch")
        try conn.execute(sql: "INSERT INTO temp.trim_turn_batch(id) \(selection)", arguments: arguments)
        try conn.execute(sql: """
            INSERT INTO trimmed_turns(provider, session_id, model, turn_count, input_tokens, output_tokens,
                                      cache_read_tokens, cache_write_tokens, cache_write_1h_tokens,
                                      first_time, last_time)
            SELECT t.provider, t.session_id, COALESCE(t.model, ''), COUNT(*),
                   COALESCE(SUM(t.input_tokens), 0), COALESCE(SUM(t.output_tokens), 0),
                   COALESCE(SUM(t.cache_read_tokens), 0), COALESCE(SUM(t.cache_write_tokens), 0),
                   CAST(COALESCE(SUM(json_extract(t.attrs, '$.cache_creation_1h_tokens')), 0) AS INTEGER),
                   MIN(CASE WHEN t.time > 0 THEN t.time END), MAX(CASE WHEN t.time > 0 THEN t.time END)
            FROM turns t
            WHERE t.id IN (SELECT id FROM temp.trim_turn_batch)
              AND NOT EXISTS (SELECT 1 FROM trimmed_turn_keys k
                              WHERE k.provider = t.provider AND k.dedup_key = t.dedup_key)
            GROUP BY t.provider, t.session_id, COALESCE(t.model, '')
            ON CONFLICT(provider, session_id, model) DO UPDATE SET
                turn_count = turn_count + excluded.turn_count,
                input_tokens = input_tokens + excluded.input_tokens,
                output_tokens = output_tokens + excluded.output_tokens,
                cache_read_tokens = cache_read_tokens + excluded.cache_read_tokens,
                cache_write_tokens = cache_write_tokens + excluded.cache_write_tokens,
                cache_write_1h_tokens = cache_write_1h_tokens + excluded.cache_write_1h_tokens,
                first_time = COALESCE(MIN(first_time, excluded.first_time), first_time, excluded.first_time),
                last_time = COALESCE(MAX(last_time, excluded.last_time), last_time, excluded.last_time)
            """)
        try conn.execute(sql: """
            INSERT OR IGNORE INTO trimmed_turn_keys(provider, dedup_key)
            SELECT provider, dedup_key FROM turns WHERE id IN (SELECT id FROM temp.trim_turn_batch)
            """)
        try conn.execute(sql: "DELETE FROM turns WHERE id IN (SELECT id FROM temp.trim_turn_batch)")
        let deleted = conn.changesCount
        try conn.execute(sql: "DELETE FROM temp.trim_turn_batch")
        return deleted
    }

    /// The distinct providers in `messages`, by a skip-scan over `messages_time`
    /// (one index probe per provider, not a scan of the table).
    private func messageProviders() throws -> [String] {
        try pool.read { conn in
            try String.fetchAll(conn, sql: """
                WITH RECURSIVE p(provider) AS (
                    SELECT MIN(provider) FROM messages
                    UNION ALL
                    SELECT (SELECT MIN(provider) FROM messages WHERE provider > p.provider)
                    FROM p WHERE p.provider IS NOT NULL)
                SELECT provider FROM p WHERE provider IS NOT NULL
                """)
        }
    }

    /// Runs `PRAGMA incremental_vacuum(pagesPerStep)` until the freelist is empty,
    /// a step frees nothing, or `deadline` passes (the first step always runs), then
    /// checkpoints the WAL with TRUNCATE so the file on disk shrinks. Returns the
    /// pages freed, or nil without touching the file when `auto_vacuum` is not 2
    /// (INCREMENTAL): a file created before the store set it cannot vacuum this way.
    /// Throws `EventStoreError.bulkLoadInProgress` during a bulk load.
    ///
    /// The checkpoint waits up to the pool's busy timeout (5 s) for open readers
    /// to leave the WAL, holding the writer meanwhile; if they do not, the pages are
    /// still freed but the file shrinks only at a later checkpoint.
    public func incrementalVacuum(pagesPerStep: Int = 2048, deadline: Date) throws -> Int? {
        try withMaintenance { try vacuumPages(pagesPerStep: pagesPerStep, until: Self.monotonic(deadline)) }
    }

    private func vacuumPages(pagesPerStep: Int, until end: ContinuousClock.Instant) throws -> Int? {
        let mode = try pool.read { conn in try Int.fetchOne(conn, sql: "PRAGMA auto_vacuum") ?? 0 }
        guard mode == 2 else { return nil }
        let step = max(1, pagesPerStep)
        var freed = 0
        while true {
            let (stepFreed, remaining) = try pool.writeWithoutTransaction(deadline: nil) { conn -> (Int, Int) in
                let before = try Int.fetchOne(conn, sql: "PRAGMA freelist_count") ?? 0
                guard before > 0 else { return (0, 0) }
                try conn.execute(sql: "PRAGMA incremental_vacuum(\(step))")
                let after = try Int.fetchOne(conn, sql: "PRAGMA freelist_count") ?? 0
                return (before - after, after)
            }
            freed += stepFreed
            if remaining == 0 || stepFreed == 0 || ContinuousClock.now >= end { break }
        }
        if freed > 0 {
            try pool.writeWithoutTransaction(deadline: nil) { conn in
                _ = try Row.fetchOne(conn, sql: "PRAGMA wal_checkpoint(TRUNCATE)")
            }
        }
        return freed
    }

    /// This store's file: sizes on disk and page accounting. Read on a
    /// connection of its own, never one of the pool's readers: a usage recount
    /// can hold every reader for minutes, and a status read must not wait
    /// behind it. The store is open, so its `-wal` and `-shm` exist and
    /// `SQLiteFileStats` opens the file read-only, WAL frames included.
    public func fileStats() throws -> StoreFileStats {
        try SQLiteFileStats.stats(path: path)
    }
}
