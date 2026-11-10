import Testing
import Foundation
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
@testable import AgenticDeveloperHubSDKSyncGRDB

@Suite("SyncMirrorProjection")
struct SyncMirrorProjectionTests {

    private func store(projected: Bool) throws -> GRDBSyncStore {
        let database = try BoundedDatabase(path: ":memory:")
        return GRDBSyncStore(
            database: database,
            projections: projected ? [TestProjection()] : [])
    }

    private let resources = [
        SyncResource(resource: "test.people", schemaVersion: 1),
        SyncResource(resource: "test.other", schemaVersion: 1)
    ]

    @Test("a projected resource gets the projection's tables, not a generic mirror")
    func projectedResourceSkipsGenericMirror() async throws {
        let store = try store(projected: true)
        try await store.prepare(resources: resources)
        try store.database.read { (conn: Database) throws in
            #expect(try conn.tableExists("people"))
            #expect(try conn.tableExists("test_people") == false)
            #expect(try conn.tableExists("test_other"))     // unprojected: unchanged
        }
    }

    @Test("a pulled change lands in the projection's columns")
    func applyRoutesToProjection() async throws {
        let store = try store(projected: true)
        try await store.prepare(resources: resources)
        try await store.apply([
            SyncChange(resource: "test.people", id: "p1", op: .upsert,
                       syncVersion: "7", data: ["name": .string("Ada")])
        ], advancingTo: nil)
        #expect(try store.liveRow(resource: "test.people", id: "p1") == ["id": .string("p1"), "name": .string("Ada")])
        try store.database.read { (conn: Database) throws in
            #expect(try String.fetchOne(conn, sql: "SELECT name FROM people WHERE id = 'p1'") == "Ada")
            #expect(try Int.fetchOne(conn, sql: "SELECT sync_version FROM people WHERE id = 'p1'") == 7)
        }
    }

    @Test("a pulled delete tombstones the projected row")
    func applyDeleteRoutesToProjection() async throws {
        let store = try store(projected: true)
        try await store.prepare(resources: resources)
        try await store.apply([
            SyncChange(resource: "test.people", id: "p1", op: .upsert, syncVersion: "1", data: ["name": .string("Ada")])
        ], advancingTo: nil)
        try await store.apply([
            SyncChange(resource: "test.people", id: "p1", op: .delete, syncVersion: "2", data: nil)
        ], advancingTo: nil)
        #expect(try store.liveRow(resource: "test.people", id: "p1") == nil)
        #expect(try store.liveRows(resource: "test.people").isEmpty)
    }

    @Test("a local mutation reads its base version from the projection")
    func stageReadsProjectedVersion() async throws {
        let store = try store(projected: true)
        try await store.prepare(resources: resources)
        try await store.apply([
            SyncChange(resource: "test.people", id: "p1", op: .upsert, syncVersion: "9", data: ["name": .string("Ada")])
        ], advancingTo: nil)
        try await store.stage(LocalMutation(
            resource: "test.people", rowId: "p1", type: .upsert, data: ["name": .string("Grace")]))

        let ops = try await store.pendingOps(limit: 10)
        #expect(ops.count == 1)
        #expect(ops[0].baseVersion == "9")
        try store.database.read { (conn: Database) throws in
            #expect(try String.fetchOne(conn, sql: "SELECT name FROM people WHERE id = 'p1'") == "Grace")
        }
    }

    @Test("the synchronous overloads work inside a caller's own transaction")
    func synchronousOverloadsShareATransaction() throws {
        let database = try BoundedDatabase(path: ":memory:")
        let store = GRDBSyncStore(database: database, projection: TestProjection())
        try database.write { conn in
            try store.prepare(resources: resources, in: conn)
            try conn.execute(sql: "INSERT INTO people (id, name) VALUES ('p1', 'Ada')")
            try store.stage(LocalMutation(
                resource: "test.people", rowId: "p1", type: .upsert,
                data: ["name": .string("Ada")]), in: conn)
        }
        #expect(try store.liveRow(resource: "test.people", id: "p1")?["name"] == .string("Ada"))
    }

    @Test("resetting for resync empties the projected tables too")
    func resetTruncatesProjection() async throws {
        let store = try store(projected: true)
        try await store.prepare(resources: resources)
        try await store.apply([
            SyncChange(resource: "test.people", id: "p1", op: .upsert, syncVersion: "1", data: ["name": .string("Ada")])
        ], advancingTo: nil)
        try await store.resetForResync()
        #expect(try store.liveRows(resource: "test.people").isEmpty)
    }

    @Test("a store with no projection behaves exactly as before")
    func projectionFreeStoreIsUnchanged() async throws {
        let store = try store(projected: false)
        try await store.prepare(resources: resources)
        try await store.apply([
            SyncChange(resource: "test.people", id: "p1", op: .upsert,
                       syncVersion: "3", data: ["name": .string("Ada")])
        ], advancingTo: nil)
        try store.database.read { (conn: Database) throws in
            #expect(try conn.tableExists("test_people"))
            #expect(try conn.tableExists("people") == false)
        }
        #expect(try store.liveRow(resource: "test.people", id: "p1")
                == ["id": .string("p1"), "name": .string("Ada")])
    }

    @Test("an unprojected resource in a projected store keeps the JSON mirror")
    func unprojectedResourcesAreUntouched() async throws {
        let store = try store(projected: true)
        try await store.prepare(resources: resources)
        try await store.apply([
            SyncChange(resource: "test.other", id: "o1", op: .upsert,
                       syncVersion: "1", data: ["k": .string("v")])
        ], advancingTo: nil)
        #expect(try store.liveRow(resource: "test.other", id: "o1")
                == ["id": .string("o1"), "k": .string("v")])
    }
}
