import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The local copy of a shared registry's project list. The rows it writes are
/// what window state hangs off, so the tests check the layout as well as the
/// row: a mirror that replaced a row instead of updating it would cascade the
/// layout away while every row column still looked right.
@MainActor
final class LocalProjectMirrorTests: XCTestCase {

    private var database: ProjectDatabase!
    private var mirror: LocalProjectMirror!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let path = TestTempDirectory.make(label: "local-project-mirror-test")
            .appendingPathComponent("Projects.db")
            .path
        database = try ProjectDatabase(path: path)
        mirror = LocalProjectMirror(database: database)
    }

    override func tearDownWithError() throws {
        mirror = nil
        database = nil
        try super.tearDownWithError()
    }

    func testAnUpsertOfANewProjectInsertsIt() throws {
        let project = makeProject(path: "/tmp/whippet", name: "whippet")
        try mirror.upsert(project)

        XCTAssertEqual(try database.repo(id: project.id), project)
    }

    func testARenameKeepsTheIDAndTheLayout() throws {
        var project = makeProject(path: "/tmp/old", name: "old")
        try mirror.upsert(project)
        let tab = try saveLayout(for: project.id)

        project.name = "new"
        project.path = "/tmp/new"
        try mirror.apply(.upserted(project))

        let found = try database.repo(id: project.id)
        XCTAssertEqual(found?.name, "new")
        XCTAssertEqual(found?.path, "/tmp/new")
        XCTAssertEqual(try database.loadTabs(repoID: project.id).tabs.map(\.id), [tab.id])
    }

    /// An upsert of a row already here is an `UPDATE`, never a delete and
    /// insert, so the layout that references it stays.
    func testAnUpsertOfAnExistingProjectKeepsItsLayout() throws {
        var project = makeProject(path: "/tmp/kept", name: "kept")
        try mirror.upsert(project)
        let tab = try saveLayout(for: project.id)

        project.lastOpened = Date(timeIntervalSince1970: 9_000)
        try mirror.upsert(project)
        try mirror.sync([project])

        XCTAssertEqual(try database.repo(id: project.id)?.lastOpened, project.lastOpened)
        let loaded = try database.loadTabs(repoID: project.id)
        XCTAssertEqual(loaded.tabs.map(\.id), [tab.id])
        XCTAssertEqual(loaded.activeTabID, tab.id)
    }

    func testDeletingOneProjectKeepsTheLayoutOfAnother() throws {
        let doomed = makeProject(path: "/tmp/doomed", name: "doomed")
        let kept = makeProject(path: "/tmp/kept", name: "kept")
        try mirror.sync([doomed, kept])
        _ = try saveLayout(for: doomed.id)
        let keptTab = try saveLayout(for: kept.id)

        try mirror.apply(.deleted(doomed.id))

        XCTAssertNil(try database.repo(id: doomed.id))
        XCTAssertTrue(try database.loadTabs(repoID: doomed.id).tabs.isEmpty)
        XCTAssertNotNil(try database.repo(id: kept.id))
        XCTAssertEqual(try database.loadTabs(repoID: kept.id).tabs.map(\.id), [keptTab.id])
    }

    /// `(path, kind)` is unique: a local project row at the registry
    /// project's path under another id gives way to the registry's.
    func testALocalRowAtTheSamePathUnderAnotherIDIsReplaced() throws {
        let local = makeProject(path: "/tmp/same", name: "local")
        try mirror.upsert(local)
        let shared = makeProject(path: "/tmp/same", name: "shared")

        try mirror.upsert(shared)

        XCTAssertNil(try database.repo(id: local.id))
        XCTAssertEqual(try database.repo(path: "/tmp/same", kind: .project)?.id, shared.id)
    }

    /// The File Browser and Git windows keep rows in the same table; no
    /// registry change ever reaches one.
    func testARowOfAnotherKindIsNeverTouched() throws {
        let browser = GitRepo(path: "/tmp/shared", name: "browser", kind: .fileBrowser)
        try database.insertRow(browser)

        try mirror.apply(.deleted(browser.id))
        try mirror.upsert(makeProject(path: "/tmp/shared", name: "project"))

        XCTAssertEqual(try database.repo(path: "/tmp/shared", kind: .fileBrowser)?.id, browser.id)
        XCTAssertThrowsError(try mirror.upsert(browser))
    }

    func testDeletingAProjectThatIsNotHereDoesNothing() throws {
        let project = makeProject(path: "/tmp/here", name: "here")
        try mirror.upsert(project)

        try mirror.delete(id: UUID())

        XCTAssertNotNil(try database.repo(id: project.id))
    }

    // MARK: - Helpers

    private func makeProject(path: String, name: String) -> GitRepo {
        GitRepo(
            path: path,
            name: name,
            remote: nil,
            firstSeen: Date(timeIntervalSince1970: 1_000),
            lastSeen: Date(timeIntervalSince1970: 2_000))
    }

    @discardableResult
    private func saveLayout(for repoID: UUID) throws -> TabRecord {
        let leaf = LayoutNode.leaf(contentType: ComposableTabsViewID("test.editor"), paneLabel: nil)
        let record = TabRecord(edge: .left, title: "tab", root: leaf, workingDirectory: nil)
        try database.saveTabs([record], activeTabID: record.id, repoID: repoID)
        return record
    }
}
