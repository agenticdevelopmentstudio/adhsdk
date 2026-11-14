// The mail vocabulary's own names (to, cc, ok) are shorter than the
// identifier_name minimum; renaming them would read worse than the rule.
// swiftlint:disable identifier_name
import XCTest
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
@testable import AgenticDeveloperHubSDKHubMail

/// Vectors hub-mail-001 to 009 and 013 to 016: the projection's writes read back through the store.
final class HubMailStoreTests: XCTestCase {

    private var dir: URL!
    private var database: BoundedDatabase!
    private var store: HubMailStore!
    private let projection = HubMailProjection()

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hub-mail-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        database = try BoundedDatabase(path: dir.appendingPathComponent("mail.db").path)
        store = try HubMailStore(database: database)
    }

    override func tearDownWithError() throws {
        store = nil
        database = nil
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - Helpers

    private func upsertMessage(
        _ id: String, connection: String = "c1", date: String? = nil, thread: String? = nil,
        labels: [String] = ["INBOX"], to: [String] = [], isDeleted: Bool = false, version: Int = 1
    ) throws {
        var data: [String: JSONValue] = [
            "connection_id": .string(connection),
            "provider": .string("gmail"),
            "external_id": .string("ext-\(id)"),
            "subject": .string("Subject \(id)"),
            "label_ids": .array(labels.map { .string($0) }),
            "to_addresses": .array(to.map { .string($0) }),
            "is_deleted": .bool(isDeleted)
        ]
        if let date { data["internal_date"] = .string(date) }
        if let thread { data["thread_id"] = .string(thread) }
        try database.write { conn in
            try projection.upsert(
                resource: HubMailResource.messages, id: id, syncVersion: version, data: data, in: conn
            )
        }
    }

    private func upsertLabel(
        _ id: String, externalId: String, name: String, type: String, connection: String = "c1"
    ) throws {
        let data: [String: JSONValue] = [
            "connection_id": .string(connection),
            "external_id": .string(externalId),
            "source_provider": .string("gmail"),
            "name": .string(name),
            "type": .string(type)
        ]
        try database.write { conn in
            try projection.upsert(resource: HubMailResource.labels, id: id, syncVersion: 1, data: data, in: conn)
        }
    }

    // MARK: - Vectors

    // 001
    func testUpsertReadsBackAsTypedFields() throws {
        try upsertMessage("m1", labels: ["INBOX"], to: ["a@x"])
        let message = try XCTUnwrap(try store.message(id: "m1"))
        XCTAssertEqual(message.to, ["a@x"])
        XCTAssertEqual(message.labelIds, ["INBOX"])
        XCTAssertEqual(message.connectionId, "c1")
        XCTAssertEqual(message.externalId, "ext-m1")
    }

    // 002
    func testDeleteHidesTheRowAndTakesTheDeleteVersion() throws {
        try upsertMessage("m1")
        try database.write { conn in
            try projection.markDeleted(resource: HubMailResource.messages, id: "m1", syncVersion: 7, in: conn)
        }
        XCTAssertNil(try store.message(id: "m1"))
        let version = try database.read { conn in
            try projection.syncVersion(resource: HubMailResource.messages, id: "m1", in: conn)
        }
        XCTAssertEqual(version, 7)
    }

    // 003
    func testUpsertAfterDeleteRevivesTheRow() throws {
        try upsertMessage("m1")
        try database.write { conn in
            try projection.markDeleted(resource: HubMailResource.messages, id: "m1", syncVersion: 7, in: conn)
        }
        try upsertMessage("m1", version: 8)
        XCTAssertNotNil(try store.message(id: "m1"))
    }

    // 004
    func testAMessageTheWorkerMarkedDeletedIsInNoRead() throws {
        try upsertMessage("gone", thread: "t1", isDeleted: true)
        XCTAssertNil(try store.message(id: "gone"))
        XCTAssertEqual(try store.messages().messages, [])
        XCTAssertEqual(try store.thread(connectionId: "c1", threadId: "t1"), [])
        XCTAssertEqual(try store.connections(), [])
    }

    // 005
    func testPagesComeNewestFirstAndTheLastHasNoNext() throws {
        for day in 1...5 {
            try upsertMessage("m\(day)", date: "2026-11-0\(day)T00:00:00Z")
        }
        let first = try store.messages(limit: 2)
        XCTAssertEqual(first.messages.map(\.id), ["m5", "m4"])
        let firstNext = try XCTUnwrap(first.next)
        let second = try store.messages(limit: 2, before: firstNext)
        XCTAssertEqual(second.messages.map(\.id), ["m3", "m2"])
        let secondNext = try XCTUnwrap(second.next)
        let third = try store.messages(limit: 2, before: secondNext)
        XCTAssertEqual(third.messages.map(\.id), ["m1"])
        XCTAssertNil(third.next)
    }

    // 006
    func testTheLabelFilterKeepsOnlyMessagesCarryingThatLabel() throws {
        try upsertMessage("in1", date: "2026-11-01T00:00:00Z", labels: ["INBOX", "UNREAD"])
        try upsertMessage("sent1", date: "2026-11-02T00:00:00Z", labels: ["SENT"])
        try upsertMessage("in2", date: "2026-11-03T00:00:00Z", labels: ["INBOX"])
        XCTAssertEqual(try store.messages(labelId: "INBOX").messages.map(\.id), ["in2", "in1"])
    }

    // 007
    func testSystemLabelsSortBeforeUserLabels() throws {
        try upsertLabel("l1", externalId: "Label_1", name: "Alpha", type: "user")
        try upsertLabel("l2", externalId: "INBOX", name: "INBOX", type: "system")
        let labels = try store.labels(connectionId: "c1")
        XCTAssertEqual(labels.map(\.externalId), ["INBOX", "Label_1"])
        XCTAssertTrue(labels[0].isSystem)
    }

    // 008
    func testAThreadReadsOldestFirst() throws {
        try upsertMessage("b", date: "2026-11-02T00:00:00Z", thread: "t1")
        try upsertMessage("c", date: "2026-11-03T00:00:00Z", thread: "t1")
        try upsertMessage("a", date: "2026-11-01T00:00:00Z", thread: "t1")
        try upsertMessage("other", date: "2026-11-01T00:00:00Z", thread: "t2")
        XCTAssertEqual(try store.thread(connectionId: "c1", threadId: "t1").map(\.id), ["a", "b", "c"])
    }

    // 009
    func testConnectionsAreDistinctAndSorted() throws {
        try upsertMessage("m1", connection: "zeta")
        try upsertMessage("m2", connection: "alpha")
        try upsertMessage("m3", connection: "zeta")
        XCTAssertEqual(try store.connections(), ["alpha", "zeta"])
    }

    // MARK: - Edge cases

    func testAnUndatedMessageSortsAfterDatedOnesAndPagesThrough() throws {
        try upsertMessage("dated", date: "2026-11-01T00:00:00Z")
        try upsertMessage("undated")
        let first = try store.messages(limit: 1)
        XCTAssertEqual(first.messages.map(\.id), ["dated"])
        let second = try store.messages(limit: 1, before: try XCTUnwrap(first.next))
        XCTAssertEqual(second.messages.map(\.id), ["undated"])
        XCTAssertNil(second.next)
    }

    func testAnUnknownResourceIsRefused() throws {
        XCTAssertThrowsError(try database.write { conn in
            try projection.upsert(resource: "personal.notes", id: "x", syncVersion: 1, data: [:], in: conn)
        }) { error in
            XCTAssertEqual(error as? HubMailProjectionError, .unknownResource("personal.notes"))
        }
    }

    func testAnUnknownColumnIsIgnored() throws {
        try database.write { conn in
            try projection.upsert(
                resource: HubMailResource.messages, id: "m1", syncVersion: 1,
                data: ["connection_id": .string("c1"), "brand_new_column": .string("x")], in: conn
            )
        }
        XCTAssertEqual(try store.message(id: "m1")?.connectionId, "c1")
    }
    // 013
    func testQueryRequiresEveryLabelAndAnyOfTheAnyLabels() throws {
        try upsertMessage("both", date: "2026-01-03T00:00:00Z", labels: ["INBOX", "Label_1"])
        try upsertMessage("inbox", date: "2026-01-02T00:00:00Z", labels: ["INBOX"])
        try upsertMessage("sent", date: "2026-01-01T00:00:00Z", labels: ["SENT"])
        let all = try store.messages(HubMailQuery(labelIds: ["INBOX", "Label_1"]))
        XCTAssertEqual(all.messages.map(\.id), ["both"])
        let any = try store.messages(HubMailQuery(anyLabelIds: ["Label_1", "SENT"]))
        XCTAssertEqual(any.messages.map(\.id), ["both", "sent"])
    }

    // 014
    func testQueryNarrowsByDate() throws {
        try upsertMessage("old", date: "2026-01-01T00:00:00Z")
        try upsertMessage("mid", date: "2026-01-05T00:00:00Z")
        try upsertMessage("new", date: "2026-01-09T00:00:00Z")
        let page = try store.messages(HubMailQuery(since: "2026-01-04T00:00:00Z", until: "2026-01-06T00:00:00Z"))
        XCTAssertEqual(page.messages.map(\.id), ["mid"])
    }

    // 015
    func testMessageByConnectionMatchesRowOrProviderId() throws {
        try upsertMessage("m1")
        try upsertMessage("m2", connection: "c2")
        XCTAssertEqual(try store.message(connectionId: "c1", id: "m1")?.id, "m1")
        XCTAssertEqual(try store.message(connectionId: "c1", id: "ext-m1")?.id, "m1")
        XCTAssertNil(try store.message(connectionId: "c1", id: "m2"))
    }

    // 016
    func testApplyLabelsKeepsTheSyncVersion() throws {
        try upsertMessage("m1", labels: ["INBOX", "UNREAD"], version: 6)
        try store.applyLabels(messageIds: ["m1", "missing"], add: ["Label_1", "UNREAD"], remove: ["INBOX"])
        XCTAssertEqual(try store.message(id: "m1")?.labelIds, ["UNREAD", "Label_1"])
        let version = try database.read { conn in
            try projection.syncVersion(resource: HubMailResource.messages, id: "m1", in: conn)
        }
        XCTAssertEqual(version, 6)
    }
}
// swiftlint:enable identifier_name
