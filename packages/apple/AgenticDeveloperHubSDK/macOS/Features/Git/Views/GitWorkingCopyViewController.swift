import AppKit
import AgenticDeveloperHubSDKCore

/// What the user asked the working copy to do. The view runs none of it; its delegate does.
public enum GitWorkingCopyIntent: Equatable {
    case stage([String]), unstage([String]), discard([String])
    case stageAll, unstageAll, discardAll
    /// Commit with `message` exactly as typed, amending the last commit when `amend`.
    case commit(message: String, amend: Bool)
    /// Amend was ticked (true) or unticked (false).
    case amendChanged(Bool)
    /// Take one side of each conflicted path whole (asks first), or mark them resolved as they stand.
    case resolve([String], GitConflictSide), markResolved([String])
    /// Open the conflicted path in the merge view.
    case openMerge(String)
}

/// Told the diff target of the working-copy file selected, or nil when nothing is, and
/// every intent the user expresses.
@MainActor public protocol GitWorkingCopyDelegate: AnyObject {
    func workingCopy(_ workingCopy: GitWorkingCopyViewController, didSelect target: GitDiffTarget?)
    func workingCopy(_ workingCopy: GitWorkingCopyViewController, didRequest intent: GitWorkingCopyIntent)
}

/// The git window's working copy (recipe `workspace/git/git-views`, "Working copy"): the
/// conflicted files (only while there are any) above the staged files above the unstaged
/// ones, each a changed-files list under a counted header, read from a
/// `GitWorkingCopyDataSource`, over the commit box.
///
/// The owner calls `reload()` when the model reports a status change. One file is
/// selected across the lists. Staging, unstaging, discarding and committing are
/// `GitWorkingCopyIntent`s sent to the delegate; the view never runs git. Used on the
/// main thread.
@MainActor
public final class GitWorkingCopyViewController: NSViewController {

    public weak var delegate: GitWorkingCopyDelegate?

    let stagedList = GitFileListViewController(identifier: "staged")
    let unstagedList = GitFileListViewController(identifier: "unstaged")
    let conflictsList = GitFileListViewController(identifier: "conflicts")
    let conflictsHeader = ThemedLabel(role: .secondaryText, textRole: .caption, weight: .semibold)
    let stagedHeader = ThemedLabel(role: .secondaryText, textRole: .caption, weight: .semibold)
    let unstagedHeader = ThemedLabel(role: .secondaryText, textRole: .caption, weight: .semibold)
    let stageAllButton = NSButton(title: "Stage All", target: nil, action: nil)
    let unstageAllButton = NSButton(title: "Unstage All", target: nil, action: nil)

    /// The message, Amend and Commit, in the pane under the lists.
    public let commitBox = GitCommitBoxViewController()

    /// Whether there is a commit to amend; set by the owner. False disables Amend.
    public var canAmend: Bool {
        get { commitBox.canAmend }
        set { commitBox.canAmend = newValue }
    }

    let splitView = ThemedSplitView()
    let source: GitWorkingCopyDataSource

    public init(source: GitWorkingCopyDataSource) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
        conflictsList.delegate = self
        stagedList.delegate = self
        unstagedList.delegate = self
        conflictsHeader.accessibilityID("git.workingCopy.conflictsHeader")
        stagedHeader.accessibilityID("git.workingCopy.stagedHeader")
        unstagedHeader.accessibilityID("git.workingCopy.unstagedHeader")
        configureActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.workingCopy")

        splitView.accessibilityID("git.workingCopy.split")
        splitView.isVertical = false
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false
        addChild(conflictsList)
        addChild(stagedList)
        addChild(unstagedList)
        addChild(commitBox)
        splitView.addArrangedSubview(pane("conflicts", header: conflictsHeader, button: nil, list: conflictsList))
        splitView.addArrangedSubview(pane("staged", header: stagedHeader, button: unstageAllButton, list: stagedList))
        splitView.addArrangedSubview(pane("unstaged", header: unstagedHeader, button: stageAllButton,
                                          list: unstagedList))
        splitView.addArrangedSubview(commitBox.view)
        // The lists take a window resize; the commit box keeps its height.
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(260), forSubviewAt: 3)
        root.addSubview(splitView)
        NSLayoutConstraint.activate([
            splitView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            splitView.topAnchor.constraint(equalTo: root.topAnchor),
            splitView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        view = root
        reload()
    }

    /// Re-reads the lists; the Conflicts pane is hidden while there are no conflicts, and a
    /// conflicted path is listed only there, not under Unstaged. A selected file still in
    /// its list stays selected, without a delegate call unless its status changed, when the
    /// delegate is told its new target; one that left its list is deselected and the
    /// delegate is told nil.
    public func reload() {
        let conflictKinds = source.conflicts
        let conflicts = conflictKinds.keys.sorted().map {
            GitFileListItem(path: $0, oldPath: nil, status: .conflicted)
        }
        let staged = source.staged.map(GitFileListItem.init(change:))
        let unstaged = source.unstaged.filter { conflictKinds[$0.path] == nil }.map(GitFileListItem.init(change:))
        reloadLFS()
        conflictsHeader.stringValue = "Conflicts (\(conflicts.count))"
        conflictsList.files = conflicts
        if splitView.arrangedSubviews.count > 3 {
            splitView.arrangedSubviews[0].isHidden = conflicts.isEmpty
        }
        stagedHeader.stringValue = "Staged (\(staged.count))"
        unstagedHeader.stringValue = "Unstaged (\(unstaged.count))"
        stagedList.files = staged
        unstagedList.files = unstaged
        unstageAllButton.isEnabled = !staged.isEmpty
        stageAllButton.isEnabled = !unstaged.isEmpty
        commitBox.hasStagedChanges = !staged.isEmpty
    }

    /// Empties the message, forgets its undo history and unticks Amend, after the
    /// owner's commit succeeded.
    public func commitDidSucceed() {
        commitBox.message = ""
        commitBox.clearUndoHistory()
        commitBox.isAmend = false
    }

    private func configureActions() {
        for (button, identifier) in [(stageAllButton, "stageAll"), (unstageAllButton, "unstageAll")] {
            button.accessibilityID("git.workingCopy.\(identifier)")
            button.isBordered = false
            button.controlSize = .small
            button.target = self
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.observeTheme { button, palette in
                button.font = palette.font(.caption)
                button.contentTintColor = palette.nsColor(.accent)
            }
        }
        stageAllButton.action = #selector(stageAll(_:))
        unstageAllButton.action = #selector(unstageAll(_:))

        stagedList.menuProvider = { [weak self] item in self?.stagedMenu(for: item) }
        unstagedList.menuProvider = { [weak self] item in self?.unstagedMenu(for: item) }
        stagedList.onDoubleClick = { [weak self] item in
            self?.request(.unstage(Self.stagedPaths(of: item)))
        }
        unstagedList.onDoubleClick = { [weak self] item in self?.request(.stage([item.path])) }
        conflictsList.menuProvider = { [weak self] item in self?.conflictMenu(for: item) }
        conflictsList.onDoubleClick = { [weak self] item in
            guard let self, self.source.conflicts[item.path]?.hasMarkers == true else { return }
            self.request(.openMerge(item.path))
        }

        commitBox.onCommit = { [weak self] message, amend in self?.request(.commit(message: message, amend: amend)) }
        commitBox.onAmendChanged = { [weak self] amend in self?.request(.amendChanged(amend)) }
    }

    /// A staged item's paths: its old path, for a rename or copy, then its path.
    private static func stagedPaths(of item: GitFileListItem) -> [String] {
        [item.oldPath, item.path].compactMap { $0 }
    }

    private func request(_ intent: GitWorkingCopyIntent) {
        delegate?.workingCopy(self, didRequest: intent)
    }

    @objc private func stageAll(_ sender: Any?) { request(.stageAll) }

    @objc private func unstageAll(_ sender: Any?) { request(.unstageAll) }

    @objc private func performMenuIntent(_ sender: NSMenuItem) {
        guard let intent = sender.payload(GitWorkingCopyIntent.self) else { return }
        request(intent)
    }

    private func stagedMenu(for item: GitFileListItem) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(menuItem("Unstage", "unstage", .unstage(Self.stagedPaths(of: item))))
        return menu
    }

    private func unstagedMenu(for item: GitFileListItem) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(menuItem("Stage", "stage", .stage([item.path])))
        menu.addItem(menuItem("Discard Changes…", "discard", .discard([item.path])))
        menu.addItem(.separator())
        menu.addItem(menuItem("Discard All Changes…", "discardAll", .discardAll))
        return menu
    }

    private func conflictMenu(for item: GitFileListItem) -> NSMenu {
        let menu = NSMenu()
        let paths = [item.path]
        if source.conflicts[item.path]?.hasMarkers == true {
            menu.addItem(menuItem("Open in Merge View", "openMerge", .openMerge(item.path)))
            menu.addItem(.separator())
        }
        menu.addItem(menuItem("Resolve Using Ours…", "resolveOurs", .resolve(paths, .ours)))
        menu.addItem(menuItem("Resolve Using Theirs…", "resolveTheirs", .resolve(paths, .theirs)))
        menu.addItem(menuItem("Mark Resolved", "markResolved", .markResolved(paths)))
        return menu
    }

    private func menuItem(_ title: String, _ name: String, _ intent: GitWorkingCopyIntent) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(performMenuIntent(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = MenuPayload(intent)
        item.accessibilityID("git.workingCopy.menu.\(name)")
        return item
    }

    private func pane(_ name: String, header: ThemedLabel, button: NSButton?,
                      list: GitFileListViewController) -> NSView {
        let pane = NSView()
        pane.accessibilityID("git.workingCopy.\(name)Pane")
        let listView = list.view
        for view in [header, button, listView].compactMap({ $0 }) {
            view.translatesAutoresizingMaskIntoConstraints = false
            pane.addSubview(view)
        }
        if let button {
            NSLayoutConstraint.activate([
                header.trailingAnchor.constraint(lessThanOrEqualTo: button.leadingAnchor, constant: -8),
                button.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -8),
                button.centerYAnchor.constraint(equalTo: header.centerYAnchor)
            ])
        } else {
            header.trailingAnchor.constraint(lessThanOrEqualTo: pane.trailingAnchor, constant: -8).isActive = true
        }
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 8),
            header.topAnchor.constraint(equalTo: pane.topAnchor, constant: 6),
            listView.leadingAnchor.constraint(equalTo: pane.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: pane.trailingAnchor),
            listView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 4),
            listView.bottomAnchor.constraint(equalTo: pane.bottomAnchor),
            pane.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        return pane
    }

    /// The diff a selected item of `list` shows.
    private func target(for item: GitFileListItem, in list: GitFileListViewController) -> GitDiffTarget {
        if list === conflictsList { return .conflicted(path: item.path) }
        if list === stagedList { return .staged(paths: [item.path]) }
        if item.status == .untracked { return .untracked(path: item.path) }
        return .unstaged(paths: [item.path])
    }
}

extension GitWorkingCopyViewController: GitFileListDelegate {
    /// A conflicted file with markers opens in the merge view, as a double-click does; any
    /// other selection is reported as its diff target (a conflict without markers as
    /// `.conflicted`, its working file against the merge base).
    public func fileList(_ list: GitFileListViewController, didSelect item: GitFileListItem?) {
        guard let item else {
            delegate?.workingCopy(self, didSelect: nil)
            return
        }
        for other in [conflictsList, stagedList, unstagedList] where other !== list {
            other.clearSelection()
        }
        if list === conflictsList, source.conflicts[item.path]?.hasMarkers == true {
            request(.openMerge(item.path))
            return
        }
        delegate?.workingCopy(self, didSelect: target(for: item, in: list))
    }
}
