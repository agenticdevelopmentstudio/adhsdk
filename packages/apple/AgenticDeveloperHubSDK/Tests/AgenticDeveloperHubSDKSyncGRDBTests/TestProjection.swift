import Foundation
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
@testable import AgenticDeveloperHubSDKSyncGRDB

/// A projection that keeps its resources in one table with two real columns,
/// following the projection contract: a delete keeps the row as a tombstone
/// and takes the delete's version when it has one, and an upsert brings a
/// tombstoned row back. It records each truncate call's resources and each
/// identity purge, so a test can see what the store handed it.
final class TestProjection: SyncMirrorProjection, @unchecked Sendable {

    let resources: Set<String>
    let table: String
    private let lock = NSLock()
    private var truncations: [[String]] = []
    private var purges = 0
    private var fullRowFlags: [Bool] = []
    private var finishes: [Int] = []

    init(resources: Set<String> = ["test.people"], table: String = "people") {
        self.resources = resources
        self.table = table
    }

    var truncated: [[String]] { lock.withLock { truncations } }
    var purged: Int { lock.withLock { purges } }
    /// The `isFullRow` of every upsert, in order. It stays empty if the store
    /// ever reaches only the requirement without the flag, which is what the
    /// protocol's forwarding default would make it do.
    var upsertFullRowFlags: [Bool] { lock.withLock { fullRowFlags } }
    /// One entry per `finishBatch` call: how many rows the table held then,
    /// which shows the call came after the batch's writes, in its transaction.
    var finishedBatches: [Int] { lock.withLock { finishes } }

    func createTables(in conn: Database) throws {
        try conn.execute(sql: """
            CREATE TABLE IF NOT EXISTS \(table) (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL DEFAULT '',
                sync_version INTEGER NOT NULL DEFAULT 0,
                deleted_at TEXT);
            """)
    }

    func upsert(resource: String, id: String, syncVersion: Int,
                data: [String: JSONValue], in conn: Database) throws {
        let name: String
        if case .string(let value) = data["name"] { name = value } else { name = "" }
        try conn.execute(
            sql: """
                INSERT INTO \(table) (id, name, sync_version, deleted_at) VALUES (?, ?, ?, NULL)
                ON CONFLICT(id) DO UPDATE SET name = excluded.name,
                    sync_version = excluded.sync_version, deleted_at = NULL
                """,
            arguments: [id, name, syncVersion])
    }

    func upsert(resource: String, id: String, syncVersion: Int,
                data: [String: JSONValue], isFullRow: Bool, in conn: Database) throws {
        lock.withLock { fullRowFlags.append(isFullRow) }
        try upsert(resource: resource, id: id, syncVersion: syncVersion, data: data, in: conn)
    }

    func markDeleted(resource: String, id: String, syncVersion: Int?, in conn: Database) throws {
        try conn.execute(
            sql: """
                UPDATE \(table) SET deleted_at = datetime('now'),
                    sync_version = COALESCE(?, sync_version) WHERE id = ?
                """,
            arguments: [syncVersion, id])
    }

    func setSyncVersion(_ version: Int, resource: String, id: String, in conn: Database) throws {
        try conn.execute(sql: "UPDATE \(table) SET sync_version = ? WHERE id = ?", arguments: [version, id])
    }

    func syncVersion(resource: String, id: String, in conn: Database) throws -> Int? {
        try Int.fetchOne(conn, sql: "SELECT sync_version FROM \(table) WHERE id = ?", arguments: [id])
    }

    func truncate(resources: [String], in conn: Database) throws {
        lock.withLock { truncations.append(resources) }
        try conn.execute(sql: "DELETE FROM \(table)")
    }

    func purgeIdentityState(in conn: Database) throws {
        lock.withLock { purges += 1 }
    }

    func finishBatch(in conn: Database) throws {
        let rows = try Int.fetchOne(conn, sql: "SELECT count(*) FROM \(table)") ?? 0
        lock.withLock { finishes.append(rows) }
    }

    func rows(resource: String, limit: Int, offset: Int, in conn: Database) throws -> [[String: JSONValue]] {
        try Row.fetchAll(
            conn,
            sql: "SELECT id, name FROM \(table) WHERE deleted_at IS NULL ORDER BY id LIMIT ? OFFSET ?",
            arguments: [limit, offset]
        ).map { ["id": .string($0["id"]), "name": .string($0["name"])] }
    }

    func row(resource: String, id: String, in conn: Database) throws -> [String: JSONValue]? {
        try Row.fetchOne(
            conn,
            sql: "SELECT id, name FROM \(table) WHERE id = ? AND deleted_at IS NULL",
            arguments: [id]
        ).map { ["id": .string($0["id"]), "name": .string($0["name"])] }
    }
}
