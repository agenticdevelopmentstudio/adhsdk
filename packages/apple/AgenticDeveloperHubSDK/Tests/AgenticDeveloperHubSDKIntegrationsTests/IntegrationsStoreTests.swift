import Testing
import Foundation
import GRDB
import AgenticDeveloperHubSDKDatabase
@testable import AgenticDeveloperHubSDKIntegrations

@Suite("IntegrationsStore")
struct IntegrationsStoreTests {

    private func makeStore() throws -> (IntegrationsStore, BoundedDatabase) {
        let database = try BoundedDatabase(path: ":memory:")
        return (try IntegrationsStore(database: database), database)
    }

    private func connection(_ id: String = "c1", email: String = "a@b.c") -> IntegrationConnection {
        IntegrationConnection(id: id, externalAccountId: email, displayName: email, scopes: "gmail.modify")
    }

    private func message(
        _ externalId: String, day: Int = 1, labels: [String] = ["INBOX"], subject: String = "Hi",
        connectionId: String = "c1"
    ) -> EmailMessage {
        EmailMessage(
            id: "id-\(externalId)", connectionId: connectionId, externalId: externalId, threadId: "t",
            fromAddress: "x@y.z", subject: subject, snippet: "s", labelIds: labels,
            internalDate: String(format: "2026-11-%02dT10:00:00.000Z", day)
        )
    }

    @Test("upserting the same message twice leaves one row with the new subject")
    func upsertMessagesIsIdempotent() throws {
        let (store, database) = try makeStore()
        try store.upsertMessages([message("e1", subject: "old")])
        try store.upsertMessages([message("e1", subject: "new")])
        let count = try database.read { try Int.fetchOne($0, sql: "SELECT COUNT(*) FROM integration_email_messages") }
        #expect(count == 1)
        #expect(try store.message(connectionId: "c1", idOrExternalId: "e1")?.subject == "new")
    }

    @Test("upserting a tombstoned message revives it")
    func upsertRevivesTombstone() throws {
        let (store, _) = try makeStore()
        try store.upsertMessages([message("e1")])
        try store.tombstoneMessages(connectionId: "c1", externalIds: ["e1"])
        #expect(try store.message(connectionId: "c1", idOrExternalId: "e1") == nil)
        try store.upsertMessages([message("e1")])
        let back = try store.message(connectionId: "c1", idOrExternalId: "e1")
        #expect(back?.isDeleted == false)
        #expect(back?.deletedAt == nil)
    }

    @Test("a query filters by inclusive date range and every label, newest first")
    func queryFiltersByDateRangeAndAllLabels() throws {
        let (store, _) = try makeStore()
        try store.upsertMessages([
            message("e1", day: 1, labels: ["INBOX", "Label_1"]),
            message("e2", day: 2, labels: ["INBOX"]),
            message("e3", day: 3, labels: ["INBOX", "Label_1"])
        ])
        let all = try store.messages(MessageQuery(connectionId: "c1"))
        #expect(all.map(\.externalId) == ["e3", "e2", "e1"])
        let ranged = try store.messages(MessageQuery(
            connectionId: "c1", since: "2026-11-02T10:00:00.000Z", until: "2026-11-03T10:00:00.000Z"))
        #expect(ranged.map(\.externalId) == ["e3", "e2"])
        let both = try store.messages(MessageQuery(connectionId: "c1", labelIds: ["INBOX", "Label_1"]))
        #expect(both.map(\.externalId) == ["e3", "e1"])
        let none = try store.messages(MessageQuery(connectionId: "c1", labelIds: ["INBOX", "Nope"]))
        #expect(none.isEmpty)
    }

    @Test("a query pages with limit and offset")
    func queryPagesWithLimitAndOffset() throws {
        let (store, _) = try makeStore()
        try store.upsertMessages((1...5).map { message("e\($0)", day: $0) })
        let page = try store.messages(MessageQuery(connectionId: "c1", limit: 2, offset: 1))
        #expect(page.map(\.externalId) == ["e4", "e3"])
    }

    @Test("a query resumes after a key, unmoved by rows that leave the filter ahead of it")
    func queryResumesAfterKey() throws {
        let (store, _) = try makeStore()
        try store.upsertMessages((1...5).map { message("e\($0)", day: $0) })
        let first = try store.messages(MessageQuery(connectionId: "c1", limit: 2))
        #expect(first.map(\.externalId) == ["e5", "e4"])
        try store.tombstoneMessages(connectionId: "c1", externalIds: ["e5"])
        let last = try #require(first.last)
        let next = try store.messages(MessageQuery(
            connectionId: "c1", limit: 2, after: MessageKey(internalDate: last.internalDate, id: last.id)))
        #expect(next.map(\.externalId) == ["e3", "e2"])
    }

    @Test("tombstoning by class removes only that class")
    func tombstoneByClassRemovesOnlyThatClass() throws {
        let (store, _) = try makeStore()
        try store.upsertMessages([
            message("keep", labels: ["INBOX"]), message("junk", labels: ["SPAM"]),
            message("bin", labels: ["TRASH"])
        ])
        try store.tombstoneMessages(connectionId: "c1", classes: [.spam])
        let live = try store.messages(MessageQuery(connectionId: "c1"))
        #expect(Set(live.map(\.externalId)) == ["keep", "bin"])
        #expect(try store.liveExternalIds(connectionId: "c1", since: "2026-01-01T00:00:00.000Z") == ["keep", "bin"])
    }

    @Test("replacing labels tombstones those that vanished")
    func replaceLabelsTombstonesVanished() throws {
        let (store, _) = try makeStore()
        func label(_ ext: String) -> EmailLabel {
            EmailLabel(id: "l-\(ext)", connectionId: "c1", externalId: ext, name: ext)
        }
        try store.replaceLabels(connectionId: "c1", with: [label("A"), label("B")])
        try store.replaceLabels(connectionId: "c1", with: [label("B"), label("C")])
        #expect(try store.labels(connectionId: "c1").map(\.externalId).sorted() == ["B", "C"])
        try store.replaceLabels(connectionId: "c1", with: [label("A")])
        #expect(try store.labels(connectionId: "c1").map(\.externalId) == ["A"])
    }

    @Test("a connection is found by id or by email")
    func connectionLookupByIdOrEmail() throws {
        let (store, _) = try makeStore()
        try store.upsertConnection(connection("c1", email: "a@b.c"))
        #expect(try store.connection(idOrEmail: "c1")?.externalAccountId == "a@b.c")
        #expect(try store.connection(idOrEmail: "a@b.c")?.id == "c1")
        #expect(try store.connection(idOrEmail: "nobody") == nil)
        #expect(try store.connections(provider: "gmail").count == 1)
    }

    @Test("email lookup and the upsert key ignore case")
    func emailMatchingIgnoresCase() throws {
        let (store, _) = try makeStore()
        try store.upsertConnection(connection("c1", email: "Me@Example.com"))
        #expect(try store.connection(idOrEmail: "me@example.COM")?.id == "c1")
        try store.upsertConnection(connection("c2", email: "me@example.com"))
        #expect(try store.connections(provider: "gmail").map(\.id) == ["c1"])
    }

    @Test("updating the sync state of an unknown or removed connection throws")
    func updateSyncStateOnUnknownIdThrows() throws {
        let (store, _) = try makeStore()
        #expect(throws: IntegrationError.unknownAccount("nope")) {
            try store.updateSyncState(id: "nope", cursor: "1", lastSyncAt: nil, status: .active, lastError: nil)
        }
        try store.upsertConnection(connection())
        try store.deleteConnection(id: "c1")
        #expect(throws: IntegrationError.unknownAccount("c1")) {
            try store.updateSyncState(id: "c1", cursor: "1", lastSyncAt: nil, status: .active, lastError: nil)
        }
    }

    @Test("tombstoning more ids than one statement may bind works and counts what it removed")
    func tombstoneManyIdsIsChunkedAndCounted() throws {
        let (store, _) = try makeStore()
        let ids = (0..<1_200).map { "e\($0)" }
        try store.upsertMessages(ids.map { message($0) })
        let removed = try store.tombstoneMessages(
            connectionId: "c1", externalIds: ids + ["never-stored"] + Array(repeating: "e0", count: 40_000))
        #expect(removed == 1_200)
        #expect(try store.messages(MessageQuery(connectionId: "c1", limit: 10)).isEmpty)
        #expect(try store.tombstoneMessages(connectionId: "c1", externalIds: ids) == 0, "already tombstoned")
    }

    @Test("tombstoning by date removes only live rows older than the cutoff")
    func tombstoneOlderThan() throws {
        let (store, _) = try makeStore()
        try store.upsertMessages([message("old", day: 1), message("edge", day: 3), message("new", day: 5)])
        let removed = try store.tombstoneMessages(connectionId: "c1", olderThan: "2026-11-03T10:00:00.000Z")
        #expect(removed == 1)
        #expect(Set(try store.messages(MessageQuery(connectionId: "c1")).map(\.externalId)) == ["edge", "new"])
    }

    @Test("re-upserting a deleted connection's email makes a new live row")
    func reUpsertAfterDelete() throws {
        let (store, _) = try makeStore()
        try store.upsertConnection(connection("c1"))
        try store.deleteConnection(id: "c1")
        try store.upsertConnection(connection("c2"))
        #expect(try store.connection(idOrEmail: "a@b.c")?.id == "c2")
        #expect(try store.connections(provider: "gmail").map(\.id) == ["c2"])
    }

    @Test("one connection's messages and tombstones never touch another's")
    func connectionsAreIsolated() throws {
        let (store, _) = try makeStore()
        try store.upsertMessages([message("e1", connectionId: "c1"),
                                  EmailMessage(id: "other-e1", connectionId: "c2", externalId: "e1", threadId: "t",
                                               fromAddress: "x@y.z", subject: "Hi", snippet: "s",
                                               labelIds: ["INBOX"], internalDate: "2026-11-01T10:00:00.000Z")])
        try store.tombstoneMessages(connectionId: "c1", externalIds: ["e1"])
        #expect(try store.message(connectionId: "c1", idOrExternalId: "e1") == nil)
        #expect(try store.message(connectionId: "c2", idOrExternalId: "e1")?.id == "other-e1")
        #expect(try store.messages(MessageQuery(connectionId: "c2")).count == 1)
        #expect(try store.liveExternalIds(connectionId: "c2", since: "2026-01-01T00:00:00.000Z") == ["e1"])
    }

    @Test("liveExternalIds includes a row dated exactly at `since` and excludes one just before")
    func liveExternalIdsSinceBoundary() throws {
        let (store, _) = try makeStore()
        try store.upsertMessages([message("before", day: 2), message("at", day: 3)])
        #expect(try store.liveExternalIds(connectionId: "c1", since: "2026-11-03T10:00:00.000Z") == ["at"])
    }

    @Test("upserting a connection for the same email reuses its id")
    func upsertConnectionReusesRowForSameEmail() throws {
        let (store, _) = try makeStore()
        try store.upsertConnection(connection("c1", email: "a@b.c"))
        var again = connection("c2", email: "a@b.c")
        again.displayName = "Renamed"
        try store.upsertConnection(again)
        let all = try store.connections(provider: "gmail")
        #expect(all.map(\.id) == ["c1"])
        #expect(all.first?.displayName == "Renamed")
    }

    @Test("deleting a connection tombstones it, its messages and its labels")
    func deleteConnectionTombstonesItsMessages() throws {
        let (store, _) = try makeStore()
        try store.upsertConnection(connection())
        try store.upsertMessages([message("e1")])
        try store.replaceLabels(
            connectionId: "c1", with: [EmailLabel(id: "l", connectionId: "c1", externalId: "A", name: "A")])
        try store.deleteConnection(id: "c1")
        #expect(try store.connection(idOrEmail: "c1") == nil)
        #expect(try store.messages(MessageQuery(connectionId: "c1")).isEmpty)
        #expect(try store.labels(connectionId: "c1").isEmpty)
    }

    @Test("sync state, provider configs and action logs round-trip")
    func syncStateConfigsAndLogs() throws {
        let (store, database) = try makeStore()
        try store.upsertConnection(connection())
        try store.updateSyncState(
            id: "c1", cursor: "99", lastSyncAt: "2026-11-06T00:00:00.000Z", status: .active, lastError: nil)
        let conn = try store.connection(idOrEmail: "c1")
        #expect(conn?.syncCursor == "99")
        #expect(conn?.status == .active)

        try store.upsertProviderConfig(ProviderConfig(id: "p1", name: "Gmail", clientId: "cid"))
        try store.upsertProviderConfig(ProviderConfig(id: "p2", name: "Gmail 2", clientId: "cid2"))
        #expect(try store.providerConfig(providerId: "gmail")?.clientId == "cid2")
        try store.deleteProviderConfig(providerId: "gmail")
        #expect(try store.providerConfig(providerId: "gmail") == nil)

        try store.insertActionLog(ActionLog(id: "a1", connectionId: "c1", actionType: "archive", requestPayload: "{}"))
        try store.finishActionLog(id: "a1", status: "ok", result: "{}", error: nil)
        let status = try database.read {
            try String.fetchOne($0, sql: "SELECT status FROM integration_action_logs WHERE id = 'a1'")
        }
        #expect(status == "ok")
    }
}
