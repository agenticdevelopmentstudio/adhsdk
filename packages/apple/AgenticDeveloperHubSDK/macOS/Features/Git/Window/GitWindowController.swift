import AppKit
import AgenticDeveloperHubSDKCore
import os

/// One repository's Git window (recipe `workspace/git/git-window`, "Window identity"):
/// titled with the repository's folder name, subtitled with its branch, keyed by the
/// canonical top level so the window id is `git:<path>`.
///
/// It owns the repository model and its watcher: the model starts when the window is
/// made and stops when it closes. The toolbar's search goes to the history, its
/// Refresh reloads every part and every view. Used on the main thread.
@MainActor
public final class GitWindowController: SingleWindowController {

    /// The canonical top level this window shows.
    public let root: URL

    let model: GitRepositoryModel
    let content: GitWindowSplitViewController
    private let toolbar = GitWindowToolbar()
    private let client: GitClient
    private let onClose: () -> Void
    private var observation: AnyObject?
    /// Bumped by every subtitle read, so an older answer never replaces a newer one.
    private var subtitleGeneration = 0
    /// The subtitle read in flight or last finished; tests await it.
    private(set) var subtitleTask: Task<Void, Never>?
    private(set) var searchTask: Task<Void, Never>?

    static let initialSize = NSSize(width: 1200, height: 760)
    static let minimumSize = NSSize(width: 720, height: 440)

    /// - Parameters:
    ///   - root: the repository's canonical top level.
    ///   - onClose: called when the user closes the window, never while the app quits.
    ///   - onOpenDirectory: a submodule or worktree asking for a window of its own.
    init(
        root: URL,
        client: GitClient,
        coloring: GitSyntaxColoring?,
        onOpenDirectory: @escaping (URL) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.root = root
        self.client = client
        self.onClose = onClose
        model = GitRepositoryModel(
            root: root, client: client,
            watcher: GitDeferredRepositoryWatcher(root: root, client: client))
        content = GitWindowSplitViewController(model: model, client: client, coloring: coloring)
        super.init(windowID: "git:" + root.path, contentViewController: content)
        windowTitle = root.lastPathComponent.isEmpty ? root.path : root.lastPathComponent
        windowTitleSymbolName = "point.3.connected.trianglepath.dotted"
        windowStyleMask = [.titled, .closable, .miniaturizable, .resizable]
        minSize = Self.minimumSize
        accessibilityIdentifier = "git-window"
        windowSpec = WindowSpec(
            defaultSize: Self.initialSize,
            minSize: Self.minimumSize,
            defaultPosition: .center,
            behavior: [.persistsFrame])
        content.onOpenDirectory = onOpenDirectory
        toolbar.onSearch = { [weak self] text in self?.search(text) }
        toolbar.onRefresh = { [weak self] in self?.refresh() }
        observation = model.observe { [weak self] changes in
            if changes.contains(.refs) { self?.updateSubtitle() }
        }
        Task { [weak self] in
            await self?.model.start()
        }
        updateSubtitle()
    }

    public override func configureWindow(_ window: NSWindow) {
        toolbar.install(in: window)
        window.subtitle = ""
    }

    public override func windowWillClose(_ notification: Notification) {
        super.windowWillClose(notification)
        searchTask?.cancel()
        model.stop()
        if !WindowManager.shared.isTerminating {
            onClose()
        }
    }

    // MARK: - Toolbar

    /// Sends the search text to the history; the history decides which call is latest.
    func search(_ text: String) {
        let history = content.history
        searchTask = Task { await history.setQuery(text) }
    }

    /// Reloads every part of the model, then every view, and shows the selection again.
    func refresh() {
        Task { [weak self] in
            guard let self else { return }
            await self.model.refresh(Set(GitRepositoryChange.allCases))
            self.content.reloadAll()
            self.updateSubtitle()
        }
    }

    // MARK: - Subtitle

    /// The checked-out branch, or "detached HEAD". A failed read is logged and keeps the
    /// last subtitle.
    func updateSubtitle() {
        subtitleGeneration += 1
        let generation = subtitleGeneration
        let root = root
        let client = client
        subtitleTask = Task { [weak self] in
            let subtitle: String
            do {
                subtitle = try await client.currentBranch(in: root) ?? "detached HEAD"
            } catch {
                Self.logger.error(
                    "Could not read the branch: \(GitClientError.logDescription(of: error), privacy: .public)")
                return
            }
            guard let self, generation == self.subtitleGeneration else { return }
            self.window?.subtitle = subtitle
        }
    }
}

extension GitWindowController: Loggable {
    public static nonisolated let logger = makeLogger()
}
