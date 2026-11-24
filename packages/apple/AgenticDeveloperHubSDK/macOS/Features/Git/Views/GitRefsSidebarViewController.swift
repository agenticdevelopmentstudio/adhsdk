import AppKit
import AgenticDeveloperHubSDKCore

/// What the user asked the sidebar to do to a ref, a remote, a stash, a worktree or a
/// submodule. The view runs none of it; its delegate does.
public enum GitRefIntent: Equatable {
    /// A local branch, or a remote branch to check out as a local one that tracks it.
    case checkout(GitRef), createBranch(from: GitRef), rename(GitRef)
    /// A local or a remote branch; the ref's kind decides which git verb runs.
    case delete(GitRef)
    case push(GitRef), pull, fetch(remote: String)
    case deleteTag(GitRef), pushTag(GitRef)
    case applyStash(GitStash), popStash(GitStash), dropStash(GitStash)
    /// Merge the ref into the checked-out branch; rebase the checked-out branch onto the ref.
    case merge(GitRef), rebaseOnto(GitRef)
    /// A new worktree, on `branch` when it is a local branch, otherwise on a new branch the
    /// user names (nil: from the `Worktrees` header).
    case newWorktree(branch: GitRef?)
    case removeWorktree(GitWorktree)
    /// One submodule, or every submodule, initialising those not yet checked out.
    case updateSubmodule(GitSubmodule), updateAllSubmodules
    /// A worktree's or a submodule's directory, opened in its own window; runs no git.
    case openDirectory(URL)
}

/// What the refs sidebar tells its owner the user chose.
@MainActor public protocol GitRefsSidebarDelegate: AnyObject {
    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelect ref: GitRef)
    func sidebarDidSelectWorkingCopy(_ sidebar: GitRefsSidebarViewController)
    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelectStash stash: GitStash)
    /// A submodule or a worktree: a repository of its own, opened in its own window.
    func sidebar(_ sidebar: GitRefsSidebarViewController, open directory: URL)
    /// An action chosen from a row's context menu, or a branch double-clicked.
    func sidebar(_ sidebar: GitRefsSidebarViewController, didRequest intent: GitRefIntent)
    /// The Workspace section's Reflog row.
    func sidebarDidSelectReflog(_ sidebar: GitRefsSidebarViewController)
    /// A Pull Requests row selected (`.show`), or a pull request menu's item chosen.
    func sidebar(_ sidebar: GitRefsSidebarViewController, didRequestPullRequest intent: GitPullRequestIntent)
}

public extension GitRefsSidebarDelegate {
    /// A delegate with no reflog browser ignores the Reflog row.
    func sidebarDidSelectReflog(_ sidebar: GitRefsSidebarViewController) {}
    /// A delegate with no pull requests ignores their rows and menus.
    func sidebar(_ sidebar: GitRefsSidebarViewController, didRequestPullRequest intent: GitPullRequestIntent) {}
}

/// A git window's sidebar: the working copy, branches with ahead/behind badges,
/// remote branches by remote, tags, stashes, submodules and worktrees, on a
/// `TopicListViewController` it hosts as a child.
///
/// It reads a `GitRefsDataSource` and reports selections to its delegate; its
/// owner calls `reload()` when the refs change. A branch, tag, stash, submodule or
/// linked worktree row, a remote's section header and the `Worktrees` and `Submodules`
/// headers have context menus whose items, like a double-clicked branch, reach the
/// delegate as `GitRefIntent`s; the sidebar runs no git.
///
/// Branch, remote branch and tag rows drag as their ref's full name; dropping one on
/// the checked-out branch's row pops up a menu to merge it in or rebase onto it.
@MainActor
public final class GitRefsSidebarViewController: NSViewController {

    public weak var delegate: GitRefsSidebarDelegate?

    /// The sections last built from the data source, as handed to the list.
    public private(set) var sections: [TopicListSection] = []

    let list = TopicListViewController()

    private let source: GitRefsDataSource

    /// What each row id names, rebuilt with the sections.
    private var targets: [String: Target] = [:]

    /// The remote each `Remotes · <remote>` section header names, by its title.
    private var remotesBySectionTitle: [String: String] = [:]

    /// The id of the row last reported to the delegate as selected. A
    /// submodule or worktree row is an action, not a place, so it never
    /// becomes the selection.
    private(set) var selectedID: String?

    private enum Target {
        case workingCopy
        case reflog
        case ref(GitRef)
        case stash(GitStash)
        case submodule(GitSubmodule, URL)
        case worktree(GitWorktree)
        case pullRequest(GitPullRequest)

        /// The directory a submodule or worktree row opens; nil for every other row.
        var directory: URL? {
            switch self {
            case .submodule(_, let url): url
            case .worktree(let worktree): worktree.directory
            case .workingCopy, .reflog, .ref, .stash, .pullRequest: nil
            }
        }
    }

    private static let workingCopyID = "workspace.working-copy"
    static let reflogID = "git.sidebar.reflog"

    /// The agent sessions that ran on a local branch; nil (no provider) leaves the branch
    /// menu without its Agent Sessions submenu.
    public var agentSessionsOnBranch: ((GitRef) -> [GitAgentSession])?
    /// Opens an agent session by id; nil leaves the submenu's items disabled.
    public var onOpenAgentSession: ((String) -> Void)?

    /// Shows a drop menu at the pointer in `view`. Tests replace it to capture the menu.
    var menuPresenter: @MainActor (NSMenu, NSView) -> Void = { menu, view in
        // After the drop returns: a menu tracked inside the drag session's callback
        // would block it.
        Task { @MainActor in
            let point = view.window.map { view.convert($0.mouseLocationOutsideOfEventStream, from: nil) } ?? .zero
            menu.popUp(positioning: nil, at: point, in: view)
        }
    }

    public init(source: GitRefsDataSource) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
        list.onSelect = { [weak self] item in
            guard let self, let item else { return }
            self.select(itemID: item.id)
        }
        list.itemMenuProvider = { [weak self] item in self?.contextMenu(forItemID: item.id) }
        list.headerMenuProvider = { [weak self] title in self?.contextMenu(forSectionTitle: title) }
        list.onDoubleClick = { [weak self] item in self?.doubleClick(itemID: item.id) }
        list.dragPayloadProvider = { [weak self] item in self?.dragPayload(forItemID: item.id) }
        list.dropValidator = { [weak self] payload, target in
            self?.canDrop(refNamed: payload, onItemID: target.id) ?? false
        }
        list.onDrop = { [weak self] payload, _ in
            guard let self, let menu = self.dropMenu(forRefNamed: payload) else { return }
            self.menuPresenter(menu, self.list.view)
        }
        reload()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.sidebar")
        addChild(list)
        let listView = list.view
        listView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(listView)
        NSLayoutConstraint.activate([
            listView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            listView.topAnchor.constraint(equalTo: root.topAnchor),
            listView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        view = root
    }

    /// Rebuilds every section from the data source. The list keeps the selected
    /// row when its id survives, without reporting it again; when the selected
    /// ref or stash is gone, the selection falls back to the working copy and
    /// the delegate is told, so the owner never keeps showing what vanished.
    public func reload() {
        var targets: [String: Target] = [Self.workingCopyID: .workingCopy, Self.reflogID: .reflog]
        var sections = [TopicListSection(title: "Workspace", items: [
            TopicListItem(id: Self.workingCopyID, title: "Working Copy", icon: Self.symbol("square.and.pencil")),
            TopicListItem(id: Self.reflogID, title: "Reflog", icon: Self.symbol("clock.arrow.circlepath"))
        ])]

        func add(_ title: String, _ rows: [(item: TopicListItem, target: Target)]) {
            guard !rows.isEmpty else { return }
            sections.append(TopicListSection(title: title, items: rows.map(\.item)))
            for row in rows { targets[row.item.id] = row.target }
        }

        let refs = source.refs
        add("Branches", refs.filter { $0.kind == .localBranch }.map { ref in
            (TopicListItem(
                id: ref.fullName, title: ref.name, icon: Self.symbol("arrow.triangle.branch"),
                badge: Self.aheadBehindBadge(ahead: ref.ahead, behind: ref.behind), isEmphasized: ref.isHead
            ), .ref(ref))
        })

        let remoteBranches = refs.filter { $0.kind == .remoteBranch }
        var remotes: [String] = []
        for ref in remoteBranches {
            if let remote = ref.remote, !remotes.contains(remote) { remotes.append(remote) }
        }
        var remotesBySectionTitle: [String: String] = [:]
        for remote in remotes {
            remotesBySectionTitle[Self.remoteSectionTitle(remote)] = remote
            add(Self.remoteSectionTitle(remote), remoteBranches.filter { $0.remote == remote }.map { ref in
                (TopicListItem(id: ref.fullName, title: Self.remoteBranchTitle(ref, remote: remote),
                               icon: Self.symbol("network")), .ref(ref))
            })
        }

        add("Tags", refs.filter { $0.kind == .tag }.map { ref in
            (TopicListItem(id: ref.fullName, title: ref.name, icon: Self.symbol("tag")), .ref(ref))
        })

        add("Stashes", source.stashes.map { stash in
            (TopicListItem(
                id: "stash:\(stash.id)", title: stash.message.isEmpty ? "stash@{\(stash.index)}" : stash.message,
                icon: Self.symbol("tray")
            ), .stash(stash))
        })

        let root = source.root
        add("Submodules", source.submodules.map { submodule in
            (TopicListItem(id: "submodule:\(submodule.path)", title: submodule.path, icon: Self.symbol("shippingbox")),
             .submodule(submodule, root.appendingPathComponent(submodule.path, isDirectory: true)))
        })

        add("Worktrees", source.worktrees.filter { !$0.isBare }.map { worktree in
            (TopicListItem(
                id: "worktree:\(worktree.directory.path)", title: worktree.directory.lastPathComponent,
                icon: Self.symbol("folder")
            ), .worktree(worktree))
        })

        // Present while `gh` answers, even with no row: the header's menu creates one.
        if let pullRequests = source.pullRequests {
            let rows = pullRequestRows(pullRequests, headPullRequest: source.headPullRequest)
            sections.append(TopicListSection(title: Self.pullRequestsTitle, items: rows.map(\.item),
                                             accessibilityIdentifier: Self.pullRequestsID))
            for row in rows { targets[row.item.id] = .pullRequest(row.pullRequest) }
        }

        self.targets = targets
        self.remotesBySectionTitle = remotesBySectionTitle
        self.sections = sections
        list.setSections(sections)

        if let selectedID, targets[selectedID] == nil {
            self.selectedID = Self.workingCopyID
            list.selectItem(withId: Self.workingCopyID)
            delegate?.sidebarDidSelectWorkingCopy(self)
        }
    }

    /// Selects the working copy row without telling the delegate: the owner's
    /// starting selection, so the sidebar shows what the window shows.
    func selectWorkingCopy() {
        selectedID = Self.workingCopyID
        list.selectItem(withId: Self.workingCopyID)
    }

    /// Leaves no row selected, without telling the delegate: the owner shows
    /// something no row stands for (a detached HEAD's history).
    func clearSelection() {
        selectedID = nil
        list.deselectAll()
    }

    /// Selects the row of the ref named `fullName` and tells the delegate, as a
    /// click does; false when no row shows that ref.
    @discardableResult
    func select(refNamed fullName: String) -> Bool {
        guard case .ref = targets[fullName] else { return false }
        list.selectItem(withId: fullName)
        select(itemID: fullName)
        return true
    }

    /// Selects the row of pull request `number` and tells the delegate, as a click
    /// does; false when no row shows it.
    @discardableResult
    func select(pullRequestNumber number: Int) -> Bool {
        let id = Self.pullRequestRowID(number)
        guard case .pullRequest = targets[id] else { return false }
        list.selectItem(withId: id)
        select(itemID: id)
        return true
    }

    /// A remote branch's name less its `<remote>/` prefix, or the whole name
    /// when that would leave nothing (a ref directly under `refs/remotes/<x>`).
    private static func remoteBranchTitle(_ ref: GitRef, remote: String) -> String {
        let prefix = remote + "/"
        guard ref.name.hasPrefix(prefix), ref.name.count > prefix.count else { return ref.name }
        return String(ref.name.dropFirst(prefix.count))
    }

    /// `↑n ↓m`, each half only when its count is non-zero; nil when both are zero.
    public static func aheadBehindBadge(ahead: Int, behind: Int) -> String? {
        var parts: [String] = []
        if ahead != 0 { parts.append("↑\(ahead)") }
        if behind != 0 { parts.append("↓\(behind)") }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    private func select(itemID: String) {
        guard let target = targets[itemID] else { return }
        if let directory = target.directory {
            // An action: the previous selection comes back, so clicking the
            // same row again opens the window again.
            if let selectedID { list.selectItem(withId: selectedID) }
            delegate?.sidebar(self, open: directory)
            return
        }
        selectedID = itemID
        guard let delegate else { return }
        switch target {
        case .workingCopy: delegate.sidebarDidSelectWorkingCopy(self)
        case .reflog: delegate.sidebarDidSelectReflog(self)
        case .ref(let ref): delegate.sidebar(self, didSelect: ref)
        case .stash(let stash): delegate.sidebar(self, didSelectStash: stash)
        case .pullRequest(let pullRequest): delegate.sidebar(self, didRequestPullRequest: .show(pullRequest))
        case .submodule, .worktree: break
        }
    }

    private static func remoteSectionTitle(_ remote: String) -> String { "Remotes · \(remote)" }

    // MARK: - Context menus and double-click

    /// The context menu for the row `id` names: a branch, remote branch, tag, stash,
    /// submodule or linked worktree row's actions; nil for the working copy, the main
    /// worktree or an unknown id.
    func contextMenu(forItemID id: String) -> NSMenu? {
        switch targets[id] {
        case .ref(let ref):
            switch ref.kind {
            case .localBranch: return localBranchMenu(ref)
            case .remoteBranch: return remoteBranchMenu(ref)
            case .tag:
                // A tag has no checkout group, so its merge group follows its own items.
                let entries: [MenuEntry?] = [
                    ("Push", "tag.push", .pushTag(ref)), ("Delete…", "tag.delete", .deleteTag(ref))
                ]
                return makeMenu(entries + mergeEntries(ref))
            }
        case .stash(let stash):
            return makeMenu([
                ("Apply", "apply", .applyStash(stash)), ("Pop", "pop", .popStash(stash)),
                ("Drop…", "drop", .dropStash(stash))
            ])
        case .submodule(let submodule, let url):
            return makeMenu([
                ("Open", "open", .openDirectory(url)), ("Update", "updateSubmodule", .updateSubmodule(submodule))
            ])
        case .worktree(let worktree):
            return worktreeMenu(worktree)
        case .pullRequest(let pullRequest):
            return pullRequestMenu(pullRequest)
        case .workingCopy, .reflog, nil:
            return nil
        }
    }

    /// `Fetch` for a remote's section header, `New Worktree…` for `Worktrees` and
    /// `Update All` for `Submodules`; nil for every other section.
    func contextMenu(forSectionTitle title: String) -> NSMenu? {
        switch title {
        case "Worktrees": return makeMenu([("New Worktree…", "newWorktree", .newWorktree(branch: nil))])
        case "Submodules": return makeMenu([("Update All", "updateAllSubmodules", .updateAllSubmodules)])
        case Self.pullRequestsTitle:
            let head = source.refs.first { $0.kind == .localBranch && $0.isHead }
            return pullRequestsHeaderMenu(head: head, headPullRequest: source.headPullRequest)
        default:
            guard let remote = remotesBySectionTitle[title] else { return nil }
            return makeMenu([("Fetch", "fetch", .fetch(remote: remote))])
        }
    }

    /// `Open` and `Remove…` for a linked worktree; only `Open` for the window's own one,
    /// which cannot remove the folder it is showing; nil for the main worktree.
    private func worktreeMenu(_ worktree: GitWorktree) -> NSMenu? {
        guard !worktree.isMain else { return nil }
        var entries: [MenuEntry?] = [("Open", "open", .openDirectory(worktree.directory))]
        if worktree.directory.standardizedFileURL.path != source.root.standardizedFileURL.path {
            entries.append(("Remove…", "removeWorktree", .removeWorktree(worktree)))
        }
        return makeMenu(entries)
    }

    /// Whether the local branch `ref` is checked out nowhere: not HEAD, and no worktree's
    /// branch names it.
    private func isCheckedOutNowhere(_ ref: GitRef) -> Bool {
        !ref.isHead && !source.worktrees.contains { $0.branch == ref.name }
    }

    /// A double-clicked local or remote branch is checked out; the checked-out branch,
    /// and every other row, asks for nothing.
    func doubleClick(itemID id: String) {
        guard case .ref(let ref) = targets[id], ref.kind != .tag, !ref.isHead else { return }
        request(.checkout(ref))
    }

    private typealias MenuEntry = (title: String, name: String, intent: GitRefIntent)

    private func localBranchMenu(_ ref: GitRef) -> NSMenu {
        var entries: [MenuEntry?] = []
        if !ref.isHead { entries.append(("Checkout", "checkout", .checkout(ref))) }
        if isCheckedOutNowhere(ref) {
            entries.append(("Check Out in New Worktree…", "newWorktree", .newWorktree(branch: ref)))
        }
        entries.append(("New Branch…", "newBranch", .createBranch(from: ref)))
        entries.append(("Rename…", "rename", .rename(ref)))
        if !ref.isHead { entries.append(("Delete…", "delete", .delete(ref))) }
        entries += mergeEntries(ref)
        entries.append(nil)
        entries.append(("Push", "push", .push(ref)))
        if ref.isHead { entries.append(("Pull", "pull", .pull)) }
        let menu = makeMenu(entries)
        addAgentSessionsSubmenu(to: menu, for: ref)
        return menu
    }

    private func remoteBranchMenu(_ ref: GitRef) -> NSMenu {
        var entries: [MenuEntry?] = [
            ("Checkout", "checkout", .checkout(ref)), ("New Branch…", "newBranch", .createBranch(from: ref)),
            ("Delete…", "delete", .delete(ref))
        ]
        entries += mergeEntries(ref)
        if let remote = ref.remote {
            entries.append(nil)
            entries.append(("Fetch \(remote)", "fetch", .fetch(remote: remote)))
        }
        return makeMenu(entries)
    }

    // MARK: - Merge and rebase

    /// The checked-out branch, when `ref` can be merged into it or it rebased onto `ref`:
    /// HEAD is on a branch, `ref` is not that branch, and no operation is in progress.
    private func mergeHead(for ref: GitRef) -> GitRef? {
        guard !ref.isHead, source.operationState == .none,
              let head = source.refs.first(where: { $0.kind == .localBranch && $0.isHead }),
              head.fullName != ref.fullName else { return nil }
        return head
    }

    /// A separator, `Merge into <head>` and `Rebase <head> onto <name>`, or nothing when
    /// `mergeHead(for:)` says neither applies.
    private func mergeEntries(_ ref: GitRef) -> [MenuEntry?] {
        guard let head = mergeHead(for: ref) else { return [] }
        return [
            nil,
            ("Merge into \(head.name)", "merge", .merge(ref)),
            ("Rebase \(head.name) onto \(ref.name)", "rebase", .rebaseOnto(ref))
        ]
    }

    /// The ref row `fullName` names, when it is a branch, remote branch or tag.
    private func ref(named fullName: String) -> GitRef? {
        guard case .ref(let ref) = targets[fullName] else { return nil }
        return ref
    }

    /// A branch, remote branch or tag row drags as its ref's full name; nothing else drags.
    func dragPayload(forItemID id: String) -> String? {
        ref(named: id)?.fullName
    }

    /// Whether `payload` may be dropped on the row `id`: the checked-out branch's row, and
    /// a ref the drop menu has items for.
    func canDrop(refNamed payload: String, onItemID id: String) -> Bool {
        guard let target = ref(named: id), target.kind == .localBranch, target.isHead else { return false }
        return dropMenu(forRefNamed: payload) != nil
    }

    /// The menu a drop of the ref `fullName` pops up: merge it, rebase onto it, or cancel;
    /// nil when the ref is unknown or HEAD, HEAD is detached, or an operation is in progress.
    public func dropMenu(forRefNamed fullName: String) -> NSMenu? {
        guard let ref = ref(named: fullName), let head = mergeHead(for: ref) else { return nil }
        let menu = NSMenu()
        for (title, name, intent) in [
            ("Merge into \(head.name)", "merge", GitRefIntent.merge(ref)),
            ("Rebase \(head.name) onto \(ref.name)", "rebase", GitRefIntent.rebaseOnto(ref))
        ] {
            let item = NSMenuItem(title: title, action: #selector(performMenuIntent(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = MenuPayload(intent)
            item.accessibilityID("git.drop.menu.\(name)")
            menu.addItem(item)
        }
        menu.addItem(.separator())
        // A no-op target and action keep it enabled; choosing it just closes the menu.
        let cancel = NSMenuItem(title: "Cancel", action: #selector(cancelDropMenu(_:)), keyEquivalent: "")
        cancel.target = self
        cancel.accessibilityID("git.drop.menu.cancel")
        menu.addItem(cancel)
        return menu
    }

    @objc private func cancelDropMenu(_ sender: NSMenuItem) {}

    /// A menu of `entries` in order, a nil entry being a separator.
    private func makeMenu(_ entries: [MenuEntry?]) -> NSMenu {
        let menu = NSMenu()
        for entry in entries {
            guard let entry else {
                menu.addItem(.separator())
                continue
            }
            let item = NSMenuItem(title: entry.title, action: #selector(performMenuIntent(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = MenuPayload(entry.intent)
            item.accessibilityID("git.sidebar.menu.\(entry.name)")
            menu.addItem(item)
        }
        return menu
    }

    @objc private func performMenuIntent(_ sender: NSMenuItem) {
        guard let intent = sender.payload(GitRefIntent.self) else { return }
        request(intent)
    }

    private func request(_ intent: GitRefIntent) {
        delegate?.sidebar(self, didRequest: intent)
    }

    private static func symbol(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }
}
