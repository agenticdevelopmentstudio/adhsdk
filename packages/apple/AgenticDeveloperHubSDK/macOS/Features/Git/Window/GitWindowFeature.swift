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
/// taking the foreground; a root that is no longer a repository is dropped. The
/// rows and the remembered roots are `StandaloneWindowRows`' bookkeeping, shared
/// with the File Browser and Document windows: closing a window deletes its row
/// and saved frame, and launch deletes every row whose root is not remembered. Every
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

    /// The `.gitWindow` rows and the remembered roots.
    private let rows: StandaloneWindowRows
    /// The open the last Open Git Window for Path started; nil until one is.
    private(set) var openTask: Task<Void, Never>?
    /// Tells the user that the folder they chose in New Git Window… is in no
    /// repository; nil shows `NotInRepositoryAlert`. The open-for-path command and
    /// the branch card only log.
    private let notInRepository: (@MainActor (URL) -> Void)?
    /// The not-in-a-repository alert on screen, kept until its OK closes it.
    private var notInRepositoryAlert: NotInRepositoryAlert?
    /// Where the agent sessions shown beside commits and branches come from; nil leaves
    /// them absent. Read-only.
    private let sessionsProvider: (any GitSessionsProviding)?
    /// The user's own `gh`, shared by every window's Pull Requests section; nil leaves
    /// the section absent.
    private let gitHub: GitHubCLI?
    /// Opens an agent session by id, for every window; nil leaves the sessions shown
    /// but unclickable.
    public var onOpenAgentSession: ((String) -> Void)? {
        didSet { for session in sessions.values { session.onOpenAgentSession = onOpenAgentSession } }
    }
    /// Where the Coding Partner reviews shown beside commits come from; nil leaves them
    /// absent. Read-only: the window never writes a review.
    private let reviewsProvider: (any GitReviewsProviding)?
    /// Opens a Coding Partner review by id, for every window; nil hides the detail's
    /// "Open in Coding Partner".
    public var onOpenReview: ((String) -> Void)? {
        didSet { for session in sessions.values { session.onOpenReview = onOpenReview } }
    }

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
    ///   - notInRepository: tells the user a chosen folder is in no repository; nil
    ///     shows `NotInRepositoryAlert`.
    ///   - sessions: the agent sessions shown beside commits and branches; nil (no
    ///     daemon) leaves them absent.
    ///   - reviews: the Coding Partner reviews shown beside commits; nil (no Partner
    ///     store) leaves them absent. Read-only.
    ///   - gitHub: the `gh` the Pull Requests section reads through; nil leaves it absent.
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
        openRoots: UserSetting<[String]> = UserSettings.openGitWindowRoots,
        notInRepository: (@MainActor (URL) -> Void)? = nil,
        sessions: (any GitSessionsProviding)? = nil,
        reviews: (any GitReviewsProviding)? = nil,
        gitHub: GitHubCLI? = nil
    ) {
        self.sessionsProvider = sessions
        self.reviewsProvider = reviews
        self.gitHub = gitHub
        self.resources = resources
        self.userGrammarsDirectory = userGrammarsDirectory
        self.extensionGrammars = extensionGrammars
        self.fileTypeOverride = fileTypeOverride
        self.client = client
        self.windows = windows
        self.terminals = terminals
        self.rows = StandaloneWindowRows(kind: .gitWindow, database: database, openPaths: openRoots)
        self.notInRepository = notInRepository
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
            ),
            registerUndoCommand(in: registry)
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
                Task { await self.openChosen(url) }
            }
        }
    }

    /// Opens the folder the user chose, telling them when it is in no repository.
    @discardableResult
    func openChosen(_ folder: URL) async -> ComposableTabsWindowController? {
        let controller = await open(path: folder)
        if controller == nil {
            if let notInRepository {
                notInRepository(folder)
            } else {
                showNotInRepositoryAlert(for: folder)
            }
        }
        return controller
    }

    /// What the alert says about `folder`.
    static func notInRepositoryMessage(for folder: URL) -> String {
        let name = folder.lastPathComponent.isEmpty ? folder.path : folder.lastPathComponent
        return "\(name) is not in a Git repository"
    }

    private func showNotInRepositoryAlert(for folder: URL) {
        notInRepositoryAlert?.close()
        let alert = NotInRepositoryAlert(message: Self.notInRepositoryMessage(for: folder)) { [weak self] in
            self?.notInRepositoryAlert = nil
        }
        notInRepositoryAlert = alert
        alert.show()
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
        return openWindow(at: StandaloneWindowRows.canonical(topLevel), activates: activates)
    }

    /// Reopens the windows that were open when the app last quit, without taking the
    /// foreground. A root that is no longer a repository is dropped, and every
    /// `.gitWindow` row whose root is not about to reopen is deleted. Without a
    /// layout nothing can open, so nothing is restored and nothing is forgotten.
    public func restoreOpenWindows() {
        guard layout != nil else {
            Self.logger.error("No Git window layout: the remembered windows stay remembered")
            return
        }
        for path in rows.rememberedPaths where !Self.isRepositoryRoot(path) {
            Self.logger.error("Not a repository: \(path, privacy: .public)")
            rows.forget(path)
        }
        rows.discardForgottenRows()
        for path in rows.rememberedPaths
        where openWindow(at: URL(fileURLWithPath: path, isDirectory: true), activates: false) == nil {
            rows.forget(path)
        }
    }

    /// The one non-empty string `openForPath` takes; nil for anything else, which the
    /// command ignores.
    static func path(from arguments: [Any]) -> String? {
        guard arguments.count == 1, let path = arguments.first as? String, !path.isEmpty else { return nil }
        return path
    }

    // MARK: - Windows

    /// Whether `path` is a directory holding `.git`: a repository's top level.
    private static func isRepositoryRoot(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
            && FileManager.default.fileExists(atPath: (path as NSString).appendingPathComponent(".git"))
    }

    /// Opens the window on the canonical top level `root`, or finds the one already
    /// open on it (brought forward only when `activates`), and remembers `root`.
    private func openWindow(at root: URL, activates: Bool) -> ComposableTabsWindowController? {
        guard Self.isRepositoryRoot(root.path) else {
            Self.logger.error("Not a repository: \(root.path, privacy: .public)")
            return nil
        }
        guard let layout else { return nil }
        let repo: GitRepo
        do {
            repo = try rows.row(for: root)
        } catch {
            Self.logger.error("Could not record the Git window row for \(root.path, privacy: .public): \(error)")
            return nil
        }
        let wasOpen = windows.windowController(for: repo.id) != nil
        let toolbar = GitWindowToolbar(showsCommandLog: terminals != nil)
        guard let controller = windows.openStandaloneWindow(
            repo, layout: layout, startsLanguageServices: false, activates: activates,
            toolbarItems: toolbar.items,
            onClose: { [weak self] closed in self?.windowClosed(closed) }) else { return nil }
        rows.remember(repo.path)
        // A window already open keeps the toolbar and session wiring it was built with.
        guard !wasOpen else { return controller }
        toolbars[repo.id] = toolbar
        if let session = sessions[repo.id] {
            toolbar.session = session
            toolbar.window = controller.window
            toolbar.followUndo()
            session.onRefsChange = { [weak controller] in controller?.refreshTitleBranch() }
            session.presenter = GitAlertPresenter(window: { [weak controller] in controller?.window })
            session.onOpenDirectory = { [weak self] directory in
                guard let self else { return }
                Task { await self.open(path: directory) }
            }
            session.onRemoveDirectory = { [weak self] directory in self?.closeWindow(at: directory) }
            Task { await session.start() }
        } else {
            Self.logger.error("The Git window on \(root.path, privacy: .public) made no session")
        }
        return controller
    }

    /// Closes the window open on `root`, a removed worktree's canonical folder; nothing
    /// when none is. The close is the user's, so the root is forgotten and the row discarded.
    func closeWindow(at root: URL) {
        guard let repo = try? rows.existingRow(for: root),
              let controller = windows.windowController(for: repo.id) else { return }
        controller.window?.close()
    }

    /// The user closed `repo`'s window: its session stops, its root is forgotten,
    /// and its row and frame are deleted a turn later, once its panes have written
    /// what they write on the way out.
    private func windowClosed(_ repo: GitRepo) {
        sessions.removeValue(forKey: repo.id)?.stop()
        toolbars.removeValue(forKey: repo.id)
        rows.forget(repo.path)
        let rows = rows
        DispatchQueue.main.async { rows.discard(repo) }
    }

    /// The session of the window `context` names, made the first time one of its
    /// panes is asked for.
    private func session(for context: ComposableTabsViewContext) -> GitWindowSession {
        if let existing = sessions[context.project.id] { return existing }
        let root = context.project.directoryURL
        let model = GitRepositoryModel(
            root: root, client: client, watcher: GitDeferredRepositoryWatcher(root: root, client: client),
            reviews: reviewsProvider)
        let session = GitWindowSession(model: model, client: client, coloring: coloring(), sessions: sessionsProvider)
        session.onOpenAgentSession = onOpenAgentSession
        session.onOpenReview = onOpenReview
        if let gitHub {
            session.configurePullRequests(GitPullRequestsModel(model: model, gitHub: gitHub, client: client))
        }
        sessions[context.project.id] = session
        return session
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

/// The informational alert New Git Window… shows for a folder in no repository,
/// presented without a modal loop and without activating the app: there is no
/// window to attach a sheet to, so it is the alert's own window, ordered front
/// (made key only when presentation is not quiet), and its OK closes it.
@MainActor
final class NotInRepositoryAlert: NSObject {
    let alert = NSAlert()
    private let onClose: () -> Void

    init(message: String, onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
        alert.alertStyle = .informational
        alert.messageText = message
        let okButton = alert.addButton(withTitle: "OK")
        okButton.setAccessibilityIdentifier("git.prompt.ok")
        okButton.target = self
        okButton.action = #selector(dismiss(_:))
        alert.window.setAccessibilityIdentifier("git.prompt.failure")
        alert.layout()
    }

    func show() {
        let window = alert.window
        window.center()
        if QuietWindowPresentation.isEnabled {
            window.orderFront(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func close() {
        alert.window.orderOut(nil)
        onClose()
    }

    @objc private func dismiss(_ sender: Any?) {
        close()
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
