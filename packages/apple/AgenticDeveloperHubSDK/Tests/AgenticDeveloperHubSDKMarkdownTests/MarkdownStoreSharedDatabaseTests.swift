import Testing
import Foundation
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
import AgenticDeveloperHubSDKSyncGRDB
@testable import AgenticDeveloperHubSDKMarkdown

/// `MarkdownStore.init(database:syncStore:…)`: the store joins a database the
/// host owns, beside a `GRDBSyncStore` the host prepared.
@Suite("MarkdownStore on a shared database")
struct MarkdownStoreSharedDatabaseTests {

    @Test("a create on a shared pool shows in the host's change feed")
    func createShowsInTheFeed() throws {
        let database = try BoundedDatabase(path: ":memory:")
        let syncStore = GRDBSyncStore(
            database: database,
            pullOnlyResources: Set(MarkdownProjection.pullOnlyResources),
            projection: MarkdownProjection())
        try database.write { conn in
            try syncStore.prepare(resources: MarkdownProjection.syncResources, in: conn)
        }

        let store = try MarkdownStore(
            database: database, syncStore: syncStore, customerID: "cust-1", ecosystemID: "eco-1")
        let created = try store.createDocument(content: "# Shared", markers: [.note])

        #expect(store.database === database)
        let changes = try syncStore.changes(since: 0, limit: 10)
            .filter { $0.resource == "content.markdown" }
        #expect(changes.map(\.id) == [created.id])
        #expect(changes.first?.resource == "content.markdown")
        #expect(changes.first?.version == 1)
    }

    @Test("a committed local write fires the host's observers")
    func localWriteFiresObservers() throws {
        let database = try BoundedDatabase(path: ":memory:")
        let syncStore = GRDBSyncStore(
            database: database,
            pullOnlyResources: Set(MarkdownProjection.pullOnlyResources),
            projection: MarkdownProjection())
        try database.write { conn in
            try syncStore.prepare(resources: MarkdownProjection.syncResources, in: conn)
        }
        let store = try MarkdownStore(
            database: database, syncStore: syncStore, customerID: "cust-1", ecosystemID: "eco-1")

        let fired = Counter()
        syncStore.observeCommittedChanges { fired.increment() }
        _ = try store.createDocument(content: "# Shared", markers: [.note])

        #expect(fired.value == 1)
    }

    @Test("a sync store built on another database is refused before anything runs")
    func mismatchedSyncStoreIsRefused() throws {
        let database = try BoundedDatabase(path: ":memory:")
        let other = try BoundedDatabase(path: ":memory:")
        let syncStore = GRDBSyncStore(
            database: other,
            pullOnlyResources: Set(MarkdownProjection.pullOnlyResources),
            projection: MarkdownProjection())

        #expect(throws: MarkdownStoreError.syncStoreDatabaseMismatch) {
            try MarkdownStore(
                database: database, syncStore: syncStore, customerID: "cust-1", ecosystemID: "eco-1")
        }
        // Refused before the migrations: the host's database is untouched.
        let tables = try database.read { conn in
            try String.fetchAll(
                conn, sql: "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'markdown'")
        }
        #expect(tables.isEmpty)
    }
}

/// A thread-safe tally for a `@Sendable` observer.
private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
    func increment() { lock.lock(); count += 1; lock.unlock() }
}
