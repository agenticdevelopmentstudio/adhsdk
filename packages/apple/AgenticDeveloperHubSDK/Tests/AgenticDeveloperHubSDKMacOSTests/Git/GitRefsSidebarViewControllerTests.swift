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
    var operationState: GitOperationState = .none
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

    private(set) var intents: [GitRefIntent] = []
    func sidebar(_ sidebar: GitRefsSidebarViewController, didRequest intent: GitRefIntent) { intents.append(intent) }
}

/// A delegate that counts Reflog row selections and ignores every other call.
@MainActor
private final class ReflogRecordingDelegate: GitRefsSidebarDelegate {
    private(set) var reflogSelections = 0
    func sidebarDidSelectReflog(_ sidebar: GitRefsSidebarViewController) { reflogSelections += 1 }
    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelect ref: GitRef) {}
    func sidebarDidSelectWorkingCopy(_ sidebar: GitRefsSidebarViewController) {}
    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelectStash stash: GitStash) {}
    func sidebar(_ sidebar: GitRefsSidebarViewController, open directory: URL) {}
    func sidebar(_ sidebar: GitRefsSidebarViewController, didRequest intent: GitRefIntent) {}
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

    private static func worktree(_ path: String, main: Bool = false, bare: Bool = false,
                                 branch: String? = nil) -> GitWorktree {
        GitWorktree(directory: URL(fileURLWithPath: path, isDirectory: true), head: nil, branch: branch,
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
            ["Working Copy", "Reflog"], ["main", "dev"], ["main", "dev"], ["main"], ["v1"],
            ["WIP on main", "stash@{1}"],
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
        #expect(rows(unborn) == [["Working Copy", "Reflog"]])
    }

    @Test("the Workspace section's Reflog row reports itself, has no menu and survives a reload")
    func reflogRow() {
        let source = FakeRefsSource()
        let sidebar = GitRefsSidebarViewController(source: source)
        let delegate = ReflogRecordingDelegate()
        sidebar.delegate = delegate
        _ = sidebar.view
        let reflog = item(sidebar, section: 0, row: 1)
        #expect(reflog.id == "git.sidebar.reflog")
        #expect(reflog.title == "Reflog")
        click(sidebar, "git.sidebar.reflog")
        #expect(delegate.reflogSelections == 1)
        #expect(sidebar.contextMenu(forItemID: "git.sidebar.reflog") == nil)
        sidebar.reload()
        #expect(sidebar.list.selectedItem?.id == "git.sidebar.reflog")
        #expect(delegate.reflogSelections == 1)
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

        #expect(rows(sidebar) == [["Working Copy", "Reflog"], ["main", "x"]])
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
        #expect(rows(sidebar) == [["Working Copy", "Reflog"], ["repo"]])
    }

    @Test("the root view carries git.sidebar and hosts the topic list")
    func identifier() {
        let sidebar = GitRefsSidebarViewController(source: FakeRefsSource())
        #expect(sidebar.view.accessibilityIdentifier() == "git.sidebar")
        #expect(sidebar.list.parent === sidebar)
        #expect(sidebar.list.view.superview === sidebar.view)
    }

    // MARK: - Context menus and double-click

    /// The menu the list asks the sidebar for at `section`/`row`.
    private func rowMenu(_ sidebar: GitRefsSidebarViewController, section: Int, row: Int) -> NSMenu? {
        sidebar.list.itemMenuProvider?(item(sidebar, section: section, row: row))
    }

    private func menuTitles(_ menu: NSMenu?) -> [String] {
        (menu?.items ?? []).map { $0.isSeparatorItem ? "-" : $0.title }
    }

    private func menuIDs(_ menu: NSMenu?) -> [String] {
        (menu?.items ?? []).filter { !$0.isSeparatorItem }.compactMap { $0.accessibilityIdentifier() }
    }

    /// Fires every item of `menu` in order, the way AppKit does when the user chooses one.
    private func fireAll(_ menu: NSMenu?) throws {
        for item in try #require(menu).items where !item.isSeparatorItem {
            let action = try #require(item.action)
            let target = try #require(item.target as? NSObject)
            target.perform(action, with: item)
        }
    }

    @Test("a local branch's menu checks out, branches, renames, deletes and pushes it")
    func localBranchMenu() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        let menu = rowMenu(sidebar, section: 1, row: 1)
        #expect(menuTitles(menu) == [
            "Checkout", "Check Out in New Worktree…", "New Branch…", "Rename…", "Delete…", "-",
            "Merge into main", "Rebase main onto dev", "-", "Push"
        ])
        #expect(menuIDs(menu) == [
            "git.sidebar.menu.checkout", "git.sidebar.menu.newWorktree", "git.sidebar.menu.newBranch",
            "git.sidebar.menu.rename", "git.sidebar.menu.delete", "git.sidebar.menu.merge", "git.sidebar.menu.rebase",
            "git.sidebar.menu.push"
        ])
        try fireAll(menu)
        let dev = Self.branch("dev")
        #expect(delegate.intents == [
            .checkout(dev), .newWorktree(branch: dev), .createBranch(from: dev), .rename(dev), .delete(dev),
            .merge(dev), .rebaseOnto(dev), .push(dev)
        ])
        #expect(delegate.events.isEmpty)
    }

    @Test("the checked-out branch's menu has Pull and no Checkout or Delete")
    func headBranchMenu() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        let menu = rowMenu(sidebar, section: 1, row: 0)
        #expect(menuTitles(menu) == ["New Branch…", "Rename…", "-", "Push", "Pull"])
        #expect(menuIDs(menu).last == "git.sidebar.menu.pull")
        try fireAll(menu)
        let main = Self.branch("main", ahead: 2, behind: 1, head: true)
        #expect(delegate.intents == [.createBranch(from: main), .rename(main), .push(main), .pull])
    }

    @Test("a remote branch's menu checks out, branches, deletes it and fetches its remote")
    func remoteBranchMenu() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        let menu = rowMenu(sidebar, section: 2, row: 1)
        #expect(menuTitles(menu) == [
            "Checkout", "New Branch…", "Delete…", "-", "Merge into main", "Rebase main onto origin/dev", "-",
            "Fetch origin"
        ])
        #expect(menuIDs(menu) == [
            "git.sidebar.menu.checkout", "git.sidebar.menu.newBranch", "git.sidebar.menu.delete",
            "git.sidebar.menu.merge", "git.sidebar.menu.rebase", "git.sidebar.menu.fetch"
        ])
        try fireAll(menu)
        let dev = Self.remote("origin/dev")
        #expect(delegate.intents == [
            .checkout(dev), .createBranch(from: dev), .delete(dev), .merge(dev), .rebaseOnto(dev),
            .fetch(remote: "origin")
        ])
    }

    @Test("a remote's section header fetches that remote; other headers have no menu")
    func remoteHeaderMenu() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        let menu = sidebar.list.headerMenuProvider?("Remotes · upstream")
        #expect(menuTitles(menu) == ["Fetch"])
        #expect(menuIDs(menu) == ["git.sidebar.menu.fetch"])
        try fireAll(menu)
        #expect(delegate.intents == [.fetch(remote: "upstream")])
        for title in ["Workspace", "Branches", "Tags", "Stashes"] {
            #expect(sidebar.list.headerMenuProvider?(title) == nil)
        }
    }

    @Test("a tag's menu pushes and deletes it; a stash's applies, pops and drops it")
    func tagAndStashMenus() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        let tagMenu = rowMenu(sidebar, section: 4, row: 0)
        #expect(menuTitles(tagMenu) == ["Push", "Delete…", "-", "Merge into main", "Rebase main onto v1"])
        #expect(menuIDs(tagMenu) == [
            "git.sidebar.menu.tag.push", "git.sidebar.menu.tag.delete", "git.sidebar.menu.merge",
            "git.sidebar.menu.rebase"
        ])
        let stashMenu = rowMenu(sidebar, section: 5, row: 1)
        #expect(menuTitles(stashMenu) == ["Apply", "Pop", "Drop…"])
        #expect(menuIDs(stashMenu) == ["git.sidebar.menu.apply", "git.sidebar.menu.pop", "git.sidebar.menu.drop"])
        try fireAll(tagMenu)
        try fireAll(stashMenu)
        let tag = Self.tag("v1")
        let stash = Self.fullSource().stashes[1]
        #expect(delegate.intents == [
            .pushTag(tag), .deleteTag(tag), .merge(tag), .rebaseOnto(tag), .applyStash(stash), .popStash(stash),
            .dropStash(stash)
        ])
    }

    @Test("the working copy and the main worktree rows have no menu")
    func rowsWithoutMenus() {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        #expect(rowMenu(sidebar, section: 0, row: 0) == nil)
        #expect(rowMenu(sidebar, section: 7, row: 0) == nil)
    }

    // MARK: - Worktrees and submodules

    @Test("the Worktrees header asks for a new worktree; a linked worktree's row opens or removes it")
    func worktreeMenus() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        let header = sidebar.list.headerMenuProvider?("Worktrees")
        #expect(menuTitles(header) == ["New Worktree…"])
        #expect(menuIDs(header) == ["git.sidebar.menu.newWorktree"])
        let row = rowMenu(sidebar, section: 7, row: 1)
        #expect(menuTitles(row) == ["Open", "Remove…"])
        #expect(menuIDs(row) == ["git.sidebar.menu.open", "git.sidebar.menu.removeWorktree"])
        try fireAll(header)
        try fireAll(row)
        let feature = Self.worktree("/w/feature")
        #expect(delegate.intents == [.newWorktree(branch: nil), .openDirectory(feature.directory),
                                     .removeWorktree(feature)])
        #expect(delegate.events.isEmpty)
    }

    @Test("the window's own worktree can be opened from its row but not removed")
    func ownWorktreeNotRemovable() {
        let source = Self.fullSource()
        source.root = URL(fileURLWithPath: "/w/feature", isDirectory: true)
        let sidebar = GitRefsSidebarViewController(source: source)
        #expect(menuTitles(rowMenu(sidebar, section: 7, row: 1)) == ["Open"])
    }

    @Test("Check Out in New Worktree… only on a branch checked out nowhere")
    func newWorktreeOnlyForFreeBranches() {
        let source = Self.fullSource()
        source.worktrees = [Self.worktree("/repo", main: true, branch: "main"),
                            Self.worktree("/w/feature", branch: "dev")]
        let sidebar = GitRefsSidebarViewController(source: source)
        #expect(!menuIDs(rowMenu(sidebar, section: 1, row: 1)).contains("git.sidebar.menu.newWorktree"))
        #expect(!menuIDs(rowMenu(sidebar, section: 1, row: 0)).contains("git.sidebar.menu.newWorktree"))
    }

    @Test("the Submodules header updates them all; a submodule's row opens or updates it")
    func submoduleMenus() throws {
        let source = Self.fullSource()
        let submodule = GitSubmodule(path: "lib/sub dir", id: "abc", state: .uninitialized)
        source.submodules = [submodule]
        let sidebar = GitRefsSidebarViewController(source: source)
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        let header = sidebar.list.headerMenuProvider?("Submodules")
        #expect(menuTitles(header) == ["Update All"])
        #expect(menuIDs(header) == ["git.sidebar.menu.updateAllSubmodules"])
        let row = rowMenu(sidebar, section: 6, row: 0)
        #expect(menuTitles(row) == ["Open", "Update"])
        #expect(menuIDs(row) == ["git.sidebar.menu.open", "git.sidebar.menu.updateSubmodule"])
        try fireAll(header)
        try fireAll(row)
        #expect(delegate.intents == [
            .updateAllSubmodules, .openDirectory(URL(fileURLWithPath: "/repo/lib/sub dir", isDirectory: true)),
            .updateSubmodule(submodule)
        ])
        #expect(delegate.events.isEmpty)
    }

    @Test("double-clicking a local or remote branch checks it out; other rows ask for nothing")
    func doubleClickChecksOut() {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        let doubleClick = sidebar.list.onDoubleClick
        doubleClick?(item(sidebar, section: 1, row: 1))
        doubleClick?(item(sidebar, section: 2, row: 0))
        for (section, row) in [(0, 0), (1, 0), (4, 0), (5, 0), (6, 0), (7, 1)] {
            doubleClick?(item(sidebar, section: section, row: row))
        }
        #expect(delegate.intents == [.checkout(Self.branch("dev")), .checkout(Self.remote("origin/main"))])
        #expect(delegate.events.isEmpty)
    }

    // MARK: - Merge, rebase and drops

    @Test("no merge or rebase items on a detached HEAD or while an operation is in progress")
    func mergeItemsAbsent() {
        let detached = Self.fullSource()
        detached.refs = detached.refs.map { ref in
            ref.kind == .localBranch && ref.isHead ? Self.branch(ref.name) : ref
        }
        let busy = Self.fullSource()
        busy.operationState = .merging(head: "abc")
        for source in [detached, busy] {
            let sidebar = GitRefsSidebarViewController(source: source)
            for (section, row) in [(1, 1), (2, 1), (4, 0)] {
                let ids = menuIDs(rowMenu(sidebar, section: section, row: row))
                #expect(!ids.contains("git.sidebar.menu.merge"))
                #expect(!ids.contains("git.sidebar.menu.rebase"))
            }
            #expect(sidebar.dropMenu(forRefNamed: "refs/heads/dev") == nil)
        }
        let plain = GitRefsSidebarViewController(source: detached)
        #expect(menuTitles(rowMenu(plain, section: 1, row: 1)).last == "Push", "no trailing separator either")
    }

    @Test("branch, remote branch and tag rows drag as their full name; other rows do not drag")
    func dragPayloads() {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        let provider = sidebar.list.dragPayloadProvider
        #expect(provider?(item(sidebar, section: 1, row: 1)) == "refs/heads/dev")
        #expect(provider?(item(sidebar, section: 1, row: 0)) == "refs/heads/main")
        #expect(provider?(item(sidebar, section: 2, row: 0)) == "refs/remotes/origin/main")
        #expect(provider?(item(sidebar, section: 4, row: 0)) == "refs/tags/v1")
        for (section, row) in [(0, 0), (5, 0), (6, 0), (7, 0)] {
            #expect(provider?(item(sidebar, section: section, row: row)) == nil)
        }
    }

    @Test("only the checked-out branch's row takes a drop, and only of another ref")
    func dropValidation() {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        let validator = sidebar.list.dropValidator
        let headRow = item(sidebar, section: 1, row: 0)
        #expect(validator?("refs/heads/dev", headRow) == true)
        #expect(validator?("refs/remotes/origin/dev", headRow) == true)
        #expect(validator?("refs/tags/v1", headRow) == true)
        #expect(validator?("refs/heads/main", headRow) == false, "HEAD onto itself")
        #expect(validator?("refs/heads/nope", headRow) == false, "not a ref the sidebar shows")
        #expect(validator?("refs/heads/dev", item(sidebar, section: 1, row: 1)) == false, "not HEAD's row")
        #expect(validator?("refs/heads/dev", item(sidebar, section: 4, row: 0)) == false)

        let busy = Self.fullSource()
        busy.operationState = .rebasing(branch: "main", onto: nil, step: 1, total: 2, interactive: false)
        let busySidebar = GitRefsSidebarViewController(source: busy)
        #expect(busySidebar.list.dropValidator?("refs/heads/dev", item(busySidebar, section: 1, row: 0)) == false)
    }

    @Test("a drop pops up merge, rebase and Cancel; choosing one sends its intent, the drop alone nothing")
    func dropMenu() throws {
        let sidebar = GitRefsSidebarViewController(source: Self.fullSource())
        let delegate = RecordingDelegate()
        sidebar.delegate = delegate
        var shown: [NSMenu] = []
        sidebar.menuPresenter = { menu, _ in shown.append(menu) }
        sidebar.list.onDrop?("refs/remotes/origin/dev", item(sidebar, section: 1, row: 0))
        #expect(delegate.intents.isEmpty, "the drop alone does nothing")
        let menu = try #require(shown.first)
        #expect(menuTitles(menu) == ["Merge into main", "Rebase main onto origin/dev", "-", "Cancel"])
        #expect(menuIDs(menu) == ["git.drop.menu.merge", "git.drop.menu.rebase", "git.drop.menu.cancel"])
        try fireAll(menu)
        let dev = Self.remote("origin/dev")
        #expect(delegate.intents == [.merge(dev), .rebaseOnto(dev)], "Cancel sends nothing")
    }
}
