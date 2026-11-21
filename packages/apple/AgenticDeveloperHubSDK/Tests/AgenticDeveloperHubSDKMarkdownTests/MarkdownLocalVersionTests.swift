import Testing
import Foundation
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
@testable import AgenticDeveloperHubSDKMarkdown

/// `markdown.local_version` (migration `markdown-v7-local-version`): every
/// write bumps it, a stale `expectedVersion` is refused, and every change —
/// local or pulled — is logged to the feed.
@Suite("Markdown local version")
struct MarkdownLocalVersionTests {

    private func store() throws -> MarkdownStore {
        try MarkdownStore(path: ":memory:", customerID: "cust-1", ecosystemID: "eco-1")
    }

    @Test("a create returns version 1 and an update bumps it")
    func createAndUpdateBump() throws {
        let store = try store()
        let created = try store.createDocument(content: "# A", markers: [.note])
        #expect(created.version == 1)
        #expect(try store.document(id: created.id)?.version == 1)

        var edited = created
        edited.content = "# A, edited"
        try store.updateDocument(edited, expectedVersion: 1)
        #expect(try store.document(id: created.id)?.version == 2)
    }

    @Test("a stale expectedVersion is refused and nothing changes")
    func staleIsRefused() throws {
        let store = try store()
        let created = try store.createDocument(content: "# A", markers: [.note])
        var edited = created
        edited.content = "# B"
        try store.updateDocument(edited)

        var stale = created
        stale.content = "# C"
        #expect(throws: MarkdownStoreError.staleVersion(current: 2)) {
            try store.updateDocument(stale, expectedVersion: 1)
        }
        #expect(throws: MarkdownStoreError.staleVersion(current: 2)) {
            try store.mutateDocument(id: created.id, expectedVersion: 1) { document, _ in
                document.content = "# D"
            }
        }
        #expect(throws: MarkdownStoreError.staleVersion(current: 2)) {
            try store.deleteDocument(id: created.id, expectedVersion: 1)
        }
        let after = try #require(try store.document(id: created.id))
        #expect(after.content == "# B")
        #expect(after.version == 2)
    }

    @Test("a local write appends to the change feed")
    func localWritesAreLogged() throws {
        let store = try store()
        let created = try store.createDocument(content: "# A", markers: [.note])
        try store.deleteDocument(id: created.id)

        let changes = try store.syncStore.changes(since: 0, limit: 10)
            .filter { $0.resource == "content.markdown" }
        #expect(changes.map(\.kind) == [.upsert, .delete])
        #expect(changes.map(\.version) == [1, 2])
        #expect(changes.allSatisfy { $0.id == created.id })
    }

    @Test("a v6 database migrates to v7 with every row at version 1")
    func v6MigratesToV7() throws {
        let database = try BoundedDatabase(path: ":memory:")
        try MarkdownSchema.migrator().migrate(database.writer, upTo: "markdown-v6-owner-pair")
        try database.write { conn in
            for id in ["m1", "m2"] {
                try conn.execute(
                    sql: """
                        INSERT INTO markdown (id, title, content, created_at, updated_at)
                        VALUES (?, 't', 'c', '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z')
                        """,
                    arguments: [id])
            }
        }

        try MarkdownSchema.migrate(database)

        try database.read { conn in
            let versions = try Int64.fetchAll(conn, sql: "SELECT local_version FROM markdown ORDER BY id")
            #expect(versions == [1, 1])
        }
    }

    @Test("a pulled upsert bumps the version and logs a change")
    func projectionUpsertLogsAChange() async throws {
        let store = try store()
        try await store.syncStore.apply([
            SyncChange(
                resource: "content.markdown", id: "m1", op: .upsert, syncVersion: "5",
                data: [
                    "title": .string("From the server"),
                    "content": .string("# From the server"),
                    "owner_kind": .string("customer"),
                    "owner_id": .string("cust-1"),
                    "created_at": .string("2026-01-01T00:00:00Z"),
                    "updated_at": .string("2026-01-02T00:00:00Z")
                ])
        ], advancingTo: nil)

        #expect(try store.document(id: "m1")?.version == 1)
        let changes = try store.syncStore.changes(since: 0, limit: 10)
        #expect(changes.contains {
            $0.resource == "content.markdown" && $0.id == "m1" && $0.kind == .upsert && $0.version == 1
        })
    }
}
