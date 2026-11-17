import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
@Suite("GitCommitDetailViewController agent sessions")
struct GitCommitDetailAgentSessionsTests {
    private static let date = Date(timeIntervalSince1970: 1_800_000_000)

    private static func commit(_ id: String) -> GitCommit {
        let person = GitPerson(name: "Ann Lee", email: "ann@example.com", date: date)
        return GitCommit(id: id, parents: [], author: person, committer: person, subject: "subject", body: "")
    }

    private static func session(_ id: String, title: String? = nil) -> GitAgentSession {
        GitAgentSession(id: id, title: title, cwd: "/repo", branch: "main",
                        startedAt: date, lastActivityAt: date.addingTimeInterval(600))
    }

    private static func detail() -> GitCommitDetailViewController {
        let detail = GitCommitDetailViewController(source: GitViewsFakeContentSource(),
                                                   pasteboard: NSPasteboard(name: .init("git.sessions.\(UUID())")))
        detail.loadViewIfNeeded()
        return detail
    }

    @Test("absent without a provider, and when nothing matches")
    func absent() {
        let detail = Self.detail()
        detail.show(commit: Self.commit("c1"))
        #expect(detail.agentSessionsView.isHidden)
        detail.agentSessionMatches = { _ in [] }
        #expect(detail.agentSessionsView.isHidden)
        #expect(detail.agentSessionsView.rowButtons.isEmpty)
    }

    @Test("one row per matched session, under the caption, and a commit change re-matches")
    func rows() {
        let detail = Self.detail()
        detail.agentSessionMatches = { commit in
            commit.id == "c1" ? [Self.session("0123456789", title: "Fix it"), Self.session("abcdefghij")] : []
        }
        detail.show(commit: Self.commit("c1"))
        let view = detail.agentSessionsView
        #expect(!view.isHidden)
        #expect(view.accessibilityIdentifier() == "git.commit.sessions")
        #expect(view.caption.stringValue == "Agent Sessions")
        #expect(view.rowButtons.count == 2)
        #expect(view.rowButtons[0].title.hasPrefix("Fix it · main · "))
        #expect(view.rowButtons[1].title.hasPrefix("abcdefgh · main · "))
        #expect(view.rowButtons.allSatisfy { $0.accessibilityIdentifier() == "git.commit.sessions.row" })
        #expect(view.rowButtons.allSatisfy { !$0.isEnabled })
        detail.show(commit: Self.commit("c2"))
        #expect(view.isHidden)
    }

    @Test("clicking a row opens its session by id")
    func clickOpens() {
        let detail = Self.detail()
        var opened: [String] = []
        detail.onOpenAgentSession = { opened.append($0) }
        detail.agentSessionMatches = { _ in [Self.session("first"), Self.session("second")] }
        detail.show(commit: Self.commit("c1"))
        let allEnabled = detail.agentSessionsView.rowButtons.allSatisfy { $0.isEnabled }
        #expect(allEnabled)
        detail.agentSessionsView.rowButtons[1].performClick(nil)
        #expect(opened == ["second"])
    }
}
