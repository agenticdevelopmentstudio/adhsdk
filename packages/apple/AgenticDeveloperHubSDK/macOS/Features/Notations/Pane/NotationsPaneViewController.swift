import os
import AppKit
import Combine
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKUI

/// The Notations pane: the notes of the branch its tab's working directory
/// has checked out, as two panes — Markdown, the editable source, and
/// Preview, its rendering — each framed by a tab bar the way the Document
/// pane frames its editors.
///
/// The layout control sits right-justified in the pane's title bar
/// (`PaneAccessoryProviding`): both panes as tabs of one frame, or side by
/// side, each in a frame of its own. In a single pane the tabs pick which
/// pane shows. The tabs have no close buttons; neither pane is ever closed.
/// Both choices start as Markdown in a single pane and are remembered in
/// `UserSettings.notationsPaneLayout` and `.notationsPaneContent`.
///
/// It follows HEAD: switching branches in a terminal beside it switches the
/// notes. Nothing is written until the first edit, so opening a project on a
/// branch nobody has written about leaves no row behind. On a detached HEAD
/// there is no branch to keep notes for, and the source is read-only.
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

    private let layoutBar = IconTabBar(
        items: [
            .init(id: NotationsPaneLayout.singlePane.rawValue, symbol: "square", title: "Single Pane"),
            .init(id: NotationsPaneLayout.sideBySide.rawValue, symbol: "square.split.2x1", title: "Side by Side")
        ],
        accessibilityID: "notations-pane.layout")

    private let source = NotationsSourceViewController()
    private let preview = MarkdownViewerController(palette: ThemeScope.app.palette)

    /// Single pane: one frame holding both panes as tabs.
    private let singleFrame = MultiTabbedViewController()
    /// Side by side: a frame per pane, each with its one tab.
    private let markdownFrame = MultiTabbedViewController()
    private let previewFrame = MultiTabbedViewController()
    private let splitView = ThemedSplitView(frame: .zero)

    /// The tab ids, the same in whichever frame a pane is in.
    private let markdownTabID = UUID()
    private let previewTabID = UUID()

    private var layout: NotationsPaneLayout = UserSettings.notationsPaneLayout.value
    private var shownContent: NotationsPaneContent = UserSettings.notationsPaneContent.value

    /// True while the panes are being moved between frames, whose removals
    /// and insertions report tab selections that are not the user's.
    private var isRearranging = false
    /// Set when the split view is shown, so the next layout pass with a real
    /// width gives the two frames half each.
    private var needsSplitEqualized = false

    /// The branch being shown, once resolved.
    private var key: NotationKey?
    /// The row behind the editor; `nil` until the first edit writes one.
    private var notationID: UUID?
    private var pendingSave: DispatchWorkItem?
    private var pendingContent: String?
    private var savesInFlight = 0
    private var pendingRender: DispatchWorkItem?
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
        pendingRender?.cancel()
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

        layoutBar.onSelect = { [weak self] id in
            guard let self, let layout = NotationsPaneLayout(rawValue: id) else { return }
            self.choose(layout: layout)
        }

        source.pane.isEditable = false

        for frame in [singleFrame, markdownFrame, previewFrame] {
            frame.delegate = self
            frame.showsCloseButtons = false
            addChild(frame)
        }
        splitView.dividerStyle = .thin
        splitView.addArrangedSubview(markdownFrame.view)
        splitView.addArrangedSubview(previewFrame.view)

        let contentViews: [NSView] = [singleFrame.view, splitView]
        for content in contentViews {
            content.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(content)
        }

        var constraints: [NSLayoutConstraint] = []
        for content in contentViews {
            constraints += [
                content.topAnchor.constraint(equalTo: container.topAnchor),
                content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ]
        }
        NSLayoutConstraint.activate(constraints)
        view = container
        applyArrangement()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        source.pane.onTextChange = { [weak self] text in
            self?.scheduleRender()
            self?.contentChanged(text)
        }
        source.pane.applyTheme(ThemeScope.app.palette)
        view.observeTheme { [weak self] _, palette in
            self?.source.pane.applyTheme(palette)
            self?.preview.palette = palette
        }
        changesSubscription = store.changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.storeChanged() }
            }
        refresh()
        startWatchingHead()
    }

    public override func viewDidLayout() {
        super.viewDidLayout()
        guard needsSplitEqualized, !splitView.isHidden, splitView.bounds.width > 0 else { return }
        needsSplitEqualized = false
        splitView.setPosition((splitView.bounds.width - splitView.dividerThickness) / 2, ofDividerAt: 0)
    }

    // MARK: - Layout and content

    private func choose(layout: NotationsPaneLayout) {
        guard layout != self.layout else {
            syncHeader()
            return
        }
        self.layout = layout
        UserSettings.notationsPaneLayout.value = layout
        applyArrangement()
    }

    private func choose(content: NotationsPaneContent) {
        guard content != shownContent else {
            syncHeader()
            return
        }
        shownContent = content
        UserSettings.notationsPaneContent.value = content
        if layout == .singlePane {
            isRearranging = true
            singleFrame.selectTab(id: tabID(for: content), on: .top)
            isRearranging = false
        }
        syncHeader()
        if content == .preview { flushPendingRender() }
    }

    /// Puts the two panes in the frames `layout` calls for and shows those
    /// frames. Every tab is taken down first, so a pane is only ever in one
    /// frame and the frame it leaves unmounts it.
    private func applyArrangement() {
        isRearranging = true
        for frame in [singleFrame, markdownFrame, previewFrame] {
            for tab in frame.tabs(on: .top) { frame.removeTab(id: tab.id) }
        }
        let markdownTab = MultiTabbedViewController.Tab(
            id: markdownTabID, title: NotationsPaneContent.markdown.title, viewController: source)
        let previewTab = MultiTabbedViewController.Tab(
            id: previewTabID, title: NotationsPaneContent.preview.title, viewController: preview)
        switch layout {
        case .singlePane:
            singleFrame.addTab(markdownTab, on: .top)
            singleFrame.addTab(previewTab, on: .top)
            singleFrame.selectTab(id: tabID(for: shownContent), on: .top)
        case .sideBySide:
            markdownFrame.addTab(markdownTab, on: .top)
            previewFrame.addTab(previewTab, on: .top)
            needsSplitEqualized = true
        }
        singleFrame.view.isHidden = layout != .singlePane
        splitView.isHidden = layout != .sideBySide
        isRearranging = false
        syncHeader()
        flushPendingRender()
        view.needsLayout = true
    }

    private func syncHeader() {
        layoutBar.selectedID = layout.rawValue
    }

    private func tabID(for content: NotationsPaneContent) -> UUID {
        content == .markdown ? markdownTabID : previewTabID
    }

    private func content(forTabID id: UUID) -> NotationsPaneContent? {
        switch id {
        case markdownTabID: return .markdown
        case previewTabID: return .preview
        default: return nil
        }
    }

    /// Shows `text` in both panes, now. For text that did not come from
    /// typing, which `MarkdownTextPane` does not report.
    private func show(_ text: String) {
        source.pane.text = text
        flushPendingRender()
    }

    /// Debounced like `MarkdownEditorController`'s preview, and for the same
    /// reason: a rendering that repaints on every character makes typing
    /// feel slow.
    private func scheduleRender() {
        pendingRender?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.flushPendingRender() }
        }
        pendingRender = work
        DispatchQueue.main.asyncAfter(deadline: .now() + MarkdownEditorController.renderDebounce, execute: work)
    }

    private func flushPendingRender() {
        pendingRender?.cancel()
        pendingRender = nil
        preview.content = source.pane.text
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
            show(notation?.content ?? "")
            source.pane.isEditable = true
        case .detached, .unavailable:
            key = nil
            notationID = nil
            show("")
            source.pane.isEditable = false
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
            if self.source.pane.text != content { self.show(content) }
        }
    }
}

extension NotationsPaneViewController: MultiTabbedViewControllerDelegate {

    /// A tab click in the single-pane frame picks which pane shows.
    public func multiTabbedViewController(
        _ controller: MultiTabbedViewController,
        didSelectTab id: UUID,
        on edge: Edge
    ) {
        guard !isRearranging, controller === singleFrame, let content = content(forTabID: id) else { return }
        choose(content: content)
    }

    /// Neither pane is ever closed, and the tabs carry no close button. A
    /// close that arrives anyway (a menu or a key) on one of two side-by-side
    /// frames leaves the other, so the pane becomes a single pane showing
    /// what is left; in a single pane the close is refused.
    public func multiTabbedViewController(
        _ controller: MultiTabbedViewController,
        didRequestCloseTab id: UUID,
        on edge: Edge
    ) {
        guard layout == .sideBySide, let closed = content(forTabID: id) else { return }
        shownContent = closed == .markdown ? .preview : .markdown
        UserSettings.notationsPaneContent.value = shownContent
        choose(layout: .singlePane)
    }

    /// File > New Tab reaches these frames first whenever the keyboard is in
    /// the pane, and they have no tabs to add: hand it on to the nearest
    /// enclosing tabbed container, the project window's.
    public func multiTabbedViewControllerNeedsNewTab(_ controller: MultiTabbedViewController) {
        var ancestor = parent
        while let candidate = ancestor {
            if let tabbed = candidate as? MultiTabbedViewController {
                tabbed.newTab(nil)
                return
            }
            ancestor = candidate.parent
        }
    }
}

/// The Markdown pane: the notation's source in a `MarkdownTextPane`, as a
/// view controller so a tab can hold it.
@MainActor
private final class NotationsSourceViewController: NSViewController {

    let pane = MarkdownTextPane(editable: true)

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        view = pane
    }
}

extension NotationsPaneViewController: PaneAccessoryProviding {

    /// The layout control, right-justified in the pane's title bar.
    public func makePaneAccessoryViews() -> [NSView] {
        [layoutBar]
    }
}

extension NotationsPaneViewController: Loggable {
    public static nonisolated let logger = makeLogger()
}
