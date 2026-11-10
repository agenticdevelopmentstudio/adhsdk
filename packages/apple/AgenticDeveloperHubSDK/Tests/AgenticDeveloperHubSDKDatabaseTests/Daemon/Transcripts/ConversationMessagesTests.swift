import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// `ConversationStore.conversationMessages`: one session's messages, oldest
/// first, paged by message id — the read behind `steno conversation fetch`.
final class ConversationMessagesTests: XCTestCase {

    private var database: DaemonDatabase!
    private var store: ConversationStore!
    private var tmpPath: String!
    private var session = ""

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        database = opened.db
        tmpPath = opened.path
        store = ConversationStore(database: opened.db)
        session = UUID().uuidString
        try database.createSessionStubIfMissing(
            sessionId: session, cwd: "/src/alpha", model: "claude-opus-5",
            startedAt: "2026-09-01T00:00:00Z", lastActivityAt: "2026-09-01T00:00:00Z",
            gitBranch: "main", accountEmail: "")
    }

    override func tearDownWithError() throws {
        store = nil
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
    }

    // MARK: - Helpers

    private func line(_ lineNo: Int, type: String, at timestamp: String, json: String)
    -> JSONLScanner.RawTranscriptLine {
        JSONLScanner.RawTranscriptLine(
            lineNo: lineNo, sessionId: session, entryUuid: UUID().uuidString, parentUuid: "",
            entryType: type, role: type, timestamp: timestamp, isSidechain: false, rawJSON: json,
            isQueuedPrompt: QueuedPrompt.isQueuedPrompt(rawJSON: json))
    }

    private func prompt(_ lineNo: Int, at timestamp: String, _ text: String) -> JSONLScanner.RawTranscriptLine {
        line(lineNo, type: "user", at: timestamp,
             json: #"{"type":"user","message":{"role":"user","content":"\#(text)"}}"#)
    }

    private func reply(_ lineNo: Int, at timestamp: String, _ texts: String...) -> JSONLScanner.RawTranscriptLine {
        let blocks = texts.map { #"{"type":"text","text":"\#($0)"}"# }.joined(separator: ",")
        return line(lineNo, type: "assistant", at: timestamp,
                    json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"end_turn","#
                        + #""content":[\#(blocks)]}}"#)
    }

    private func progress(_ lineNo: Int, at timestamp: String, _ text: String) -> JSONLScanner.RawTranscriptLine {
        line(lineNo, type: "assistant", at: timestamp,
             json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"tool_use","#
                 + #""content":[{"type":"text","text":"\#(text)"}]}}"#)
    }

    private func insertDialogue() throws {
        try database.insertTranscriptLines([
            prompt(1, at: "2026-09-01T10:00:00Z", "hello claude"),
            progress(2, at: "2026-09-01T10:00:01Z", "looking around"),
            reply(3, at: "2026-09-01T10:00:02Z", "hello", "how can I help"),
            prompt(4, at: "2026-09-01T10:00:03Z", "thanks")
        ], filePath: "/tmp/\(session).jsonl")
    }

    private func page(
        after: Int? = nil, through: Int? = nil, limit: Int = 100, work: Bool = false
    ) throws -> ConversationMessagesPageDTO {
        try store.conversationMessages(
            sessionId: session, afterId: after, throughId: through, limit: limit, includeWorkOutput: work)
    }

    // MARK: - Tests

    func testTheWholeConversationComesBackOldestFirstWithUserAndModelTypes() throws {
        try insertDialogue()
        let result = try page()
        XCTAssertEqual(result.messages.map(\.content), ["hello claude", "hello", "how can I help", "thanks"])
        XCTAssertEqual(result.messages.map(\.type), ["user", "model", "model", "user"])
        XCTAssertTrue(result.isComplete)
        XCTAssertEqual(result.nextAfterId, result.messages.last?.id)
    }

    func testWorkOutputIsLeftOutUnlessAskedFor() throws {
        try insertDialogue()
        XCTAssertFalse(try page().messages.map(\.content).contains("looking around"))
        XCTAssertTrue(try page(work: true).messages.map(\.content).contains("looking around"))
    }

    func testAfterIsExclusiveAndThroughIsInclusive() throws {
        try insertDialogue()
        let all = try page().messages
        let after = try page(after: all[0].id).messages
        XCTAssertEqual(after.map(\.content), ["hello", "how can I help", "thanks"])
        // Cutting inside one transcript entry keeps its earlier block only.
        let through = try page(after: all[0].id, through: all[1].id).messages
        XCTAssertEqual(through.map(\.content), ["hello"])
    }

    func testAFullPageSaysWhereToContinue() throws {
        try insertDialogue()
        let first = try page(limit: 1)
        XCTAssertEqual(first.messages.map(\.content), ["hello claude"])
        XCTAssertFalse(first.isComplete)
        let rest = try page(after: first.nextAfterId)
        XCTAssertEqual(rest.messages.map(\.content), ["hello", "how can I help", "thanks"])
        XCTAssertTrue(rest.isComplete)
    }

    func testTheNewestIdAsksForNothingMore() throws {
        try insertDialogue()
        let last = try XCTUnwrap(try page().messages.last)
        let next = try page(after: last.id)
        XCTAssertTrue(next.messages.isEmpty)
        XCTAssertTrue(next.isComplete)
        XCTAssertEqual(next.nextAfterId, last.id)
    }

    func testAnIdFromNowhereIsRefused() throws {
        try insertDialogue()
        XCTAssertThrowsError(try page(after: 999_999_000)) { error in
            XCTAssertEqual(error as? ConversationRangeError, .unknownMessageId(999_999_000))
        }
    }

    func testAnEmptyConversationIsCompleteAndEmpty() throws {
        let result = try page()
        XCTAssertTrue(result.messages.isEmpty)
        XCTAssertTrue(result.isComplete)
        XCTAssertNil(result.nextAfterId)
    }
}
