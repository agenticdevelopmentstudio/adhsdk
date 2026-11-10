import Testing
import Foundation
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
@testable import AgenticDeveloperHubSDKSyncGRDB

/// One resource in one table of its own, recording which resources each
/// truncate call was handed.
private final class TableProjection: SyncMirrorProjection, @unchecked Sendable {
    let resources: Set<String>
    let table: String
    private let lock = NSLock()
    private var truncations: [[String]] = []
    private var purges = 0

    init(resource: String, table: String) {
        self.resources = [resource]
        self.table = table
    }

    var truncated: [[String]] { lock.withLock { truncations } }
    var purged: Int { lock.withLock { purges } }

    func createTables(in conn: Database) throws {
        try conn.execute(sql: """
            CREATE TABLE IF NOT EXISTS \(table) (
                id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL DEFAULT '',
                sync_version INTEGER NOT NULL DEFAULT 0, deleted_at TEXT)
            """)
    }

    func upsert(resource: String, id: String, syncVersion: Int, data: [String: JSONValue], in conn: Database) throws {
        let name: String
        if case .string(let value) = data["name"] { name = value } else { name = "" }
        try conn.execute(sql: """
            INSERT INTO \(table) (id, name, sync_version) VALUES (?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET name = excluded.name, sync_version = excluded.sync_version
            """, arguments: [id, name, syncVersion])
    }

    func markDeleted(resource: String, id: String, syncVersion: Int?, in conn: Database) throws {
        try conn.execute(sql: "UPDATE \(table) SET deleted_at = 'now' WHERE id = ?", arguments: [id])
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

    func rows(resource: String, limit: Int, offset: Int, in conn: Database) throws -> [[String: JSONValue]] {
        try Row.fetchAll(conn, sql: """
            SELECT id, name FROM \(table) WHERE deleted_at IS NULL ORDER BY id LIMIT ? OFFSET ?
            """, arguments: [limit, offset]).map { ["id": .string($0["id"]), "name": .string($0["name"])] }
    }

    func row(resource: String, id: String, in conn: Database) throws -> [String: JSONValue]? {
        try Row.fetchOne(conn, sql: "SELECT id, name FROM \(table) WHERE id = ? AND deleted_at IS NULL",
                         arguments: [id]).map { ["id": .string($0["id"]), "name": .string($0["name"])] }
    }
}

@Suite("Several mirror projections")
struct MultipleProjectionsTests {

    private let resources = [
        SyncResource(resource: "test.people", schemaVersion: 1),
        SyncResource(resource: "test.places", schemaVersion: 1),
        SyncResource(resource: "test.other", schemaVersion: 1)
    ]

    @Test("each resource lands in the projection that claims it, and the rest stay generic")
    func routesByResource() async throws {
        let people = TableProjection(resource: "test.people", table: "people")
        let places = TableProjection(resource: "test.places", table: "places")
        let store = GRDBSyncStore(database: try BoundedDatabase(path: ":memory:"), projections: [people, places])
        try await store.prepare(resources: resources)
        try await store.apply([
            SyncChange(resource: "test.people", id: "p1", op: .upsert, syncVersion: "2",
                       data: ["name": .string("Ada")]),
            SyncChange(resource: "test.places", id: "l1", op: .upsert, syncVersion: "3",
                       data: ["name": .string("Kew")]),
            SyncChange(resource: "test.other", id: "o1", op: .upsert, syncVersion: "4", data: ["k": .string("v")])
        ], advancingTo: nil)
        try store.database.read { (conn: Database) throws in
            #expect(try String.fetchOne(conn, sql: "SELECT name FROM people") == "Ada")
            #expect(try String.fetchOne(conn, sql: "SELECT name FROM places") == "Kew")
            #expect(try conn.tableExists("test_other"))
            #expect(try conn.tableExists("test_people") == false)
        }
        #expect(try store.liveRow(resource: "test.places", id: "l1") == ["id": .string("l1"), "name": .string("Kew")])
        try await store.apply([
            SyncChange(resource: "test.places", id: "l1", op: .delete, syncVersion: "5", data: nil)
        ], advancingTo: nil)
        #expect(try store.liveRows(resource: "test.places").isEmpty)
        #expect(try store.liveRows(resource: "test.people").count == 1)
    }

    @Test("a resync hands each projection only its own resources, and an identity change reaches every one")
    func truncateAndPurgeReachEachProjection() async throws {
        let people = TableProjection(resource: "test.people", table: "people")
        let places = TableProjection(resource: "test.places", table: "places")
        let store = GRDBSyncStore(database: try BoundedDatabase(path: ":memory:"), projections: [people, places])
        try await store.prepare(resources: resources)
        try await store.resetForResync()
        #expect(people.truncated == [["test.people"]])
        #expect(places.truncated == [["test.places"]])
        try await store.purgeForIdentityChange()
        #expect(people.purged == 1)
        #expect(places.purged == 1)
    }
}
