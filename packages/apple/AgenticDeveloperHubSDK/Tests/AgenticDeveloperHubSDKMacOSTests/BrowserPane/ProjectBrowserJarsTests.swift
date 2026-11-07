import XCTest
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The project settings sheet's Cookies and Site Data topic. Every registry
/// here is a seeded database in a temporary folder, and every store a
/// non-persistent one: nothing reads or writes the user's jars.
@MainActor
final class ProjectBrowserJarsTests: XCTestCase {

    private var tempRoot: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("project-browser-jars-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempRoot)
        try await super.tearDown()
    }

    // MARK: - Fixtures

    /// The real registry's rows, with a throwaway store per jar in place of
    /// the named one on disk.
    private final class SeededJars: ProjectBrowserJarsProviding {
        let registry: BrowserJarRegistry
        private var stores: [UUID: WKWebsiteDataStore] = [:]

        init(registry: BrowserJarRegistry) { self.registry = registry }

        func records(repoID: UUID) -> [BrowserJarRecord] { registry.records(repoID: repoID) }

        func siteData(for record: BrowserJarRecord) -> BrowserSiteData {
            let store = stores[record.id] ?? .nonPersistent()
            stores[record.id] = store
            return BrowserSiteData(dataStore: store)
        }
    }

    /// Holds every site read open until the test answers it, so a test can
    /// order the answers the way a slow WebKit might.
    @MainActor
    private final class HeldReads {
        typealias Reply = CheckedContinuation<[WKWebsiteDataRecord], Never>
        private(set) var pending: [(data: BrowserSiteData, reply: Reply)] = []
        private(set) var answered = 0

        func read(_ data: BrowserSiteData) async -> [WKWebsiteDataRecord] {
            await withCheckedContinuation { pending.append((data, $0)) }
        }

        /// Waits until `count` reads have been asked for, answered or not.
        func waitForReads(_ count: Int, file: StaticString = #filePath, line: UInt = #line) async {
            // A Clear's own WebKit removal sits between some reads, so this
            // waits in real time, not just in yields.
            for _ in 0..<1000 where pending.count < count {
                try? await Task.sleep(for: .milliseconds(5))
            }
            XCTAssertGreaterThanOrEqual(pending.count, count, "reads asked for", file: file, line: line)
        }

        func answer(_ index: Int, with records: [WKWebsiteDataRecord] = []) {
            pending[index].reply.resume(returning: records)
            answered += 1
        }
    }

    /// One real record for `example.test`, read back from a cookie set in a
    /// throwaway store — WebKit gives no other way to make one.
    private func exampleRecord(
        in store: WKWebsiteDataStore = .nonPersistent()
    ) async throws -> WKWebsiteDataRecord {
        let cookie = try XCTUnwrap(HTTPCookie(properties: [
            .domain: "example.test", .path: "/", .name: "session", .value: "1"
        ]))
        await store.httpCookieStore.setCookie(cookie)
        let records = await BrowserSiteData(dataStore: store).records()
        guard let record = records.first else {
            throw XCTSkip("WebKit listed no record for a cookie set in this test host")
        }
        return record
    }

    private func makePanel(_ registry: BrowserJarRegistry, repoID: UUID) -> ProjectBrowserJarsSettingsPanel {
        let panel = ProjectBrowserJarsSettingsPanel(
            jars: ProjectBrowserJars(provider: SeededJars(registry: registry), repoID: repoID)
        )
        panel.loadViewIfNeeded()
        panel.reloadJars()
        return panel
    }

    private func makeRegistry() throws -> BrowserJarRegistry {
        BrowserJarRegistry(database: try ProjectDatabase(path: tempRoot.appendingPathComponent("Test.db").path))
    }

    private func worktreeJar(_ repoID: UUID, _ path: String) -> BrowserJarRecord {
        BrowserJarRecord(kind: .worktree, repoID: repoID, worktreePath: path, paneNodeID: nil, label: "")
    }

    private func paneJar(_ repoID: UUID, _ path: String, label: String) -> BrowserJarRecord {
        BrowserJarRecord(kind: .pane, repoID: repoID, worktreePath: path, paneNodeID: UUID(), label: label)
    }

    // MARK: - Labels

    func testWorktreeJarLabel() {
        let record = worktreeJar(UUID(), "/Users/me/src/app/feature-x")
        XCTAssertEqual(ProjectBrowserJarsSettingsPanel.label(for: record), "feature-x — worktree")
    }

    func testPaneJarLabel() {
        let record = paneJar(UUID(), "/Users/me/src/app/main", label: "GitHub")
        XCTAssertEqual(ProjectBrowserJarsSettingsPanel.label(for: record), "GitHub — main")
    }

    func testPaneJarLabelFallsBackToBrowser() {
        let record = paneJar(UUID(), "/Users/me/src/app/main", label: "")
        XCTAssertEqual(ProjectBrowserJarsSettingsPanel.label(for: record), "Browser — main")
    }

    // MARK: - The list

    func testTopicListsOnlyThisProjectsJars() throws {
        let registry = try makeRegistry()
        let mine = UUID()
        let theirs = UUID()
        let myWorktree = worktreeJar(mine, "/src/app/main")
        let myPane = paneJar(mine, "/src/app/main", label: "Docs")
        try registry.database.insertBrowserJar(myPane)
        try registry.database.insertBrowserJar(myWorktree)
        try registry.database.insertBrowserJar(worktreeJar(theirs, "/src/other/main"))
        try registry.database.insertBrowserJar(paneJar(theirs, "/src/other/main", label: "Mail"))

        let panel = ProjectBrowserJarsSettingsPanel(
            jars: ProjectBrowserJars(provider: SeededJars(registry: registry), repoID: mine)
        )
        panel.loadViewIfNeeded()
        panel.reloadJars()

        XCTAssertEqual(panel.jarItems.map(\.record.id), [myWorktree.id, myPane.id])
        XCTAssertEqual(
            panel.jarItems.map { ProjectBrowserJarsSettingsPanel.label(for: $0.record) },
            ["main — worktree", "Docs — main"]
        )
        XCTAssertEqual(panel.outlineView.numberOfRows, 2)
    }

    func testClearEmptiesTheJarAndKeepsItsRow() async throws {
        let registry = try makeRegistry()
        let repoID = UUID()
        let record = worktreeJar(repoID, "/src/app/main")
        try registry.database.insertBrowserJar(record)
        let panel = ProjectBrowserJarsSettingsPanel(
            jars: ProjectBrowserJars(provider: SeededJars(registry: registry), repoID: repoID)
        )
        panel.loadViewIfNeeded()
        panel.reloadJars()
        let jar = try XCTUnwrap(panel.jarItems.first)

        let cookie = try XCTUnwrap(HTTPCookie(properties: [
            .domain: "example.test", .path: "/", .name: "session", .value: "1"
        ]))
        await jar.siteData.dataStore.httpCookieStore.setCookie(cookie)
        await panel.loadSites().value
        guard !jar.sites.isEmpty else {
            throw XCTSkip("WebKit listed no record for a cookie set in this test host")
        }
        XCTAssertEqual(ProjectBrowserJarsSettingsPanel.siteCount(jar.sites.count), "1 site")

        await panel.clear(jar)

        XCTAssertTrue(jar.sites.isEmpty)
        XCTAssertEqual(registry.records(repoID: repoID), [record])
    }

    // MARK: - Reads compose

    /// A Remove pressed while the first read of every jar is still out must
    /// not stop that read reaching the other jars.
    func testReadingOneJarDoesNotStopTheReadOfEveryJar() async throws {
        let registry = try makeRegistry()
        let repoID = UUID()
        try registry.database.insertBrowserJar(worktreeJar(repoID, "/src/app/main"))
        try registry.database.insertBrowserJar(paneJar(repoID, "/src/app/main", label: "Docs"))
        let panel = makePanel(registry, repoID: repoID)
        let reads = HeldReads()
        panel.readSites = { await reads.read($0) }

        let everyJar = panel.loadSites()
        await reads.waitForReads(1)
        let first = try XCTUnwrap(panel.jarItems.first)
        let oneJar = panel.loadSites(of: first)
        await reads.waitForReads(2)

        reads.answer(1)
        await oneJar.value
        reads.answer(0)
        await reads.waitForReads(3)
        reads.answer(2)
        await everyJar.value

        XCTAssertEqual(panel.jarItems.map(\.hasLoadedSites), [true, true])
    }

    /// A Refresh pressed while a Clear is out rebuilds the rows; the Clear's
    /// read must still land, and the Refresh's older read must not cover it.
    func testClearDuringRefreshShowsTheJarEmpty() async throws {
        let registry = try makeRegistry()
        let repoID = UUID()
        try registry.database.insertBrowserJar(worktreeJar(repoID, "/src/app/main"))
        let panel = makePanel(registry, repoID: repoID)
        let site = try await exampleRecord()
        let reads = HeldReads()
        panel.readSites = { await reads.read($0) }

        let initial = panel.loadSites()
        await reads.waitForReads(1)
        reads.answer(0, with: [site])
        await initial.value
        let beforeRefresh = try XCTUnwrap(panel.jarItems.first)
        XCTAssertEqual(beforeRefresh.sites.count, 1)

        // Refresh: new rows, and a read of every jar that answers late with
        // what the jar held before the Clear.
        panel.reloadJars()
        let refresh = panel.loadSites()
        await reads.waitForReads(2)

        // The Clear was started on the row from before the Refresh.
        let clear = Task { await panel.clear(beforeRefresh) }
        await reads.waitForReads(3)
        reads.answer(2)
        await clear.value
        reads.answer(1, with: [site])
        await refresh.value

        let current = try XCTUnwrap(panel.jarItems.first)
        XCTAssertFalse(current === beforeRefresh)
        XCTAssertTrue(current.sites.isEmpty)
        XCTAssertTrue(current.hasLoadedSites)
    }

    // MARK: - Selection

    /// Two jars holding the same site: re-reading one of them must leave the
    /// selection on the jar the user picked, and a site that is gone takes
    /// the selection with it rather than handing it to its namesake.
    func testSelectionStaysWithItsJar() async throws {
        let registry = try makeRegistry()
        let repoID = UUID()
        try registry.database.insertBrowserJar(worktreeJar(repoID, "/src/app/main"))
        try registry.database.insertBrowserJar(paneJar(repoID, "/src/app/main", label: "GitHub"))
        let panel = makePanel(registry, repoID: repoID)
        let inWorktree = try await exampleRecord()
        let inPane = try await exampleRecord()
        XCTAssertEqual(inWorktree.displayName, inPane.displayName)
        let reads = HeldReads()
        panel.readSites = { await reads.read($0) }

        let load = panel.loadSites()
        await reads.waitForReads(1)
        reads.answer(0, with: [inWorktree])
        await reads.waitForReads(2)
        reads.answer(1, with: [inPane])
        await load.value

        let worktree = panel.jarItems[0]
        let pane = panel.jarItems[1]
        panel.outlineView.expandItem(worktree)
        panel.outlineView.expandItem(pane)
        let row = panel.outlineView.row(forItem: worktree.sites[0])
        panel.outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        let picked = ProjectBrowserJarsSettingsPanel.SiteKey(
            jarID: worktree.record.id, displayName: inWorktree.displayName
        )
        XCTAssertEqual(panel.selectedSiteKey, picked)

        // The other jar is re-read — after a Remove there, say.
        let otherJar = panel.loadSites(of: pane)
        await reads.waitForReads(3)
        reads.answer(2, with: [inPane])
        await otherJar.value
        XCTAssertEqual(panel.selectedSiteKey, picked)

        // A Refresh rebuilds every row; the selection follows the pair.
        panel.reloadJars()
        XCTAssertEqual(panel.selectedSiteKey, picked)

        // The picked site is gone from its jar: nothing is selected, and
        // Remove has nothing to act on.
        let ownJar = panel.loadSites(of: panel.jarItems[0])
        await reads.waitForReads(4)
        reads.answer(3)
        await ownJar.value
        XCTAssertNil(panel.selectedItem)
        XCTAssertFalse(panel.removeButton.isEnabled)
    }

    // MARK: - The sheet

    func testSheetListsTheTopicsItIsGiven() throws {
        let plain = ComposableTabsSettingsViewController(isEdgeEnabled: { _ in true }, setEdgeEnabled: { _, _ in })
        XCTAssertEqual(plain.topicTitles, ["Tabs"])

        let withJars = ComposableTabsSettingsViewController(
            isEdgeEnabled: { _ in true },
            setEdgeEnabled: { _, _ in },
            topics: [ProjectBrowserJarsSettingsPanel(
                jars: ProjectBrowserJars(provider: SeededJars(registry: try makeRegistry()), repoID: UUID())
            )]
        )
        XCTAssertEqual(withJars.topicTitles, ["Tabs", "Cookies and Site Data"])
    }

    /// The browser's registration is what brings the topic: a registry with
    /// no browser contributes none, and unregistering the browser takes it
    /// away again.
    func testRegisteringTheBrowserContributesTheTopic() throws {
        let database = try ProjectDatabase(path: tempRoot.appendingPathComponent("Workspace.db").path)
        let project = ProjectWorkspace(repo: GitRepo(path: tempRoot.path, name: "Test"), database: database)

        let registry = ComposableTabsViewRegistry()
        XCTAssertTrue(registry.makeProjectSettingsTopics(for: project).isEmpty)

        registry.registerBrowser(preferredAxis: .horizontal)
        XCTAssertEqual(
            registry.makeProjectSettingsTopics(for: project).map(\.descriptor.title),
            ["Cookies and Site Data"]
        )

        registry.unregister(.browser)
        XCTAssertTrue(registry.makeProjectSettingsTopics(for: project).isEmpty)
    }

    // MARK: - Pane label writes

    func testJarLabelIsWrittenAtMostOncePerCommittedNavigation() {
        var gate = BrowserJarLabelGate()
        // Nothing before a commit: the initial title observation is not a page.
        XCTAssertNil(gate.label(pageTitle: "Old", fallback: "host", finished: false, current: "Browser"))

        gate.navigationDidCommit()
        // A blank title mid-load waits for the real one.
        XCTAssertNil(gate.label(pageTitle: "", fallback: "host", finished: false, current: "Browser"))
        XCTAssertEqual(gate.label(pageTitle: "Inbox", fallback: "host", finished: false, current: "Browser"), "Inbox")
        // A page retitling itself on the same document writes nothing more.
        XCTAssertNil(gate.label(pageTitle: "Inbox (1)", fallback: "host", finished: false, current: "Inbox"))
        XCTAssertNil(gate.label(pageTitle: "Inbox (2)", fallback: "host", finished: true, current: "Inbox"))

        // A page that never sets a title gets the fallback once it finishes.
        gate.navigationDidCommit()
        XCTAssertNil(gate.label(pageTitle: nil, fallback: "example.test", finished: false, current: "Inbox"))
        XCTAssertEqual(
            gate.label(pageTitle: nil, fallback: "example.test", finished: true, current: "Inbox"), "example.test"
        )

        // The same title as the row already has is no write, and spends the navigation.
        gate.navigationDidCommit()
        XCTAssertNil(gate.label(pageTitle: "example.test", fallback: "x", finished: false, current: "example.test"))
        XCTAssertFalse(gate.isArmed)
    }
}
