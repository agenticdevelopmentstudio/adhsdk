import AppKit
import OSLog
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDatabase

/// Opens a project's window. Injected rather than owned so the registry — the
/// database, the scan, the chooser — does not depend on the window layer, and
/// can be exercised without one (`dependency-injection`).
@MainActor
public protocol ProjectOpening: AnyObject {
    func openProject(_ repo: GitRepo)

    /// Closes the project's window, if it has one. Called when the project
    /// stops existing: a window still bound to a row that is about to be
    /// deleted can only fail on its next write (`fail-fast`).
    func closeProject(repoID: UUID)

    /// Opens a project window with no project in it yet.
    func openNewWindow()
}

/// The project registry feature: the list of known git repositories, and the
/// scan that keeps that list true.
///
/// A "project" here is a row, not a file. Nothing about a project lives in the
/// repository's own directory, so a repository can be renamed or moved without
/// losing its settings or its window layout.
///
/// Two stores (apps suite Phase 4, Decision 4). `registry` says which projects
/// exist — the app's own `ProjectDatabase`, or adhd's, shared by every app.
/// `windowState` is always this app's own `ProjectDatabase`: layout, panes and
/// standalone-window rows, keyed by the registry's ids. When the two differ,
/// every project the registry reports is mirrored into `windowState` under the
/// same id (`LocalProjectMirror`) before anything can open a window for it.
/// The scan stays here and writes through the registry.
@MainActor
public final class ProjectsCoordinator: AppFeature {

    /// Posted after any change to the repository list — a scan finishing, a
    /// rename, a project being opened. Carries no payload: readers ask for
    /// `repos`, which is the one representation of that knowledge (`dry`).
    public static let didChangeNotification = Notification.Name("ProjectsCoordinatorDidChange")

    /// Which projects exist.
    public let registry: any ProjectRegistry
    /// This app's own window state, and the local copy of every project row.
    public let windowState: ProjectDatabase
    /// `nil` when the registry is `windowState` itself, which then needs no
    /// copy of its own rows.
    private let mirror: LocalProjectMirror?
    /// Follows `registry.changes` for the coordinator's lifetime.
    private var registryTask: Task<Void, Never>?
    /// `loadFromRegistry()` calls awaiting the registry, and the changes the
    /// feed applied meanwhile, which each load puts back on top of its list.
    private var loadsInFlight = 0
    private var changesDuringLoads: [ProjectRegistryChange] = []
    /// A reload asked for and not yet run, so a burst of changes posts one
    /// notification.
    private var reloadScheduled = false

    /// Every project, in name order. Seeded from `windowState`'s copy, then
    /// kept as the registry reports it.
    public private(set) var repos: [GitRepo] = []
    public private(set) var isScanning = false
    /// The result of the most recent scan, for anything that wants to show it
    /// after the progress panel has gone.
    public private(set) var lastScanSummary: ProjectScanSummary?

    /// The projects to offer the user: every registered one except those the
    /// scan settings now leave out.
    ///
    /// Hidden rather than deleted. A row under a directory the user has just
    /// skipped is still a repository, and the reconciler keeps it so that its
    /// layout and settings survive; taking the directory back out brings it
    /// straight back. `repos` stays the whole registry, because restoring a
    /// window or renaming a project is about the row, not about the list.
    /// Recomputed in `reload()`, which every change to either input goes
    /// through, rather than on every read: a filter field reads it per
    /// keystroke, and each `skips` call touches the disk.
    public private(set) var listedRepos: [GitRepo] = []

    /// Shows the project picker, handed in by the host — the command palette's
    /// picker mode in the app. The registry does not know what a palette is
    /// (`dependency-injection`).
    public var presentChooser: (() -> Void)?

    /// Set only by a test or a host that wants a particular walk. Left `nil`,
    /// each scan builds its own scanner from the current settings, so editing
    /// them takes effect at once rather than on the next launch.
    private let injectedScanner: GitRepoScanner?
    private weak var opener: ProjectOpening?
    private var progressWindow: ProjectScanProgressWindow?
    private var settingObservers: [AnyObject] = []

    /// Each project's last known branches and worktrees, kept current by
    /// `startWatchingRepoState()`, so a project window can be shown from them
    /// before git has answered.
    public private(set) lazy var repoState = RepoStateRefresher(registry: registry)
    private var repoStateWatcher: RepoStateWatcher?

    /// Starts watching every listed project's `.git` directory and sweeps
    /// them all once. Called by the app, never by init: a coordinator built in
    /// a test should not start FSEvents streams and git processes.
    public func startWatchingRepoState() {
        guard repoStateWatcher == nil else { return }
        let watcher = RepoStateWatcher(refresher: repoState)
        repoStateWatcher = watcher
        watcher.watch(watchedRepos)
    }

    /// Projects only, most recently opened first, so the sweep warms the
    /// likeliest switches soonest.
    private var watchedRepos: [RepoStateWatcher.Repo] {
        listedRepos
            .filter { $0.kind == .project }
            .sorted { ($0.lastOpened ?? .distantPast) > ($1.lastOpened ?? .distantPast) }
            .map { (id: $0.id, directory: $0.url) }
    }
    /// A settings change that landed while a scan was running. The running
    /// scan walked the old settings, so it is followed by one more.
    private var rescanPending = false

    /// The ids this feature's actions answer to. Named once here rather than
    /// spelled at each of the register/contribute pairs: they are the contract
    /// `contributes.menus` (4.5) and the extension host (Stage 5) address, so a
    /// typo in one of two copies would be a silently dead menu item.
    public enum CommandID {
        public static let newProjectWindow = "projects.action.newProjectWindow"
        public static let openProject = "projects.action.openProject"
        public static let scanForProjects = "projects.action.scanForProjects"
    }

    /// - Parameter commandRegistry: Where this feature's actions are registered
    ///   so a palette, a shortcut or an extension can reach them by id.
    ///
    ///   **Required, deliberately.** A defaulted private registry would let a
    ///   caller omit the argument and still get a working menu — while the
    ///   palette silently lost this entire feature's commands, with no log, no
    ///   crash and nothing a test could observe, since a private registry is
    ///   reachable only through the closures its own menu items captured. That
    ///   is the exact silent-wrong-behaviour the rest of this design refuses
    ///   (`execute` throws rather than no-op'ing; `isEnabled(id:)` answers
    ///   `false`, not `true`, for an id nobody registered). Requiring the
    ///   parameter moves the failure to compile time, where it costs one line
    ///   to fix.
    /// - Parameters:
    ///   - registry: Which projects exist. May be `windowState` itself.
    ///   - windowState: This app's own database, for everything that is not
    ///     the list of projects.
    public init(
        registry projectRegistry: any ProjectRegistry,
        windowState: ProjectDatabase,
        scanner: GitRepoScanner? = nil,
        opener: ProjectOpening? = nil,
        commandRegistry registry: CommandRegistry
    ) throws {
        self.registry = projectRegistry
        self.windowState = windowState
        self.mirror = (projectRegistry as? ProjectDatabase) === windowState
            ? nil : LocalProjectMirror(database: windowState)
        self.injectedScanner = scanner
        self.opener = opener
        super.init()

        // The local copy answers at once; the registry's own list replaces it
        // in `start()`.
        self.repos = (try? windowState.allRepos()) ?? []
        self.listedRepos = Self.listed(repos, by: currentScanner)
        followRegistry()

        // A settings change updates the registry at once: the list drops what
        // the new settings leave out straight away (a scan would not — it keeps
        // rows that are still repositories), and a quiet scan picks up what
        // they newly cover.
        let changed: () -> Void = { [weak self] in self?.scanSettingsDidChange() }
        settingObservers = [
            UserSettingObserver(UserSettings.projectDirectories) { _ in changed() },
            UserSettingObserver(UserSettings.projectSkippedDirectories) { _ in changed() },
            UserSettingObserver(UserSettings.projectScanSkipsHiddenDirectories) { _ in changed() },
            UserSettingObserver(UserSettings.projectScanSkipsSubmodules) { _ in changed() }
        ]

        registry.register(AppCommand(
            id: CommandID.newProjectWindow,
            title: "New Coding Project Window",
            category: "Projects",
            run: { [weak self] in self?.openNewWindow() }
        ))
        registry.register(AppCommand(
            id: CommandID.openProject,
            title: "Choose Project…",
            category: "Projects",
            run: { [weak self] in self?.showProjectChooser() }
        ))
        registry.register(AppCommand(
            id: CommandID.scanForProjects,
            title: "Scan for Projects",
            category: "Projects",
            run: { [weak self] in self?.scan() }
        ))

        // The Projects menu puts Add Project Panel ▸ between orders below 100
        // and the rest (see the host's menu builder).
        self.menuContributions = [
            MenuContribution(
                slot: .projects,
                title: "New Coding Project Window",
                commandID: CommandID.newProjectWindow,
                registry: registry,
                order: 0
            ),
            MenuContribution(
                slot: .projects,
                title: "Open Project…",
                commandID: CommandID.openProject,
                registry: registry,
                order: 10,
                key: "p",
                modifiers: [.command, .option]
            ),
            MenuContribution(
                slot: .projects,
                title: "Scan for Projects",
                commandID: CommandID.scanForProjects,
                registry: registry,
                order: 100,
                isHidden: { [weak self] in self?.isScanning ?? false }
            )
        ]
    }

    /// An app that keeps its own registry: one database for both.
    public convenience init(
        database: ProjectDatabase,
        scanner: GitRepoScanner? = nil,
        opener: ProjectOpening? = nil,
        commandRegistry registry: CommandRegistry
    ) throws {
        try self.init(
            registry: database,
            windowState: database,
            scanner: scanner,
            opener: opener,
            commandRegistry: registry)
    }

    isolated deinit {
        registryTask?.cancel()
    }

    /// Set once by the host after the window layer exists — the opener and the
    /// registry would otherwise have to be constructed in the same breath.
    public func setOpener(_ opener: ProjectOpening) {
        self.opener = opener
    }

    // MARK: - AppFeature

    /// Launching scans: the registry is only as good as its last look at disk,
    /// and the alternative is an app whose project list is quietly wrong until
    /// someone thinks to refresh it.
    ///
    /// The registry's list is read first, so the scan is planned against what
    /// the registry holds rather than against a local copy that may be behind.
    public override func start() throws {
        Task { [weak self] in
            await self?.loadFromRegistry()
            self?.scan()
        }
    }

    public override func stop() {
        registryTask?.cancel()
        registryTask = nil
        try? windowState.checkpoint()
    }

    /// Stops every open project's language servers before the process exits.
    ///
    /// Awaited by the host's termination sweep, which is the only place that
    /// can wait: `stop()` is synchronous and a language server exits by way of
    /// `SubprocessChannel.terminate()`, which is not. Without this, quitting
    /// with project windows open leaves the `willCloseNotification` shutdowns
    /// racing the process exit and orphans a `sourcekit-lsp` per window.
    ///
    /// Reached through `opener` rather than `ProjectWindowManager.shared` so a
    /// host that attached its own manager gets that one. The cast is the seam
    /// on purpose: `ProjectOpening` says nothing about language servers, and
    /// widening it for this one call would push an LSP concern into the
    /// protocol the registry is tested against.
    public override func terminate() async {
        guard let windows = opener as? ProjectWindowManager else { return }
        await windows.shutdownAllLanguageServices()
    }

    // MARK: - Registry

    public func repo(id: UUID) -> GitRepo? {
        repos.first { $0.id == id }
    }

    private static func listed(_ repos: [GitRepo], by scanner: GitRepoScanner) -> [GitRepo] {
        repos.filter { !scanner.skips(path: $0.path) }
    }

    /// The scanner a scan would use right now — the injected one, or one built
    /// from the current settings so an edit takes effect at once.
    private var currentScanner: GitRepoScanner {
        injectedScanner ?? UserSettings.projectScanner()
    }

    private func scanSettingsDidChange() {
        reload()
        if isScanning {
            rescanPending = true
        } else {
            scan(showingProgress: false)
        }
    }

    /// Renames a project. The name is the user's; a scan never overwrites it.
    ///
    /// The list shows the new name at once; the registry write follows, and a
    /// write that fails puts the registry's own row back.
    public func rename(repoID: UUID, to name: String) {
        guard let original = repo(id: repoID) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != original.name else { return }
        var renamed = original
        renamed.name = trimmed
        applyLocally(.upserted(renamed))
        reload()
        Task { [weak self, registry] in
            do {
                try await registry.update(renamed)
            } catch {
                Self.logger.error("Rename failed for \(repoID.uuidString, privacy: .public): \(error)")
                let current = (try? await registry.project(id: repoID)) ?? original
                self?.applyLocally(.upserted(current))
                self?.reload()
            }
        }
    }

    public func openProject(_ repo: GitRepo) {
        recordOpened(repo)
        opener?.openProject(repo)
    }

    /// Opens a project window with no project in it — File ▸ New Project
    /// Window.
    public func openNewWindow() {
        opener?.openNewWindow()
    }

    /// Stamps `repo` as just opened, which is what the browser sorts by,
    /// without opening anything — for a caller that opens the window itself.
    public func recordOpened(_ repo: GitRepo) {
        // Off the click: the window is what was asked for, the stamp only
        // reorders the next sweep. Done on the next main-queue turn so the
        // window shows first.
        Task { [weak self, registry] in
            do {
                try await registry.markOpened(id: repo.id, at: Date())
                if let opened = try await registry.project(id: repo.id) {
                    self?.applyLocally(.upserted(opened))
                }
            } catch {
                Self.logger.error("Could not record open time: \(error)")
            }
            self?.reload()
        }
    }

    /// Shows the picker the host handed in. A host that wired none has a
    /// menu item that does nothing, which is a wiring mistake worth a log line
    /// rather than silence (`fail-fast`).
    public func showProjectChooser() {
        guard let presentChooser else {
            Self.logger.error("Choose Project… has no picker: the host never set presentChooser")
            return
        }
        presentChooser()
    }

    /// The picker's content: the project browser in chooser mode, which opens
    /// the project it is told to choose after `dismiss` has put the picker
    /// away — a window must not open behind a panel about to vanish.
    public func makeChooser(dismiss: @escaping () -> Void) -> ProjectBrowserViewController {
        let browser = ProjectBrowserViewController(coordinator: self, mode: .chooser)
        browser.onChoose = { [weak self] repo in
            dismiss()
            self?.openProject(repo)
        }
        return browser
    }

    // MARK: - Following the registry

    /// Reads the registry's whole list, mirrors it, and makes it `repos`.
    /// A registry that cannot be read leaves the local copy showing.
    ///
    /// A change the feed applies while the read is out may be newer than the
    /// list the read brings back, so each one is put back on top of it.
    func loadFromRegistry() async {
        loadsInFlight += 1
        let firstChange = changesDuringLoads.count
        defer {
            loadsInFlight -= 1
            if loadsInFlight == 0 { changesDuringLoads.removeAll() }
        }
        do {
            let projects = try await registry.projects()
            if let mirror {
                do { try mirror.sync(projects) } catch {
                    Self.logger.error("Could not mirror the project list: \(error)")
                }
            }
            repos = projects
            for change in changesDuringLoads[firstChange...] {
                applyLocally(change, recording: false)
            }
            reload()
        } catch {
            Self.logger.error("Could not read the project registry: \(error)")
        }
    }

    /// Applies every registry change — this app's own writes coming back,
    /// another app's, a scan's — to the list and the local copy.
    private func followRegistry() {
        let changes = registry.changes
        registryTask = Task { [weak self] in
            for await change in changes {
                guard let self else { return }
                self.applyLocally(change)
                self.scheduleReload()
            }
        }
    }

    /// Puts one change into `repos` and, when there is one, the local mirror.
    /// Safe to repeat: a change arrives once from the write that made it and
    /// once more from the registry's feed.
    private func applyLocally(_ change: ProjectRegistryChange, recording: Bool = true) {
        if recording, loadsInFlight > 0 { changesDuringLoads.append(change) }
        if let mirror {
            do { try mirror.apply(change) } catch {
                Self.logger.error("Could not mirror \(change.id.uuidString, privacy: .public): \(error)")
            }
        }
        switch change {
        case .upserted(let project):
            if let index = repos.firstIndex(where: { $0.id == project.id }) {
                repos[index] = project
            } else {
                repos.append(project)
            }
            repos.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .deleted(let id):
            repos.removeAll { $0.id == id }
        }
    }

    /// A new project as the scan found it, under the id and name of the local
    /// row already at its path when there is one.
    ///
    /// A shared registry that has not been given this app's projects yet
    /// (before `adhd import-kitchen`) reports none of them, so the scan
    /// finds each as new. Inserted under a fresh id, the mirror would then
    /// delete the local row at that path and its layout with it; inserted
    /// under the local id, the registry adopts the row and the layout stays.
    private func adoptingLocalIdentity(_ planned: GitRepo) -> GitRepo {
        guard mirror != nil,
              let local = try? windowState.repo(path: planned.path, kind: .project),
              local.id != planned.id else { return planned }
        return GitRepo(
            id: local.id,
            path: planned.path,
            name: local.name,
            remote: planned.remote,
            firstSeen: local.firstSeen,
            lastSeen: planned.lastSeen,
            lastOpened: local.lastOpened,
            kind: .project)
    }

    private func scheduleReload() {
        guard !reloadScheduled else { return }
        reloadScheduled = true
        Task { [weak self] in
            guard let self else { return }
            self.reloadScheduled = false
            self.reload()
        }
    }

    private func reload() {
        listedRepos = Self.listed(repos, by: currentScanner)
        repoStateWatcher?.watch(watchedRepos)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }

    // MARK: - Scanning

    /// Walks the scan roots on a background queue and reconciles the result
    /// into the database. Re-entrant calls are dropped rather than queued: two
    /// scans of the same disk produce the same answer, so the second is waste.
    public func scan(showingProgress: Bool = true) {
        guard !isScanning else { return }
        isScanning = true

        if showingProgress {
            let window = ProjectScanProgressWindow()
            window.present()
            progressWindow = window
        }

        let scanner = currentScanner
        Task.detached(priority: .utility) {
            let found = scanner.scan()
            await self.finishScan(found: found)
        }
    }

    private func finishScan(found: [ScannedGitRepo]) async {
        // The scan writes to the registry, so it plans against the registry's
        // own list. `repos` can still be the local copy `init` seeded it from
        // (a scan that beats `start()`'s first load), and planned against that
        // a project the registry has never held is an update of a row that
        // does not exist: it fails, and the project is never added. A registry
        // that cannot be read gets no writes from this scan (`fail-fast`).
        let existing: [GitRepo]
        do {
            existing = try await registry.projects()
        } catch {
            Self.logger.error("Could not read the project registry to scan into it: \(error)")
            endScan()
            return
        }
        let plan = ProjectReconciler.plan(existing: existing, scanned: found)
        var summary = plan.summary

        // Each row is applied on its own. One failed write used to abandon
        // every row after it while the summary still claimed the whole plan had
        // been applied, so the registry and what the user was told disagreed
        // (`fail-fast`: report what actually happened, per row).
        for planned in plan.inserts {
            let repo = adoptingLocalIdentity(planned)
            do {
                try await registry.insert(repo)
                applyLocally(.upserted(repo))
            } catch {
                summary.added -= 1
                Self.logger.error("Could not add \(repo.path, privacy: .public): \(error)")
            }
        }
        for repo in plan.updates {
            do {
                try await registry.update(repo)
                applyLocally(.upserted(repo))
            } catch {
                Self.logger.error("Could not update \(repo.path, privacy: .public): \(error)")
            }
        }
        // Windows close first: closing one writes to the row it belongs
        // to, which after the delete is a foreign key that no longer
        // resolves.
        for repo in plan.deletes { opener?.closeProject(repoID: repo.id) }
        for repo in plan.deletes {
            do {
                try await registry.delete(id: repo.id)
                applyLocally(.deleted(repo.id))
            } catch {
                summary.removed -= 1
                Self.logger.error("Could not remove \(repo.path, privacy: .public): \(error)")
                continue
            }
            // The rows cascade; the window frame does not — it lives in
            // `UserDefaults` under an id nothing else will ever ask for
            // again, so it is cleared here or it is leaked forever.
            let windowID = ComposableTabsWindowController.windowID(for: repo.id)
            WindowManager.shared.frames.clearSavedState(for: windowID)
            WindowManager.shared.frames.clearVisibility(for: windowID)
        }

        lastScanSummary = summary
        Self.logger.info("Scan complete: \(summary.summaryText, privacy: .public)")
        endScan()
    }

    /// Ends a scan, applied or not: the list reloads, a rescan asked for
    /// meanwhile starts, and the progress window closes.
    private func endScan() {
        isScanning = false
        reload()
        if rescanPending {
            rescanPending = false
            scan(showingProgress: false)
        }
        progressWindow?.finish()
        progressWindow = nil
    }
}

extension ProjectsCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
