import Testing
import Foundation
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
@testable import AgenticDeveloperHubSDKSyncGRDB

@Suite("Several mirror projections")
struct MultipleProjectionsTests {

    private let resources = [
        SyncResource(resource: "test.people", schemaVersion: 1),
        SyncResource(resource: "test.places", schemaVersion: 1),
        SyncResource(resource: "test.other", schemaVersion: 1)
    ]

    @Test("each resource lands in the projection that claims it, and the rest stay generic")
    func routesByResource() async throws {
        let people = TestProjection(resources: ["test.people"], table: "people")
        let places = TestProjection(resources: ["test.places"], table: "places")
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
        try store.database.read { (conn: Database) throws in
            #expect(try Int.fetchOne(conn, sql: "SELECT sync_version FROM places WHERE id = 'l1'") == 5,
                    "the tombstone carries the delete's version")
        }
        try await store.apply([
            SyncChange(resource: "test.places", id: "l1", op: .upsert, syncVersion: "6",
                       data: ["name": .string("Kew Gardens")])
        ], advancingTo: nil)
        #expect(try store.liveRow(resource: "test.places", id: "l1")
                == ["id": .string("l1"), "name": .string("Kew Gardens")])
    }

    @Test("a resync hands each projection only its own resources, and an identity change reaches every one")
    func truncateAndPurgeReachEachProjection() async throws {
        let people = TestProjection(resources: ["test.people"], table: "people")
        let places = TestProjection(resources: ["test.places"], table: "places")
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
