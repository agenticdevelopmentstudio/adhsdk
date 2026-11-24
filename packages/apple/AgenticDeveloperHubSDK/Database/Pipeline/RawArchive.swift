import CryptoKit
import Foundation
import GRDB

public enum RawArchiveError: Error, Equatable {
    /// The stored bytes failed decompression, or their size or sha256 disagrees
    /// with what was recorded at write time. Wrong bytes are never returned.
    case corruptPayload(id: Int64)
    /// A record or an existing file names a different provider than this archive.
    case providerMismatch(expected: String, got: String)
}

public struct ArchivedRecord: Sendable, Equatable {
    /// The rowid; ascending ids are replay order.
    public let id: Int64
    public let record: RawRecord

    public init(id: Int64, record: RawRecord) {
        self.id = id
        self.record = record
    }
}

/// What happened to one record handed to `RawArchive.append`.
public enum ArchiveAppendOutcome: Sendable, Equatable {
    /// Stored as a new row.
    case inserted(Int64)
    /// The key was already archived with the same bytes (sha256 matches).
    case duplicate(Int64)
    /// The key was already archived with DIFFERENT bytes. The archive keeps the
    /// first payload; the incoming bytes are not stored here, so the caller must
    /// keep them (the drainer quarantines the spool record).
    case conflict(existingID: Int64, archivedSHA256: String, incomingSHA256: String)

    /// The archive row that holds this key.
    public var id: Int64 {
        switch self {
        case .inserted(let id), .duplicate(let id): return id
        case .conflict(let id, _, _): return id
        }
    }
}

public struct ArchiveAppendResult: Sendable, Equatable {
    /// Same order as the input.
    public let outcomes: [ArchiveAppendOutcome]

    public init(outcomes: [ArchiveAppendOutcome]) {
        self.outcomes = outcomes
    }

    /// Same order as the input; the existing id for a duplicate or a conflict.
    public var ids: [Int64] { outcomes.map(\.id) }

    /// New rows only; duplicates and conflicts are not counted.
    public var insertedCount: Int {
        outcomes.filter { if case .inserted = $0 { return true } else { return false } }.count
    }
}

/// The untrimmed backup of everything a provider ever ingested: every record is
/// stored verbatim (LZFSE-compressed when that helps), append-only, and never
/// deleted from, updated or trimmed by any code in this framework. A duplicate
/// dedup key keeps the first payload; `append` reports a key that arrives again
/// with different bytes as `.conflict`. One file per provider.
public final class RawArchive: @unchecked Sendable {
    public static func fileName(provider: String) -> String { "\(provider)-raw.db" }

    public let provider: String
    private let pool: BoundedDatabase

    private static let compressionLZFSE = "lzfse"
    private static let compressionNone = "none"

    public init(path: String, provider: String) throws {
        self.provider = provider
        // The archive is the backup: durability beats speed.
        self.pool = try BoundedDatabase(
            path: path, readers: 2,
            readDeadline: .seconds(30), writeDeadline: .seconds(60),
            prepare: { conn in try conn.execute(sql: "PRAGMA synchronous=FULL") }
        )
        try pool.write { conn in
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS raw_record (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    source_kind TEXT NOT NULL,
                    dedup_key TEXT NOT NULL UNIQUE,
                    received_at REAL NOT NULL,
                    payload_size INTEGER NOT NULL,
                    payload_sha256 TEXT NOT NULL,
                    compression TEXT NOT NULL,
                    payload BLOB NOT NULL
                )
                """)
            try conn.execute(sql: "CREATE TABLE IF NOT EXISTS archive_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
            let existing = try String.fetchOne(conn, sql: "SELECT value FROM archive_meta WHERE key = 'provider'")
            if let existing {
                if existing != provider {
                    throw RawArchiveError.providerMismatch(expected: provider, got: existing)
                }
            } else {
                try conn.execute(
                    sql: "INSERT INTO archive_meta(key, value) VALUES('provider', ?)", arguments: [provider])
            }
        }
    }

    // MARK: - Writing

    /// Stores every record in one transaction and reports, per record, whether it
    /// was inserted, a byte-identical duplicate, or a conflict (same key, different
    /// sha256), including against an earlier record in the same call. Throws
    /// `.providerMismatch` before writing anything if any record belongs to another
    /// provider.
    @discardableResult
    public func append(_ records: [RawRecord]) throws -> ArchiveAppendResult {
        if let foreign = records.first(where: { $0.provider != provider }) {
            throw RawArchiveError.providerMismatch(expected: provider, got: foreign.provider)
        }
        // Compress, verify and hash outside the transaction.
        let prepared = records.map { Self.encode($0.payload) }
        return try pool.write { conn in
            var outcomes: [ArchiveAppendOutcome] = []
            outcomes.reserveCapacity(records.count)
            for (record, encoded) in zip(records, prepared) {
                try conn.execute(sql: """
                    INSERT INTO raw_record(source_kind, dedup_key, received_at, payload_size,
                                           payload_sha256, compression, payload)
                    VALUES(?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(dedup_key) DO NOTHING
                    """, arguments: [
                        record.sourceKind, record.dedupKey, record.receivedAt.timeIntervalSince1970,
                        record.payload.count, encoded.sha256, encoded.compression, encoded.stored
                    ])
                let inserted = conn.changesCount > 0
                guard let row = try Row.fetchOne(
                    conn, sql: "SELECT id, payload_sha256 FROM raw_record WHERE dedup_key = ?",
                    arguments: [record.dedupKey]
                ) else {
                    throw DatabaseError(message: "raw_record row missing right after insert")
                }
                let id: Int64 = row["id"]
                let archivedSHA: String = row["payload_sha256"]
                if inserted {
                    outcomes.append(.inserted(id))
                } else if archivedSHA == encoded.sha256 {
                    outcomes.append(.duplicate(id))
                } else {
                    outcomes.append(.conflict(
                        existingID: id, archivedSHA256: archivedSHA, incomingSHA256: encoded.sha256))
                }
            }
            return ArchiveAppendResult(outcomes: outcomes)
        }
    }

    // MARK: - Reading

    /// Every reading method takes an optional `deadline`: nil keeps the archive's
    /// `readDeadline` (30 s), right for the live drain. A bulk pass over a large
    /// archive (`Replayer`) passes `EventStore.bulkDeadline`, the same budget its
    /// writes get: one 5,000-record chunk read on a slow volume can take longer
    /// than 30 s, and a replay stopped by it ends with `deadlineExceeded`.
    public func record(id: Int64, deadline: Duration? = nil) throws -> ArchivedRecord? {
        try pool.read(deadline: deadline) { conn in
            guard let row = try Row.fetchOne(conn, sql: Self.selectSQL + " WHERE id = ?", arguments: [id]) else {
                return nil
            }
            return try decode(row)
        }
    }

    /// Records with ids greater than `id`, ascending, at most `limit`.
    public func records(after id: Int64, limit: Int) throws -> [ArchivedRecord] {
        try pool.read { conn in
            let rows = try Row.fetchAll(
                conn, sql: Self.selectSQL + " WHERE id > ? ORDER BY id ASC LIMIT ?", arguments: [id, limit])
            return try rows.map { try decode($0) }
        }
    }

    /// Ids greater than `id`, ascending, at most `limit`, and cut so their total
    /// payload size stays within `maxBytes` (always at least one id).
    public func ids(after id: Int64, limit: Int,
                    maxBytes: Int = PipelineLimits.defaultMaxBatchBytes,
                    deadline: Duration? = nil) throws -> [Int64] {
        try pool.read(deadline: deadline) { conn in
            let rows = try Row.fetchAll(
                conn, sql: "SELECT id, payload_size FROM raw_record WHERE id > ? ORDER BY id ASC LIMIT ?",
                arguments: [id, limit])
            let sizes: [Int] = rows.map { $0["payload_size"] }
            let keep = PipelineLimits.prefixWithinBudget(sizes, maxBytes: maxBytes)
            return rows.prefix(keep).map { $0["id"] }
        }
    }

    /// Most ids bound into one `IN (…)` statement; SQLite's historical bind limit is 999.
    static let maxIDsPerStatement = 500

    /// The records with these ids, ascending, each once; ids that do not exist are
    /// skipped. Reads exactly the requested rows (`WHERE id IN (…)`, at most
    /// `maxIDsPerStatement` ids per statement, all in one read transaction), so a
    /// batch mixing an old id with new ones never touches the rows between them.
    public func records(ids: [Int64], deadline: Duration? = nil) throws -> [ArchivedRecord] {
        let wanted = Array(Set(ids)).sorted()
        guard !wanted.isEmpty else { return [] }
        return try pool.read(deadline: deadline) { conn in
            var result: [ArchivedRecord] = []
            result.reserveCapacity(wanted.count)
            var start = 0
            while start < wanted.count {
                let chunk = Array(wanted[start..<min(wanted.count, start + Self.maxIDsPerStatement)])
                let marks = Array(repeating: "?", count: chunk.count).joined(separator: ",")
                let rows = try Row.fetchAll(
                    conn, sql: Self.selectSQL + " WHERE id IN (\(marks)) ORDER BY id ASC",
                    arguments: StatementArguments(chunk))
                result += try rows.map { try decode($0) }
                start += chunk.count
            }
            return result
        }
    }

    public func id(forDedupKey key: String) throws -> Int64? {
        try pool.read { conn in
            try Int64.fetchOne(conn, sql: "SELECT id FROM raw_record WHERE dedup_key = ?", arguments: [key])
        }
    }

    public func count() throws -> Int {
        try pool.read { conn in try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM raw_record") ?? 0 }
    }

    /// The highest id, 0 when empty.
    public func maxID() throws -> Int64 {
        try pool.read { conn in try Int64.fetchOne(conn, sql: "SELECT MAX(id) FROM raw_record") ?? 0 }
    }

    // MARK: - Encoding

    private static let selectSQL = """
        SELECT id, source_kind, dedup_key, received_at, payload_size, payload_sha256, compression, payload
        FROM raw_record
        """

    private struct Encoded {
        let stored: Data
        let compression: String
        let sha256: String
    }

    /// Same as `Core/Text/DigestHex.swift` `hexString`; copied because Pipeline
    /// (the apple-database tier) must not import Core.
    static func hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    /// Compresses when that helps, then decompresses and compares before trusting
    /// it: a compressor bug falls back to storing the bytes uncompressed rather than
    /// surfacing only at replay.
    private static func encode(_ payload: Data) -> Encoded {
        let digest = hex(payload)
        if !payload.isEmpty,
           let compressed = try? (payload as NSData).compressed(using: .lzfse) as Data,
           compressed.count < payload.count,
           let roundTrip = try? (compressed as NSData).decompressed(using: .lzfse) as Data,
           roundTrip == payload {
            return Encoded(stored: compressed, compression: compressionLZFSE, sha256: digest)
        }
        return Encoded(stored: payload, compression: compressionNone, sha256: digest)
    }

    private func decode(_ row: Row) throws -> ArchivedRecord {
        let id: Int64 = row["id"]
        let stored: Data = row["payload"]
        let compression: String = row["compression"]
        let size: Int = row["payload_size"]
        let sha: String = row["payload_sha256"]

        let payload: Data
        switch compression {
        case Self.compressionLZFSE:
            guard let inflated = try? (stored as NSData).decompressed(using: .lzfse) as Data else {
                throw RawArchiveError.corruptPayload(id: id)
            }
            payload = inflated
        case Self.compressionNone:
            payload = stored
        default:
            throw RawArchiveError.corruptPayload(id: id)
        }
        guard payload.count == size, Self.hex(payload) == sha else {
            throw RawArchiveError.corruptPayload(id: id)
        }
        let receivedAt: Double = row["received_at"]
        return ArchivedRecord(id: id, record: RawRecord(
            provider: provider, sourceKind: row["source_kind"], dedupKey: row["dedup_key"],
            receivedAt: Date(timeIntervalSince1970: receivedAt), payload: payload))
    }
}
