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
        let fullBatch = max(1, batch)
        var limit = min(fullBatch, carriedTrimBatch ?? fullBatch)
        defer { carriedTrimBatch = limit }
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
                let outcome: Int?
                let started = ContinuousClock.now
                do {
                    outcome = try Self.shrinkingOnDeadline(&limit, until: end) { size in
                        try pool.write(deadline: nil) { conn -> Int in
                            if let batchWork { return try batchWork(conn, size) }
                            try conn.execute(sql: sql, arguments: arguments + [size])
                            return conn.changesCount
                        }
                    }
                } catch {
                    throw EventStoreTrimFailure(partial: result, underlying: error)
                }
                // Out of pass time after an ejection: stop, unfinished, with
                // the smaller size carried to the next pass.
                guard let deleted = outcome else { return false }
                ranBatch = true
                result[keyPath: field] += deleted
                let used = limit
                limit = Self.grownTrimBatch(limit, upTo: fullBatch, took: ContinuousClock.now - started)
                if deleted < used { return true }
            }
        }

        // A row with no time (`time <= 0`: the line carried no timestamp) has an
        // unknown age, not an old one: the time stages skip it, and it goes only
        // with its session, once that session was last seen before the cutoff.
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

        // The untimed rows of sessions last seen before the cutoff.
        guard try drain("DELETE FROM events WHERE id IN (\(Self.untimedRows(of: "events")))",
                        [cutoff], into: \.events) else { return result }
        guard try drain("DELETE FROM messages WHERE id IN (\(Self.untimedRows(of: "messages")))",
                        [cutoff], into: \.messages) else { return result }
        guard try drain("", [], into: \.turns, batchWork: { conn, size in
            try Self.foldAndDeleteTurns(untimedOfSessionsLastSeenBefore: cutoff, limit: size, conn)
        }) else { return result }

        guard try drain("""
            DELETE FROM sessions WHERE (provider, session_id) IN (
                SELECT s.provider, s.session_id FROM sessions s
                WHERE \(Self.lastSeenBefore)
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
    ///
    /// Halving stops once `end` has passed, returning nil with `limit` already
    /// halved: each ejected batch costs the full write deadline, so 500 → 25 is six
    /// of them, and without the check one batch could run a 300 s pass to 660 s
    /// (``vacuumSteps(pagesPerStep:carry:until:_:)`` has the same check). nil
    /// `end` never stops.
    static func shrinkingOnDeadline<T>(_ limit: inout Int, minimum: Int = minimumTrimBatch,
                                       until end: ContinuousClock.Instant? = nil,
                                       _ body: (Int) throws -> T) throws -> T? {
        while true {
            do {
                return try body(limit)
            } catch BoundedDatabaseError.deadlineExceeded where limit > minimum {
                limit = max(minimum, limit / 2)
                if let end, ContinuousClock.now >= end { return nil }
            }
        }
    }

    /// A batch that went through faster than this doubles the next one, back up
    /// to the caller's full batch: well inside the 60 s write deadline, so a
    /// shrink the disk needed only for a while does not last.
    static let trimGrowthCeiling: Duration = .seconds(10)

    /// `limit` doubled, capped at `fullBatch`, when the batch that used it took
    /// under ``trimGrowthCeiling`` (a batch that shrank first took the deadline
    /// at least, so it never grows); otherwise `limit`.
    static func grownTrimBatch(_ limit: Int, upTo fullBatch: Int, took: Duration) -> Int {
        guard took < trimGrowthCeiling, limit < fullBatch else { return limit }
        return min(fullBatch, limit * 2)
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

    /// One batch of untimed turns (`time <= 0`) of sessions last seen before
    /// `cutoff` (``lastSeenBefore``), folded and deleted like any other.
    static func foldAndDeleteTurns(untimedOfSessionsLastSeenBefore cutoff: Double, limit: Int,
                                   _ conn: Database) throws -> Int {
        try foldAndDeleteTurns(selecting: untimedRows(of: "turns"), arguments: [cutoff, limit], conn)
    }

    /// The ids (one `?` for the cutoff, one for the limit) of `table`'s untimed rows
    /// (`time <= 0`) whose session was last seen before the cutoff (``lastSeenBefore``). CROSS JOIN keeps
    /// `sessions` the outer loop, searched through `sessions_last_seen`, with each
    /// session's untimed rows found by its `(provider, session_id, time)` index;
    /// left to itself the planner scanned all of `messages_session_time`.
    static func untimedRows(of table: String) -> String {
        """
        SELECT r.id FROM sessions s CROSS JOIN \(table) r
          ON r.provider = s.provider AND r.session_id = s.session_id AND r.time <= 0
        WHERE \(lastSeenBefore) LIMIT ?
        """
    }

    /// A session the trim may remove (its rows first): last observed before the
    /// bound cutoff, whatever its status. Only a hook `SessionEnd` writes
    /// `status = 'ended'` or `ended_at`, so a session killed without one stays
    /// `active` and a transcript-only one has no status; the cutoff is the
    /// history window (7 days at the least), so a session silent that long is
    /// not live, and one that resumes gets a fresh row from its next record.
    /// Alias `s`; one `?`. The expression is the `sessions_last_seen` index's,
    /// word for word, so the planner reads only the sessions seen before the
    /// cutoff instead of the whole table (on a USB disk a full scan of 9600
    /// sessions took 45 s, four times a pass, inside write transactions), and
    /// every session that range returns is one the stage can act on.
    static let lastSeenBefore = "MAX(COALESCE(s.ended_at, s.as_of), s.as_of) < ?"

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

    /// Runs `PRAGMA incremental_vacuum` in steps of up to `pagesPerStep` pages
    /// (``vacuumSteps(pagesPerStep:carry:until:_:)``) until the freelist is empty, a step
    /// frees nothing, or `deadline` passes (the first step always runs), then
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
        var carry = carriedVacuumStep
        defer { carriedVacuumStep = carry }
        let cacheBefore = try pool.writeWithoutTransaction(deadline: nil) { conn in
            let size = try Int.fetchOne(conn, sql: "PRAGMA cache_size") ?? -2000
            try conn.execute(sql: "PRAGMA cache_size = \(-Self.vacuumCacheKiB)")
            return size
        }
        defer {
            _ = try? pool.writeWithoutTransaction(deadline: nil) { conn in
                try conn.execute(sql: "PRAGMA cache_size = \(cacheBefore)")
            }
        }
        return try Self.checkpointing({ committed in
            try Self.vacuumSteps(pagesPerStep: pagesPerStep, carry: &carry, until: end) { size in
                let step = try pool.writeWithoutTransaction(deadline: Self.vacuumStepDeadline) { conn -> (Int, Int) in
                    let before = try Int.fetchOne(conn, sql: "PRAGMA freelist_count") ?? 0
                    guard before > 0 else { return (0, 0) }
                    try conn.execute(sql: "PRAGMA incremental_vacuum(\(size))")
                    let after = try Int.fetchOne(conn, sql: "PRAGMA freelist_count") ?? 0
                    return (before - after, after)
                }
                committed += step.0
                return step
            }
        }, checkpoint: {
            try pool.writeWithoutTransaction(deadline: nil) { conn in
                _ = try Row.fetchOne(conn, sql: "PRAGMA wal_checkpoint(TRUNCATE)")
            }
        })
    }

    /// Runs `vacuum`, which adds the pages of each step it commits to its
    /// argument, and returns what it freed; then runs `checkpoint` if any page
    /// was freed. Also when `vacuum` throws after committing some steps (a step
    /// at the minimum size ejected by the deadline): those pages are freed
    /// either way, and without the checkpoint the WAL kept them at its
    /// high-water size until a later pass. A failed checkpoint there is dropped
    /// so the vacuum's own error is the one thrown.
    static func checkpointing(_ vacuum: (inout Int) throws -> Int,
                              checkpoint: () throws -> Void) throws -> Int {
        var committed = 0
        let freed: Int
        do {
            freed = try vacuum(&committed)
        } catch {
            if committed > 0 { try? checkpoint() }
            throw error
        }
        if freed > 0 { try checkpoint() }
        return freed
    }

    /// The writer's page cache while a vacuum runs, in KiB (256 MiB), put back to
    /// what it was afterwards. Every page `incremental_vacuum` moves walks the
    /// freelist's trunk pages for a slot (one trunk per ~1022 free pages at 4 KiB);
    /// with SQLite's 2000 KiB default, 2.68 M free pages (about 2600 trunks) did
    /// not fit, every move re-read the chain from a USB disk, and a pass freed
    /// nothing in half an hour. 256 MiB holds the chain of about 65 M free pages.
    static let vacuumCacheKiB = 262_144

    /// The smallest step ``vacuumSteps(pagesPerStep:carry:until:_:)`` halves down to.
    /// Deep in a 2 M-page freelist one page cost 40 ms and more, so the smallest
    /// step has to fit the step deadline there too.
    static let minimumVacuumStep = 16

    /// The write deadline of one vacuum step, shorter than the pool's 60 s: an
    /// ejected step rolls back whole, so the deadline is the work it throws away.
    /// At 60 s two passes freed nothing, each spending its 300 s on ejected steps.
    static let vacuumStepDeadline: Duration = .seconds(30)

    /// The size of the vacuum step after one that went through in `took`: doubled
    /// (up to `fullStep`) under ``trimGrowthCeiling``, halved (down to `minimum`)
    /// over twice it, otherwise unchanged. The cost of a page depends on where its
    /// slot sits in the freelist, so a pass that walks into a slow stretch has to
    /// shrink before the step deadline ejects it, not after.
    static func nextVacuumStep(_ size: Int, upTo fullStep: Int, minimum: Int, took: Duration) -> Int {
        if took > trimGrowthCeiling * 2 { return max(minimum, size / 2) }
        return grownTrimBatch(size, upTo: fullStep, took: took)
    }

    /// Runs `step(size)`, one committed `incremental_vacuum(size)`, until no free
    /// page is left, a step frees nothing, or `end` passes (the first step always
    /// runs), and returns the pages freed. A step the write deadline ejected rolled
    /// back whole, so it runs again at half the size, down to ``minimumVacuumStep``;
    /// a step that went through sizes the next by its time
    /// (``nextVacuumStep(_:upTo:minimum:took:)``). On a slow USB disk one step of 2048 pages once ran past
    /// the 60 s deadline, which failed the pass. A step at the minimum that still runs
    /// out throws the deadline error; the steps before it stay committed.
    ///
    /// The first step runs at `carry` (the size the last vacuum ended on, nil: full),
    /// and `carry` is left at the size this one ended on. Halving stops once `end`
    /// has passed: each ejected step costs the full deadline, and retrying past the
    /// end once stretched a 300 s pass to 1028 s for half a megabyte, every pass
    /// starting over at 2048 pages the disk could no longer take.
    static func vacuumSteps(pagesPerStep: Int, carry: inout Int?, until end: ContinuousClock.Instant,
                            _ step: (Int) throws -> (freed: Int, remaining: Int)) throws -> Int {
        let fullStep = max(1, pagesPerStep)
        let minimum = min(fullStep, minimumVacuumStep)
        var size = max(minimum, min(fullStep, carry ?? fullStep))
        defer { carry = size }
        var freed = 0
        while true {
            let started = ContinuousClock.now
            let stepFreed: Int
            let remaining: Int
            do {
                (stepFreed, remaining) = try step(size)
            } catch BoundedDatabaseError.deadlineExceeded where size > minimum {
                size = max(minimum, size / 2)
                if ContinuousClock.now >= end { return freed }
                continue
            }
            freed += stepFreed
            size = nextVacuumStep(size, upTo: fullStep, minimum: minimum, took: ContinuousClock.now - started)
            if remaining == 0 || stepFreed == 0 || ContinuousClock.now >= end { return freed }
        }
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
