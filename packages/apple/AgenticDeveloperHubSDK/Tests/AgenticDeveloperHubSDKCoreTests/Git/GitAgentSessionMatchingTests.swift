import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitAgentSessionMatcher")
struct GitAgentSessionMatchingTests {
    private static let base = Date(timeIntervalSince1970: 1_800_000_000)
    private static let roots = ["/repo", "/worktrees/feature"]

    private static func session(
        _ id: String, cwd: String = "/repo", branch: String? = nil,
        start: TimeInterval = 0, end: TimeInterval = 3600, title: String? = nil
    ) -> GitAgentSession {
        GitAgentSession(id: id, title: title, cwd: cwd, branch: branch,
                        startedAt: base.addingTimeInterval(start), lastActivityAt: base.addingTimeInterval(end))
    }

    private static func ids(_ sessions: [GitAgentSession]) -> [String] { sessions.map(\.id) }

    private static func forCommit(_ all: [GitAgentSession], at offset: TimeInterval,
                                  branch: String? = nil) -> [String] {
        ids(GitAgentSessionMatcher.sessions(all, forCommitAt: base.addingTimeInterval(offset),
                                            branch: branch, roots: roots))
    }

    @Test("a session in a worktree or a subdirectory belongs to the repository")
    func worktreeAndSubdirectory() {
        let all = [Self.session("wt", cwd: "/worktrees/feature"), Self.session("sub", cwd: "/repo/App/Sources")]
        #expect(Self.forCommit(all, at: 60).sorted() == ["sub", "wt"])
    }

    @Test("a directory that only shares a prefix is not under the root")
    func prefixIsNotUnder() {
        let all = [Self.session("bc", cwd: "/repobc"), Self.session("other", cwd: "/worktrees/featurex/a")]
        #expect(Self.forCommit(all, at: 60).isEmpty)
        #expect(GitAgentSessionMatcher.isUnder("/a/b", [["/", "a"]]))
        #expect(!GitAgentSessionMatcher.isUnder("/a/bc", [["/", "a", "b"]]))
    }

    @Test("the same branch matches outside the time span")
    func branchMatchOutsideSpan() {
        let all = [Self.session("old", branch: "feature", start: -90_000, end: -86_400)]
        #expect(Self.forCommit(all, at: 0, branch: "feature") == ["old"])
        #expect(Self.forCommit(all, at: 0, branch: "main").isEmpty)
    }

    @Test("with no branch known, a session active at the commit matches")
    func timeMatchWithoutBranch() {
        let all = [Self.session("during", start: 0, end: 3600), Self.session("later", start: 7200, end: 9000)]
        #expect(Self.forCommit(all, at: 1800) == ["during"])
        #expect(Self.forCommit(all, at: 1800, branch: "") == ["during"])
    }

    @Test("the ten-minute slack is inclusive at both edges")
    func slackEdges() {
        let all = [Self.session("one", start: 0, end: 3600)]
        #expect(Self.forCommit(all, at: -600) == ["one"])
        #expect(Self.forCommit(all, at: -601).isEmpty)
        #expect(Self.forCommit(all, at: 4200) == ["one"])
        #expect(Self.forCommit(all, at: 4201).isEmpty)
    }

    @Test("newest start first, ties by id")
    func sortOrder() {
        let all = [Self.session("b", start: 0), Self.session("a", start: 0), Self.session("c", start: 100)]
        #expect(Self.forCommit(all, at: 200) == ["c", "a", "b"])
    }

    @Test("on a branch: only that branch, under the roots")
    func onBranch() {
        let all = [
            Self.session("yes", branch: "feature", start: 0),
            Self.session("newer", cwd: "/worktrees/feature", branch: "feature", start: 50),
            Self.session("elsewhere", cwd: "/other", branch: "feature"),
            Self.session("main", branch: "main")
        ]
        let found = GitAgentSessionMatcher.sessions(all, onBranch: "feature", roots: Self.roots)
        #expect(Self.ids(found) == ["newer", "yes"])
    }

    @Test("the display title falls back to the id's first eight characters")
    func displayTitle() {
        #expect(Self.session("0123456789abcdef").displayTitle == "01234567")
        #expect(Self.session("0123456789abcdef", title: "Named").displayTitle == "Named")
    }
}

@Suite("GitDaemonSessions")
struct GitDaemonSessionsMappingTests {
    private static func dto(
        id: String = "s1", started: String = "2026-11-10 09:00:00", last: String = "2026-11-10 10:00:00",
        branch: String = "main", title: String = ""
    ) -> SessionDTO {
        SessionDTO(
            sessionId: id, cwd: "/repo", model: "claude-opus-5", startedAt: started, lastActivityAt: last,
            lastTool: "", status: "ended", gitBranch: branch, summary: "", pid: 1, termProgram: "",
            transcriptTitle: title, eventCount: 0)
    }

    @Test("a row maps to a session, empty strings to nil")
    func mapsRow() throws {
        let session = try #require(GitDaemonSessions.session(from: Self.dto(branch: "", title: "")))
        #expect(session.id == "s1")
        #expect(session.branch == nil)
        #expect(session.title == nil)
        #expect(session.lastActivityAt.timeIntervalSince(session.startedAt) == 3600)
        let named = try #require(GitDaemonSessions.session(from: Self.dto(title: "Fix it")))
        #expect(named.title == "Fix it")
        #expect(named.branch == "main")
    }

    @Test("no id or an unreadable start drops the row; an unreadable end is the start")
    func unreadableRows() throws {
        #expect(GitDaemonSessions.session(from: Self.dto(id: "")) == nil)
        #expect(GitDaemonSessions.session(from: Self.dto(started: "not a date")) == nil)
        let session = try #require(GitDaemonSessions.session(from: Self.dto(last: "")))
        #expect(session.lastActivityAt == session.startedAt)
        let backwards = try #require(GitDaemonSessions.session(from: Self.dto(last: "2026-11-10 08:00:00")))
        #expect(backwards.lastActivityAt == backwards.startedAt)
    }

    @Test("hours round up and stay within 1 and 90 days")
    func hours() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(GitDaemonSessions.hours(since: now, now: now) == 1)
        #expect(GitDaemonSessions.hours(since: now.addingTimeInterval(-3601), now: now) == 2)
        #expect(GitDaemonSessions.hours(since: now.addingTimeInterval(-400 * 86_400), now: now) == 2160)
    }
}
