import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage
import AgenticDeveloperHubSDKUI
import os

/// File ▸ New Git Window…: one window per repository, keyed by its canonical top
/// level, so a subdirectory and its repository's root open the same window (recipe
/// `workspace/git/git-window`).
///
/// A Git window is the project window's controller over a `.gitWindow` row, with
/// no tabs and the three panes of `GitWindowPanes`; each window's state lives in
/// its `GitWindowSession`, made by the first pane the layout asks for.
///
/// The open windows are remembered in `openRoots` and reopened at launch without
/// taking the foreground; a root that is no longer a repository is dropped. Every
/// window shares one syntax highlighter, built on the first window from the user's
/// grammars, then an extension's, then the bundled ones; without the bundled
/// resources the windows are uncoloured.
@MainActor
public final class GitWindowFeature: AppFeature {

    public enum CommandID {
        /// Asks for a folder and opens its repository's window.
        public static let open = "git.action.openWindow"
        /// Opens the window of the repository containing the path given as the one
        /// argument; anything else does nothing.
        public static let openForPath = "git.action.openWindowForPath"
    }

    private let resources: TextMateResources?
    private let userGrammarsDirectory: URL
    private let extensionGrammars: () -> (any GrammarSource)?
    private let fileTypeOverride: @Sendable (URL) -> String?
    private let client: GitClient
    private let database: ProjectDatabase
    private let windows: ProjectWindowManager
    /// The terminal panes under the commit pane; nil leaves the right column the commit alone.
    private let terminals: TerminalPaneFamily?
    /// Each open window's session, by its row's id.
    private(set) var sessions: [UUID: GitWindowSession] = [:]
    /// Each open window's toolbar verbs, by its row's id, kept beside its session:
    /// the buttons hold it weakly.
    private(set) var toolbars: [UUID: GitWindowToolbar] = [:]
    private lazy var layout: ComposableTabsLayout? = {
        do {
            return try GitWindowPanes.layout(terminals: terminals) { [unowned self] context in
                self.session(for: context)
            }
        } catch {
            Self.logger.error("The Git window layout is invalid: \(String(describing: error), privacy: .public)")
            return nil
        }
    }()

    /// Built by the first window; `nil` inside means it could not be built (logged once).
    private var sharedColoring: GitSyntaxColoring??

    private lazy var windowSet = KeyedWindowSet<ComposableTabsWindowController>(
        setting: openRoots,
        open: { [unowned self] key, activates, onClose in
            self.makeWindow(key: key, activates: activates, onClose: onClose)
        },
        bringForward: { [unowned self] controller in
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            self.windows.activateApp()
        }
    )
    private let openRoots: UserSetting<[String]>
    /// The open the last Open Git Window for Path started; nil until one is.
    private(set) var openTask: Task<Void, Never>?

    /// - Parameters:
    ///   - resources: the bundled TextMate resources; nil leaves every window uncoloured.
    ///   - userGrammarsDirectory: the user's own grammars, ahead of every other source.
    ///   - extensionGrammars: the grammars an extension contributes, read when the
    ///     highlighter is built.
    ///   - fileTypeOverride: the name of the language a file is mapped to (a File
    ///     Types display name or a language id), used only when a grammar's id or
    ///     alias matches it (`GrammarRegistry.languageID(named:)`).
    ///   - database: the projects database the windows' `.gitWindow` rows go in.
    ///   - windows: the window manager that opens them.
    ///   - terminals: the terminal panes the window offers under its commit pane.
    ///   - openRoots: where the open windows' roots are remembered.
    public init(
        commandRegistry registry: CommandRegistry,
        database: ProjectDatabase,
        windows: ProjectWindowManager = .shared,
        resources: TextMateResources?,
        userGrammarsDirectory: URL,
        extensionGrammars: @escaping () -> (any GrammarSource)?,
        fileTypeOverride: @escaping @Sendable (URL) -> String?,
        client: GitClient = .shared,
        terminals: TerminalPaneFamily? = nil,
        openRoots: UserSetting<[String]> = UserSettings.openGitWindowRoots
    ) {
        self.resources = resources
        self.userGrammarsDirectory = userGrammarsDirectory
        self.extensionGrammars = extensionGrammars
        self.fileTypeOverride = fileTypeOverride
        self.client = client
        self.database = database
        self.windows = windows
        self.terminals = terminals
        self.openRoots = openRoots
        super.init()
        registry.register(AppCommand(
            id: CommandID.open,
            title: "New Git Window…",
            category: "Git",
            run: { [weak self] _ in
                self?.chooseAndOpen()
                return nil
            }
        ))
        registry.register(AppCommand(
            id: CommandID.openForPath,
            title: "Open Git Window for Path",
            category: "Git",
            run: { [weak self] arguments in
                guard let self, let path = Self.path(from: arguments) else { return nil }
                self.openTask = Task { await self.open(path: URL(fileURLWithPath: path)) }
                return nil
            }
        ))
        menuContributions = [
            MenuContribution(
                slot: .fileNew, title: "New Git Window…",
                commandID: CommandID.open, registry: registry,
                order: 45
            )
        ]
    }

    /// Asks for a folder and opens its repository's window.
    public func chooseAndOpen() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            MainActor.assumeIsolated {
                guard let self else { return }
                Task { await self.open(path: url) }
            }
        }
    }

    /// Opens the window of the repository containing `path`, or brings forward the
    /// one already open on it.
    ///
    /// - Parameter activates: false to open (or find) the window without taking the
    ///   foreground.
    /// - Returns: the window, or nil when `path` is in no repository (logged).
    @discardableResult
    public func open(path: URL, activates: Bool = true) async -> ComposableTabsWindowController? {
        let topLevel: URL
        do {
            topLevel = try await client.topLevel(of: path)
        } catch {
            Self.logger.error("Not in a git repository: \(GitClientError.logDescription(of: error), privacy: .public)")
            return nil
        }
        let key = Self.canonical(topLevel)
        if let existing = windowSet.controller(for: key), !activates {
            return existing
        }
        return windowSet.open(key: key, activates: activates)
    }

    /// Reopens the windows that were open when the app last quit, without taking the
    /// foreground. A root that is no longer a repository is dropped.
    public func restoreOpenWindows() {
        windowSet.restore()
    }

    /// The one non-empty string `openForPath` takes; nil for anything else, which the
    /// command ignores.
    static func path(from arguments: [Any]) -> String? {
        guard arguments.count == 1, let path = arguments.first as? String, !path.isEmpty else { return nil }
        return path
    }

    /// One spelling per repository: `/tmp/x` and `/private/tmp/x` are one window.
    static func canonical(_ url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path
    }

    // MARK: - Windows

    private func makeWindow(
        key: String, activates: Bool, onClose: @escaping () -> Void
    ) -> ComposableTabsWindowController? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: key, isDirectory: &isDirectory), isDirectory.boolValue,
              FileManager.default.fileExists(atPath: (key as NSString).appendingPathComponent(".git")) else {
            Self.logger.error("Not a repository: \(key, privacy: .public)")
            return nil
        }
        guard let layout else { return nil }
        let repo: GitRepo
        do {
            repo = try row(for: URL(fileURLWithPath: key, isDirectory: true))
        } catch {
            Self.logger.error("Could not record the Git window row for \(key, privacy: .public): \(error)")
            return nil
        }
        let toolbar = GitWindowToolbar()
        guard let controller = windows.openStandaloneWindow(
            repo, layout: layout, startsLanguageServices: false, activates: activates,
            toolbarItems: toolbar.items,
            onClose: { [weak self] repo in
                self?.sessions.removeValue(forKey: repo.id)?.stop()
                self?.toolbars.removeValue(forKey: repo.id)
                onClose()
            }) else { return nil }
        // A window already open keeps the toolbar its buttons were built against.
        let liveToolbar = toolbars[repo.id] ?? toolbar
        toolbars[repo.id] = liveToolbar
        if let session = sessions[repo.id] {
            liveToolbar.session = session
            session.onRefsChange = { [weak controller] in controller?.refreshTitleBranch() }
            session.presenter = GitAlertPresenter(window: { [weak controller] in controller?.window })
            session.onOpenDirectory = { [weak self] directory in
                guard let self else { return }
                Task { await self.open(path: directory) }
            }
            Task { await session.start() }
        } else {
            Self.logger.error("The Git window on \(key, privacy: .public) made no session")
        }
        return controller
    }

    /// The session of the window `context` names, made the first time one of its
    /// panes is asked for.
    private func session(for context: ComposableTabsViewContext) -> GitWindowSession {
        if let existing = sessions[context.project.id] { return existing }
        let root = context.project.directoryURL
        let model = GitRepositoryModel(
            root: root, client: client, watcher: GitDeferredRepositoryWatcher(root: root, client: client))
        let session = GitWindowSession(model: model, client: client, coloring: coloring())
        sessions[context.project.id] = session
        return session
    }

    /// The `.gitWindow` row for `url`, inserted the first time.
    private func row(for url: URL) throws -> GitRepo {
        if let existing = try database.repo(path: url.path, kind: .gitWindow) {
            return existing
        }
        let name = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        let repo = GitRepo(path: url.path, name: name, kind: .gitWindow)
        try database.insert(repo)
        return repo
    }

    // MARK: - Highlighting

    /// The windows' shared colouring, built the first time it is asked for.
    private func coloring() -> GitSyntaxColoring? {
        if let sharedColoring { return sharedColoring }
        let built = buildColoring()
        sharedColoring = .some(built)
        return built
    }

    private func buildColoring() -> GitSyntaxColoring? {
        guard let resources else {
            Self.logger.error("No TextMate resources: Git windows are uncoloured")
            return nil
        }
        do {
            var sources: [any GrammarSource] = [DirectoryGrammarSource(directory: userGrammarsDirectory)]
            if let contributed = extensionGrammars() { sources.append(contributed) }
            sources.append(try BundledGrammarSource(resources: resources))
            let registry = GrammarRegistry(sources: sources)
            let highlighter = try SyntaxHighlighter(resources: resources, registry: registry)
            let override = fileTypeOverride
            let resolver = LanguageResolver(registry: registry) { url in
                guard let name = override(url) else { return nil }
                return registry.languageID(named: name)
            }
            return GitSyntaxColoring(
                highlighter: highlighter, resolver: resolver, registry: registry,
                theme: { CodeTheme(palette: ThemePaletteObserver.currentPalette) })
        } catch {
            let description = String(describing: error)
            Self.logger.error("Could not build the highlighter: \(description, privacy: .public)")
            return nil
        }
    }
}

extension GitWindowFeature: Loggable {
    public static nonisolated let logger = makeLogger()
}

extension UserSettings {
    /// The canonical top levels whose Git windows were open, in the order they were
    /// opened; reopened at launch.
    public static let openGitWindowRoots = UserSetting<[String]>("open_git_window_roots", default: [])
}
