import AppKit
import AgenticDeveloperHubSDKCore

/// What the refs sidebar tells its owner the user chose.
@MainActor public protocol GitRefsSidebarDelegate: AnyObject {
    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelect ref: GitRef)
    func sidebarDidSelectWorkingCopy(_ sidebar: GitRefsSidebarViewController)
    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelectStash stash: GitStash)
    /// A submodule or a worktree: a repository of its own, opened in its own window.
    func sidebar(_ sidebar: GitRefsSidebarViewController, open directory: URL)
}

/// A git window's sidebar: the working copy, branches with ahead/behind badges,
/// remote branches by remote, tags, stashes, submodules and worktrees, on a
/// `TopicListViewController` it hosts as a child.
///
/// It reads a `GitRefsDataSource` and reports selections to its delegate; its
/// owner calls `reload()` when the refs change.
@MainActor
public final class GitRefsSidebarViewController: NSViewController {

    public weak var delegate: GitRefsSidebarDelegate?

    /// The sections last built from the data source, as handed to the list.
    public private(set) var sections: [TopicListSection] = []

    let list = TopicListViewController()

    private let source: GitRefsDataSource

    /// What each row id names, rebuilt with the sections.
    private var targets: [String: Target] = [:]

    /// The id of the row last reported to the delegate as selected. A
    /// submodule or worktree row is an action, not a place, so it never
    /// becomes the selection.
    private var selectedID: String?

    private enum Target {
        case workingCopy
        case ref(GitRef)
        case stash(GitStash)
        case directory(URL)
    }

    private static let workingCopyID = "workspace.working-copy"

    public init(source: GitRefsDataSource) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
        list.onSelect = { [weak self] item in
            guard let self, let item else { return }
            self.select(itemID: item.id)
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
        var targets: [String: Target] = [Self.workingCopyID: .workingCopy]
        var sections = [TopicListSection(title: "Workspace", items: [
            TopicListItem(id: Self.workingCopyID, title: "Working Copy", icon: Self.symbol("square.and.pencil"))
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
        for remote in remotes {
            add("Remotes · \(remote)", remoteBranches.filter { $0.remote == remote }.map { ref in
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
             .directory(root.appendingPathComponent(submodule.path, isDirectory: true)))
        })

        add("Worktrees", source.worktrees.filter { !$0.isBare }.map { worktree in
            (TopicListItem(
                id: "worktree:\(worktree.directory.path)", title: worktree.directory.lastPathComponent,
                icon: Self.symbol("folder")
            ), .directory(worktree.directory))
        })

        self.targets = targets
        self.sections = sections
        list.setSections(sections)

        if let selectedID, targets[selectedID] == nil {
            self.selectedID = Self.workingCopyID
            list.selectItem(withId: Self.workingCopyID)
            delegate?.sidebarDidSelectWorkingCopy(self)
        }
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
        if case .directory = target {
            // An action: the previous selection comes back, so clicking the
            // same row again opens the window again.
            if let selectedID { list.selectItem(withId: selectedID) }
        } else {
            selectedID = itemID
        }
        guard let delegate else { return }
        switch target {
        case .workingCopy: delegate.sidebarDidSelectWorkingCopy(self)
        case .ref(let ref): delegate.sidebar(self, didSelect: ref)
        case .stash(let stash): delegate.sidebar(self, didSelectStash: stash)
        case .directory(let url): delegate.sidebar(self, open: url)
        }
    }

    private static func symbol(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }
}
