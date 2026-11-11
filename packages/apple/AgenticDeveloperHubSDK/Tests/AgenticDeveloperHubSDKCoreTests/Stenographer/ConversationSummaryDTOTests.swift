import XCTest
@testable import AgenticDeveloperHubSDKCore

/// The conversation reading of a session: status, `~` paths, `--app` matching.
final class ConversationSummaryDTOTests: XCTestCase {

    private func session(
        status: String = "active", lastEventType: String = "", subagentWorking: Bool = false,
        cwd: String = "/Users/me/src/app", termProgram: String = "iTerm.app", gitBranch: String = "main"
    ) -> SessionDTO {
        SessionDTO(
            sessionId: "s1", cwd: cwd, model: "claude-opus-5", startedAt: "2026-11-10 09:00:00",
            lastActivityAt: "2026-11-10 10:00:00", lastTool: "", status: status, gitBranch: gitBranch,
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

    func testWorkInProgressIsAFeatureBranchOrAWorktree() {
        XCTAssertFalse(ConversationSummaryDTO.isWorkInProgress(session: session(gitBranch: "main")))
        XCTAssertFalse(ConversationSummaryDTO.isWorkInProgress(session: session(gitBranch: "master")))
        XCTAssertFalse(ConversationSummaryDTO.isWorkInProgress(session: session(gitBranch: "")))
        XCTAssertFalse(ConversationSummaryDTO.isWorkInProgress(session: session(gitBranch: "HEAD")))
        XCTAssertTrue(ConversationSummaryDTO.isWorkInProgress(session: session(gitBranch: "fix-login")))
        XCTAssertTrue(ConversationSummaryDTO.isWorkInProgress(
            session: session(cwd: "/Users/me/src/app/.claude/worktrees/wt/Sources", gitBranch: "main")))
        XCTAssertFalse(ConversationSummaryDTO.isWorkInProgress(
            session: session(cwd: "/Users/me/src/app/.claude/worktrees", gitBranch: "main")))
    }

    private func info(_ session: SessionDTO, live: [SessionDTO] = []) -> ConversationInfoDTO {
        ConversationInfoDTO(session: session, liveSessions: live, homeDirectory: "/Users/me")
    }

    func testInfoCanSendOnlyToALiveSupportedTerminal() {
        XCTAssertTrue(info(session()).canSend)
        XCTAssertFalse(info(session(status: "ended")).canSend)
        XCTAssertFalse(info(session(termProgram: "vscode")).canSend)
    }

    /// A pane showing a permission prompt would take the typed message's Return as
    /// "Yes" — so a waiting conversation is refused, with the reason.
    func testWaitingConversationRefusesASend() {
        let waiting = session(lastEventType: "PermissionRequest")
        XCTAssertFalse(info(waiting).canSend)
        XCTAssertTrue(info(waiting).sendRefusal.contains("waiting on a prompt"), info(waiting).sendRefusal)
        XCTAssertNil(ConversationSendability.refusal(for: session(lastEventType: "PreToolUse"), liveSessions: []),
                     "busy queues")
        XCTAssertEqual(info(session()).sendRefusal, "")
    }

    private func iTerm(_ id: String, pane: String, status: String = "active") -> SessionDTO {
        SessionDTO(
            sessionId: id, cwd: "/Users/me/src", model: "", startedAt: "", lastActivityAt: "", lastTool: "",
            status: status, gitBranch: "", summary: "", pid: 0, termProgram: "iTerm.app",
            termSessionId: "w0t0p0:\(pane)", transcriptTitle: "", lastEventType: "Stop", eventCount: 0)
    }

    /// A `claude -p` run from another session's Bash tool inherits that session's
    /// TERM_SESSION_ID: its pane is the parent's, so neither may be sent to.
    func testSessionsSharingAPaneRefuseASend() {
        let parent = iTerm("parent", pane: "P")
        let child = iTerm("child", pane: "P")
        let elsewhere = iTerm("other", pane: "Q")
        let live = [parent, child, elsewhere]
        XCTAssertFalse(info(child, live: live).canSend)
        XCTAssertTrue(info(child, live: live).sendRefusal.contains("parent"), info(child, live: live).sendRefusal)
        XCTAssertFalse(info(parent, live: live).canSend)
        XCTAssertTrue(info(elsewhere, live: live).canSend)
        XCTAssertTrue(info(parent, live: [parent, iTerm("child", pane: "P", status: "ended")]).canSend,
                      "an ended session shares nothing")
    }
}
