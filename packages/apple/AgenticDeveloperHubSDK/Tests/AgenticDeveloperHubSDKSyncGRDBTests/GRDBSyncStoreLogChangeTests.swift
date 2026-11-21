import XCTest
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
@testable import AgenticDeveloperHubSDKSyncGRDB

/// `GRDBSyncStore.logChange` / `appendChange`: an outside writer's change
/// reaches the feed inside its own transaction, and observers fire on commit only.
final class GRDBSyncStoreLogChangeTests: XCTestCase {

    private func makeStore() async throws -> GRDBSyncStore {
        let store = GRDBSyncStore(database: try BoundedDatabase(path: ":memory:"), pullOnlyResources: [])
        try await store.prepare(resources: [SyncResource(resource: "personal.notes", schemaVersion: 1)])
        return store
    }

    func testLogChangeAppendsAndFiresOnCommit() async throws {
        let store = try await makeStore()
        let fired = LogChangeCounter()
        store.observeCommittedChanges { fired.increment() }

        try store.database.write { conn in
            try store.logChange(resource: "content.markdown", id: "m1", kind: .upsert, version: 3, in: conn)
        }

        let changes = try store.changes(since: 0, limit: 10)
        XCTAssertEqual(changes.map(\.id), ["m1"])
        XCTAssertEqual(changes.first?.kind, .upsert)
        XCTAssertEqual(changes.first?.version, 3)
        XCTAssertEqual(fired.value, 1)
    }

    func testRolledBackLogChangeLeavesNothingAndFiresNothing() async throws {
        let store = try await makeStore()
        let fired = LogChangeCounter()
        store.observeCommittedChanges { fired.increment() }
        struct Abort: Error {}

        XCTAssertThrowsError(try store.database.write { conn in
            try store.logChange(resource: "content.markdown", id: "m1", kind: .delete, version: 1, in: conn)
            throw Abort()
        })

        XCTAssertTrue(try store.changes(since: 0, limit: 10).isEmpty)
        XCTAssertEqual(fired.value, 0)
    }

    func testAppendChangeOnlyAppends() async throws {
        let store = try await makeStore()
        let fired = LogChangeCounter()
        store.observeCommittedChanges { fired.increment() }

        try store.database.write { conn in
            try GRDBSyncStore.appendChange(resource: "content.markdown", id: "m2", kind: .upsert, version: 1, in: conn)
        }

        XCTAssertEqual(try store.changes(since: 0, limit: 10).map(\.id), ["m2"])
        XCTAssertEqual(fired.value, 0)
    }
}

private final class LogChangeCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
    func increment() { lock.lock(); count += 1; lock.unlock() }
}
