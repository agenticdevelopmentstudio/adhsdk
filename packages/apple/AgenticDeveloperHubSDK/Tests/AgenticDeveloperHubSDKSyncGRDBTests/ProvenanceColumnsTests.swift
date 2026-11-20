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

    func testAnOldSchemaTableGainsLocalVersionAndAPullIsLogged() async throws {
        let database = try BoundedDatabase(path: path)
        try database.write { conn in
            try conn.execute(sql: """
                CREATE TABLE _sync_resources (resource TEXT PRIMARY KEY, schema_version INTEGER NOT NULL);
                CREATE TABLE personal_notes (
                    id TEXT PRIMARY KEY NOT NULL, sync_version INTEGER NOT NULL DEFAULT 0,
                    deleted_at TEXT, data TEXT NOT NULL DEFAULT '{}');
                INSERT INTO _sync_resources (resource, schema_version) VALUES ('personal.notes', 1);
                INSERT INTO personal_notes (id, sync_version, data) VALUES ('n1', 3, '{"title":"kept"}');
                """)
        }
        let store = GRDBSyncStore(database: database)
        try await store.prepare(resources: [notes])

        XCTAssertEqual(try store.localRecord(resource: "personal.notes", id: "n1")?.version, 0)

        try await store.apply(
            [SyncChange(resource: "personal.notes", id: "n1", op: .upsert, syncVersion: "4",
                        data: ["title": .string("pulled")])],
            advancingTo: nil)

        XCTAssertEqual(try store.localRecord(resource: "personal.notes", id: "n1")?.version, 1)
        XCTAssertEqual(try store.changes(since: 0, limit: 10),
                       [RecordChange(seq: 1, resource: "personal.notes", id: "n1", kind: .upsert, version: 1)])
        XCTAssertEqual(try store.changeHead(), 1)
    }

    /// A database from before provenance and local versions: old
    /// `_sync_state`, a registered four-column mirror table, no `_change_log`.
    private func makeOldSchemaDatabase() throws -> BoundedDatabase {
        let database = try BoundedDatabase(path: path)
        try database.write { conn in
            try conn.execute(sql: """
                CREATE TABLE _sync_state (id INTEGER PRIMARY KEY CHECK (id = 1), cursor TEXT);
                CREATE TABLE _sync_resources (resource TEXT PRIMARY KEY, schema_version INTEGER NOT NULL);
                CREATE TABLE _sync_outbox (
                    op_id TEXT PRIMARY KEY, resource TEXT NOT NULL, row_id TEXT NOT NULL,
                    type TEXT NOT NULL, base_version TEXT, payload TEXT,
                    status TEXT NOT NULL DEFAULT 'pending', attempts INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL);
                CREATE TABLE personal_notes (
                    id TEXT PRIMARY KEY NOT NULL, sync_version INTEGER NOT NULL DEFAULT 0,
                    deleted_at TEXT, data TEXT NOT NULL DEFAULT '{}');
                INSERT INTO _sync_state (id, cursor) VALUES (1, 'c7');
                INSERT INTO _sync_resources (resource, schema_version) VALUES ('personal.notes', 1);
                INSERT INTO personal_notes (id, sync_version, data) VALUES ('n1', 3, '{"title":"kept"}');
                """)
        }
        return database
    }

    // f1: the engine skips `prepare` when registrations already cover the
    // manifest, so the upgrade has to happen on the paths it does take.
    func testAPullWithoutPrepareUpgradesAnOldMirror() async throws {
        let store = GRDBSyncStore(database: try makeOldSchemaDatabase())
        let registered = try await store.registrations()
        XCTAssertEqual(registered, ["personal.notes": 1])
        _ = try await store.cursor()

        try await store.apply(
            [SyncChange(resource: "personal.notes", id: "n2", op: .upsert, syncVersion: "4",
                        data: ["title": .string("pulled")])],
            advancingTo: SyncCursor(rawValue: "c8"))

        XCTAssertEqual(try store.liveRow(resource: "personal.notes", id: "n2")?["title"], .string("pulled"))
        XCTAssertEqual(try store.liveRow(resource: "personal.notes", id: "n1")?["title"], .string("kept"))
    }

    func testAStageWithoutPrepareUpgradesAnOldMirror() async throws {
        let store = GRDBSyncStore(database: try makeOldSchemaDatabase())

        try await store.stage(LocalMutation(
            resource: "personal.notes", rowId: "n1", type: .upsert, data: ["title": .string("edited")]))

        XCTAssertEqual(try store.localRecord(resource: "personal.notes", id: "n1")?.version, 1)
        let ops = try await store.pendingOps(limit: 10)
        XCTAssertEqual(ops.map(\.rowId), ["n1"])
    }

    // MARK: f7 — queries on a never-prepared store

    func testANeverPreparedStoreAnswersRatherThanThrowingSQL() throws {
        let store = GRDBSyncStore(database: try BoundedDatabase(path: path))
        XCTAssertFalse(try store.acceptsLocalWrites(resource: "personal.notes"))
        XCTAssertThrowsError(try store.localRecord(resource: "personal.notes", id: "n1")) { error in
            XCTAssertEqual(error as? SyncStoreFailure, .unknownResource("personal.notes"))
        }
        XCTAssertThrowsError(try store.database.read { conn in
            try store.localVersion(resource: "personal.notes", id: "n1", in: conn)
        }) { error in
            XCTAssertEqual(error as? SyncStoreFailure, .unknownResource("personal.notes"))
        }
    }

    // MARK: f6 — apply and complete on an older database, first call

    func testCompleteAsTheFirstCallOnAnOldDatabaseDeletesTheAppliedOp() async throws {
        let database = try makeOldSchemaDatabase()
        try database.write { conn in
            try conn.execute(sql: """
                INSERT INTO _sync_outbox (op_id, resource, row_id, type, payload, status, created_at)
                VALUES ('op1', 'personal.notes', 'n1', 'upsert', '{}', 'inflight', datetime('now'))
                """)
        }
        let store = GRDBSyncStore(database: database)

        try await store.complete([SyncPushResult(opId: "op1", status: .applied, newVersion: "4")])

        let remaining = try database.read { conn in
            try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM _sync_outbox") ?? -1
        }
        XCTAssertEqual(remaining, 0)
    }

    func testApplyAsTheFirstCallOnAnOldDatabaseLogsTheChange() async throws {
        let store = GRDBSyncStore(database: try makeOldSchemaDatabase())

        try await store.apply(
            [SyncChange(resource: "personal.notes", id: "n1", op: .upsert, syncVersion: "4",
                        data: ["title": .string("pulled")])],
            advancingTo: nil)

        XCTAssertEqual(try store.changes(since: 0, limit: 10).map(\.id), ["n1"])
    }

    // MARK: f2 — another account never drains the bound account's queue

    private func assertMismatch(
        _ body: () async throws -> Void, file: StaticString = #filePath, line: UInt = #line
    ) async {
        do {
            try await body()
            XCTFail("expected accountMismatch", file: file, line: line)
        } catch let failure as SyncStoreFailure {
            guard case .accountMismatch = failure else {
                return XCTFail("unexpected \(failure)", file: file, line: line)
            }
        } catch {
            XCTFail("unexpected \(error)", file: file, line: line)
        }
    }

    func testADifferentAccountIsRefusedPushAndPullAndTheQueueIsKept() async throws {
        let store = GRDBSyncStore(database: try BoundedDatabase(path: path))
        try await store.prepare(resources: [notes])
        let first = try await store.signIn(account: "acct-a")
        XCTAssertEqual(first, .bound("acct-a"))
        try await store.stage(LocalMutation(
            resource: "personal.notes", rowId: "a1", type: .upsert, data: ["title": .string("A's")]))

        store.signOut()
        await assertMismatch { _ = try await store.pendingOps(limit: 10) }

        let second = try await store.signIn(account: "acct-b")
        XCTAssertEqual(second, .mismatch(bound: "acct-a", signedIn: "acct-b"))
        await assertMismatch { _ = try await store.pendingOps(limit: 10) }
        await assertMismatch { _ = try await store.cursor() }
        await assertMismatch { try await store.apply([], advancingTo: SyncCursor(rawValue: "b1")) }
        XCTAssertThrowsError(try store.checkAccountGuard())

        let back = try await store.signIn(account: "acct-a")
        XCTAssertEqual(back, .bound("acct-a"))
        let ops = try await store.pendingOps(limit: 10)
        XCTAssertEqual(ops.map(\.rowId), ["a1"], "the bound account's queue waited for it")
    }

    func testAnUndeclaredHostIsNotGuarded() async throws {
        let store = GRDBSyncStore(database: try BoundedDatabase(path: path))
        try await store.prepare(resources: [notes])
        try await store.bind(account: "acct-a")
        try await store.stage(LocalMutation(resource: "personal.notes", rowId: "a1", type: .upsert, data: [:]))
        let ops = try await store.pendingOps(limit: 10)
        XCTAssertEqual(ops.count, 1)
    }

    func testDiscardingAccountStateDropsTheQueueAndProjectionSidecarsAndRebinds() async throws {
        let projection = TestProjection(resources: ["personal.tasks"])
        let store = GRDBSyncStore(database: try BoundedDatabase(path: path), projection: projection)
        try await store.prepare(resources: [notes, SyncResource(resource: "personal.tasks", schemaVersion: 1)])
        _ = try await store.signIn(account: "acct-a")
        try await store.stage(LocalMutation(resource: "personal.notes", rowId: "a1", type: .upsert, data: [:]))
        try await store.apply([], advancingTo: SyncCursor(rawValue: "a9"))

        _ = try await store.signIn(account: "acct-b")
        try await store.discardAccountState(rebindingTo: "acct-b")

        let bound = try await store.boundAccount()
        XCTAssertEqual(bound, "acct-b")
        let ops = try await store.pendingOps(limit: 10)
        XCTAssertTrue(ops.isEmpty)
        let cursor = try await store.cursor()
        XCTAssertNil(cursor)
        XCTAssertEqual(projection.discardLocalStateCalls, 1)
        XCTAssertNotNil(try store.liveRow(resource: "personal.notes", id: "a1"), "mirror rows are kept")
    }
}
