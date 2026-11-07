import XCTest
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class BrowserJarTests: XCTestCase {

    private var tempRoot: URL!
    private var madeStoreIDs: Set<UUID> = []

    override func setUp() async throws {
        try await super.setUp()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("browser-jar-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        // Best effort: a store this test made is the test process's to clean.
        for id in madeStoreIDs {
            try? await WKWebsiteDataStore.remove(forIdentifier: id)
        }
        madeStoreIDs = []
        try? FileManager.default.removeItem(at: tempRoot)
        try await super.tearDown()
    }

    // MARK: - Fixtures

    private var databasePath: String { tempRoot.appendingPathComponent("Test.db").path }

    private func makeDatabase() throws -> ProjectDatabase {
        try ProjectDatabase(path: databasePath)
    }

    private func registerRepo(in database: ProjectDatabase) throws -> GitRepo {
        let repo = GitRepo(path: tempRoot.path, name: "Test")
        try database.insert(repo)
        return repo
    }

    private func makeSettings() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    private func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    private func context(
        node: UUID = UUID(),
        repoID: UUID,
        worktree: String,
        jars: BrowserJarRegistry?
    ) -> BrowserPaneContext {
        BrowserPaneContext(
            paneNodeID: node, projectID: repoID, projectName: "Test", worktreePath: worktree, jars: jars
        )
    }

    private func resolve(
        _ jar: BrowserStorageJar,
        _ context: BrowserPaneContext,
        in registry: BrowserJarRegistry
    ) -> BrowserJarRegistry.Resolution {
        let resolution = registry.resolve(jar, context: context, label: "Browser")
        if let id = resolution.jarID { madeStoreIDs.insert(id) }
        return resolution
    }

    private func standardized(_ path: String) -> String {
        LiveBrowserPane.standardizedPath(path)
    }

    private func browserLeaf(_ id: UUID = UUID()) -> LayoutNode {
        .leaf(id: id, contentType: .browser)
    }

    /// A moment past the reconciler's grace period for new jars.
    private var later: Date { Date().addingTimeInterval(BrowserJarReconciler.newJarGracePeriod + 1) }

    // MARK: - Schema

    func testMigrationCreatesBrowserJarsIdempotently() throws {
        let first = try makeDatabase()
        XCTAssertEqual(try first.schemaVersion(), 5)
        let record = BrowserJarRecord(kind: .worktree, repoID: UUID(), worktreePath: "/tmp/wt", paneNodeID: nil)
        try first.insertBrowserJar(record)

        let second = try makeDatabase()
        XCTAssertEqual(try second.schemaVersion(), 5)
        XCTAssertEqual(try second.allBrowserJars(), [record])
    }

    /// Killed after the table was made and before version 5 was recorded: the
    /// next open re-runs the migration, which must find its own work and go on.
    func testMigrationRecoversFromACrashBeforeRecordingItsVersion() throws {
        let first = try makeDatabase()
        let record = BrowserJarRecord(kind: .pane, repoID: UUID(), worktreePath: "/tmp/wt", paneNodeID: UUID())
        try first.insertBrowserJar(record)
        try first.execute("DELETE FROM schema_migrations WHERE version = 5")
        XCTAssertEqual(try first.schemaVersion(), 4)

        let reopened = try makeDatabase()
        XCTAssertEqual(try reopened.schemaVersion(), 5)
        XCTAssertEqual(try reopened.allBrowserJars(), [record])
    }

    /// Browser panes saved before jars existed used the shared store; the
    /// upgrade gives each a per-pane override that keeps it there, so no one
    /// is signed out by the upgrade (spec section 4, "Upgrade").
    func testAnUpgradeKeepsExistingBrowserPanesOnTheSharedJar() throws {
        let database = try makeDatabase()
        let repo = try registerRepo(in: database)
        let node = UUID()
        let tab = TabRecord(title: "main", root: browserLeaf(node))
        try database.saveTabs([tab], activeTabID: tab.id, enabledEdges: [.top], repoID: repo.id)
        // Back to a file from before jars: no table, no version 5.
        try database.execute("DROP TABLE browser_jars")
        try database.execute("DELETE FROM schema_migrations WHERE version = 5")

        let upgraded = try makeDatabase()
        XCTAssertEqual(try upgraded.schemaVersion(), 5)
        let live = pane(node, repo: repo)
        let overrides = PaneStateSettingsStorageProvider(store: DatabaseStateStore(
            database: upgraded, repoID: repo.id, nodeID: node, prefix: ComposableTabsViewRegistry.browserStatePrefix
        ))
        XCTAssertTrue(overrides.contains(UserSettings.browserPrivacyStorageJar), "written as the sheet writes it")
        XCTAssertEqual(overrides.get(UserSettings.browserPrivacyStorageJar), .global)
        XCTAssertEqual(
            BrowserJarReconciler.effectiveJar(of: live, database: upgraded, settings: makeSettings()), .global
        )

        // A second run finds its own work: one name in the index, the value kept.
        try upgraded.keepExistingBrowserPanesOnTheSharedJar()
        let index = try upgraded.paneState(
            repoID: repo.id, nodeID: node, key: ComposableTabsViewRegistry.browserStatePrefix + "settings.__keys"
        )
        XCTAssertEqual(index, "[\"\(BrowserStorageJar.settingName)\"]")
    }

    /// A fresh database has no panes to keep, so a pane made in it gets the
    /// setting's default, a jar of its own.
    func testAFreshDatabaseLeavesNewPanesOnTheirOwnJar() throws {
        let database = try makeDatabase()
        let repo = try registerRepo(in: database)
        let node = UUID()
        let tab = TabRecord(title: "main", root: browserLeaf(node))
        try database.saveTabs([tab], activeTabID: tab.id, enabledEdges: [.top], repoID: repo.id)

        let reopened = try makeDatabase()
        let overrides = PaneStateSettingsStorageProvider(store: DatabaseStateStore(
            database: reopened, repoID: repo.id, nodeID: node, prefix: ComposableTabsViewRegistry.browserStatePrefix
        ))
        XCTAssertFalse(overrides.contains(UserSettings.browserPrivacyStorageJar))
        XCTAssertEqual(
            BrowserJarReconciler.effectiveJar(of: pane(node, repo: repo), database: reopened, settings: makeSettings()),
            .pane
        )
    }

    func testTheSchemaRefusesDuplicateJarsAndUnknownKinds() throws {
        let database = try makeDatabase()
        let repoID = UUID()
        let node = UUID()
        try database.insertBrowserJar(
            BrowserJarRecord(kind: .worktree, repoID: repoID, worktreePath: "/a", paneNodeID: nil)
        )
        XCTAssertThrowsError(try database.insertBrowserJar(
            BrowserJarRecord(kind: .worktree, repoID: repoID, worktreePath: "/a", paneNodeID: nil)
        ), "one worktree jar per worktree")
        // A second worktree elsewhere, and the same path in another project, are fine.
        XCTAssertNoThrow(try database.insertBrowserJar(
            BrowserJarRecord(kind: .worktree, repoID: repoID, worktreePath: "/b", paneNodeID: nil)
        ))
        XCTAssertNoThrow(try database.insertBrowserJar(
            BrowserJarRecord(kind: .worktree, repoID: UUID(), worktreePath: "/a", paneNodeID: nil)
        ))
        try database.insertBrowserJar(
            BrowserJarRecord(kind: .pane, repoID: repoID, worktreePath: "/a", paneNodeID: node)
        )
        XCTAssertThrowsError(try database.insertBrowserJar(
            BrowserJarRecord(kind: .pane, repoID: repoID, worktreePath: "/a", paneNodeID: node)
        ), "one jar per pane")
        // Many pane jars share a worktree: the worktree index is partial.
        XCTAssertNoThrow(try database.insertBrowserJar(
            BrowserJarRecord(kind: .pane, repoID: repoID, worktreePath: "/a", paneNodeID: UUID())
        ))
        XCTAssertThrowsError(try database.execute("""
            INSERT INTO browser_jars (id, kind, repo_id, worktree_path, created_at)
            VALUES ('\(UUID().uuidString)', 'global', '\(repoID.uuidString)', '/a', 0)
        """), "the global jar has no row")
    }

    func testRecordsRoundTripAndRename() throws {
        let database = try makeDatabase()
        let repoID = UUID()
        let worktree = BrowserJarRecord(
            kind: .worktree, repoID: repoID, worktreePath: "/a", paneNodeID: nil, label: "a"
        )
        let pane = BrowserJarRecord(
            kind: .pane, repoID: repoID, worktreePath: "/a", paneNodeID: UUID(), label: "Browser"
        )
        try database.insertBrowserJar(pane)
        try database.insertBrowserJar(worktree)
        XCTAssertEqual(try database.browserJars(repoID: repoID).map(\.id), [worktree.id, pane.id])
        XCTAssertEqual(try database.browserJar(worktreeOf: repoID, path: "/a"), worktree)
        XCTAssertEqual(try database.browserJar(pane: pane.paneNodeID!), pane)

        try database.updateBrowserJarLabel(id: pane.id, label: "Docs")
        XCTAssertEqual(try database.browserJar(pane: pane.paneNodeID!)?.label, "Docs")
        try database.deleteBrowserJar(id: pane.id)
        XCTAssertNil(try database.browserJar(pane: pane.paneNodeID!))
        XCTAssertEqual(try database.allBrowserJars(), [worktree])
    }

    /// Only browser leaves count, each under the worktree its tab names, or
    /// the project's own folder when the tab names none.
    func testLiveBrowserPanesFollowTheSavedLayout() throws {
        let database = try makeDatabase()
        let repo = try registerRepo(in: database)
        let inWorktree = UUID()
        let inProject = UUID()
        let worktree = tempRoot.appendingPathComponent("wt-feature", isDirectory: true)
        let first = TabRecord(
            title: "feature",
            root: .split(
                orientation: .horizontal,
                first: browserLeaf(inWorktree),
                second: .leaf(contentType: ComposableTabsViewID("test.editor"))
            ),
            workingDirectory: worktree
        )
        let second = TabRecord(title: "main", root: browserLeaf(inProject))
        try database.saveTabs([first, second], activeTabID: first.id, enabledEdges: [.top], repoID: repo.id)

        let live = Set(try database.liveBrowserPanes())
        XCTAssertEqual(live, [
            LiveBrowserPane(nodeID: inWorktree, repoID: repo.id, worktreePath: standardized(worktree.path)),
            LiveBrowserPane(nodeID: inProject, repoID: repo.id, worktreePath: standardized(repo.path))
        ])
        XCTAssertEqual(try database.livePaneNodeIDs(), [inWorktree, inProject])
    }

    // MARK: - Registry

    func testPaneJarIsCreatedOnceAndReused() throws {
        let database = try makeDatabase()
        let registry = BrowserJarRegistry(database: database)
        let pane = context(repoID: UUID(), worktree: "/tmp/wt", jars: registry)

        let first = resolve(.pane, pane, in: registry)
        let again = resolve(.pane, pane, in: registry)
        XCTAssertEqual(first.jar, .pane)
        XCTAssertNotNil(first.jarID)
        XCTAssertEqual(first.jarID, again.jarID)
        XCTAssertEqual(first.dataStore.identifier, first.jarID)
        XCTAssertEqual(try database.allBrowserJars().count, 1)
        XCTAssertEqual(registry.jarID(for: .pane, context: pane), first.jarID)

        // A relaunch: a new registry over the same file finds the same jar.
        let relaunched = BrowserJarRegistry(database: try makeDatabase())
        XCTAssertEqual(resolve(.pane, pane, in: relaunched).jarID, first.jarID)
    }

    func testWorktreeJarIsSharedByPanesOfOneWorktree() throws {
        let registry = BrowserJarRegistry(database: try makeDatabase())
        let repoID = UUID()
        let one = resolve(.worktree, context(repoID: repoID, worktree: "/tmp/wt", jars: registry), in: registry)
        let two = resolve(.worktree, context(repoID: repoID, worktree: "/tmp/wt/", jars: registry), in: registry)
        XCTAssertEqual(one.jar, .worktree)
        XCTAssertNotNil(one.jarID)
        XCTAssertEqual(one.jarID, two.jarID, "two panes, and two spellings of one path, are one jar")
        XCTAssertEqual(registry.records(repoID: repoID).map(\.label), ["wt"])
    }

    func testWorktreeJarsDifferPerWorktree() throws {
        let registry = BrowserJarRegistry(database: try makeDatabase())
        let repoID = UUID()
        let main = resolve(.worktree, context(repoID: repoID, worktree: "/tmp/main", jars: registry), in: registry)
        let featureContext = context(repoID: repoID, worktree: "/tmp/feature", jars: registry)
        let feature = resolve(.worktree, featureContext, in: registry)
        XCTAssertNotNil(main.jarID)
        XCTAssertNotNil(feature.jarID)
        XCTAssertNotEqual(main.jarID, feature.jarID)
    }

    func testGlobalUsesTheDefaultStoreAndAnUnmakeableJarFailsClosed() throws {
        let registry = BrowserJarRegistry(database: try makeDatabase())
        let global = resolve(.global, context(repoID: UUID(), worktree: "/tmp/wt", jars: registry), in: registry)
        XCTAssertEqual(global.jar, .global)
        XCTAssertNil(global.jarID)
        XCTAssertTrue(global.dataStore === WKWebsiteDataStore.default())

        // A jar that cannot be made fails closed, onto a store of its own.
        for jar in [BrowserStorageJar.pane, .worktree] {
            let detached = resolve(jar, .detached, in: registry)
            XCTAssertEqual(detached.jar, jar)
            XCTAssertNil(detached.jarID)
            XCTAssertNotNil(detached.fallbackReason)
            XCTAssertFalse(detached.dataStore.isPersistent)
            XCTAssertFalse(detached.dataStore === WKWebsiteDataStore.default(), "never the shared store")
            XCTAssertFalse(registry.canIsolate(jar, context: .detached))
        }
    }

    func testAPaneWhoseJarCannotBeMadeGetsANonPersistentStoreAndLogsIt() throws {
        let registry = BrowserJarRegistry(database: try makeDatabase())
        let settings = makeSettings()
        settings.set(BrowserStorageJar.pane, for: UserSettings.browserPrivacyStorageJar)
        let noNode = BrowserPaneContext(
            paneNodeID: nil, projectID: UUID(), projectName: "Test", worktreePath: "/tmp/wt", jars: registry
        )
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings, context: noNode)
        let store = pane.webView.configuration.websiteDataStore
        XCTAssertFalse(store.isPersistent)
        XCTAssertFalse(store === WKWebsiteDataStore.default())
        XCTAssertTrue(pane.resolvedJar.isFallback)
        XCTAssertTrue(pane.resolvedJar.isOwnedByPane)
        XCTAssertEqual(registry.jarIDsInUse, [])
        XCTAssertEqual(BrowserSettingsPanelViewController.jarLabel(for: pane), "This Pane")
        XCTAssertTrue(pane.eventLog.entries.contains { $0.channel == "settings" && $0.event == "jarFallback" })

        pane.rebuildWebView()
        XCTAssertFalse(pane.webView.configuration.websiteDataStore.isPersistent)
        XCTAssertEqual(pane.eventLog.entries.filter { $0.event == "jarFallback" }.count, 2)
        pane.paneContentWillBeDiscarded()
    }

    func testPrivateBrowsingWinsOverJar() throws {
        let database = try makeDatabase()
        let registry = BrowserJarRegistry(database: database)
        let settings = makeSettings()
        settings.set(true, for: UserSettings.browserPrivateBrowsing)
        settings.set(BrowserStorageJar.pane, for: UserSettings.browserPrivacyStorageJar)

        let pane = BrowserPaneViewController(
            store: EphemeralPaneStateStore(),
            settings: settings,
            context: context(repoID: UUID(), worktree: "/tmp/wt", jars: registry)
        )
        XCTAssertFalse(pane.webView.configuration.websiteDataStore.isPersistent)
        XCTAssertNil(pane.resolvedJar.jar)
        XCTAssertEqual(try database.allBrowserJars(), [], "a private pane makes no jar")
        pane.paneContentWillBeDiscarded()
    }

    func testAPaneIsBuiltOnItsJarAndHoldsItWhileOpen() throws {
        let database = try makeDatabase()
        let registry = BrowserJarRegistry(database: database)
        let pane = BrowserPaneViewController(
            store: EphemeralPaneStateStore(),
            settings: makeSettings(),
            context: context(repoID: UUID(), worktree: "/tmp/wt", jars: registry)
        )
        let jarID = try XCTUnwrap(pane.resolvedJar.jarID)
        madeStoreIDs.insert(jarID)
        XCTAssertEqual(pane.resolvedJar.jar, .pane, "a pane jar is the default")
        XCTAssertEqual(pane.webView.configuration.websiteDataStore.identifier, jarID)
        XCTAssertEqual(registry.jarIDsInUse, [jarID])

        pane.paneContentWillBeDiscarded()
        XCTAssertEqual(registry.jarIDsInUse, [])
    }

    // MARK: - Rebuild

    func testARebuiltWebViewTakesBackTheFocusTheOldOneHad() throws {
        let pane = BrowserPaneViewController(
            store: EphemeralPaneStateStore(),
            settings: makeSettings(),
            context: context(repoID: UUID(), worktree: "/tmp/wt", jars: nil)
        )
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 100, height: 22))
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        container.addSubview(field)
        pane.view.frame = NSRect(x: 0, y: 40, width: 400, height: 260)
        container.addSubview(pane.view)
        let window = NSWindow(
            contentRect: container.frame, styleMask: [.titled], backing: .buffered, defer: true
        )
        window.contentView = container
        func pageHasFocus() -> Bool {
            guard let responder = window.firstResponder as? NSView else { return false }
            return responder === pane.webView || responder.isDescendant(of: pane.webView)
        }

        // The page had it: the new page gets it.
        XCTAssertTrue(window.makeFirstResponder(pane.webView))
        var old = pane.webView
        pane.rebuildWebView()
        XCTAssertFalse(pane.webView === old)
        XCTAssertTrue(pageHasFocus())

        // Something else had it: the rebuild leaves it there.
        XCTAssertTrue(window.makeFirstResponder(field))
        pane.rebuildWebView()
        XCTAssertFalse(pageHasFocus())

        // A paused pane's page takes a focus nothing else holds...
        pane.setEventsPaused(true)
        XCTAssertTrue(window.makeFirstResponder(nil))
        old = pane.webView
        pane.rebuildWebView()
        XCTAssertFalse(pane.webView === old)
        XCTAssertTrue(pageHasFocus())

        // ...but never pulls it out of another view, such as a terminal.
        XCTAssertTrue(window.makeFirstResponder(field))
        pane.rebuildWebView()
        XCTAssertFalse(pageHasFocus())
        pane.paneContentWillBeDiscarded()
    }

    func testAGlobalJarChangeRebuildsAPaneThatFollowsIt() throws {
        let registry = BrowserJarRegistry(database: try makeDatabase())
        let global = makeSettings()
        let layered = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: EphemeralPaneStateStore()),
            fallback: global
        )
        let pane = BrowserPaneViewController(
            store: EphemeralPaneStateStore(),
            settings: layered,
            context: context(repoID: UUID(), worktree: "/tmp/wt", jars: registry)
        )
        _ = pane.view
        let automation = pane.automation
        let before = pane.webView
        if let id = pane.resolvedJar.jarID { madeStoreIDs.insert(id) }

        global.set(BrowserStorageJar.global, for: UserSettings.browserPrivacyStorageJar)
        settle()

        XCTAssertEqual(pane.resolvedJar.jar, .global)
        XCTAssertFalse(pane.webView === before, "a new jar is a new web view")
        XCTAssertTrue(pane.webView.configuration.websiteDataStore === WKWebsiteDataStore.default())
        XCTAssertTrue(automation === pane.automation)
        XCTAssertTrue(automation.webView === pane.webView, "the model drives the page on screen")
        XCTAssertNil(before.superview, "the old web view is out of the pane")
        XCTAssertTrue(pane.webView.isDescendant(of: pane.view))
        XCTAssertEqual(registry.jarIDsInUse, [], "the global jar holds no row")

        // The same setting again changes nothing.
        let rebuilt = pane.webView
        global.set(BrowserStorageJar.global, for: UserSettings.browserPrivacyStorageJar)
        settle()
        XCTAssertTrue(pane.webView === rebuilt)
        pane.paneContentWillBeDiscarded()
    }

    func testAPaneOverridingTheJarIsNotRebuiltByAGlobalChange() throws {
        let registry = BrowserJarRegistry(database: try makeDatabase())
        let global = makeSettings()
        let layered = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: EphemeralPaneStateStore()),
            fallback: global
        )
        layered.set(BrowserStorageJar.pane, for: UserSettings.browserPrivacyStorageJar)
        let pane = BrowserPaneViewController(
            store: EphemeralPaneStateStore(),
            settings: layered,
            context: context(repoID: UUID(), worktree: "/tmp/wt", jars: registry)
        )
        if let id = pane.resolvedJar.jarID { madeStoreIDs.insert(id) }
        let before = pane.webView

        global.set(BrowserStorageJar.worktree, for: UserSettings.browserPrivacyStorageJar)
        settle()

        XCTAssertTrue(pane.webView === before)
        XCTAssertEqual(pane.resolvedJar.jar, .pane)
        pane.paneContentWillBeDiscarded()
    }

    // MARK: - Cookies follow the jar

    func testAPaneCookieOverrideCountsOnlyOnItsOwnJar() {
        let global = makeSettings()
        let layered = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: EphemeralPaneStateStore()),
            fallback: global
        )
        layered.set(false, for: UserSettings.browserAcceptsCookies)

        XCTAssertFalse(BrowserPaneViewController.acceptsCookies(settings: layered, ownsDataStore: true))
        XCTAssertTrue(BrowserPaneViewController.acceptsCookies(settings: layered, ownsDataStore: false),
                      "a shared store takes the shared value")
        global.set(false, for: UserSettings.browserAcceptsCookies)
        XCTAssertFalse(BrowserPaneViewController.acceptsCookies(settings: layered, ownsDataStore: false))
        XCTAssertFalse(BrowserPaneViewController.acceptsCookies(settings: global, ownsDataStore: false))
    }

    // MARK: - Reconciler

    private func pane(_ node: UUID, repo: GitRepo) -> LiveBrowserPane {
        LiveBrowserPane(nodeID: node, repoID: repo.id, worktreePath: standardized(repo.path))
    }

    private func worktreeJar(of repo: GitRepo) -> BrowserJarRecord {
        BrowserJarRecord(kind: .worktree, repoID: repo.id, worktreePath: standardized(repo.path), paneNodeID: nil)
    }

    func testWorktreeJarSurvivesWhileAPaneStillUsesIt() throws {
        let repo = GitRepo(path: tempRoot.path, name: "Test")
        let first = pane(UUID(), repo: repo)
        let second = pane(UUID(), repo: repo)
        let jar = worktreeJar(of: repo)

        // One of two panes still resolves to the worktree jar.
        XCTAssertEqual(BrowserJarReconciler.staleJarIDs(
            records: [jar], livePanes: [first, second], effectiveJar: { $0 == first ? .worktree : .pane }
        ), [])
        // Neither does any more.
        XCTAssertEqual(BrowserJarReconciler.staleJarIDs(
            records: [jar], livePanes: [first, second], effectiveJar: { _ in .pane }
        ), [jar.id])
        // A pane in another worktree does not keep it.
        let elsewhere = LiveBrowserPane(nodeID: UUID(), repoID: repo.id, worktreePath: "/elsewhere")
        XCTAssertEqual(BrowserJarReconciler.staleJarIDs(
            records: [jar], livePanes: [elsewhere], effectiveJar: { _ in .worktree }
        ), [jar.id])
        // An open pane holding it keeps it whatever the layout says.
        XCTAssertEqual(BrowserJarReconciler.staleJarIDs(
            records: [jar], livePanes: [], effectiveJar: { _ in .worktree }, inUse: [jar.id]
        ), [])
    }

    /// A row another app copy made a moment ago may be for a pane whose layout
    /// it has not saved yet; the reconciler leaves it for a later pass.
    func testANewJarIsKeptThroughTheGracePeriod() {
        let now = Date()
        let young = BrowserJarRecord(kind: .pane, repoID: UUID(), worktreePath: "/a", paneNodeID: UUID())
        let old = BrowserJarRecord(kind: .pane, repoID: UUID(), worktreePath: "/a", paneNodeID: UUID())
        let undated = BrowserJarRecord(kind: .pane, repoID: UUID(), worktreePath: "/a", paneNodeID: UUID())
        XCTAssertEqual(BrowserJarReconciler.staleJarIDs(
            records: [young, old, undated], livePanes: [], effectiveJar: { _ in .pane },
            createdAt: [young.id: now.addingTimeInterval(-10), old.id: now.addingTimeInterval(-120)],
            now: now
        ), [old.id, undated.id])
    }

    func testTheReconcilerSparesAJarJustMade() async throws {
        let database = try makeDatabase()
        let repo = try registerRepo(in: database)
        let jar = BrowserJarRecord(
            kind: .pane, repoID: repo.id, worktreePath: standardized(repo.path), paneNodeID: UUID()
        )
        try database.insertBrowserJar(jar)
        let stores = FakeDataStores()
        await BrowserJarReconciler.reconcile(database: database, settings: makeSettings(), dataStores: stores.api)
        XCTAssertEqual(try database.allBrowserJars(), [jar], "made a moment ago, by this copy or another")
        await BrowserJarReconciler.reconcile(
            database: database, settings: makeSettings(), dataStores: stores.api, now: later
        )
        XCTAssertEqual(try database.allBrowserJars(), [])
    }

    func testAPaneJarIsKeptForAPaneKnownOnlyByAStateKey() {
        let node = UUID()
        let jar = BrowserJarRecord(kind: .pane, repoID: UUID(), worktreePath: "/a", paneNodeID: node)
        XCTAssertEqual(BrowserJarReconciler.staleJarIDs(
            records: [jar], livePanes: [], effectiveJar: { _ in .pane }
        ), [jar.id])
        XCTAssertEqual(BrowserJarReconciler.staleJarIDs(
            records: [jar], livePanes: [], liveNodeIDs: [node], effectiveJar: { _ in .pane }
        ), [])
    }

    /// A browser nested inside another pane is no layout node: it files its
    /// rows under that pane with its own id in the key, and is live exactly as
    /// long as its owner is.
    func testANestedBrowserPaneIsLiveWhileItsOwnerIs() async throws {
        let database = try makeDatabase()
        let repo = try registerRepo(in: database)
        let owner = UUID()
        let nested = UUID()
        let tab = TabRecord(title: "docs", root: .leaf(id: owner, contentType: ComposableTabsViewID("test.document")))
        try database.saveTabs([tab], activeTabID: tab.id, enabledEdges: [.top], repoID: repo.id)
        nestedStore(database, repo: repo, owner: owner, nested: nested).setPaneStateValue("x", forKey: "url")
        let jar = BrowserJarRecord(
            kind: .pane, repoID: repo.id, worktreePath: standardized(repo.path), paneNodeID: nested
        )
        try database.insertBrowserJar(jar)

        XCTAssertEqual(try database.liveBrowserPanes(), [
            LiveBrowserPane(nodeID: nested, repoID: repo.id, worktreePath: standardized(repo.path), ownerNodeID: owner)
        ])
        XCTAssertTrue(try database.livePaneNodeIDs().contains(nested))

        let stores = FakeDataStores()
        await BrowserJarReconciler.reconcile(
            database: database, settings: makeSettings(), dataStores: stores.api, now: later
        )
        XCTAssertEqual(try database.allBrowserJars(), [jar], "the nested pane still holds its jar")

        // The owner closes: saveTabs prunes its rows, and the nested pane goes with them.
        let other = TabRecord(title: "main", root: browserLeaf())
        try database.saveTabs([other], activeTabID: other.id, enabledEdges: [.top], repoID: repo.id)
        XCTAssertFalse(try database.livePaneNodeIDs().contains(nested))
        await BrowserJarReconciler.reconcile(
            database: database, settings: makeSettings(), dataStores: stores.api, now: later
        )
        XCTAssertEqual(try database.allBrowserJars(), [])
    }

    /// End to end over the database: a pane whose own override says
    /// `worktree` keeps the worktree jar while the shared setting says `pane`.
    func testReconcilerReadsAPanesOverrideFromItsState() async throws {
        let database = try makeDatabase()
        let repo = try registerRepo(in: database)
        let node = UUID()
        let tab = TabRecord(title: "main", root: browserLeaf(node))
        try database.saveTabs([tab], activeTabID: tab.id, enabledEdges: [.top], repoID: repo.id)
        let jar = worktreeJar(of: repo)
        try database.insertBrowserJar(jar)
        let settings = makeSettings()
        settings.set(BrowserStorageJar.pane, for: UserSettings.browserPrivacyStorageJar)
        let stores = FakeDataStores()

        await BrowserJarReconciler.reconcile(database: database, settings: settings, dataStores: stores.api, now: later)
        XCTAssertEqual(try database.allBrowserJars(), [], "no pane resolves to the worktree jar")

        try database.insertBrowserJar(jar)
        PaneStateSettingsStorageProvider(store: DatabaseStateStore(
            database: database, repoID: repo.id, nodeID: node, prefix: ComposableTabsViewRegistry.browserStatePrefix
        )).set(BrowserStorageJar.worktree, for: UserSettings.browserPrivacyStorageJar)
        await BrowserJarReconciler.reconcile(database: database, settings: settings, dataStores: stores.api, now: later)
        XCTAssertEqual(try database.allBrowserJars(), [jar], "the pane's own override keeps it")
    }

    /// A nested pane's override lives under its owner's node, with its own id
    /// in the key; the reconciler must read it from there.
    func testReconcilerReadsANestedPanesOverrideUnderItsOwner() async throws {
        let database = try makeDatabase()
        let repo = try registerRepo(in: database)
        let owner = UUID()
        let nested = UUID()
        let tab = TabRecord(title: "docs", root: .leaf(id: owner, contentType: ComposableTabsViewID("test.document")))
        try database.saveTabs([tab], activeTabID: tab.id, enabledEdges: [.top], repoID: repo.id)
        PaneStateSettingsStorageProvider(store: nestedStore(database, repo: repo, owner: owner, nested: nested))
            .set(BrowserStorageJar.worktree, for: UserSettings.browserPrivacyStorageJar)
        let jar = worktreeJar(of: repo)
        try database.insertBrowserJar(jar)
        let settings = makeSettings()
        settings.set(BrowserStorageJar.pane, for: UserSettings.browserPrivacyStorageJar)

        await BrowserJarReconciler.reconcile(
            database: database, settings: settings, dataStores: FakeDataStores().api, now: later
        )
        XCTAssertEqual(try database.allBrowserJars(), [jar])
    }

    func testReconcilerDropsJarsOfRemovedPanes() async throws {
        let database = try makeDatabase()
        let repo = try registerRepo(in: database)
        let registry = BrowserJarRegistry(database: database)
        let kept = UUID()
        let removed = UUID()
        let keptJar = try XCTUnwrap(
            resolve(.pane, context(node: kept, repoID: repo.id, worktree: repo.path, jars: registry), in: registry)
                .jarID
        )
        let removedJar = try XCTUnwrap(
            resolve(.pane, context(node: removed, repoID: repo.id, worktree: repo.path, jars: registry), in: registry)
                .jarID
        )
        let stores = FakeDataStores()

        let both = TabRecord(
            title: "main",
            root: .split(orientation: .horizontal, first: browserLeaf(kept), second: browserLeaf(removed))
        )
        try database.saveTabs([both], activeTabID: both.id, enabledEdges: [.top], repoID: repo.id)
        await BrowserJarReconciler.reconcile(
            database: database, settings: makeSettings(), dataStores: stores.api, now: later
        )
        XCTAssertEqual(Set(try database.allBrowserJars().map(\.id)), [keptJar, removedJar])

        let one = TabRecord(id: both.id, title: "main", root: browserLeaf(kept))
        try database.saveTabs([one], activeTabID: one.id, enabledEdges: [.top], repoID: repo.id)
        await BrowserJarReconciler.reconcile(
            database: database, settings: makeSettings(), dataStores: stores.api, now: later
        )
        XCTAssertEqual(try database.allBrowserJars().map(\.id), [keptJar])

        // Idempotent: a second pass finds nothing more to do.
        await BrowserJarReconciler.reconcile(
            database: database, settings: makeSettings(), dataStores: stores.api, now: later
        )
        XCTAssertEqual(try database.allBrowserJars().map(\.id), [keptJar])
    }

    /// The sweep removes a WebKit store only when no row names it and no open
    /// pane holds it — through a fake, never the test host's own stores.
    func testTheSweepRemovesOnlyStoresNothingNamesOrHolds() async throws {
        let database = try makeDatabase()
        let repo = try registerRepo(in: database)
        let registry = BrowserJarRegistry.shared(for: database)
        let node = UUID()
        let tab = TabRecord(title: "main", root: browserLeaf(node))
        try database.saveTabs([tab], activeTabID: tab.id, enabledEdges: [.top], repoID: repo.id)
        let rowJar = BrowserJarRecord(
            kind: .pane, repoID: repo.id, worktreePath: standardized(repo.path), paneNodeID: node
        )
        try database.insertBrowserJar(rowJar)
        let held = UUID()
        let holder = NSObject()
        registry.noteUse(of: held, by: holder)
        let orphan = UUID()
        let stores = FakeDataStores(identifiers: [rowJar.id, held, orphan])

        await BrowserJarReconciler.reconcile(
            database: database, settings: makeSettings(), dataStores: stores.api, now: later
        )
        XCTAssertEqual(stores.removed, [orphan])
        XCTAssertEqual(stores.identifiers, [rowJar.id, held])

        // Idempotent, and a refusal is left for the next pass.
        stores.refuses = true
        stores.identifiers.append(UUID())
        await BrowserJarReconciler.reconcile(
            database: database, settings: makeSettings(), dataStores: stores.api, now: later
        )
        XCTAssertEqual(stores.removed, [orphan])
        XCTAssertEqual(stores.identifiers.count, 3)
        withExtendedLifetime(holder) {}
    }

    private func nestedStore(
        _ database: ProjectDatabase,
        repo: GitRepo,
        owner: UUID,
        nested: UUID
    ) -> DatabaseStateStore {
        // `ProjectPaneStateStore.storageKey(for:)`'s owned shape, spelled out:
        // rows under the owner, the nested pane's id after the store's prefix.
        DatabaseStateStore(
            database: database,
            repoID: repo.id,
            nodeID: owner,
            prefix: ComposableTabsViewRegistry.browserStatePrefix + nested.uuidString + "."
        )
    }
}

/// A pane's state rows, written straight to the database, so a test can give
/// a pane with no window state the reconciler must read back.
@MainActor
private final class DatabaseStateStore: PaneStateStore {
    let database: ProjectDatabase
    let repoID: UUID
    let nodeID: UUID
    let prefix: String

    init(database: ProjectDatabase, repoID: UUID, nodeID: UUID, prefix: String) {
        self.database = database
        self.repoID = repoID
        self.nodeID = nodeID
        self.prefix = prefix
    }

    func paneStateValue(forKey key: String) -> String? {
        try? database.paneState(repoID: repoID, nodeID: nodeID, key: prefix + key)
    }

    func setPaneStateValue(_ value: String?, forKey key: String) {
        try? database.setPaneState(repoID: repoID, nodeID: nodeID, key: prefix + key, value: value)
    }
}

/// Named stores the sweep sees, with no WebKit behind them.
@MainActor
private final class FakeDataStores {
    var identifiers: [UUID]
    var removed: [UUID] = []
    /// Answers every removal the way WebKit does while a web view holds the
    /// store.
    var refuses = false

    init(identifiers: [UUID] = []) {
        self.identifiers = identifiers
    }

    var api: BrowserJarReconciler.DataStores {
        BrowserJarReconciler.DataStores(
            // Strong on purpose: the closures are the fake's only owner once a
            // test's last line names it, and nothing holds them back.
            identifiers: { self.identifiers },
            remove: { id in
                if self.refuses { throw CocoaError(.fileWriteNoPermission) }
                self.removed.append(id)
                self.identifiers.removeAll { $0 == id }
            }
        )
    }
}
