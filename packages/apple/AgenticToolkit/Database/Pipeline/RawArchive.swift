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

public struct ArchiveAppendResult: Sendable, Equatable {
    /// Same order as the input; an existing id for a duplicate.
    public let ids: [Int64]
    /// New rows only; duplicates are not counted.
    public let insertedCount: Int

    public init(ids: [Int64], insertedCount: Int) {
        self.ids = ids
        self.insertedCount = insertedCount
    }
}

/// The untrimmed backup of everything a provider ever ingested: every record is
/// stored verbatim (LZFSE-compressed when that helps), append-only, and never
/// deleted from, updated or trimmed by any code in this framework. A duplicate
/// dedup key keeps the first payload. One file per provider.
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

    /// Stores every record in one transaction. Throws `.providerMismatch` before
    /// writing anything if any record belongs to another provider.
    public func append(_ records: [RawRecord]) throws -> ArchiveAppendResult {
        if let foreign = records.first(where: { $0.provider != provider }) {
            throw RawArchiveError.providerMismatch(expected: provider, got: foreign.provider)
        }
        // Compress and hash outside the transaction.
        let prepared = records.map { Self.encode($0.payload) }
        return try pool.write { conn in
            var ids: [Int64] = []
            ids.reserveCapacity(records.count)
            var inserted = 0
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
                if conn.changesCount > 0 { inserted += 1 }
                guard let id = try Int64.fetchOne(
                    conn, sql: "SELECT id FROM raw_record WHERE dedup_key = ?", arguments: [record.dedupKey]
                ) else {
                    throw DatabaseError(message: "raw_record row missing right after insert")
                }
                ids.append(id)
            }
            return ArchiveAppendResult(ids: ids, insertedCount: inserted)
        }
    }

    // MARK: - Reading

    public func record(id: Int64) throws -> ArchivedRecord? {
        try pool.read { conn in
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

    private static func hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func encode(_ payload: Data) -> Encoded {
        let digest = hex(payload)
        if !payload.isEmpty,
           let compressed = try? (payload as NSData).compressed(using: .lzfse) as Data,
           compressed.count < payload.count {
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
