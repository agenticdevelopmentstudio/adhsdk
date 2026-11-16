import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A refs data source holding one local branch, `feature`.
@MainActor
private final class OneBranchSource: GitRefsDataSource {
    var root = URL(fileURLWithPath: "/repo", isDirectory: true)
    var refs: [GitRef] = [
        GitRef(kind: .localBranch, fullName: "refs/heads/feature", name: "feature", target: "afeature",
               upstream: nil, ahead: 0, behind: 0, isHead: false)
    ]
    var stashes: [GitStash] = []
    var submodules: [GitSubmodule] = []
    var worktrees: [GitWorktree] = []
    var operationState: GitOperationState = .none
}

@MainActor
@Suite("GitRefsSidebarViewController agent sessions")
struct GitRefsSidebarAgentSessionsTests {
    private static func sessions(_ count: Int) -> [GitAgentSession] {
        (0..<count).map { index in
            GitAgentSession(id: "session-\(index)", title: "Session \(index)", cwd: "/repo", branch: "feature",
                            startedAt: Date(timeIntervalSince1970: 1_800_000_000 - Double(index)),
                            lastActivityAt: Date(timeIntervalSince1970: 1_800_003_600))
        }
    }

    private static func sidebar(_ sessions: [GitAgentSession]?) -> GitRefsSidebarViewController {
        let sidebar = GitRefsSidebarViewController(source: OneBranchSource())
        sidebar.loadViewIfNeeded()
        sidebar.reload()
        if let sessions { sidebar.agentSessionsOnBranch = { _ in sessions } }
        return sidebar
    }

    private static func sessionsItem(_ menu: NSMenu?) -> NSMenuItem? {
        menu?.items.first { $0.accessibilityIdentifier() == "git.sidebar.menu.sessions" }
    }

    @Test("no provider or no sessions: no submenu")
    func absent() {
        #expect(Self.sessionsItem(Self.sidebar(nil).contextMenu(forItemID: "refs/heads/feature")) == nil)
        #expect(Self.sessionsItem(Self.sidebar([]).contextMenu(forItemID: "refs/heads/feature")) == nil)
    }

    @Test("the branch menu ends with the sessions, at most twenty")
    func submenuLimited() throws {
        let menu = try #require(Self.sidebar(Self.sessions(25)).contextMenu(forItemID: "refs/heads/feature"))
        let parent = try #require(Self.sessionsItem(menu))
        #expect(menu.items.last === parent)
        #expect(parent.title == "Agent Sessions")
        let items = try #require(parent.submenu).items
        #expect(items.count == GitRefsSidebarViewController.maximumAgentSessions)
        #expect(items.allSatisfy { $0.accessibilityIdentifier() == "git.sidebar.menu.sessions.item" })
        #expect(items[0].title.hasPrefix("Session 0 · feature · "))
    }

    @Test("without an open route the items are disabled; with one, choosing an item opens it")
    func choosingOpens() throws {
        let sidebar = Self.sidebar(Self.sessions(2))
        let inert = try #require(Self.sessionsItem(sidebar.contextMenu(forItemID: "refs/heads/feature"))?.submenu)
        #expect(inert.items.allSatisfy { $0.action == nil })

        var opened: [String] = []
        sidebar.onOpenAgentSession = { opened.append($0) }
        let submenu = try #require(Self.sessionsItem(sidebar.contextMenu(forItemID: "refs/heads/feature"))?.submenu)
        let item = submenu.items[1]
        let action = try #require(item.action)
        let target = try #require(item.target as? NSObject)
        target.perform(action, with: item)
        #expect(opened == ["session-1"])
    }
}
