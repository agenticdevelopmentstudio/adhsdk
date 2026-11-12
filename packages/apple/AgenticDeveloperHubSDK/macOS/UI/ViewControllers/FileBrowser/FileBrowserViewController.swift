import AppKit
import Combine

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKLanguage

/// A file browser — a breadcrumb naming the selection, the tree, and a filter
/// field under it — so one can be dropped into any AppKit container: a
/// document pane, a sidebar, a window.
///
/// Owns one `FileTreeManager` per root directory, and starts/stops watching with
/// the view's appearance: a browser in a hidden tab has no business running an
/// FSEvents stream and re-shelling `git status` every time a build writes.
@MainActor
public final class FileBrowserViewController: NSViewController {

    /// The roots this browser shows. A host that wants the list to outlive the
    /// pane owns this object and hands it in.
    public let directories: FileBrowserDirectories

    /// The primary root's manager. Exposed so a host can force a resync or read
    /// the detected IDE — those are questions about *the project*, which is the
    /// primary root, not about a directory someone dragged in beside it.
    public var manager: FileTreeManager { managerForPrimary }

    /// What the user has clicked. Shared rather than private so a host can
    /// drive it directly — restoring a selection, or reacting to one.
    public let selection: FileBrowserSelection

    /// What was open and what was selected last time. Shared rather than
    /// private for the same reason `selection` is: the host that persists it
    /// owns it, and a browser used alone gets one of its own that nobody reads.
    public let restoration: FileBrowserRestorationState

    /// `PaneSelectionDescribing`'s change callback. Stored here rather than in
    /// the conformance below because Swift has no stored properties in
    /// extensions, and the protocol declares it `{ get set }`.
    public var onPaneSelectionChange: (() -> Void)?

    /// Where a file the user picked in the tree should be shown — a plain
    /// click, or one of the context menu's three verbs. Forwarded straight
    /// from `tree`, whose own `onOpenRequest` is `internal`: this is the seam
    /// a host outside the module (the app, wiring the File Browser pane to the
    /// Document pane) actually reaches.
    public var onOpenRequest: ((URL, DocumentDestination) -> Void)? {
        get { tree.onOpenRequest }
        set { tree.onOpenRequest = newValue }
    }

    /// Moves the highlight onto a file an editor has come into focus showing,
    /// opening whatever folders it takes to get there. The return trip of
    /// `onOpenRequest`, and forwarded for the same reason: `tree` is internal,
    /// and the host wiring these two panes together is outside the module.
    public func reveal(_ url: URL) {
        tree.reveal(url)
    }

    /// Clears the highlight — the editor the tree is following has no file
    /// open, so there is nothing in the tree to point at.
    public func revealNothing() {
        tree.revealNothing()
    }

    /// Watches `selection` so `onPaneSelectionChange` fires for every way a
    /// file gets selected — the tree, a restore, a host setting it directly —
    /// rather than only for the clicks the tree happens to route through a
    /// delegate (`dry`).
    private var selectionObserver: AnyCancellable?

    private let excludedURL: URL
    private let config: FileTreeConfig

    /// The user's `.gitignore`-style exclusions, watched so an edit in
    /// Settings re-filters every root of this browser as it is made.
    private let exclusionsObserver: UserSettingObserver<[String]>

    /// Whether the patterns apply at all — the gear menu's Hide Excluded
    /// Content. Shared with the project's other browsers.
    public let exclusionState: FileBrowserExclusionState

    /// The matcher every root filters by: the patterns, or none of them while
    /// the reader has set them aside.
    private var exclusions: GitIgnoreMatcher {
        GitIgnoreMatcher(patterns: exclusionState.hidesExcludedContent ? exclusionsObserver.value : [])
    }

    private func applyExclusions() {
        let matcher = exclusions
        managersByRoot.values.forEach { $0.exclusions = matcher }
    }

    /// The app-wide open-document registry, threaded down to the tree so it
    /// can show a dirty indicator on a node with unsaved changes.
    private let documentStore: TextDocumentStore

    /// A status provider handed in from outside — for the root it belongs to,
    /// used instead of a freshly built one. `nil` for every browser that has
    /// no reason to share one, which is today's behaviour: a provider per root.
    private let injectedGitStatusProvider: GitStatusProvider?

    /// One manager per root, keyed by the root it scans, so rebuilding the list
    /// after an add or a remove reuses every manager that survived — a scanned
    /// tree is not rescanned because a *different* directory appeared. Internal
    /// read so a test can see which manager serves which root; write stays
    /// private — nothing outside this class may mutate it.
    private(set) var managersByRoot: [URL: FileTreeManager] = [:]
    private let roots = FileBrowserRootsModel()

    private lazy var tree = FileTreeOutlineViewController(
        roots: roots,
        directories: directories,
        selection: selection,
        restoration: restoration,
        documentStore: documentStore
    )

    /// The path of the selected node, under the pane's title bar, spelled
    /// from `~` so it says where the file is on disk, not only in the project.
    private lazy var breadcrumb = BreadcrumbView(rootURL: directories.primary, style: .homeRelative)

    /// Narrows the tree to the names that contain what is typed.
    private let filterField = ThemedSearchField(placeholder: "Filter")

    /// Tab and Shift-Tab between the filter and the list.
    private lazy var keyViewLoop = KeyViewLoop([filterField, tree.listView])

    /// Whether this pane was the active one at the last active-pane change, so
    /// the filter takes the keyboard on becoming active, not on every change.
    private var wasActivePane = false

    /// `PanePreferredThicknessProviding`'s callback. Stored here because Swift
    /// has no stored properties in extensions.
    public var onPreferredThicknessChange: ((CGFloat) -> Void)?

    /// Settings > File Browser > General's "Automatically adjust width to
    /// content".
    private let widthSettingObserver = UserSettingObserver(UserSettings.fileBrowserAdjustsWidthToContent)
    private var themeObserver: ThemePaletteObserver?
    private var isWidthUpdateScheduled = false

    private var isWatching = false
    private var hasLoaded = false
    private var cancellables = Set<AnyCancellable>()

    /// - Parameters:
    ///   - directories: The roots to show. The primary is the project itself;
    ///     the rest are the user's additions.
    ///   - excludedURL: A directory left out of the tree and the watcher. For
    ///     a document-backed browser this is the document's own package, so the
    ///     browser neither indexes nor thrashes on it.
    ///   - config: Which directory extensions are opaque packages, and the
    ///     `UserDefaults` keys backing the browser's settings.
    ///   - exclusions: The setting holding the `.gitignore`-style patterns to
    ///     leave out of the tree, anchored at each root. Watched: a change
    ///     re-filters the tree on screen at once.
    ///   - exclusionState: Whether `exclusions` applies. A project passes the
    ///     one all its browsers share; the default is a browser's own, on.
    ///   - selection: The selection this tree drives. Defaults to one of its
    ///     own, so a browser used alone needs to know nothing about it.
    ///   - documentStore: The app-wide open-document registry, threaded down
    ///     to the tree for its dirty indicator. Injected — never built here.
    ///   - gitStatusProvider: A status provider to hand to the manager for
    ///     whichever root it belongs to; `nil` (the default) keeps today's
    ///     behaviour of one freshly built provider per root.
    public init(
        directories: FileBrowserDirectories,
        excludedURL: URL,
        config: FileTreeConfig = .default,
        exclusions: UserSetting<[String]> = UserSettings.fileBrowserExcludedPatterns,
        exclusionState: FileBrowserExclusionState = FileBrowserExclusionState(),
        selection: FileBrowserSelection = FileBrowserSelection(),
        restoration: FileBrowserRestorationState = FileBrowserRestorationState(),
        documentStore: TextDocumentStore,
        gitStatusProvider: GitStatusProvider? = nil
    ) {
        self.directories = directories
        self.exclusionState = exclusionState
        self.excludedURL = excludedURL
        self.config = config
        self.exclusionsObserver = UserSettingObserver(exclusions)
        self.selection = selection
        self.restoration = restoration
        self.documentStore = documentStore
        self.injectedGitStatusProvider = gitStatusProvider
        super.init(nibName: nil, bundle: nil)

        exclusionsObserver.onChange = { [weak self] _ in self?.applyExclusions() }
        // `@Published` publishes from `willSet`; the hop lets the new value land
        // before `exclusions` reads it back.
        exclusionState.$hidesExcludedContent
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyExclusions() }
            .store(in: &cancellables)

        rebuildManagers()
        directories.$additional
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.rebuildManagers() }
            .store(in: &cancellables)

        // `@Published` publishes from `willSet`, so a synchronous sink reads
        // the *previous* node back out of `selection` — the footer would name
        // the file clicked before this one. Hopping to the run loop lets the
        // store complete first. `removeDuplicates` keeps a re-click on the row
        // that is already selected from re-rendering the whole path, and
        // `dropFirst` drops the value `@Published` replays on subscribe: a
        // report made before the host installs `onPaneSelectionChange` would
        // otherwise surface one turn late, as a change nobody asked about.
        selectionObserver = selection.$selectedNode
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.onPaneSelectionChange?() }
    }

    /// A browser over a single directory, with nothing to add to or remove.
    public convenience init(
        rootURL: URL,
        excludedURL: URL,
        config: FileTreeConfig = .default,
        exclusions: UserSetting<[String]> = UserSettings.fileBrowserExcludedPatterns,
        selection: FileBrowserSelection = FileBrowserSelection(),
        restoration: FileBrowserRestorationState = FileBrowserRestorationState(),
        documentStore: TextDocumentStore,
        gitStatusProvider: GitStatusProvider? = nil
    ) {
        self.init(
            directories: FileBrowserDirectories(primary: rootURL),
            excludedURL: excludedURL,
            config: config,
            exclusions: exclusions,
            selection: selection,
            restoration: restoration,
            documentStore: documentStore,
            gitStatusProvider: gitStatusProvider
        )
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)
        container.frame = NSRect(x: 0, y: 0, width: 260, height: 400)

        addChild(tree)
        let treeView = tree.view
        treeView.translatesAutoresizingMaskIntoConstraints = false

        breadcrumb.translatesAutoresizingMaskIntoConstraints = false
        breadcrumb.setContentHuggingPriority(.defaultLow, for: .horizontal)
        breadcrumb.setAccessibilityIdentifier("file-browser.breadcrumb")

        let topDivider = Self.makeSeparator()
        let bottomDivider = Self.makeSeparator()
        let filterBar = makeFilterBar()

        let strips: [NSView] = [breadcrumb, topDivider, treeView, bottomDivider, filterBar]
        strips.forEach { container.addSubview($0) }

        var constraints: [NSLayoutConstraint] = [
            breadcrumb.topAnchor.constraint(equalTo: container.topAnchor),
            breadcrumb.heightAnchor.constraint(equalToConstant: Self.breadcrumbHeight),
            topDivider.topAnchor.constraint(equalTo: breadcrumb.bottomAnchor),
            treeView.topAnchor.constraint(equalTo: topDivider.bottomAnchor),
            bottomDivider.topAnchor.constraint(equalTo: treeView.bottomAnchor),
            filterBar.topAnchor.constraint(equalTo: bottomDivider.bottomAnchor),
            filterBar.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ]
        for strip in strips {
            constraints.append(strip.leadingAnchor.constraint(equalTo: container.leadingAnchor))
            constraints.append(strip.trailingAnchor.constraint(equalTo: container.trailingAnchor))
        }
        NSLayoutConstraint.activate(constraints)

        view = container
    }

    private static let breadcrumbHeight: CGFloat = 24

    private static func makeSeparator() -> NSBox {
        let divider = NSBox()
        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        return divider
    }

    /// The filter field under the tree, inset the way the Projects shelf
    /// insets its own search field, so the two read as the same control.
    private func makeFilterBar() -> NSView {
        let bar = ThemedBackgroundView(role: .surface)
        bar.translatesAutoresizingMaskIntoConstraints = false

        filterField.delegate = self
        filterField.target = self
        filterField.action = #selector(filterChanged(_:))
        // Filter as the reader types, every keystroke, rather than on Return.
        filterField.sendsWholeSearchString = false
        filterField.sendsSearchStringImmediately = true
        filterField.controlSize = .small
        filterField.setAccessibilityIdentifier("file-browser.filter")
        filterField.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(filterField)

        NSLayoutConstraint.activate([
            filterField.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 8),
            filterField.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -8),
            filterField.topAnchor.constraint(equalTo: bar.topAnchor, constant: 6),
            filterField.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -6)
        ])
        return bar
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // The breadcrumb names the selected node, and choosing in it is the
        // same as a click in the tree (`dry`). The hop lets `@Published`'s
        // `willSet` land before the strip reads the node back.
        selection.$selectedNode
            .receive(on: RunLoop.main)
            .sink { [weak self] node in self?.breadcrumb.fileURL = node?.url }
            .store(in: &cancellables)
        breadcrumb.onSelect = { [weak self] url in self?.tree.onOpenRequest?(url, .current) }
        // The crumb menus leave out what the tree leaves out, Hide Excluded
        // Content included, anchored at the root the file sits under.
        breadcrumb.filter = { [weak self] in
            guard let self else { return .none }
            let file = self.selection.selectedNode?.url.standardizedFileURL.path ?? ""
            let root = ([self.directories.primary] + self.directories.additional)
                .first { file.hasPrefix($0.standardizedFileURL.path + "/") } ?? self.directories.primary
            return FileTreeFilter(rootURL: root, matcher: self.exclusions)
        }

        // Synchronous on purpose: the active pane posts from its mouse-down
        // monitor *before* the click is delivered, and `NSApp.currentEvent` is
        // only that mouse-down while the post is still on the stack.
        NotificationCenter.default
            .publisher(for: ComposableTabsActivePane.didChangeNotification)
            .sink { [weak self] note in self?.activePaneDidChange(in: note.object as? NSWindow) }
            .store(in: &cancellables)

        tree.onRowsChanged = { [weak self] in self?.scheduleWidthUpdate() }
        widthSettingObserver.onChange = { [weak self] _ in self?.scheduleWidthUpdate() }
        // The rows' fonts come from the palette, so a text-size change is a
        // width change.
        themeObserver = ThemePaletteObserver(host: view) { [weak self] _ in self?.scheduleWidthUpdate() }
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        keyViewLoop.refresh()
        wasActivePane = ComposableTabsActivePane.shared.isInActivePane(view)
        scheduleWidthUpdate()
    }

    // MARK: - Filter

    @objc private func filterChanged(_ sender: NSSearchField) {
        tree.setFilter(sender.stringValue)
    }

    /// Puts the keyboard in the filter field. Internal so a test can drive it.
    func focusFilter() {
        view.window?.makeFirstResponder(filterField)
    }

    /// The filter takes the keyboard whenever this pane becomes the active
    /// one — by the keyboard, a menu, a tab switch — except when the reader
    /// clicked into the list itself, which already says where they want to be.
    private func activePaneDidChange(in window: NSWindow?) {
        guard isViewLoaded, let window, window === view.window else { return }
        let isActive = ComposableTabsActivePane.shared.isInActivePane(view)
        defer { wasActivePane = isActive }
        guard isActive, !wasActivePane else { return }
        if let event = NSApp.currentEvent, Self.isMouseDown(event), event.window === window {
            let point = tree.view.convert(event.locationInWindow, from: nil)
            if tree.view.bounds.contains(point) { return }
        }
        if let responder = window.firstResponder as? NSView, responder.isDescendant(of: view) { return }
        // After the click or key that activated the pane has been handled, so
        // whatever it does with the first responder does not undo this.
        DispatchQueue.main.async { [weak self] in self?.focusFilter() }
    }

    private static func isMouseDown(_ event: NSEvent) -> Bool {
        [.leftMouseDown, .rightMouseDown, .otherMouseDown].contains(event.type)
    }

    // MARK: - Width

    /// Asks the host for the width the visible rows need, once per turn of the
    /// run loop however many expansions, reloads and keystrokes asked for it.
    private func scheduleWidthUpdate() {
        guard !isWidthUpdateScheduled else { return }
        isWidthUpdateScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isWidthUpdateScheduled = false
            guard self.widthSettingObserver.value, self.isViewLoaded, self.view.window != nil else { return }
            self.onPreferredThicknessChange?(self.tree.preferredContentWidth())
        }
    }

    public override func viewWillAppear() {
        super.viewWillAppear()
        // `loadInitial()` reads each root's top level; doing it once keeps a
        // tab switch from re-reading it.
        if !hasLoaded {
            hasLoaded = true
            managersByRoot.values.forEach { $0.loadInitial() }
        }
        startWatching()
    }

    public override func viewDidDisappear() {
        super.viewDidDisappear()
        stopWatching()
    }

    // MARK: - Directories

    /// Rebuilds the manager list to match `directories.all`, reusing the
    /// managers whose roots are still listed and tearing down the rest.
    private func rebuildManagers() {
        let wanted = directories.all
        var rebuilt: [URL: FileTreeManager] = [:]
        var ordered: [FileTreeManager] = []

        for root in wanted {
            let manager = managersByRoot[root] ?? makeManager(for: root)
            rebuilt[root] = manager
            ordered.append(manager)
        }

        for (root, manager) in managersByRoot where rebuilt[root] == nil {
            manager.stopWatching()
            // A pane's selection must not outlive the directory it came from,
            // or the viewer keeps showing a file the tree no longer lists.
            if let selected = selection.selectedNode?.url,
               selected.path == root.path || selected.path.hasPrefix(root.path + "/") {
                selection.selectedNode = nil
            }
            // Nor may the selection keep aiming at a root that is gone — which
            // it can be because *another* pane of the same project removed it.
            if selection.selectedRoot == root { selection.selectedRoot = nil }
        }

        managersByRoot = rebuilt
        roots.managers = ordered

        // A directory added while the browser is already on screen has missed
        // both `viewWillAppear` hooks, so it gets them here.
        if hasLoaded {
            for manager in ordered where manager.rootNode == nil {
                manager.loadInitial()
            }
        }
        if isWatching {
            ordered.forEach { $0.startWatching() }
        }
    }

    private func makeManager(for root: URL) -> FileTreeManager {
        // `resolvingSymlinksInPath()`, not `standardizedFileURL`, for the
        // reason `ProjectCheckout.swift:12` documents: the injected provider's
        // `repoRoot` is a resolved checkout directory, and this root is
        // whatever the window was opened with. A lexical comparison misses
        // whenever a symlink stands between them, and the miss is silent — the
        // pane quietly builds a second, uninstrumented provider of its own.
        let provider = injectedGitStatusProvider.flatMap { candidate in
            candidate.repoRoot.resolvingSymlinksInPath() == root.resolvingSymlinksInPath() ? candidate : nil
        }
        return FileTreeManager(
            repoRootURL: root,
            packageURL: excludedURL,
            config: config,
            exclusions: exclusions,
            gitStatusProvider: provider
        )
    }

    private var managerForPrimary: FileTreeManager {
        // `rebuildManagers()` runs in `init` and always inserts the primary, so
        // a miss here means the invariant broke — say so rather than papering
        // over it with a throwaway manager (`fail-fast`).
        guard let manager = managersByRoot[directories.primary] else {
            preconditionFailure("No manager for the primary root \(directories.primary.path)")
        }
        return manager
    }

    // MARK: - Watching

    private func startWatching() {
        guard !isWatching else { return }
        isWatching = true
        managersByRoot.values.forEach { $0.startWatching() }
    }

    private func stopWatching() {
        guard isWatching else { return }
        isWatching = false
        managersByRoot.values.forEach { $0.stopWatching() }
    }
}

extension FileBrowserViewController: PaneContentTeardown {
    /// Closing the pane ends the FSEvents streams and the debounced git/IDE
    /// work, whether or not the view ever got a `viewDidDisappear`.
    public func paneContentWillBeDiscarded() {
        stopWatching()
    }
}

extension FileBrowserViewController: PaneMenuProviding {
    /// Hide Excluded Content: on, the Settings > File Browser > Excluded
    /// patterns apply; off, the tree shows everything they hide, for as long
    /// as the reader needs to see it. Per project, and remembered.
    public func makePaneMenuItems() -> [NSMenuItem] {
        let item = NSMenuItem(
            title: "Hide Excluded Content",
            action: #selector(toggleHidesExcludedContent),
            keyEquivalent: ""
        )
        item.target = self
        item.state = exclusionState.hidesExcludedContent ? .on : .off
        item.accessibilityID("pane.options.hide-excluded")
        return [item]
    }

    @objc private func toggleHidesExcludedContent() {
        exclusionState.hidesExcludedContent.toggle()
    }
}

/// Reports the width the visible rows need, which the pane hosting this
/// browser turns into a divider position while the setting is on. The
/// callback itself is the stored `onPreferredThicknessChange` above.
extension FileBrowserViewController: PanePreferredThicknessProviding {}

extension FileBrowserViewController: NSSearchFieldDelegate {
    public func controlTextDidChange(_ obj: Notification) {
        tree.setFilter(filterField.stringValue)
    }

    /// Down arrow leaves the field for the list, the way it does from the
    /// Projects shelf's search field.
    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard control === filterField, commandSelector == #selector(NSResponder.moveDown(_:)) else { return false }
        tree.focusList()
        return true
    }
}

extension FileBrowserViewController: PaneSelectionDescribing {
    /// The selected file's name, not its path: the footer already names the
    /// project and the pane in the segments before this one, and a repo-rooted
    /// path repeated there would push the part the user is looking for off the
    /// truncation.
    public var paneSelectionDescription: String? {
        selection.selectedNode?.name
    }
}

/// The managers the pane draws, as one observable list.
///
/// The tree cannot observe a dictionary owned by a view controller, and making
/// the controller itself observable would publish far more than the one fact
/// the tree needs (`separation-of-concerns`).
@MainActor
final class FileBrowserRootsModel: ObservableObject {
    @Published var managers: [FileTreeManager] = []
}
