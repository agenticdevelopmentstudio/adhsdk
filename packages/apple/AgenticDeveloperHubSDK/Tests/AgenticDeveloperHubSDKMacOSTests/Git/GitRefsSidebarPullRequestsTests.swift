import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A refs data source with a pull request list a test sets directly.
@MainActor
private final class PullRequestRefsSource: GitRefsDataSource {
    var root = URL(fileURLWithPath: "/repo", isDirectory: true)
    var refs: [GitRef] = []
    var stashes: [GitStash] = []
    var submodules: [GitSubmodule] = []
    var worktrees: [GitWorktree] = []
    var operationState: GitOperationState = .none
    var pullRequests: [GitPullRequest]?
    var headPullRequest: GitPullRequest?
}

/// Records the pull request intents the sidebar sends and ignores every other call.
@MainActor
private final class PullRequestRecordingDelegate: GitRefsSidebarDelegate {
    private(set) var intents: [GitPullRequestIntent] = []
    func sidebar(_ sidebar: GitRefsSidebarViewController, didRequestPullRequest intent: GitPullRequestIntent) {
        intents.append(intent)
    }
    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelect ref: GitRef) {}
    func sidebarDidSelectWorkingCopy(_ sidebar: GitRefsSidebarViewController) {}
    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelectStash stash: GitStash) {}
    func sidebar(_ sidebar: GitRefsSidebarViewController, open directory: URL) {}
    func sidebar(_ sidebar: GitRefsSidebarViewController, didRequest intent: GitRefIntent) {}
}

@Suite("GitRefsSidebarViewController pull requests")
@MainActor
struct GitRefsSidebarPullRequestsTests {

    static func pullRequest(_ number: Int, title: String, head: String, draft: Bool = false,
                            checks: GitPullRequestChecks? = nil) -> GitPullRequest {
        GitPullRequest(
            number: number, title: title, state: "OPEN", isDraft: draft, author: "octocat",
            headRefName: head, baseRefName: "main",
            url: URL(string: "https://github.com/o/r/pull/\(number)")!,
            updatedAt: Date(timeIntervalSince1970: 1_767_268_800), checks: checks, reviewDecision: nil)
    }

    private static func branch(_ name: String, head: Bool = false) -> GitRef {
        GitRef(kind: .localBranch, fullName: "refs/heads/\(name)", name: name, target: "a\(name)",
               upstream: nil, ahead: 0, behind: 0, isHead: head)
    }

    private static func source(_ pullRequests: [GitPullRequest]?, headBranch: String? = "feature",
                               headPullRequest: GitPullRequest? = nil) -> PullRequestRefsSource {
        let source = PullRequestRefsSource()
        source.refs = [branch("main", head: headBranch == "main"), branch("feature", head: headBranch == "feature")]
        source.pullRequests = pullRequests
        source.headPullRequest = headPullRequest
        return source
    }

    private static let list = [
        pullRequest(7, title: "Add the parser", head: "feature",
                    checks: GitPullRequestChecks(passing: 2, failing: 0, pending: 0)),
        pullRequest(5, title: "Fix the docs", head: "docs", draft: true)
    ]

    private func section(_ sidebar: GitRefsSidebarViewController) -> TopicListSection? {
        sidebar.sections.first { $0.title == "Pull Requests" }
    }

    @Test("the section is absent while pull requests are nil")
    func absentWhenNil() {
        let sidebar = GitRefsSidebarViewController(source: Self.source(nil))
        #expect(section(sidebar) == nil)
    }

    @Test("the section is present with no rows when gh answers an empty list")
    func presentWhenEmpty() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.source([]))
        let section = try #require(section(sidebar))
        #expect(section.items.isEmpty)
    }

    @Test("the section's header carries git.sidebar.pullRequests")
    func headerIdentifier() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.source([]))
        let section = try #require(section(sidebar))
        #expect(section.accessibilityIdentifier == "git.sidebar.pullRequests")
    }

    @Test("rows read #n title, with the check symbol as the badge, the HEAD branch's own row bold")
    func rows() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.source(Self.list, headPullRequest: Self.list[0]))
        let section = try #require(section(sidebar))
        #expect(section.items.map(\.title) == ["#7 Add the parser", "#5 Fix the docs"])
        #expect(section.items.map(\.id) == ["git.sidebar.pullRequests.7", "git.sidebar.pullRequests.5"])
        #expect(section.items.map(\.isEmphasized) == [true, false])
        #expect(section.items.map(\.badge) == ["✓", nil])
        #expect(section.items.allSatisfy { $0.icon != nil })
    }

    @Test("a row's menu is Check Out, Open in Browser, Copy URL")
    func rowMenu() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.source(Self.list))
        let menu = try #require(sidebar.contextMenu(forItemID: "git.sidebar.pullRequests.7"))
        #expect(menu.items.map(\.title) == ["Check Out", "Open in Browser", "Copy URL"])
        #expect(menu.items.map { $0.accessibilityIdentifier() } == [
            "git.sidebar.pullRequests.menu.checkout", "git.sidebar.pullRequests.menu.open",
            "git.sidebar.pullRequests.menu.copyURL"
        ])
    }

    @Test("the row menu's items send checkout and open-in-browser intents")
    func rowMenuIntents() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.source(Self.list))
        let delegate = PullRequestRecordingDelegate()
        sidebar.delegate = delegate
        let menu = try #require(sidebar.contextMenu(forItemID: "git.sidebar.pullRequests.7"))
        for item in menu.items.prefix(2) {
            _ = item.target?.perform(item.action, with: item)
        }
        #expect(delegate.intents == [.checkout(Self.list[0]), .openInBrowser(Self.list[0])])
    }

    @Test("the header menu creates a pull request for a branch that has none")
    func headerMenu() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.source([], headBranch: "main"))
        let menu = try #require(sidebar.contextMenu(forSectionTitle: "Pull Requests"))
        #expect(menu.items.map(\.title) == ["Create Pull Request for main…"])
        #expect(menu.items.first?.accessibilityIdentifier() == "git.sidebar.pullRequests.menu.create")

        let delegate = PullRequestRecordingDelegate()
        sidebar.delegate = delegate
        let item = try #require(menu.items.first)
        _ = item.target?.perform(item.action, with: item)
        #expect(delegate.intents == [.create])
    }

    @Test("the header menu is absent when the HEAD branch has its own open pull request")
    func headerMenuAbsentWithExistingPullRequest() {
        let source = Self.source(Self.list, headBranch: "feature", headPullRequest: Self.list[0])
        let sidebar = GitRefsSidebarViewController(source: source)
        #expect(sidebar.contextMenu(forSectionTitle: "Pull Requests") == nil)
    }

    @Test("a fork's pull request named like the HEAD branch is not bold and leaves Create")
    func forkPullRequestWithTheHeadName() throws {
        // The list has #7 from `feature`, but gh's per-branch lookup found none of ours.
        let sidebar = GitRefsSidebarViewController(source: Self.source(Self.list, headBranch: "feature"))
        let section = try #require(section(sidebar))
        #expect(section.items.map(\.isEmphasized) == [false, false])
        let menu = try #require(sidebar.contextMenu(forSectionTitle: "Pull Requests"))
        #expect(menu.items.map(\.title) == ["Create Pull Request for feature…"])
    }

    @Test("the header menu is absent on a detached HEAD")
    func headerMenuAbsentWhenDetached() {
        let sidebar = GitRefsSidebarViewController(source: Self.source([], headBranch: nil))
        #expect(sidebar.contextMenu(forSectionTitle: "Pull Requests") == nil)
    }

    @Test("selecting a row asks to show that pull request")
    func selectionShows() {
        let sidebar = GitRefsSidebarViewController(source: Self.source(Self.list))
        let delegate = PullRequestRecordingDelegate()
        sidebar.delegate = delegate
        #expect(sidebar.select(pullRequestNumber: 5))
        #expect(delegate.intents == [.show(Self.list[1])])
        #expect(!sidebar.select(pullRequestNumber: 99))
    }
}
