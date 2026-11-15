import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKUI
import os

/// One Git window's state and routing (recipe `workspace/git/git-window`, "Layout"):
/// the repository model, every Git view, and the three panes the window's
/// composable-tabs layout shows (`GitWindowPanes`) — the overview (the refs
/// sidebar), the history (the history or the working copy) and the commit (the
/// commit detail over a bottom pane that shows a diff, a blame or a file's
/// history).
///
/// It routes what each view reports to the next: the sidebar picks the history
/// pane's content, a commit picks the detail, a file picks the diff, and the
/// diff's Blame and History buttons pick the bottom pane. It observes the model
/// and reloads only the views a change names. Used on the main thread.
@MainActor
final class GitWindowSession {

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
    /// The in-progress operation banner, above the overview pane's content.
    let banner = GitOperationBannerViewController()

    /// The three panes, as the layout's factories hand them out.
    let overviewPane: GitWindowOverviewPaneViewController
    let centre: GitWindowHistoryPaneViewController
    let commitPane = GitWindowContainerViewController(identifier: "git.window.commit", paneTitle: "Commit")

    let bottom = GitWindowContainerViewController(identifier: "git.window.bottom", paneTitle: "")
    let detailHost: GitWindowDetailHostViewController
    private let right: GitWindowRightSplitViewController

    /// Called when a submodule or worktree row asks for a window of its own.
    var onOpenDirectory: ((URL) -> Void)?
    /// Called when the refs change, so the window can read its branch again.
    var onRefsChange: (() -> Void)?

    /// Asks the user before and after an action; set by the feature. While nil, an
    /// action that needs the user (a confirmation, a name) does nothing, and a failure
    /// is only logged.
    var presenter: GitActionPresenting?
    /// Called with true when an action starts running git and false when git returns;
    /// never while a sheet waits for the user. The overview's spinner follows it.
    var onBusyChange: ((Bool) -> Void)?
    /// The action running or last finished; tests await it. Set only by `perform(_:)`
    /// (GitWindowSession+Actions.swift), which is why the setter is not private.
    var actionTask: Task<Void, Never>?
    /// True while an action runs; a request made meanwhile is ignored. Set only by
    /// `perform(_:)`.
    var isActing = false

    private(set) var selection: Selection = .workingCopy
    /// The commit the selected ref pointed at when it was last shown in the history;
    /// nil until the ref's commit was found loaded.
    private var appliedRefTarget: String?
    /// Bumped by every commit load, so a load a newer one overtook is dropped.
    private var loadGeneration = 0
    /// The single-commit read in flight or last finished; tests await it.
    private(set) var commitLoadTask: Task<Void, Never>?
    /// The search in flight or last finished; tests await it.
    private(set) var searchTask: Task<Void, Never>?
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
        overviewPane = GitWindowOverviewPaneViewController(banner: banner)
        centre = GitWindowHistoryPaneViewController()
        overviewPane.onRefresh = { [weak self] in self?.refresh() }
        centre.onSearch = { [weak self] text in self?.search(text) }
        sidebar.delegate = self
        history.delegate = self
        workingCopy.delegate = self
        detail.delegate = self
        diff.delegate = self
        blame.delegate = self
        fileHistory.diffViewController.delegate = self
        banner.delegate = self
        banner.state = model.operationState
        history.refDropValidator = { [weak self] name in self?.sidebar.dropMenu(forRefNamed: name) != nil }
        history.onRefDrop = { [weak self] name in
            guard let self, let menu = self.sidebar.dropMenu(forRefNamed: name) else { return }
            self.sidebar.menuPresenter(menu, self.history.tableView)
        }
        sidebar.selectWorkingCopy()
        overviewPane.show(sidebar)
        centre.show(workingCopy)
        commitPane.show(right)
        bottom.show(diff)
        workingCopy.canAmend = model.hasCommits
        observation = model.observe { [weak self] changes in
            self?.modelDidChange(changes)
        }
    }

    /// One divider layout per repository, so two Git windows never share theirs.
    static func autosaveName(_ base: String, root: URL) -> NSSplitView.AutosaveName {
        NSSplitView.AutosaveName(base + ":" + root.path)
    }

    // MARK: - Lifetime

    /// Reads every part of the model and starts watching the repository.
    func start() async {
        await model.start()
    }

    /// Stops watching the repository and drops a search and an action in flight; the
    /// window closed. A cancelled action's git gets SIGTERM, which git answers by
    /// removing its lock files, no step after it runs, and nothing is shown.
    func stop() {
        searchTask?.cancel()
        actionTask?.cancel()
        model.stop()
    }

    // MARK: - Search and refresh

    /// Sends the search text to the history; the history decides which call is latest.
    /// A search typed over the working copy picks the checked-out branch first, as a
    /// click on it would, so the history it filters is the one on screen.
    func search(_ text: String) {
        if selection == .workingCopy,
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !selectCheckedOutBranch() {
            centre.show(history)
        }
        let history = history
        searchTask = Task { await history.setQuery(text) }
    }

    /// Picks the checked-out branch in the sidebar, which shows it in the history;
    /// false on a detached HEAD, which has no branch row.
    private func selectCheckedOutBranch() -> Bool {
        guard let head = model.refs.first(where: { $0.kind == .localBranch && $0.isHead }) else { return false }
        return sidebar.select(refNamed: head.fullName)
    }

    /// Reloads every part of the model, then every view, and shows the selection again.
    func refresh() {
        Task { [weak self] in
            guard let self else { return }
            await self.model.refresh(Set(GitRepositoryChange.allCases))
            self.reloadAll()
            self.onRefsChange?()
        }
    }

    // MARK: - Model changes

    /// Reloads every view `changes` names first, then shows the selected ref again once,
    /// so the history already holds a commit the refs moved to. The bottom pane reads
    /// again when what it shows can have changed: a working-copy diff or a blame of the
    /// working file on a working-copy change, a file's history on a history change.
    func modelDidChange(_ changes: Set<GitRepositoryChange>) {
        let workingCopyChanged = !changes.isDisjoint(with: [.workingCopy, .operation])
        banner.state = model.operationState
        if changes.contains(.refs) {
            sidebar.reload()
            onRefsChange?()
        }
        if changes.contains(.history) { history.reload() }
        if workingCopyChanged { workingCopy.reload() }
        if workingCopyChanged || changes.contains(.refs) { workingCopy.canAmend = model.hasCommits }
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
        banner.state = model.operationState
        sidebar.reload()
        history.reload()
        workingCopy.reload()
        workingCopy.canAmend = model.hasCommits
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

extension GitWindowSession: GitRefsSidebarDelegate {
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

    func sidebar(_ sidebar: GitRefsSidebarViewController, didRequest intent: GitRefIntent) {
        perform(.ref(intent))
    }
}

// MARK: - GitHistoryDelegate

extension GitWindowSession: GitOperationBannerDelegate {
    func banner(_ banner: GitOperationBannerViewController, didRequest intent: GitOperationIntent) {
        switch intent {
        case .step(let step): perform(.operation(step))
        }
    }
}

extension GitWindowSession: GitHistoryDelegate {
    func history(_ history: GitHistoryViewController, didSelect commit: GitCommit?) {
        loadGeneration += 1
        detailHost.clearError()
        detail.show(commit: commit)
        clearDiff()
    }

    func history(_ history: GitHistoryViewController, didRequest intent: GitCommitIntent, for commit: GitCommit) {
        perform(.commit(intent, commit))
    }
}

// MARK: - GitCommitDetailDelegate

extension GitWindowSession: GitCommitDetailDelegate {
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

extension GitWindowSession: GitWorkingCopyDelegate {
    func workingCopy(_ workingCopy: GitWorkingCopyViewController, didSelect target: GitDiffTarget?) {
        guard let target, let file = Self.file(of: target) else {
            clearDiff()
            return
        }
        showDiff(target: target, file: file)
    }

    func workingCopy(_ workingCopy: GitWorkingCopyViewController, didRequest intent: GitWorkingCopyIntent) {
        perform(.workingCopy(intent))
    }
}

// MARK: - GitDiffDelegate

extension GitWindowSession: GitDiffDelegate {
    func diff(_ diff: GitDiffViewController, didRequestBlameFor path: String, at revision: String?) {
        bottom.show(blame)
        blame.show(path: path, at: revision)
    }

    func diff(_ diff: GitDiffViewController, didRequestHistoryFor path: String) {
        bottom.show(fileHistory)
        fileHistory.show(path: path)
    }

    func diff(_ diff: GitDiffViewController, didRequest intent: GitDiffIntent) {
        perform(.diff(intent))
    }
}

// MARK: - GitBlameDelegate

extension GitWindowSession: GitBlameDelegate {
    func blame(_ blame: GitBlameViewController, didSelectCommit id: String) {
        showCommit(id: id)
    }
}

extension GitWindowSession: Loggable {
    static nonisolated let logger = makeLogger()
}

// MARK: - Containers

/// Shows one child view controller at a time, filling its view; `show(_:)` swaps it.
/// As a pane's content it names the pane (`PaneTitleProviding`).
@MainActor
class GitWindowContainerViewController: NSViewController, PaneTitleProviding {
    private(set) var content: NSViewController?
    private let identifierString: String
    /// A child shown above the content, at its own height, and collapsing when hidden.
    private let header: NSViewController?
    /// Where the content goes: the root, or the area below the header.
    private let contentHost = NSView()

    /// What the pane's title bar says.
    var paneTitle: String {
        didSet { if paneTitle != oldValue { onPaneTitleChange?() } }
    }
    var onPaneTitleChange: (() -> Void)?

    init(identifier: String, paneTitle: String, header: NSViewController? = nil) {
        identifierString = identifier
        self.paneTitle = paneTitle
        self.header = header
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        let root = NSView()
        root.accessibilityID(identifierString)
        var views: [NSView] = [contentHost]
        if let header {
            addChild(header)
            views.insert(header.view, at: 0)
        }
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.spacing = 0
        stack.distribution = .fill
        // A hidden header gives its row back to the content.
        stack.detachesHiddenViews = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)
        var constraints = [
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ]
        for view in views {
            constraints.append(view.widthAnchor.constraint(equalTo: stack.widthAnchor))
        }
        header?.view.setContentHuggingPriority(.required, for: .vertical)
        contentHost.setContentHuggingPriority(.defaultLow, for: .vertical)
        NSLayoutConstraint.activate(constraints)
        view = root
        if let content { install(content) }
    }

    /// Makes `controller` the one child shown; showing the current one does nothing.
    func show(_ controller: NSViewController) {
        defer { contentDidChange() }
        guard controller !== content else { return }
        if let content {
            content.view.removeFromSuperview()
            content.removeFromParent()
        }
        content = controller
        if isViewLoaded { install(controller) }
    }

    /// Called after every `show(_:)`, for a pane whose title follows its content.
    func contentDidChange() {}

    private func install(_ controller: NSViewController) {
        addChild(controller)
        let child = controller.view
        child.translatesAutoresizingMaskIntoConstraints = false
        contentHost.addSubview(child)
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: contentHost.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: contentHost.trailingAnchor),
            child.topAnchor.constraint(equalTo: contentHost.topAnchor),
            child.bottomAnchor.constraint(equalTo: contentHost.bottomAnchor)
        ])
    }
}

/// The overview pane: the refs sidebar under the in-progress operation banner, with a
/// spinner shown while an action runs and the Refresh button in the pane's title bar
/// (`PaneAccessoryProviding`).
@MainActor
final class GitWindowOverviewPaneViewController: GitWindowContainerViewController, PaneAccessoryProviding {
    /// What the Refresh button does.
    var onRefresh: (() -> Void)?

    /// Spins while the window runs an action; hidden otherwise.
    let busyIndicator = NSProgressIndicator()
    /// Whether the spinner is showing.
    private(set) var isBusy = false

    init(banner: NSViewController) {
        super.init(identifier: "git.window.overview", paneTitle: "Overview", header: banner)
        busyIndicator.style = .spinning
        busyIndicator.controlSize = .small
        busyIndicator.isIndeterminate = true
        busyIndicator.isDisplayedWhenStopped = false
        busyIndicator.isHidden = true
        busyIndicator.setAccessibilityLabel("Running")
        busyIndicator.accessibilityID("git.window.busy")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Shows and spins the indicator while `busy`, hides it otherwise.
    func setBusy(_ busy: Bool) {
        isBusy = busy
        busyIndicator.isHidden = !busy
        if busy {
            busyIndicator.startAnimation(nil)
        } else {
            busyIndicator.stopAnimation(nil)
        }
    }

    func makePaneAccessoryViews() -> [NSView] {
        [busyIndicator, makeRefreshButton()]
    }

    private func makeRefreshButton() -> NSView {
        let title = "Refresh"
        let image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: title) ?? NSImage()
        let button = NSButton(image: image, target: self, action: #selector(refresh(_:)))
        button.isBordered = false
        button.bezelStyle = .accessoryBarAction
        button.toolTip = title
        button.setAccessibilityLabel(title)
        button.accessibilityID("git.window.refresh")
        return button
    }

    @objc private func refresh(_ sender: Any?) {
        onRefresh?()
    }
}

/// The history pane: the history or the working copy, titled after the one it
/// shows. The window's toolbar search reaches the history through it
/// (`PaneSearchable`).
@MainActor
final class GitWindowHistoryPaneViewController: GitWindowContainerViewController, PaneSearchable {
    /// Where a search goes.
    var onSearch: ((String) -> Void)?

    init() {
        super.init(identifier: "git.window.centre", paneTitle: "History")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func contentDidChange() {
        paneTitle = content is GitWorkingCopyViewController ? "Working Copy" : "History"
    }

    var paneSearchPlaceholder: String { "Search History" }

    func paneSearch(for query: String) {
        onSearch?(query)
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
