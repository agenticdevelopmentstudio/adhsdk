import AppKit
import Combine
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKUI

/// The Notations pane: the notes of the branch its tab's working directory
/// has checked out, in the Notes markdown editor.
///
/// It follows HEAD: switching branches in a terminal beside it switches the
/// notes. Nothing is written until the first edit, so opening a project on a
/// branch nobody has written about leaves no row behind. On a detached HEAD
/// there is no branch to keep notes for, and the editor is read-only.
///
/// Git and the store are only ever touched off the main thread; the pane
/// hands results back to the main actor to show.
@MainActor
public final class NotationsPaneViewController: NSViewController {

    public static let saveDebounce: TimeInterval = 0.5

    private let store: NotationsStore
    private let resolver: NotationResolver
    private let git: NotationsGit
    private let projectID: UUID
    private let projectName: String
    private let projectPath: String
    private let workingDirectory: URL

    private let header = ThemedLabel(role: .secondaryText, textRole: .caption)
    private let editorController = MarkdownEditorController(palette: ThemeScope.app.palette)

    /// The branch being shown, once resolved.
    private var key: NotationKey?
    /// The row behind the editor; `nil` until the first edit writes one.
    private var notationID: UUID?
    private var pendingSave: DispatchWorkItem?
    private var pendingContent: String?
    private var savesInFlight = 0
    private var resolveTask: Task<Void, Never>?
    private var resolveGeneration = 0
    private var watcher: FileSystemWatcher?
    private var headPath: String?
    private var changesSubscription: AnyCancellable?

    /// Serial, so saves land in the order they were typed.
    private let saveQueue = DispatchQueue(label: "com.agenticdeveloperhubsdk.notations.pane.save", qos: .utility)

    public init(
        store: NotationsStore,
        projectID: UUID,
        projectName: String,
        projectPath: String,
        workingDirectory: URL,
        git: NotationsGit = NotationsGit()
    ) {
        self.store = store
        self.git = git
        self.resolver = NotationResolver(git: git, store: store)
        self.projectID = projectID
        self.projectName = projectName
        self.projectPath = projectPath
        self.workingDirectory = workingDirectory
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    isolated deinit {
        resolveTask?.cancel()
        watcher?.stop()
        pendingSave?.cancel()
        // No `self` past this point: a weak reference cannot be formed to an
        // object being deallocated, so the last edit is saved without one.
        if let content = pendingContent, let key {
            let store = store
            let id = notationID
            saveQueue.async {
                _ = try? store.save(id: id, key: key, content: content)
            }
        }
    }

    // MARK: - View

    public override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)

        header.lineBreakMode = .byTruncatingMiddle
        header.cell?.usesSingleLineMode = true
        header.translatesAutoresizingMaskIntoConstraints = false
        header.accessibilityID("notations-pane.branch")

        editorController.showsHelpButton = false
        editorController.showsImportButton = false
        editorController.isEditable = false
        addChild(editorController)
        let editorView = editorController.view
        editorView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(header)
        container.addSubview(editorView)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            header.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            header.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -10),

            editorView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 4),
            editorView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            editorView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        view = container
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        editorController.onContentChange = { [weak self] content in
            self?.contentChanged(content)
        }
        editorController.view.observeTheme { [weak editorController] _, palette in
            editorController?.palette = palette
        }
        changesSubscription = store.changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.storeChanged() }
            }
        refresh()
        startWatchingHead()
    }

    // MARK: - Branch

    /// Re-resolves the branch and its notation, and shows the result. A
    /// newer call supersedes an older one still in flight.
    public func refresh() {
        flushPendingSave()
        resolveGeneration += 1
        let generation = resolveGeneration
        resolveTask?.cancel()
        let resolver = resolver
        let projectID = projectID, projectName = projectName, projectPath = projectPath
        let workingDirectory = workingDirectory
        resolveTask = Task { [weak self] in
            let resolution = await Task.detached(priority: .userInitiated) {
                await resolver.resolve(projectID: projectID, projectName: projectName,
                                       projectPath: projectPath, workingDirectory: workingDirectory)
            }.value
            guard !Task.isCancelled else { return }
            self?.apply(resolution, generation: generation)
        }
    }

    private func apply(_ resolution: NotationResolution, generation: Int) {
        guard generation == resolveGeneration else { return }
        switch resolution {
        case .branch(let key, let notation):
            self.key = key
            notationID = notation?.id
            header.stringValue = key.branch
            editorController.content = notation?.content ?? ""
            editorController.isEditable = true
        case .detached:
            key = nil
            notationID = nil
            header.stringValue = "Detached HEAD"
            editorController.content = ""
            editorController.isEditable = false
        case .unavailable:
            key = nil
            notationID = nil
            header.stringValue = "No branch"
            editorController.content = ""
            editorController.isEditable = false
        }
    }

    /// Watches the directory HEAD lives in (FSEvents watches directories,
    /// and git replaces HEAD by renaming `HEAD.lock` over it) and refreshes
    /// when HEAD is among the changed paths.
    private func startWatchingHead() {
        let git = git
        let workingDirectory = workingDirectory
        Task { [weak self] in
            guard let head = try? await git.headPath(in: workingDirectory) else { return }
            let resolved = head.resolvingSymlinksInPath()
            let directory = resolved.deletingLastPathComponent().path
            self?.watchHead(at: resolved.path, in: directory)
        }
    }

    private func watchHead(at path: String, in directory: String) {
        headPath = path
        let excluded = ["objects", "refs", "logs", "worktrees", "modules", "lfs", "hooks"]
            .map { (directory as NSString).appendingPathComponent($0) }
        let watcher = FileSystemWatcher(rootPath: directory, excludedPrefixes: excluded) { [weak self] paths in
            MainActor.assumeIsolated { self?.headDirectoryChanged(paths) }
        }
        self.watcher = watcher
        watcher.start()
    }

    private func headDirectoryChanged(_ paths: [String]) {
        guard let headPath else { return }
        let headName = (headPath as NSString).lastPathComponent
        let touched = paths.contains { path in
            let resolved = (path as NSString).resolvingSymlinksInPath
            return resolved == headPath || (path as NSString).lastPathComponent == headName
        }
        if touched { refresh() }
    }

    // MARK: - Saving

    private func contentChanged(_ content: String) {
        guard key != nil else { return }
        pendingContent = content
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.flushPendingSave() }
        }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.saveDebounce, execute: work)
    }

    /// Writes whatever is waiting, now, off the main thread.
    private func flushPendingSave() {
        pendingSave?.cancel()
        pendingSave = nil
        guard let content = pendingContent, let key else { return }
        pendingContent = nil
        let store = store
        let id = notationID
        savesInFlight += 1
        saveQueue.async { [weak self] in
            let saved: Notation?
            do {
                saved = try store.save(id: id, key: key, content: content)
            } catch {
                Self.logger.error("Saving the notation for \(key.branch) failed: \(error.localizedDescription)")
                saved = nil
            }
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.savesInFlight -= 1
                    if let saved, self.key == key { self.notationID = saved.id }
                }
            }
        }
    }

    /// Another writer changed the store (the window, a tool, a script, a
    /// reconcile). Reload, unless this pane has its own edit on the way,
    /// which would otherwise be overwritten by the text it is replacing.
    private func storeChanged() {
        guard pendingContent == nil, savesInFlight == 0, key != nil else { return }
        let store = store
        let id = notationID
        let key = key
        Task { [weak self] in
            let current: Notation? = await Task.detached(priority: .utility) {
                if let id, let byID = try? store.notation(id: id), byID.state == .active { return byID }
                guard let key else { return nil }
                return try? store.activeNotation(for: key)
            }.value
            guard let self, self.pendingContent == nil, self.savesInFlight == 0, self.key == key else { return }
            self.notationID = current?.id
            let content = current?.content ?? ""
            if self.editorController.content != content { self.editorController.content = content }
        }
    }
}

extension NotationsPaneViewController: Loggable {
    public static nonisolated let logger = makeLogger()
}
