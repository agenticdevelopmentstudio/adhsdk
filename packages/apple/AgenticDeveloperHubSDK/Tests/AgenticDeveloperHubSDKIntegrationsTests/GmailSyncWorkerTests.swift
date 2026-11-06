import Testing
import Foundation
import AgenticDeveloperHubSDKDatabase
@testable import AgenticDeveloperHubSDKIntegrations

@Suite("GmailSyncWorker")
struct GmailSyncWorkerTests {

    private static let now = Date(timeIntervalSince1970: 1_793_000_000)

    private func makeWorker(
        api: FakeGmailAPI, settings: MailSyncSettings = .default, cursor: String? = nil
    ) throws -> (GmailSyncWorker, IntegrationsStore, IntegrationConnection) {
        let store = try IntegrationsStore(database: BoundedDatabase(path: ":memory:"))
        let seed = IntegrationConnection(
            id: "c1", externalAccountId: "me@example.com", displayName: "Me", status: .active,
            syncCursor: cursor, syncSettings: settings, scopes: "gmail.modify")
        try store.upsertConnection(seed)
        let connection = try #require(try store.connection(idOrEmail: "c1"))
        return (GmailSyncWorker(api: api, store: store, now: { Self.now }), store, connection)
    }

    private func dto(_ id: String, labels: [String], ageDays: Double = 1) -> GmailMessageDTO {
        let millis = Int((Self.now.timeIntervalSince1970 - ageDays * 86_400) * 1000)
        return GmailMessageDTO(
            id: id, threadId: "t-\(id)", labelIds: labels, snippet: "s", historyId: "1",
            internalDate: String(millis), payload: GmailPart(headers: [GmailHeader(name: "Subject", value: id)]))
    }

    private func parsed(_ message: GmailMessageDTO, id: String? = nil) -> EmailMessage {
        GmailMessageParser.parse(message, connectionId: "c1", existingId: id)
    }

    private func liveIds(_ store: IntegrationsStore) throws -> Set<String> {
        Set(try store.messages(MessageQuery(connectionId: "c1", limit: 1000)).map(\.externalId))
    }

    @Test("full sync keeps filed mail and drops archived by default; cursor is the profile historyId")
    func fullSyncKeepsFiledDropsArchivedByDefault() async throws {
        let api = FakeGmailAPI()
        api.historyId = "500"
        for message in [
            dto("a", labels: ["INBOX"]), dto("b", labels: ["Label_1"]), dto("c", labels: ["STARRED"]),
            dto("d", labels: ["CATEGORY_PROMOTIONS"])
        ] { api.setMessage(message) }
        let (worker, store, connection) = try makeWorker(api: api)

        let outcome = try await worker.sync(connection: connection)

        #expect(outcome == GmailSyncOutcome(mode: .full, upserted: 3, tombstoned: 0))
        #expect(try liveIds(store) == ["a", "b", "c"])
        let saved = try #require(try store.connection(idOrEmail: "c1"))
        #expect(saved.syncCursor == "500")
        #expect(saved.status == .active)
        #expect(saved.lastError == nil)
        #expect(saved.lastSyncAt != nil)
    }

    @Test("full sync stores the historyId taken before listing")
    func fullSyncUsesBaselineHistoryIdTakenBeforeListing() async throws {
        let api = FakeGmailAPI()
        api.historyId = "500"
        api.setMessage(dto("a", labels: ["INBOX"]))
        api.onListMessageIds = { $0.historyId = "900" }
        let (worker, store, connection) = try makeWorker(api: api)

        _ = try await worker.sync(connection: connection)

        #expect(try store.connection(idOrEmail: "c1")?.syncCursor == "500")
    }

    @Test("full sync with includeArchived keeps archived mail")
    func fullSyncWithArchivedOnKeepsArchived() async throws {
        let api = FakeGmailAPI()
        api.setMessage(dto("a", labels: ["INBOX"]))
        api.setMessage(dto("d", labels: ["CATEGORY_PROMOTIONS"]))
        let (worker, store, connection) = try makeWorker(api: api, settings: MailSyncSettings(includeArchived: true))

        _ = try await worker.sync(connection: connection)

        #expect(try liveIds(store) == ["a", "d"])
    }

    @Test("full sync tombstones in-window rows that were not kept, and leaves older rows alone")
    func fullSyncTombstonesMissing() async throws {
        let api = FakeGmailAPI()
        api.setMessage(dto("a", labels: ["INBOX"]))
        let (worker, store, connection) = try makeWorker(api: api)
        try store.upsertMessages([
            parsed(dto("gone", labels: ["INBOX"], ageDays: 2)),
            parsed(dto("old", labels: ["INBOX"], ageDays: 90))
        ])

        let outcome = try await worker.sync(connection: connection)

        #expect(outcome.tombstoned == 1)
        #expect(try liveIds(store) == ["a", "old"])
    }

    @Test("a re-synced message keeps its local id")
    func resyncKeepsLocalId() async throws {
        let api = FakeGmailAPI()
        api.setMessage(dto("a", labels: ["INBOX"]))
        let (worker, store, connection) = try makeWorker(api: api)
        try store.upsertMessages([parsed(dto("a", labels: ["INBOX"]), id: "local-a")])

        _ = try await worker.sync(connection: connection)

        #expect(try store.message(connectionId: "c1", idOrExternalId: "a")?.id == "local-a")
    }

    @Test("incremental upserts changed messages and tombstones deleted ones")
    func incrementalUpsertsChangedAndTombstonesDeleted() async throws {
        let api = FakeGmailAPI()
        api.setMessage(dto("new", labels: ["INBOX"]))
        api.historyPages = [
            GmailHistoryPage(changedIds: ["new"], deletedIds: [], historyId: "610", nextPageToken: "1"),
            GmailHistoryPage(changedIds: [], deletedIds: ["del"], historyId: "620", nextPageToken: nil)
        ]
        let (worker, store, connection) = try makeWorker(api: api, cursor: "600")
        try store.upsertMessages([parsed(dto("del", labels: ["INBOX"]))])

        let outcome = try await worker.sync(connection: connection)

        #expect(outcome == GmailSyncOutcome(mode: .incremental, upserted: 1, tombstoned: 1))
        #expect(try liveIds(store) == ["new"])
        #expect(api.historyCalls == ["600", "600"])
        #expect(try store.connection(idOrEmail: "c1")?.syncCursor == "620")
    }

    @Test("incremental tombstones a message that became archived")
    func incrementalTombstonesMessageThatBecameArchived() async throws {
        let api = FakeGmailAPI()
        api.setMessage(dto("a", labels: ["CATEGORY_PROMOTIONS"]))
        api.historyPages = [GmailHistoryPage(changedIds: ["a"], deletedIds: [], historyId: "610", nextPageToken: nil)]
        let (worker, store, connection) = try makeWorker(api: api, cursor: "600")
        try store.upsertMessages([parsed(dto("a", labels: ["INBOX"]))])

        let outcome = try await worker.sync(connection: connection)

        #expect(outcome.tombstoned == 1)
        #expect(try liveIds(store).isEmpty)
    }

    @Test("an expired cursor falls back to one full sync and resets the cursor")
    func incrementalFallsBackToFullOn404() async throws {
        let api = FakeGmailAPI()
        api.historyId = "700"
        api.historyError = GmailCursorExpired()
        api.setMessage(dto("a", labels: ["INBOX"]))
        let (worker, store, connection) = try makeWorker(api: api, cursor: "600")

        let outcome = try await worker.sync(connection: connection)

        #expect(outcome.mode == .full)
        #expect(outcome.upserted == 1)
        #expect(api.listCalls.count == 1)
        #expect(try store.connection(idOrEmail: "c1")?.syncCursor == "700")
    }

    @Test("labels are synced with parent names, and vanished labels are tombstoned")
    func labelsSyncedAndVanishedTombstoned() async throws {
        let api = FakeGmailAPI()
        api.labels = [
            GmailLabelDTO(id: "INBOX", name: "INBOX", type: "system"),
            GmailLabelDTO(id: "Label_1", name: "Work/Clients/Acme", type: "user", messagesTotal: 4),
            GmailLabelDTO(id: "Label_2", name: "Gone", type: "user")
        ]
        let (worker, store, connection) = try makeWorker(api: api)
        _ = try await worker.sync(connection: connection)

        let first = try store.labels(connectionId: "c1")
        #expect(first.map(\.externalId).sorted() == ["INBOX", "Label_1", "Label_2"])
        let acme = try #require(first.first { $0.externalId == "Label_1" })
        #expect(acme.parentName == "Work/Clients")
        #expect(acme.type == "user")
        #expect(acme.messagesTotal == 4)
        #expect(first.first { $0.externalId == "INBOX" }?.type == "system")
        #expect(first.first { $0.externalId == "INBOX" }?.parentName == nil)

        api.labels = [GmailLabelDTO(id: "Label_1", name: "Work/Clients/Acme", type: "user")]
        _ = try await worker.sync(connection: try #require(try store.connection(idOrEmail: "c1")))
        let second = try store.labels(connectionId: "c1")
        #expect(second.map(\.externalId) == ["Label_1"])
        #expect(second.first?.id == acme.id)
    }

    @Test("a 404 fetching a changed message tombstones it")
    func messageFetch404DuringIncrementalTombstones() async throws {
        let api = FakeGmailAPI()
        api.messageErrors["a"] = IntegrationError.gmail(status: 404, message: "Not Found")
        api.historyPages = [GmailHistoryPage(changedIds: ["a"], deletedIds: [], historyId: "610", nextPageToken: nil)]
        let (worker, store, connection) = try makeWorker(api: api, cursor: "600")
        try store.upsertMessages([parsed(dto("a", labels: ["INBOX"]))])

        let outcome = try await worker.sync(connection: connection)

        #expect(outcome == GmailSyncOutcome(mode: .incremental, upserted: 0, tombstoned: 1))
        #expect(try liveIds(store).isEmpty)
    }

    @Test("a non-404 fetch error fails the sync and leaves the cursor alone")
    func fetchErrorPropagates() async throws {
        let api = FakeGmailAPI()
        api.messageErrors["a"] = IntegrationError.gmail(status: 500, message: "Boom")
        api.historyPages = [GmailHistoryPage(changedIds: ["a"], deletedIds: [], historyId: "610", nextPageToken: nil)]
        let (worker, store, connection) = try makeWorker(api: api, cursor: "600")

        await #expect(throws: IntegrationError.gmail(status: 500, message: "Boom")) {
            _ = try await worker.sync(connection: connection)
        }
        #expect(try store.connection(idOrEmail: "c1")?.syncCursor == "600")
    }
}
