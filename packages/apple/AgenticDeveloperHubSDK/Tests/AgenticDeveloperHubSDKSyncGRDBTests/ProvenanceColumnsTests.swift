import XCTest
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
@testable import AgenticDeveloperHubSDKSyncGRDB

/// Provenance (`origin`, `reached_accounts`), the account binding, and the
/// in-place upgrade of a mirror written before either existed.
final class ProvenanceColumnsTests: XCTestCase {

    private var dir: URL!
    private var path: String!
    private let notes = SyncResource(resource: "personal.notes", schemaVersion: 1)

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("provenance-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        path = dir.appendingPathComponent("mirror.db").path
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func provenance(_ store: GRDBSyncStore, id: String) throws -> (origin: String, reached: [String])? {
        try store.database.read { conn in
            try Row.fetchOne(
                conn, sql: "SELECT origin, reached_accounts FROM personal_notes WHERE id = ?", arguments: [id]
            ).map { row in
                let reached: String = row["reached_accounts"]
                return (row["origin"], try JSONDecoder().decode([String].self, from: Data(reached.utf8)))
            }
        }
    }

    func testAnOldSchemaDatabaseGainsTheColumnsAndKeepsItsRows() async throws {
        // The schema as it was before provenance and binding.
        let database = try BoundedDatabase(path: path)
        try database.write { conn in
            try conn.execute(sql: """
                CREATE TABLE _sync_state (id INTEGER PRIMARY KEY CHECK (id = 1), cursor TEXT);
                CREATE TABLE _sync_resources (resource TEXT PRIMARY KEY, schema_version INTEGER NOT NULL);
                CREATE TABLE personal_notes (
                    id TEXT PRIMARY KEY NOT NULL, sync_version INTEGER NOT NULL DEFAULT 0,
                    deleted_at TEXT, data TEXT NOT NULL DEFAULT '{}');
                INSERT INTO _sync_state (id, cursor) VALUES (1, 'c7');
                INSERT INTO _sync_resources (resource, schema_version) VALUES ('personal.notes', 1);
                INSERT INTO personal_notes (id, sync_version, data) VALUES ('n1', 3, '{"title":"kept"}');
                """)
        }
        let store = GRDBSyncStore(database: database)

        try await store.migrateProvenanceColumns()
        try await store.prepare(resources: [notes]) // and again through prepare: idempotent

        XCTAssertEqual(try store.liveRow(resource: "personal.notes", id: "n1")?["title"], .string("kept"))
        let row = try provenance(store, id: "n1")
        XCTAssertEqual(row?.origin, "local")
        XCTAssertEqual(row?.reached, [])
        let cursor = try await store.cursor()
        XCTAssertEqual(cursor?.rawValue, "c7")
        let bound = try await store.boundAccount()
        XCTAssertNil(bound)
    }

    func testAPulledRowRecordsItsOrigin() async throws {
        let store = GRDBSyncStore(database: try BoundedDatabase(path: path))
        try await store.prepare(resources: [notes])
        try await store.bind(account: "acct-a")

        try await store.apply(
            [SyncChange(resource: "personal.notes", id: "p1", op: .upsert, syncVersion: "1",
                        data: ["title": .string("pulled")])],
            advancingTo: SyncCursor(rawValue: "c1"))

        let row = try provenance(store, id: "p1")
        XCTAssertEqual(row?.origin, "account:acct-a")
        XCTAssertEqual(row?.reached, ["acct-a"])
    }

    func testALocalRowIsLocalUntilAPushReachesTheBoundAccount() async throws {
        let store = GRDBSyncStore(database: try BoundedDatabase(path: path))
        try await store.prepare(resources: [notes])
        try await store.bind(account: "acct-a")
        try await store.stage(LocalMutation(
            resource: "personal.notes", rowId: "l1", type: .upsert, data: ["title": .string("mine")]))

        XCTAssertEqual(try provenance(store, id: "l1")?.origin, "local")
        XCTAssertEqual(try provenance(store, id: "l1")?.reached, [])

        let ops = try await store.pendingOps(limit: 10)
        try await store.complete([SyncPushResult(opId: ops[0].opId, status: .applied, newVersion: "2")])

        let row = try provenance(store, id: "l1")
        XCTAssertEqual(row?.origin, "local")
        XCTAssertEqual(row?.reached, ["acct-a"])
    }

    func testBindingSurvivesAndCanBeRead() async throws {
        let store = GRDBSyncStore(database: try BoundedDatabase(path: path))
        let unbound = try await store.boundAccount()
        XCTAssertNil(unbound)
        try await store.apply([], advancingTo: SyncCursor(rawValue: "c2"))
        try await store.bind(account: "acct-a")
        let bound = try await store.boundAccount()
        XCTAssertEqual(bound, "acct-a")
        let cursor = try await store.cursor()
        XCTAssertEqual(cursor?.rawValue, "c2", "binding keeps the cursor")
    }
}
