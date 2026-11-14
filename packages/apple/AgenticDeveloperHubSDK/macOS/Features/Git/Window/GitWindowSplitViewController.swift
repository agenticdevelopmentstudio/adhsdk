import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKUI
import os

/// The Git window's content (recipe `workspace/git/git-window`, "Layout"): the refs
/// sidebar, a centre column that shows the history or the working copy, and a right
/// column of the commit detail over a bottom pane that shows a diff, a blame or a
/// file's history.
///
/// It owns the views and routes what each reports to the next: the sidebar picks the
/// centre, a commit picks the detail, a file picks the diff, and the diff's Blame and
/// History buttons pick the bottom pane. It observes the model and reloads only the
/// views a change names. Used on the main thread.
@MainActor
final class GitWindowSplitViewController: ThemedSplitViewController {

    /// What the sidebar has selected.
    enum Selection: Equatable {
        case workingCopy
        /// A branch, remote branch or tag, by full name.
        case ref(String)
        /// A stash, by its commit's sha.
        case stash(String)
    }

    let model: GitRepositoryModel
    let sidebar: GitRefsSidebarViewController
    let history: GitHistoryViewController
    let workingCopy: GitWorkingCopyViewController
    let detail: GitCommitDetailViewController
    let diff: GitDiffViewController
    let blame: GitBlameViewController
    let fileHistory: GitFileHistoryViewController

    let centre = GitWindowContainerViewController(identifier: "git.window.centre")
    let bottom = GitWindowContainerViewController(identifier: "git.window.bottom")
    let detailHost: GitWindowDetailHostViewController
    private let right: GitWindowRightSplitViewController

    /// Called when a submodule or worktree row asks for a window of its own.
    var onOpenDirectory: ((URL) -> Void)?

    private(set) var selection: Selection = .workingCopy
    /// The commit the selected ref pointed at when it was last shown in the history;
    /// nil until the ref's commit was found loaded.
    private var appliedRefTarget: String?
    /// Bumped by every commit load, so a load a newer one overtook is dropped.
    private var loadGeneration = 0
    /// The single-commit read in flight or last finished; tests await it.
    private(set) var commitLoadTask: Task<Void, Never>?
    private let client: GitClient
    private var observation: AnyObject?

    init(model: GitRepositoryModel, client: GitClient, coloring: GitSyntaxColoring?) {
        self.model = model
        self.client = client
        sidebar = GitRefsSidebarViewController(source: model)
        history = GitHistoryViewController(source: model)
        workingCopy = GitWorkingCopyViewController(source: model)
        detail = GitCommitDetailViewController(source: model)
        diff = GitDiffViewController(source: model, coloring: coloring)
        blame = GitBlameViewController(source: model, coloring: coloring)
        fileHistory = GitFileHistoryViewController(source: model, coloring: coloring)
        detailHost = GitWindowDetailHostViewController(detail: detail)
        right = GitWindowRightSplitViewController(
            top: detailHost, bottom: bottom, autosaveName: Self.autosaveName("git.window.right", root: model.root))
        super.init(nibName: nil, bundle: nil)
        sidebar.delegate = self
        history.delegate = self
        workingCopy.delegate = self
        detail.delegate = self
        diff.delegate = self
        blame.delegate = self
        fileHistory.diffViewController.delegate = self
        sidebar.selectWorkingCopy()
        centre.show(workingCopy)
        bottom.show(diff)
        observation = model.observe { [weak self] changes in
            self?.modelDidChange(changes)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityID("git.window.content")

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebar)
        sidebarItem.minimumThickness = 160
        sidebarItem.maximumThickness = 360
        sidebarItem.canCollapse = true
        sidebarItem.holdingPriority = .defaultLow + 1

        let centreItem = NSSplitViewItem(viewController: centre)
        centreItem.minimumThickness = 360

        let rightItem = NSSplitViewItem(viewController: right)
        rightItem.minimumThickness = 320

        addSplitViewItem(sidebarItem)
        addSplitViewItem(centreItem)
        addSplitViewItem(rightItem)

        splitView.dividerStyle = .thin
        splitView.accessibilityID("git.window.split")
        splitView.autosaveName = Self.autosaveName("git.window.split", root: model.root)
    }

    /// One divider layout per repository, so two Git windows never share theirs.
    static func autosaveName(_ base: String, root: URL) -> NSSplitView.AutosaveName {
        NSSplitView.AutosaveName(base + ":" + root.path)
    }

    // MARK: - Model changes

    /// Reloads every view `changes` names first, then shows the selected ref again once,
    /// so the history already holds a commit the refs moved to. The bottom pane reads
    /// again when what it shows can have changed: a working-copy diff or a blame of the
    /// working file on a working-copy change, a file's history on a history change.
    func modelDidChange(_ changes: Set<GitRepositoryChange>) {
        let workingCopyChanged = !changes.isDisjoint(with: [.workingCopy, .operation])
        if changes.contains(.refs) { sidebar.reload() }
        if changes.contains(.history) { history.reload() }
        if workingCopyChanged { workingCopy.reload() }
        if !changes.isDisjoint(with: [.refs, .history]) { reapplyRefSelection() }

        switch bottom.content {
        case let shown as GitDiffViewController where workingCopyChanged && shown.isShowingWorkingCopy:
            shown.reload()
        case let shown as GitBlameViewController where workingCopyChanged && shown.isShowingWorkingFile:
            shown.reload()
        case let shown as GitFileHistoryViewController where changes.contains(.history):
            shown.reload()
        default:
            break
        }
    }

    /// After a Refresh: every view reads the model again, the selected ref is shown
    /// again if it moved, and the bottom pane reads its diff, blame or file history
    /// again, whether or not the refresh reported a change. A commit picked in the
    /// history after the ref stays picked while the ref has not moved.
    func reloadAll() {
        sidebar.reload()
        history.reload()
        workingCopy.reload()
        reapplyRefSelection()
        switch bottom.content {
        case let shown as GitDiffViewController: shown.reload()
        case let shown as GitBlameViewController: shown.reload()
        case let shown as GitFileHistoryViewController: shown.reload()
        default: break
        }
    }

    /// Shows the selected ref's commit in the history when it has moved or was not
    /// loaded when the ref was picked.
    private func reapplyRefSelection() {
        guard case .ref(let fullName) = selection,
              let ref = model.refs.first(where: { $0.fullName == fullName }),
              ref.target != appliedRefTarget else { return }
        showInHistory(ref)
    }

    /// Selects the ref's commit in the history and shows it in the detail. It counts as
    /// applied only once the history holds the commit; until then a later reload tries
    /// again.
    private func showInHistory(_ ref: GitRef) {
        guard model.commit(ref.target) != nil, history.select(commitID: ref.target) else {
            appliedRefTarget = nil
            return
        }
        appliedRefTarget = ref.target
        // The history tells its delegate only about a change of row, so a ref on the
        // commit already selected there (after a stash showed in the detail) is
        // shown here.
        if detail.commit?.id != ref.target {
            detailHost.clearError()
            detail.show(commit: model.commit(ref.target))
            clearDiff()
        }
    }

    // MARK: - Commits

    /// Shows the commit `id` in the history when it is loaded there, and otherwise
    /// loads it on its own into the detail.
    private func showCommit(id: String) {
        if model.commit(id) != nil, centre.content === history {
            history.select(commitID: id)
        } else {
            loadCommit(id: id)
        }
    }

    /// Reads one commit (a stash, or a parent outside the loaded history) and shows it
    /// in the detail; a failure is logged and shown in place of the detail.
    private func loadCommit(id: String) {
        loadGeneration += 1
        let generation = loadGeneration
        var query = GitLogQuery()
        query.revisions = [id]
        query.limit = 1
        let root = model.root
        let client = client
        commitLoadTask = Task { [weak self] in
            do {
                let commits = try await client.log(query, in: root)
                guard let self, generation == self.loadGeneration else { return }
                self.detailHost.clearError()
                self.detail.show(commit: commits.first)
                self.diff.clear()
            } catch {
                guard let self, generation == self.loadGeneration else { return }
                let description = GitClientError.logDescription(of: error)
                Self.logger.error("Could not read commit: \(description, privacy: .public)")
                self.detail.show(commit: nil)
                self.detailHost.showError(error.localizedDescription)
                self.diff.clear()
            }
        }
    }

    // MARK: - Bottom pane

    private func showDiff(target: GitDiffTarget, file: String) {
        bottom.show(diff)
        diff.show(target: target, file: file)
    }

    private func clearDiff() {
        bottom.show(diff)
        diff.clear()
    }

    /// The one path a working-copy target names.
    static func file(of target: GitDiffTarget) -> String? {
        switch target {
        case .unstaged(let paths), .staged(let paths): return paths.first
        case .untracked(let path): return path
        case .commit(_, let paths), .range(_, _, let paths): return paths.last
        }
    }
}

// MARK: - GitRefsSidebarDelegate

extension GitWindowSplitViewController: GitRefsSidebarDelegate {
    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelect ref: GitRef) {
        selection = .ref(ref.fullName)
        loadGeneration += 1
        detailHost.clearError()
        centre.show(history)
        showInHistory(ref)
    }

    func sidebarDidSelectWorkingCopy(_ sidebar: GitRefsSidebarViewController) {
        selection = .workingCopy
        loadGeneration += 1
        appliedRefTarget = nil
        detailHost.clearError()
        detail.show(commit: nil)
        centre.show(workingCopy)
        clearDiff()
    }

    func sidebar(_ sidebar: GitRefsSidebarViewController, didSelectStash stash: GitStash) {
        selection = .stash(stash.id)
        appliedRefTarget = nil
        centre.show(history)
        loadCommit(id: stash.id)
    }

    func sidebar(_ sidebar: GitRefsSidebarViewController, open directory: URL) {
        onOpenDirectory?(directory)
    }
}

// MARK: - GitHistoryDelegate

extension GitWindowSplitViewController: GitHistoryDelegate {
    func history(_ history: GitHistoryViewController, didSelect commit: GitCommit?) {
        loadGeneration += 1
        detailHost.clearError()
        detail.show(commit: commit)
        clearDiff()
    }
}

// MARK: - GitCommitDetailDelegate

extension GitWindowSplitViewController: GitCommitDetailDelegate {
    func commitDetail(_ detail: GitCommitDetailViewController, didSelectCommit id: String) {
        showCommit(id: id)
    }

    func commitDetail(_ detail: GitCommitDetailViewController, didSelectFile file: GitFileListItem?,
                      in commit: GitCommit) {
        guard let file else {
            clearDiff()
            return
        }
        showDiff(target: .commit(commit.id, paths: [file.oldPath, file.path].compactMap { $0 }), file: file.path)
    }
}

// MARK: - GitWorkingCopyDelegate

extension GitWindowSplitViewController: GitWorkingCopyDelegate {
    func workingCopy(_ workingCopy: GitWorkingCopyViewController, didSelect target: GitDiffTarget?) {
        guard let target, let file = Self.file(of: target) else {
            clearDiff()
            return
        }
        showDiff(target: target, file: file)
    }
}

// MARK: - GitDiffDelegate

extension GitWindowSplitViewController: GitDiffDelegate {
    func diff(_ diff: GitDiffViewController, didRequestBlameFor path: String, at revision: String?) {
        bottom.show(blame)
        blame.show(path: path, at: revision)
    }

    func diff(_ diff: GitDiffViewController, didRequestHistoryFor path: String) {
        bottom.show(fileHistory)
        fileHistory.show(path: path)
    }
}

// MARK: - GitBlameDelegate

extension GitWindowSplitViewController: GitBlameDelegate {
    func blame(_ blame: GitBlameViewController, didSelectCommit id: String) {
        showCommit(id: id)
    }
}

extension GitWindowSplitViewController: Loggable {
    static nonisolated let logger = makeLogger()
}

// MARK: - Containers

/// Shows one child view controller at a time, filling its view; `show(_:)` swaps it.
@MainActor
final class GitWindowContainerViewController: NSViewController {
    private(set) var content: NSViewController?
    private let identifierString: String

    init(identifier: String) {
        identifierString = identifier
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        let root = NSView()
        root.accessibilityID(identifierString)
        view = root
        if let content { install(content) }
    }

    /// Makes `controller` the one child shown; showing the current one does nothing.
    func show(_ controller: NSViewController) {
        guard controller !== content else { return }
        if let content {
            content.view.removeFromSuperview()
            content.removeFromParent()
        }
        content = controller
        if isViewLoaded { install(controller) }
    }

    private func install(_ controller: NSViewController) {
        addChild(controller)
        let child = controller.view
        child.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child)
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.topAnchor.constraint(equalTo: view.topAnchor),
            child.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

/// The commit detail with an error label over it, shown in its place when a commit
/// could not be read.
@MainActor
final class GitWindowDetailHostViewController: NSViewController {
    let detail: GitCommitDetailViewController
    let errorLabel = ThemedLabel.wrapping("", width: 400, role: .danger, textRole: .body)

    init(detail: GitCommitDetailViewController) {
        self.detail = detail
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        let root = NSView()
        root.accessibilityID("git.window.detail")
        addChild(detail)
        let child = detail.view
        child.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.accessibilityID("git.window.error")
        errorLabel.isHidden = true
        root.addSubview(child)
        root.addSubview(errorLabel)
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            child.topAnchor.constraint(equalTo: root.topAnchor),
            child.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -16),
            errorLabel.topAnchor.constraint(equalTo: root.topAnchor, constant: 16)
        ])
        view = root
    }

    func showError(_ message: String) {
        loadViewIfNeeded()
        errorLabel.stringValue = message
        errorLabel.isHidden = false
        detail.view.isHidden = true
    }

    func clearError() {
        guard isViewLoaded else { return }
        errorLabel.stringValue = ""
        errorLabel.isHidden = true
        detail.view.isHidden = false
    }
}

/// The right column: the detail host over the bottom pane, split by a horizontal divider.
@MainActor
final class GitWindowRightSplitViewController: ThemedSplitViewController {
    private let top: NSViewController
    private let bottomController: NSViewController
    private let autosaveName: NSSplitView.AutosaveName

    init(top: NSViewController, bottom: NSViewController, autosaveName: NSSplitView.AutosaveName) {
        self.top = top
        bottomController = bottom
        self.autosaveName = autosaveName
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.isVertical = false
        splitView.dividerStyle = .thin
        let topItem = NSSplitViewItem(viewController: top)
        topItem.minimumThickness = 160
        let bottomItem = NSSplitViewItem(viewController: bottomController)
        bottomItem.minimumThickness = 160
        addSplitViewItem(topItem)
        addSplitViewItem(bottomItem)
        splitView.accessibilityID("git.window.right")
        splitView.autosaveName = autosaveName
    }
}
