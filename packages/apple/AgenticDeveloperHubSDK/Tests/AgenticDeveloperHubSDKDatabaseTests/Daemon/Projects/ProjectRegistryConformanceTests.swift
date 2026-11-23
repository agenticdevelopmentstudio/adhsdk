import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// The `ProjectRegistry` contract, exercised through the protocol so that any
/// other registry (adhd's, over its client library) can be held to the same
/// tests. `ProjectDatabase` is the conformer here.
final class ProjectRegistryConformanceTests: XCTestCase {

    private var tempRoot: URL!
    private var database: ProjectDatabase!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("project-registry-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        database = try ProjectDatabase(path: tempRoot.appendingPathComponent("Projects.db").path)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(at: tempRoot)
        try super.tearDownWithError()
    }

    private var registry: any ProjectRegistry { database }

    // MARK: - Rows

    func testAnInsertedProjectIsFoundByIDAndByPath() async throws {
        let project = makeProject(path: "/tmp/whippet", name: "whippet")
        try await registry.insert(project)

        let byID = try await registry.project(id: project.id)
        let byPath = try await registry.project(path: "/tmp/whippet")
        XCTAssertEqual(byID, project)
        XCTAssertEqual(byPath, project)
    }

    func testAMissingProjectIsNil() async throws {
        let byID = try await registry.project(id: UUID())
        let byPath = try await registry.project(path: "/tmp/nowhere")
        XCTAssertNil(byID)
        XCTAssertNil(byPath)
    }

    func testARowOfAnotherKindIsRefused() async throws {
        let browser = GitRepo(path: "/tmp/browser", name: "browser", kind: .fileBrowser)
        do {
            try await registry.insert(browser)
            XCTFail("a file browser row was accepted as a project")
        } catch ProjectDatabaseError.notAProject(let kind) {
            XCTAssertEqual(kind, .fileBrowser)
        }
        let projects = try await registry.projects()
        XCTAssertTrue(projects.isEmpty)
    }

    func testUpdateRenamesAndMovesAProjectKeepingItsID() async throws {
        var project = makeProject(path: "/tmp/old", name: "old")
        try await registry.insert(project)
        project.name = "new"
        project.path = "/tmp/new"
        try await registry.update(project)

        let found = try await registry.project(id: project.id)
        XCTAssertEqual(found?.name, "new")
        XCTAssertEqual(found?.path, "/tmp/new")
        let atOldPath = try await registry.project(path: "/tmp/old")
        XCTAssertNil(atOldPath)
    }

    func testMarkOpenedRecordsTheTimeAndNothingElse() async throws {
        let project = makeProject(path: "/tmp/opened", name: "opened")
        try await registry.insert(project)
        let opened = Date(timeIntervalSince1970: 5_000)
        try await registry.markOpened(id: project.id, at: opened)

        let found = try await registry.project(id: project.id)
        XCTAssertEqual(found?.lastOpened, opened)
        XCTAssertEqual(found?.name, project.name)
        XCTAssertEqual(found?.lastSeen, project.lastSeen)
    }

    func testDeleteRemovesTheProject() async throws {
        let project = makeProject(path: "/tmp/doomed", name: "doomed")
        try await registry.insert(project)
        try await registry.delete(id: project.id)

        let found = try await registry.project(id: project.id)
        XCTAssertNil(found)
        let projects = try await registry.projects()
        XCTAssertTrue(projects.isEmpty)
    }

    func testProjectsAreOrderedByNameIgnoringCase() async throws {
        try await registry.insert(makeProject(path: "/tmp/one", name: "zebra"))
        try await registry.insert(makeProject(path: "/tmp/two", name: "Apple"))
        try await registry.insert(makeProject(path: "/tmp/three", name: "mango"))

        let names = try await registry.projects().map(\.name)
        XCTAssertEqual(names, ["Apple", "mango", "zebra"])
    }

    /// The file browser, document and git windows keep rows in the same table;
    /// none of them is a project, so the registry never shows one.
    func testRowsOfOtherKindsAreInvisible() async throws {
        let project = makeProject(path: "/tmp/shared", name: "shared")
        let browser = GitRepo(path: "/tmp/shared", name: "shared", kind: .fileBrowser)
        try await registry.insert(project)
        try database.insertRow(browser)

        let projects = try await registry.projects()
        XCTAssertEqual(projects.map(\.id), [project.id])
        let byPath = try await registry.project(path: "/tmp/shared")
        XCTAssertEqual(byPath?.id, project.id)
        let browserByID = try await registry.project(id: browser.id)
        XCTAssertNil(browserByID)

        // Neither update, markOpened nor delete reaches a row of another kind.
        try await registry.markOpened(id: browser.id, at: Date(timeIntervalSince1970: 9_000))
        try await registry.delete(id: browser.id)
        XCTAssertEqual(try database.repo(path: "/tmp/shared", kind: .fileBrowser)?.id, browser.id)
        XCTAssertNil(try database.repo(path: "/tmp/shared", kind: .fileBrowser)?.lastOpened)
    }

    // MARK: - Repository state

    func testRepoStateRoundTrips() async throws {
        let project = makeProject(path: "/tmp/stateful", name: "stateful")
        try await registry.insert(project)
        let missing = try await registry.repoState(id: project.id)
        XCTAssertNil(missing)

        let state = RepoStateSnapshot(
            checkouts: [
                .init(path: "/tmp/stateful", branch: "main", isMain: true),
                .init(path: "/tmp/stateful-feature", branch: "feature", isMain: false)
            ],
            branches: ["feature", "main"],
            refreshedAt: Date(timeIntervalSince1970: 7_000))
        try await registry.saveRepoState(state, id: project.id)

        let loaded = try await registry.repoState(id: project.id)
        XCTAssertEqual(loaded, state)
    }

    // MARK: - Changes

    func testChangesAnnounceUpsertsAndDeletes() async throws {
        var iterator = registry.changes.makeAsyncIterator()
        var project = makeProject(path: "/tmp/watched", name: "watched")

        try await registry.insert(project)
        let inserted = await iterator.next()
        XCTAssertEqual(inserted, .upserted(project))

        project.name = "renamed"
        try await registry.update(project)
        let updated = await iterator.next()
        XCTAssertEqual(updated, .upserted(project))

        let opened = Date(timeIntervalSince1970: 8_000)
        try await registry.markOpened(id: project.id, at: opened)
        let marked = await iterator.next()
        project.lastOpened = opened
        XCTAssertEqual(marked, .upserted(project))

        try await registry.delete(id: project.id)
        let deleted = await iterator.next()
        XCTAssertEqual(deleted, .deleted(project.id))
        XCTAssertEqual(deleted?.id, project.id)
    }

    /// A write that matched nothing changed nothing, so it announces nothing:
    /// the next change a subscriber sees is the next real one.
    func testAWriteThatMatchesNothingAnnouncesNothing() async throws {
        var iterator = registry.changes.makeAsyncIterator()
        try await registry.delete(id: UUID())
        try await registry.markOpened(id: UUID(), at: Date(timeIntervalSince1970: 1))
        try await registry.update(makeProject(path: "/tmp/never-inserted", name: "ghost"))

        let project = makeProject(path: "/tmp/real", name: "real")
        try await registry.insert(project)
        let first = await iterator.next()
        XCTAssertEqual(first, .upserted(project))
    }

    // MARK: - Helpers

    /// Whole-second dates: the table stores seconds as a double, and a
    /// fraction is the one thing that could make a round trip unequal.
    private func makeProject(path: String, name: String) -> GitRepo {
        GitRepo(
            path: path,
            name: name,
            remote: "git@example.com:\(name).git",
            firstSeen: Date(timeIntervalSince1970: 1_000),
            lastSeen: Date(timeIntervalSince1970: 2_000))
    }
}
