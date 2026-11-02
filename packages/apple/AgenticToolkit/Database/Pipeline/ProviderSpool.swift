import Foundation
import GRDB

public enum ProviderSpoolError: Error, Equatable {
    /// A record or an existing file names a different provider than this spool.
    case providerMismatch(expected: String, got: String)
}

public struct SpooledRecord: Sendable, Equatable {
    public let id: Int64
    public let record: RawRecord
    public let attempts: Int

    public init(id: Int64, record: RawRecord, attempts: Int) {
        self.id = id
        self.record = record
        self.attempts = attempts
    }
}

public struct QuarantinedRecord: Sendable, Equatable {
    public let id: Int64
    public let record: RawRecord
    public let reason: String
    public let quarantinedAt: Date

    public init(id: Int64, record: RawRecord, reason: String, quarantinedAt: Date) {
        self.id = id
        self.record = record
        self.reason = reason
        self.quarantinedAt = quarantinedAt
    }
}

/// The durable inbox of one provider. A record that has been appended leaves the
/// spool only through `complete` or by moving to quarantine; it is never lost.
/// `dedup_key` is deliberately not unique here: redeliveries are collapsed by the
/// archive and the store, so the spool never refuses input.
///
/// Durability: `synchronous=FULL`. An append is acknowledged to the source (a hook
/// exits, a cursor advances) only after it commits, so a commit must survive power
/// loss; under NORMAL the last transactions in the WAL can roll back.
public final class ProviderSpool: @unchecked Sendable {
    public static func fileName(provider: String) -> String { "\(provider)-ingest.db" }
    public static let maxAttempts = 5

    public let provider: String
    private let pool: BoundedDatabase

    public init(path: String, provider: String) throws {
        self.provider = provider
        self.pool = try BoundedDatabase(
            path: path, readers: 2,
            readDeadline: .seconds(30), writeDeadline: .seconds(60),
            prepare: { conn in try conn.execute(sql: "PRAGMA synchronous=FULL") }
        )
        try pool.write { conn in
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS spooled_record (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    source_kind TEXT NOT NULL, dedup_key TEXT NOT NULL,
                    received_at REAL NOT NULL, payload BLOB NOT NULL,
                    attempts INTEGER NOT NULL DEFAULT 0, last_error TEXT)
                """)
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS quarantined_record (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    source_kind TEXT NOT NULL, dedup_key TEXT NOT NULL,
                    received_at REAL NOT NULL, payload BLOB NOT NULL,
                    reason TEXT NOT NULL, quarantined_at REAL NOT NULL)
                """)
            try conn.execute(sql: "CREATE TABLE IF NOT EXISTS source_state (key TEXT PRIMARY KEY, value BLOB NOT NULL)")
            try conn.execute(sql: "CREATE TABLE IF NOT EXISTS spool_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
            let existing = try String.fetchOne(conn, sql: "SELECT value FROM spool_meta WHERE key = 'provider'")
            if let existing {
                if existing != provider {
                    throw ProviderSpoolError.providerMismatch(expected: provider, got: existing)
                }
            } else {
                try conn.execute(
                    sql: "INSERT INTO spool_meta(key, value) VALUES('provider', ?)", arguments: [provider])
            }
        }
    }

    // MARK: - Writing

    /// Spools every record in one transaction. Throws `.providerMismatch` before
    /// writing anything if any record belongs to another provider.
    public func append(_ records: [RawRecord]) throws {
        try checkProviders(records)
        try pool.write { conn in try Self.insert(records, conn) }
    }

    /// Appends and advances a source cursor in the same transaction.
    public func append(_ records: [RawRecord], settingSourceState key: String, to value: Data) throws {
        try checkProviders(records)
        try pool.write { conn in
            try Self.insert(records, conn)
            try Self.upsertState(key, value, conn)
        }
    }

    public func complete(ids: [Int64]) throws {
        guard !ids.isEmpty else { return }
        try pool.write { conn in
            for id in ids {
                try conn.execute(sql: "DELETE FROM spooled_record WHERE id = ?", arguments: [id])
            }
        }
    }

    /// Bumps attempts. Returns true when attempts reach `maxAttempts`.
    public func recordFailure(id: Int64, reason: String) throws -> Bool {
        try pool.write { conn in
            try conn.execute(
                sql: "UPDATE spooled_record SET attempts = attempts + 1, last_error = ? WHERE id = ?",
                arguments: [reason, id])
            let attempts = try Int.fetchOne(
                conn, sql: "SELECT attempts FROM spooled_record WHERE id = ?", arguments: [id]) ?? 0
            return attempts >= Self.maxAttempts
        }
    }

    /// Moves the row to quarantine in one transaction. The record is never deleted.
    public func quarantine(id: Int64, reason: String) throws {
        try pool.write { conn in
            try conn.execute(sql: """
                INSERT INTO quarantined_record(source_kind, dedup_key, received_at, payload, reason, quarantined_at)
                SELECT source_kind, dedup_key, received_at, payload, ?, ? FROM spooled_record WHERE id = ?
                """, arguments: [reason, Date().timeIntervalSince1970, id])
            try conn.execute(sql: "DELETE FROM spooled_record WHERE id = ?", arguments: [id])
        }
    }

    /// Moves quarantined rows back to the spool with attempts 0, in one transaction.
    public func requeueQuarantined(ids: [Int64]) throws {
        guard !ids.isEmpty else { return }
        try pool.write { conn in
            for id in ids {
                try conn.execute(sql: """
                    INSERT INTO spooled_record(source_kind, dedup_key, received_at, payload, attempts)
                    SELECT source_kind, dedup_key, received_at, payload, 0 FROM quarantined_record WHERE id = ?
                    """, arguments: [id])
                try conn.execute(sql: "DELETE FROM quarantined_record WHERE id = ?", arguments: [id])
            }
        }
    }

    public func setSourceState(_ key: String, _ value: Data) throws {
        try pool.write { conn in try Self.upsertState(key, value, conn) }
    }

    // MARK: - Reading

    /// Oldest first (ascending id), at most `limit` records whose payloads total at
    /// most `maxBytes`; always at least one record when any is pending, even one
    /// larger than the budget. A limit of zero or less returns nothing.
    public func pendingBatch(limit: Int, maxBytes: Int = PipelineLimits.defaultMaxBatchBytes) throws
        -> [SpooledRecord] {
        guard limit > 0 else { return [] }
        return try pool.read { conn in
            // Size first, so an oversized batch is cut before any payload is read.
            let sized = try Row.fetchAll(conn, sql: """
                SELECT id, length(payload) AS size FROM spooled_record ORDER BY id ASC LIMIT ?
                """, arguments: [limit])
            let sizes: [Int] = sized.map { $0["size"] ?? 0 }
            let keep = PipelineLimits.prefixWithinBudget(sizes, maxBytes: maxBytes)
            guard keep > 0 else { return [] }
            let lastID: Int64 = sized[keep - 1]["id"]
            let rows = try Row.fetchAll(conn, sql: """
                SELECT id, source_kind, dedup_key, received_at, payload, attempts
                FROM spooled_record WHERE id <= ? ORDER BY id ASC LIMIT ?
                """, arguments: [lastID, keep])
            return rows.map { row in
                SpooledRecord(id: row["id"], record: makeRecord(row), attempts: row["attempts"])
            }
        }
    }

    public func quarantined(limit: Int) throws -> [QuarantinedRecord] {
        guard limit > 0 else { return [] }
        return try pool.read { conn in
            let rows = try Row.fetchAll(conn, sql: """
                SELECT id, source_kind, dedup_key, received_at, payload, reason, quarantined_at
                FROM quarantined_record ORDER BY id ASC LIMIT ?
                """, arguments: [limit])
            return rows.map { row in
                let when: Double = row["quarantined_at"]
                return QuarantinedRecord(
                    id: row["id"], record: makeRecord(row), reason: row["reason"],
                    quarantinedAt: Date(timeIntervalSince1970: when))
            }
        }
    }

    public func pendingCount() throws -> Int {
        try pool.read { conn in try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM spooled_record") ?? 0 }
    }

    /// Records parked in quarantine: out of attempts, or bytes the archive refused.
    public func quarantinedCount() throws -> Int {
        try pool.read { conn in try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM quarantined_record") ?? 0 }
    }

    public func sourceState(_ key: String) throws -> Data? {
        try pool.read { conn in
            try Data.fetchOne(conn, sql: "SELECT value FROM source_state WHERE key = ?", arguments: [key])
        }
    }

    // MARK: - Helpers

    private func checkProviders(_ records: [RawRecord]) throws {
        if let foreign = records.first(where: { $0.provider != provider }) {
            throw ProviderSpoolError.providerMismatch(expected: provider, got: foreign.provider)
        }
    }

    private func makeRecord(_ row: Row) -> RawRecord {
        let received: Double = row["received_at"]
        return RawRecord(
            provider: provider, sourceKind: row["source_kind"], dedupKey: row["dedup_key"],
            receivedAt: Date(timeIntervalSince1970: received), payload: row["payload"])
    }

    private static func insert(_ records: [RawRecord], _ conn: Database) throws {
        for record in records {
            try conn.execute(sql: """
                INSERT INTO spooled_record(source_kind, dedup_key, received_at, payload)
                VALUES(?, ?, ?, ?)
                """, arguments: [
                    record.sourceKind, record.dedupKey, record.receivedAt.timeIntervalSince1970, record.payload
                ])
        }
    }

    private static func upsertState(_ key: String, _ value: Data, _ conn: Database) throws {
        try conn.execute(sql: """
            INSERT INTO source_state(key, value) VALUES(?, ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value
            """, arguments: [key, value])
    }
}
