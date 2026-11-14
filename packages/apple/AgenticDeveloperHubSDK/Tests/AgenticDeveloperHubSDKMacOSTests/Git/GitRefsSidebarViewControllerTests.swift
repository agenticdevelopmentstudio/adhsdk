import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A refs data source whose lists a test sets directly.
@MainActor
private final class FakeRefsSource: GitRefsDataSource {
    var root = URL(fileURLWithPath: "/repo", isDirectory: true)
    var refs: [GitRef] = []
    var stashes: [GitStash] = []
    var submodules: [GitSubmodule] = []
    var worktrees: [GitWorktree] = []
}

/// Records every delegate call in order.
@MainActor
private final class RecordingDelegate: GitRefsSidebarDelegate {
    enum Event: Equatable {
        case ref(String)
        case workingCopy
        case stash(String)
        case directory(URL)
    }

    private(set) var events: [Event] = []

    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelect ref: GitRef) { events.append(.ref(ref.fullName)) }
    func sidebarDidSelectWorkingCopy(_ sidebar: GitRefsSidebarViewController) { events.append(.workingCopy) }
    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelectStash stash: GitStash) {
        events.append(.stash(stash.id))
    }
    func sidebar(_ sidebar: GitRefsSidebarViewController, open directory: URL) { events.append(.directory(directory)) }
}

@Suite("GitRefsSidebarViewController")
@MainActor
struct GitRefsSidebarViewControllerTests {

    private static func branch(_ name: String, ahead: Int = 0, behind: Int = 0, head: Bool = false) -> GitRef {
        GitRef(kind: .localBranch, fullName: "refs/heads/\(name)", name: name, target: "a\(name)",
               upstream: nil, ahead: ahead, behind: behind, isHead: head)
    }

    private static func remote(_ name: String) -> GitRef {
        GitRef(kind: .remoteBranch, fullName: "refs/remotes/\(name)", name: name, target: "r\(name)",
               upstream: nil, ahead: 0, behind: 0, isHead: false)
    }

    private static func tag(_ name: String) -> GitRef {
        GitRef(kind: .tag, fullName: "refs/tags/\(name)", name: name, target: "t\(name)",
               upstream: nil, ahead: 0, behind: 0, isHead: false)
    }

    private static func worktree(_ path: String, main: Bool = false, bare: Bool = false) -> GitWorktree {
        GitWorktree(directory: URL(fileURLWithPath: path, isDirectory: true), head: nil, branch: nil,
                    isMain: main, isBare: bare, isDetached: false)
    }

    private static func fullSource() -> FakeRefsSource {
        let source = FakeRefsSource()
        source.refs = [
            branch("main", ahead: 2, behind: 1, head: true), branch("dev"),
            remote("origin/main"), remote("upstream/main"), remote("origin/dev"),
            tag("v1")
        ]
        source.stashes = [
            GitStash(index: 0, id: "s0", message: "WIP on main", date: Date(timeIntervalSince1970: 0)),
            GitStash(index: 1, id: "s1", message: "", date: Date(timeIntervalSince1970: 0))
        ]
        source.submodules = [GitSubmodule(path: "lib/sub dir", id: "abc", state: .current)]
        source.worktrees = [worktree("/repo", main: true), worktree("/bare", bare: true), worktree("/w/feature")]
        return source
    }

    private func titles(_ sidebar: GitRefsSidebarViewController) -> [String?] {
        sidebar.sections.map(\.title)
    }

    private func rows(_ sidebar: GitRefsSidebarViewController) -> [[String]] {
        sidebar.sections.map { $0.items.map(\.title) }
    }

    private func item(_ sidebar: GitRefsSidebarViewController, section: Int, row: Int) -> any TopicListItemProtocol {
        sidebar.sections[section].items[row]
    }

    @Test("sections come in order with their rows, remotes grouped by remote name, bare worktrees left out")
    func sectionsAndOrder() {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())

        #expect(titles(sidebar) == [
            "Workspace", "Branches", "Remotes · origin", "Remotes · upstream", "Tags", "Stashes", "Submodules",
            "Worktrees"
        ])
        #expect(rows(sidebar) == [
            ["Working Copy"], ["main", "dev"], ["main", "dev"], ["main"], ["v1"], ["WIP on main", "stash@{1}"],
            ["lib/sub dir"], ["repo", "feature"]
        ])
    }

    @Test("ahead/behind badge shows each non-zero half")
    func badgeText() {
        #expect(GitRefsSidebarViewController.aheadBehindBadge(ahead: 2, behind: 1) == "↑2 ↓1")
        #expect(GitRefsSidebarViewController.aheadBehindBadge(ahead: 2, behind: 0) == "↑2")
        #expect(GitRefsSidebarViewController.aheadBehindBadge(ahead: 0, behind: 3) == "↓3")
        #expect(GitRefsSidebarViewController.aheadBehindBadge(ahead: 0, behind: 0) == nil)

        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        #expect(item(sidebar, section: 1, row: 0).badge == "↑2 ↓1")
        #expect(item(sidebar, section: 1, row: 1).badge == nil)
        #expect(item(sidebar, section: 2, row: 0).badge == nil)
        #expect(item(sidebar, section: 0, row: 0).badge == nil)
    }

    @Test("only the checked-out branch is emphasized")
    func headBold() {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        #expect(item(sidebar, section: 1, row: 0).isEmphasized)
        #expect(!item(sidebar, section: 1, row: 1).isEmphasized)
        #expect(sidebar.sections.flatMap(\.items).filter(\.isEmphasized).count == 1)
    }

    @Test("empty sections are omitted")
    func emptySectionsOmitted() {
        let source = FakeRefsSource()
        source.refs = [Self.branch("main", head: true)]
        let sidebar = GitRefsSidebarViewController(source: source)
        #expect(titles(sidebar) == ["Workspace", "Branches"])

        let unborn = GitRefsSidebarViewController(source: FakeRefsSource())
        #expect(titles(unborn) == ["Workspace"])
        #expect(rows(unborn) == [["Working Copy"]])
    }

    @Test("selecting each row kind calls the delegate once with what it names")
    func selectionCallsDelegate() {
        let source = Self.fullSource()
        let sidebar = GitRefsSidebarViewController(source: source)
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate

        let picks = [(0, 0), (1, 0), (2, 0), (4, 0), (5, 1), (6, 0), (7, 1)]
        for (section, row) in picks {
            sidebar.list.onSelect?(item(sidebar, section: section, row: row))
        }
        sidebar.list.onSelect?(nil)

        #expect(delegate.events == [
            .workingCopy,
            .ref("refs/heads/main"),
            .ref("refs/remotes/origin/main"),
            .ref("refs/tags/v1"),
            .stash("s1"),
            .directory(URL(fileURLWithPath: "/repo/lib/sub dir", isDirectory: true)),
            .directory(URL(fileURLWithPath: "/w/feature", isDirectory: true))
        ])
    }

    @Test("reload rebuilds from the source without calling the delegate")
    func reloadRebuilds() {
        let source = FakeRefsSource()
        source.refs = [Self.branch("main", head: true)]
        let sidebar = GitRefsSidebarViewController(source: source)
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        _ = sidebar.view

        source.refs.append(Self.branch("x"))
        sidebar.reload()

        #expect(rows(sidebar) == [["Working Copy"], ["main", "x"]])
        #expect(delegate.events.isEmpty)
    }

    /// Selects the row with `id` the way a click does: in the list, then reported.
    private func click(_ sidebar: GitRefsSidebarViewController, _ id: String) {
        sidebar.list.selectItem(withId: id)
        let item = sidebar.sections.flatMap(\.items).first { $0.id == id }
        sidebar.list.onSelect?(item)
    }

    @Test("reload keeps a selected row that survives, without calling the delegate")
    func reloadKeepsSurvivingSelection() {
        let source = FakeRefsSource()
        source.refs = [Self.branch("main", head: true), Self.branch("dev")]
        let sidebar = GitRefsSidebarViewController(source: source)
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        _ = sidebar.view
        click(sidebar, "refs/heads/dev")

        source.refs.insert(Self.branch("aaa"), at: 0)
        source.refs[2] = Self.branch("dev", ahead: 3)
        sidebar.reload()

        #expect(delegate.events == [.ref("refs/heads/dev")])
        #expect(sidebar.list.selectedItem?.id == "refs/heads/dev")
    }

    @Test("reload that drops the selected ref or stash falls back to the working copy and says so")
    func reloadDropsRemovedSelection() {
        let source = Self.fullSource()
        let sidebar = GitRefsSidebarViewController(source: source)
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        _ = sidebar.view

        click(sidebar, "stash:s0")
        source.stashes.removeFirst()
        sidebar.reload()
        #expect(delegate.events == [.stash("s0"), .workingCopy])
        #expect(sidebar.list.selectedItem?.id == "workspace.working-copy")

        click(sidebar, "refs/heads/dev")
        source.refs.removeAll { $0.fullName == "refs/heads/dev" }
        sidebar.reload()
        #expect(delegate.events == [.stash("s0"), .workingCopy, .ref("refs/heads/dev"), .workingCopy])
        #expect(sidebar.list.selectedItem?.id == "workspace.working-copy")

        // Nothing selected stays a no-op on reload.
        sidebar.reload()
        #expect(delegate.events.count == 4)
    }

    @Test("opening a submodule or worktree restores the previous selection")
    func directoryRowIsAnAction() {
        let source = Self.fullSource()
        let sidebar = GitRefsSidebarViewController(source: source)
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        _ = sidebar.view

        click(sidebar, "refs/tags/v1")
        click(sidebar, "worktree:/w/feature")
        #expect(sidebar.list.selectedItem?.id == "refs/tags/v1")

        // A reload after the action does not treat the directory as the selection.
        sidebar.reload()
        #expect(delegate.events == [
            .ref("refs/tags/v1"), .directory(URL(fileURLWithPath: "/w/feature", isDirectory: true))
        ])
    }

    @Test("a remote ref with nothing after its remote keeps its whole name")
    func remoteTitleFallback() {
        let source = FakeRefsSource()
        source.refs = [Self.remote("origin/main"), Self.remote("odd")]
        let sidebar = GitRefsSidebarViewController(source: source)
        #expect(titles(sidebar) == ["Workspace", "Remotes · origin", "Remotes · odd"])
        #expect(Array(rows(sidebar).dropFirst()) == [["main"], ["odd"]])
    }

    @Test("an unborn repository with a worktree lists Workspace and Worktrees")
    func unbornWithWorktree() {
        let source = FakeRefsSource()
        source.worktrees = [Self.worktree("/repo", main: true)]
        let sidebar = GitRefsSidebarViewController(source: source)
        #expect(titles(sidebar) == ["Workspace", "Worktrees"])
        #expect(rows(sidebar) == [["Working Copy"], ["repo"]])
    }

    @Test("the root view carries git.sidebar and hosts the topic list")
    func identifier() {
        let sidebar = GitRefsSidebarViewController(source: FakeRefsSource())
        #expect(sidebar.view.accessibilityIdentifier() == "git.sidebar")
        #expect(sidebar.list.parent === sidebar)
        #expect(sidebar.list.view.superview === sidebar.view)
    }
}
