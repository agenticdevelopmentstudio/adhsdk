import XCTest
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
import AgenticDeveloperHubSDKMail
import AgenticDeveloperHubSDKHubMail
@testable import AgenticDeveloperHubSDKHubMailBridge

/// Records label writes and pulls, and can be told to refuse a write.
private actor Recorder {
    var writes: [HubMailLabelWrite] = []
    var pulls = 0
    var refusal: String?

    func record(_ write: HubMailLabelWrite) throws {
        if let refusal { throw HubMailBridge.Failure(refusal) }
        writes.append(write)
    }

    func pull() { pulls += 1 }
    func refuse(_ message: String) { refusal = message }
}

/// Vectors hub-mail-bridge-001 to 022.
final class HubMailBridgeTests: XCTestCase {

    private var dir: URL!
    private var database: BoundedDatabase!
    private var store: HubMailStore!
    private var recorder: Recorder!
    private var bridge: HubMailBridge!
    private let projection = HubMailProjection()

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hub-mail-bridge-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        database = try BoundedDatabase(path: dir.appendingPathComponent("mail.db").path)
        store = try HubMailStore(database: database)
        let recorder = Recorder()
        self.recorder = recorder
        bridge = HubMailBridge(
            store: store,
            writeLabels: { try await recorder.record($0) },
            syncNow: { await recorder.pull() })
    }

    override func tearDownWithError() throws {
        bridge = nil
        store = nil
        database = nil
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - Helpers

    private struct Seed {
        var connection = "c1"
        var date: String?
        var thread: String?
        var labels = ["INBOX"]
        var from: String?
        var bodyText: String?
        var bodyHtml: String?
        var version = 1
    }

    private func upsertMessage(_ id: String, _ seed: Seed = Seed()) throws {
        var data: [String: JSONValue] = [
            "connection_id": .string(seed.connection),
            "provider": .string("gmail"),
            "external_id": .string("ext-\(id)"),
            "subject": .string("Subject \(id)"),
            "label_ids": .array(seed.labels.map { .string($0) }),
            "is_deleted": .bool(false)
        ]
        if let date = seed.date { data["internal_date"] = .string(date) }
        if let thread = seed.thread { data["thread_id"] = .string(thread) }
        if let from = seed.from { data["from_address"] = .string(from) }
        if let text = seed.bodyText { data["body_text"] = .string(text) }
        if let html = seed.bodyHtml { data["body_html"] = .string(html) }
        try database.write { conn in
            try projection.upsert(
                resource: HubMailResource.messages, id: id, syncVersion: seed.version, data: data, in: conn)
        }
    }

    private func upsertLabel(_ externalId: String, name: String, type: String = "user", connection: String = "c1")
        throws {
        let data: [String: JSONValue] = [
            "connection_id": .string(connection),
            "external_id": .string(externalId),
            "source_provider": .string("gmail"),
            "name": .string(name),
            "type": .string(type)
        ]
        try database.write { conn in
            try projection.upsert(
                resource: HubMailResource.labels, id: "\(connection)-\(externalId)", syncVersion: 1,
                data: data, in: conn)
        }
    }

    private func seedStandardLabels() throws {
        try upsertLabel("INBOX", name: "INBOX", type: "system")
        try upsertLabel("SENT", name: "SENT", type: "system")
        try upsertLabel("Label_1", name: "Work")
    }

    private func page(_ response: MailResponse, file: StaticString = #filePath, line: UInt = #line)
        throws -> MailMessagePage {
        guard case .messages(let page) = response else {
            XCTFail("expected messages, got \(response)", file: file, line: line)
            throw HubMailBridge.Failure("unexpected response")
        }
        return page
    }

    private func failure(_ response: MailResponse) -> String? {
        if case .failure(let message, _) = response { return message }
        return nil
    }

    private func syncVersion(_ id: String) throws -> Int? {
        try database.read { conn in
            try projection.syncVersion(resource: HubMailResource.messages, id: id, in: conn)
        }
    }

    // MARK: - Vectors

    // 001
    func testProviderStatusIsConfiguredWithNoClientId() async {
        let response = await bridge.respond(to: .providerStatus)
        XCTAssertEqual(response, .providerStatus(MailProviderStatus(configured: true, clientId: nil)))
    }

    // 002
    func testAdminRequestsAreRefused() async throws {
        try upsertMessage("m1")
        let requests: [MailRequest] = [
            .signIn, .removeAccount(account: "c1"),
            .updateSettings(account: "c1", settings: .default), .importOAuthClient(json: Data())
        ]
        for request in requests {
            let response = await bridge.respond(to: request)
            XCTAssertNotNil(failure(response), "\(request)")
        }
        XCTAssertNotNil(try store.message(id: "m1"))
        let writes = await recorder.writes
        XCTAssertTrue(writes.isEmpty)
    }

    // 003
    func testAccountsComeFromConnectionsWithTheSentAddress() async throws {
        try upsertMessage("m1", Seed(labels: ["SENT"], from: "Me <Me@X.com>"))
        try upsertMessage("m2", Seed(connection: "c2"))
        let response = await bridge.respond(to: .listAccounts)
        guard case .accounts(let accounts) = response else { return XCTFail("\(response)") }
        XCTAssertEqual(accounts.map(\.id), ["c1", "c2"])
        XCTAssertEqual(accounts.map(\.email), ["me@x.com", "c2"])
        XCTAssertTrue(accounts.allSatisfy { $0.status == .active })
    }

    func testAddressReadsTheAngleBracketPart() {
        XCTAssertEqual(HubMailBridge.address("Me <Me@X.com>"), "me@x.com")
        XCTAssertEqual(HubMailBridge.address("  A@B.c "), "a@b.c")
        XCTAssertNil(HubMailBridge.address("   "))
    }

    // 004
    func testAccountLookupByEmailIgnoresCaseAndUnknownIsNotFound() async throws {
        try seedStandardLabels()
        try upsertMessage("m1", Seed(labels: ["SENT"], from: "Me <me@x.com>"))
        let found = await bridge.respond(to: .listLabels(account: "ME@x.com"))
        guard case .labels(let labels) = found else { return XCTFail("\(found)") }
        XCTAssertEqual(labels.count, 3)
        let missing = await bridge.respond(to: .listLabels(account: "nobody"))
        XCTAssertEqual(missing, .notFound("unknown account: nobody"))
    }

    // 005
    func testLabelsAreMappedSystemFirst() async throws {
        try upsertLabel("Label_1", name: "Work")
        try upsertLabel("INBOX", name: "INBOX", type: "system")
        let response = await bridge.respond(to: .listLabels(account: "c1"))
        guard case .labels(let labels) = response else { return XCTFail("\(response)") }
        XCTAssertEqual(labels.map(\.id), ["INBOX", "Label_1"])
        XCTAssertEqual(labels.last?.name, "Work")
    }

    // 006
    func testLabelFilterResolvesNames() async throws {
        try seedStandardLabels()
        try upsertMessage("m1", Seed(labels: ["INBOX", "Label_1"]))
        try upsertMessage("m2", Seed(labels: ["INBOX"]))
        let response = await bridge.respond(to: .listMessages(MailMessageFilter(account: "c1", labels: ["Work"])))
        XCTAssertEqual(try page(response).messages.map(\.id), ["m1"])
    }

    // 007
    func testAnyLabelsAreApplied() async throws {
        try seedStandardLabels()
        try upsertMessage("m1", Seed(date: "2026-01-01T00:00:00Z", labels: ["INBOX"]))
        try upsertMessage("m2", Seed(date: "2026-01-02T00:00:00Z", labels: ["SENT"]))
        try upsertMessage("m3", Seed(date: "2026-01-03T00:00:00Z", labels: ["Label_1"]))
        let response = await bridge.respond(
            to: .listMessages(MailMessageFilter(account: "c1", anyLabels: ["INBOX", "SENT"])))
        let result = try page(response)
        XCTAssertEqual(result.messages.map(\.id), ["m2", "m1"])
        XCTAssertTrue(result.appliedAnyLabels)
    }

    // 008
    func testSinceAndUntilNarrowTheDates() async throws {
        try upsertMessage("m1", Seed(date: "2026-01-01T00:00:00Z"))
        try upsertMessage("m2", Seed(date: "2026-01-05T00:00:00Z"))
        try upsertMessage("m3", Seed(date: "2026-01-09T00:00:00Z"))
        let filter = MailMessageFilter(account: "c1", since: "2026-01-04T00:00:00Z", until: "2026-01-06T00:00:00Z")
        let response = await bridge.respond(to: .listMessages(filter))
        XCTAssertEqual(try page(response).messages.map(\.id), ["m2"])
    }

    // 009
    func testCursorPagesThroughTheMirror() async throws {
        try upsertMessage("m1", Seed(date: "2026-01-01T00:00:00Z"))
        try upsertMessage("m2", Seed(date: "2026-01-02T00:00:00Z"))
        try upsertMessage("m3", Seed(date: "2026-01-03T00:00:00Z"))
        let first = try page(await bridge.respond(to: .listMessages(MailMessageFilter(account: "c1", limit: 2))))
        XCTAssertEqual(first.messages.map(\.id), ["m3", "m2"])
        let cursor = try XCTUnwrap(first.nextCursor)
        let second = try page(await bridge.respond(
            to: .listMessages(MailMessageFilter(account: "c1", limit: 2, cursor: cursor))))
        XCTAssertEqual(second.messages.map(\.id), ["m1"])
        XCTAssertNil(second.nextCursor)
    }

    // 010
    func testBadCursorFails() async throws {
        try upsertMessage("m1")
        let response = await bridge.respond(to: .listMessages(MailMessageFilter(account: "c1", cursor: "zzz")))
        XCTAssertEqual(failure(response), "bad cursor")
    }

    // 011
    func testSearchIsRefusedButABlankQueryLists() async throws {
        try upsertMessage("m1")
        let refused = await bridge.respond(to: .listMessages(MailMessageFilter(account: "c1", query: "from:a")))
        XCTAssertNotNil(failure(refused))
        let blank = await bridge.respond(to: .listMessages(MailMessageFilter(account: "c1", query: "  ")))
        XCTAssertEqual(try page(blank).messages.map(\.id), ["m1"])
    }

    // 012
    func testUnknownLabelFails() async throws {
        try seedStandardLabels()
        try upsertMessage("m1")
        let response = await bridge.respond(to: .listMessages(MailMessageFilter(account: "c1", labels: ["Nope"])))
        XCTAssertEqual(failure(response), "unknown label: Nope")
    }

    // 013
    func testGetMessageByProviderIdReadsHTMLAsText() async throws {
        try seedStandardLabels()
        try upsertMessage("m1", Seed(labels: ["INBOX", "Label_1"], bodyHtml: "<p>Hello <b>there</b></p>"))
        let response = await bridge.respond(to: .getMessage(account: "c1", id: "ext-m1"))
        guard case .message(let message) = response else { return XCTFail("\(response)") }
        XCTAssertEqual(message.id, "m1")
        XCTAssertEqual(message.gmailId, "ext-m1")
        XCTAssertEqual(message.labelNames, ["INBOX", "Work"])
        XCTAssertEqual(message.bodyText?.contains("Hello"), true)
        XCTAssertEqual(message.bodyText?.contains("<p>"), false)
        let missing = await bridge.respond(to: .getMessage(account: "c1", id: "nope"))
        XCTAssertEqual(missing, .notFound("unknown message: nope"))
    }

    // 014
    func testListWithoutBodiesCarriesNone() async throws {
        try upsertMessage("m1", Seed(bodyText: "text", bodyHtml: "<p>html</p>"))
        let response = await bridge.respond(to: .listMessages(MailMessageFilter(account: "c1")))
        let message = try XCTUnwrap(try page(response).messages.first)
        XCTAssertNil(message.bodyText)
        XCTAssertNil(message.bodyHtml)
    }

    // 015
    func testThreadByMessageIdIsOldestFirst() async throws {
        try upsertMessage("m1", Seed(date: "2026-01-01T00:00:00Z", thread: "t1"))
        try upsertMessage("m2", Seed(date: "2026-01-02T00:00:00Z", thread: "t1"))
        try upsertMessage("m3", Seed(date: "2026-01-03T00:00:00Z", thread: "t1"))
        let response = await bridge.respond(to: .getThread(account: "c1", id: "m2", includeBodies: false))
        guard case .thread(let thread) = response else { return XCTFail("\(response)") }
        XCTAssertEqual(thread.id, "t1")
        XCTAssertEqual(thread.messages.map(\.id), ["m1", "m2", "m3"])
        let missing = await bridge.respond(to: .getThread(account: "c1", id: "nope", includeBodies: false))
        XCTAssertEqual(missing, .notFound("unknown thread: nope"))
    }

    // 016
    func testModifyLabelsWritesThroughTheHubThenTheMirror() async throws {
        try seedStandardLabels()
        try upsertMessage("m1", Seed(labels: ["INBOX"], version: 4))
        let response = await bridge.respond(
            to: .modifyLabels(account: "c1", messageIds: ["m1"], add: ["Work"], remove: ["INBOX"]))
        let writes = await recorder.writes
        XCTAssertEqual(writes, [
            HubMailLabelWrite(connectionId: "c1", messageIds: ["ext-m1"], add: ["Label_1"], remove: ["INBOX"])
        ])
        XCTAssertEqual(try page(response).messages.first?.labels, ["Label_1"])
        XCTAssertEqual(try store.message(id: "m1")?.labelIds, ["Label_1"])
        XCTAssertEqual(try syncVersion("m1"), 4)
    }

    // 017
    func testModifyWithNothingToChangeWritesNothing() async throws {
        try seedStandardLabels()
        try upsertMessage("m1")
        let response = await bridge.respond(to: .modifyLabels(account: "c1", messageIds: ["m1"], add: [], remove: []))
        let writes = await recorder.writes
        XCTAssertTrue(writes.isEmpty)
        XCTAssertEqual(try page(response).messages.first?.labels, ["INBOX"])
    }

    // 018
    func testMoveWritesOnlyTheMessagesThatChange() async throws {
        try seedStandardLabels()
        try upsertMessage("m1", Seed(labels: ["Label_1"]))
        try upsertMessage("m2", Seed(labels: ["INBOX"]))
        let response = await bridge.respond(
            to: .moveMessages(account: "c1", messageIds: ["m1", "m2"], destination: "Work", from: nil))
        guard case .moved(let results) = response else { return XCTFail("\(response)") }
        let writes = await recorder.writes
        XCTAssertEqual(writes.map(\.messageIds), [["ext-m2"]])
        XCTAssertEqual(results.map(\.added), [[], ["Work"]])
        XCTAssertEqual(results.map(\.removed), [[], ["INBOX"]])
        XCTAssertEqual(try store.message(id: "m2")?.labelIds, ["Label_1"])
    }

    // 019
    func testMoveToALabelAlsoMovedFromFails() async throws {
        try seedStandardLabels()
        try upsertMessage("m1")
        let response = await bridge.respond(
            to: .moveMessages(account: "c1", messageIds: ["m1"], destination: "INBOX", from: ["INBOX"]))
        XCTAssertNotNil(failure(response))
        let writes = await recorder.writes
        XCTAssertTrue(writes.isEmpty)
    }

    // 020
    func testWriterFailureLeavesTheMirrorAlone() async throws {
        try seedStandardLabels()
        try upsertMessage("m1")
        await recorder.refuse("hub said no")
        let response = await bridge.respond(
            to: .modifyLabels(account: "c1", messageIds: ["m1"], add: ["Work"], remove: []))
        XCTAssertEqual(failure(response), "hub said no")
        XCTAssertEqual(try store.message(id: "m1")?.labelIds, ["INBOX"])
    }

    func testHubRejectionNamesTheStatus() async throws {
        try seedStandardLabels()
        try upsertMessage("m1")
        let rejecting = HubMailBridge(
            store: store, writeLabels: { _ in throw HubMailSendError.rejected(statusCode: 403) }, syncNow: {})
        let response = await rejecting.respond(
            to: .modifyLabels(account: "c1", messageIds: ["m1"], add: ["Work"], remove: []))
        XCTAssertEqual(failure(response), "the hub refused the label change (status 403)")
    }

    // 021
    func testSyncNowRunsThePullOnce() async {
        let response = await bridge.respond(to: .syncNow(account: nil))
        XCTAssertEqual(response, .ok)
        let pulls = await recorder.pulls
        XCTAssertEqual(pulls, 1)
    }

    // 022
    func testClientTransportAnswersAccounts() async throws {
        try upsertMessage("m1", Seed(labels: ["SENT"], from: "me@x.com"))
        let accounts = try await bridge.client.accounts()
        XCTAssertEqual(accounts.map(\.email), ["me@x.com"])
        guard case .accounts(let direct) = await bridge.respond(to: .listAccounts) else {
            return XCTFail("listAccounts did not answer accounts")
        }
        XCTAssertEqual(accounts, direct)
    }
}
