import XCTest
@testable import AgenticDeveloperHubSDKCore

final class ConversationMessageDTOConformanceTests: XCTestCase {

    private static let storeSkip = "Needs the daemon's ConversationStore; covered by ConversationMessagesTests"

    func testV001_promptIsUser() {
        XCTAssertEqual(ConversationMessageDTO.type(forKind: "prompt"), "user")
    }

    func testV002_noticeIsNotice() {
        XCTAssertEqual(ConversationMessageDTO.type(forKind: "notice"), "notice")
    }

    func testV003_otherKindsAreModel() {
        for kind in ["reply", "progress", "thinking", "mystery"] {
            XCTAssertEqual(ConversationMessageDTO.type(forKind: kind), "model", kind)
        }
    }

    func testV004_initFromEntry() {
        let entry = ConversationEntryDTO(
            id: 5000, sessionId: "s1", kind: "reply", text: "hi", timestamp: "2026-09-01T10:00:00Z",
            projectName: "p", gitBranch: "main", sessionName: "n")
        let message = ConversationMessageDTO(entry: entry)
        XCTAssertEqual(message.id, 5000)
        XCTAssertEqual(message.type, "model")
        XCTAssertEqual(message.kind, "reply")
        XCTAssertEqual(message.content, "hi")
        XCTAssertEqual(message.time, "2026-09-01T10:00:00Z")
        XCTAssertNil(message.agentId)
    }

    func testV005_rangeErrorDescription() {
        XCTAssertEqual(
            ConversationRangeError.unknownMessageId(42).errorDescription,
            "No message 42 in this conversation.")
    }

    func testV006_rangeErrorEquatable() {
        XCTAssertEqual(
            ConversationRangeError.unknownMessageId(999_999_000),
            ConversationRangeError.unknownMessageId(999_999_000))
        XCTAssertNotEqual(
            ConversationRangeError.unknownMessageId(1), ConversationRangeError.unknownMessageId(2))
    }

    func testV007_wholeConversationPage() throws {
        throw XCTSkip(Self.storeSkip)
    }

    func testV008_afterIsExclusiveThroughIsInclusive() throws {
        throw XCTSkip(Self.storeSkip)
    }

    func testV009_fullPageSaysWhereToContinue() throws {
        throw XCTSkip(Self.storeSkip)
    }

    func testV010_newestIdAsksForNothingMore() throws {
        throw XCTSkip(Self.storeSkip)
    }

    func testV011_emptyConversationIsCompleteAndEmpty() throws {
        throw XCTSkip(Self.storeSkip)
    }

    func testV012_workOutputFilter() throws {
        throw XCTSkip(Self.storeSkip)
    }

    func testV013_subagentAgentId() throws {
        throw XCTSkip(Self.storeSkip)
    }

    func testV014_missingAgentIdDecodesAsNil() throws {
        let data = Data(#"{"id":1,"type":"user","kind":"prompt","content":"x","time":"t"}"#.utf8)
        let decoded = try JSONDecoder().decode(ConversationMessageDTO.self, from: data)
        XCTAssertNil(decoded.agentId)
        XCTAssertEqual(decoded.content, "x")
    }

    func testV015_memberwiseInitDefaultsAgentIdToNil() {
        let message = ConversationMessageDTO(id: 1, type: "user", kind: "prompt", content: "x", time: "t")
        XCTAssertNil(message.agentId)
    }
}
