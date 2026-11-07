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

    // MARK: - The sheet

    func testSheetShowsTheTopicOnlyWithJars() throws {
        let plain = ComposableTabsSettingsViewController(isEdgeEnabled: { _ in true }, setEdgeEnabled: { _, _ in })
        XCTAssertEqual(plain.topicTitles, ["Tabs"])

        let withJars = ComposableTabsSettingsViewController(
            isEdgeEnabled: { _ in true },
            setEdgeEnabled: { _, _ in },
            browserJars: ProjectBrowserJars(provider: SeededJars(registry: try makeRegistry()), repoID: UUID())
        )
        XCTAssertEqual(withJars.topicTitles, ["Tabs", "Cookies and Site Data"])
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
