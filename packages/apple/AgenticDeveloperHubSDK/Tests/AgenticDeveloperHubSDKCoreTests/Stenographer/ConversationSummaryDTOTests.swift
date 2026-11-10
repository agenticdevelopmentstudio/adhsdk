import XCTest
@testable import AgenticDeveloperHubSDKCore

/// The conversation reading of a session: status, `~` paths, `--app` matching.
final class ConversationSummaryDTOTests: XCTestCase {

    private func session(
        status: String = "active", lastEventType: String = "", subagentWorking: Bool = false,
        cwd: String = "/Users/me/src/app", termProgram: String = "iTerm.app"
    ) -> SessionDTO {
        SessionDTO(
            sessionId: "s1", cwd: cwd, model: "claude-opus-5", startedAt: "2026-11-10 09:00:00",
            lastActivityAt: "2026-11-10 10:00:00", lastTool: "", status: status, gitBranch: "main",
            summary: "", pid: 42, termProgram: termProgram, transcriptTitle: "my chat",
            lastEventType: lastEventType, eventCount: 0, subagentWorking: subagentWorking)
    }

    func testStatusFollowsTheTurn() {
        XCTAssertEqual(ConversationStatus(session: session(lastEventType: "Stop")), .idle)
        XCTAssertEqual(ConversationStatus(session: session(lastEventType: "PreToolUse")), .busy)
        XCTAssertEqual(ConversationStatus(session: session(lastEventType: "PermissionRequest")), .waiting)
        XCTAssertEqual(ConversationStatus(session: session(lastEventType: "Stop", subagentWorking: true)), .busy)
        XCTAssertEqual(ConversationStatus(session: session(status: "ended", lastEventType: "Stop")), .ended)
    }

    func testHomeRelative() {
        XCTAssertEqual(ConversationSummaryDTO.homeRelative("/Users/me/src", homeDirectory: "/Users/me"), "~/src")
        XCTAssertEqual(ConversationSummaryDTO.homeRelative("/Users/me", homeDirectory: "/Users/me/"), "~")
        XCTAssertEqual(ConversationSummaryDTO.homeRelative("/Users/meow", homeDirectory: "/Users/me"), "/Users/meow")
        XCTAssertEqual(ConversationSummaryDTO.homeRelative("/tmp", homeDirectory: ""), "/tmp")
    }

    func testSummaryReadsTheSession() {
        let row = ConversationSummaryDTO(session: session(), homeDirectory: "/Users/me")
        XCTAssertEqual(row.cwd, "~/src/app")
        XCTAssertEqual(row.sessionName, "my chat")
        XCTAssertEqual(row.agent, "claude")
        XCTAssertEqual(row.lastActivity, UTCTimestamp.canonical("2026-11-10 10:00:00"))
    }

    func testAppMatchesAgentOrTerminalByPrefix() {
        let iterm = session(termProgram: "iTerm.app")
        XCTAssertTrue(ConversationSummaryDTO.matches(app: "claude", session: iterm))
        XCTAssertTrue(ConversationSummaryDTO.matches(app: "ITERM", session: iterm))
        XCTAssertFalse(ConversationSummaryDTO.matches(app: "ghostty", session: iterm))
    }

    func testInfoCanSendOnlyToALiveSupportedTerminal() {
        XCTAssertTrue(ConversationInfoDTO(session: session(), homeDirectory: "/Users/me").canSend)
        XCTAssertFalse(ConversationInfoDTO(session: session(status: "ended"), homeDirectory: "/Users/me").canSend)
        XCTAssertFalse(ConversationInfoDTO(session: session(termProgram: "vscode"), homeDirectory: "/Users/me").canSend)
    }
}
