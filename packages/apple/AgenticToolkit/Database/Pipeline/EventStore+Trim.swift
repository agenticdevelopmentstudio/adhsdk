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
}

/// Stats for a SQLite file the toolkit owns no store for (the main database, a raw
/// archive). Opens it read-only and never creates it.
public enum SQLiteFileStats {
    public static func stats(path: String) throws -> StoreFileStats {
        guard FileManager.default.fileExists(atPath: path) else { throw SQLiteFileStatsError.missingFile(path: path) }
        var configuration = Configuration()
        configuration.readonly = true
        let queue = try DatabaseQueue(path: path, configuration: configuration)
        defer { try? queue.close() }
        return try queue.read { conn in try StoreFileStats.read(path: path, conn) }
    }
}

extension EventStore {

    /// Deletes rows with `time < cutoff`, oldest first, `batch` rows per write
    /// transaction (the writer is released between batches): events, then
    /// messages, then turns, then the `sessions` rows of this file that are ended
    /// (`status = 'ended'` or `ended_at IS NOT NULL`), ended before the cutoff, and
    /// have no events, messages or turns left. Never touches any other database.
    ///
    /// The first batch always runs, so every call makes progress; before each later
    /// one, a passed `deadline` stops the call with `finished = false`. A rerun with
    /// the same cutoff continues where this one stopped.
    public func trim(olderThan cutoff: Double, batch: Int = 500, deadline: Date) throws -> EventStoreTrimResult {
        let limit = max(1, batch)
        var result = EventStoreTrimResult(finished: false)
        var ranBatch = false

        /// Runs `sql` (bound to `arguments` + the limit) until a batch deletes fewer
        /// than `limit` rows; false when the deadline stopped it first.
        func drain(_ sql: String, _ arguments: StatementArguments,
                   into field: WritableKeyPath<EventStoreTrimResult, Int>) throws -> Bool {
            while true {
                if ranBatch && Date() >= deadline { return false }
                let deleted = try pool.write(deadline: nil) { conn -> Int in
                    try conn.execute(sql: sql, arguments: arguments + [limit])
                    return conn.changesCount
                }
                ranBatch = true
                result[keyPath: field] += deleted
                if deleted < limit { return true }
            }
        }

        guard try drain("""
            DELETE FROM events WHERE id IN (SELECT id FROM events WHERE time < ? ORDER BY time LIMIT ?)
            """, [cutoff], into: \.events) else { return result }

        // `messages_time` leads with provider, so trim one provider at a time.
        for provider in try messageProviders() {
            guard try drain("""
                DELETE FROM messages WHERE id IN (
                    SELECT id FROM messages WHERE provider = ? AND time < ? ORDER BY time LIMIT ?)
                """, [provider, cutoff], into: \.messages) else { return result }
        }

        guard try drain("""
            DELETE FROM turns WHERE id IN (SELECT id FROM turns WHERE time < ? ORDER BY time LIMIT ?)
            """, [cutoff], into: \.turns) else { return result }

        guard try drain("""
            DELETE FROM sessions WHERE (provider, session_id) IN (
                SELECT s.provider, s.session_id FROM sessions s
                WHERE (s.status = 'ended' OR s.ended_at IS NOT NULL)
                  AND COALESCE(s.ended_at, s.as_of) < ?
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
    public func incrementalVacuum(pagesPerStep: Int = 2048, deadline: Date) throws -> Int? {
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
            if remaining == 0 || stepFreed == 0 || Date() >= deadline { break }
        }
        if freed > 0 {
            try pool.writeWithoutTransaction(deadline: nil) { conn in
                _ = try Row.fetchOne(conn, sql: "PRAGMA wal_checkpoint(TRUNCATE)")
            }
        }
        return freed
    }

    /// This store's file: sizes on disk and page accounting.
    public func fileStats() throws -> StoreFileStats {
        try pool.read { conn in try StoreFileStats.read(path: path, conn) }
    }
}
