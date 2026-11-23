import XCTest
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDatabase

/// The project registry's storage contract: a repository is a row, its
/// settings hang off that row, and nothing about it is a file on disk. The
/// window-layout half, and the migrations that reshape it, are tested beside
/// the layout code in the macOS tests.
final class ProjectDatabaseTests: XCTestCase {

    private var tempRoot: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("project-db-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
        try super.tearDownWithError()
    }

    func testInsertedRepoRoundTripsEveryColumn() throws {
        let database = try makeDatabase()
        let firstSeen = Date(timeIntervalSince1970: 1_000)
        let repo = GitRepo(
            path: "/Users/someone/Development/whippet",
            name: "whippet",
            remote: "git@github.com:someone/whippet.git",
            firstSeen: firstSeen,
            lastSeen: Date(timeIntervalSince1970: 2_000),
            lastOpened: Date(timeIntervalSince1970: 3_000)
        )
        try database.insert(repo)

        let loaded = try XCTUnwrap(database.repo(id: repo.id))
        XCTAssertEqual(loaded.path, repo.path)
        XCTAssertEqual(loaded.name, "whippet")
        XCTAssertEqual(loaded.remote, "git@github.com:someone/whippet.git")
        XCTAssertEqual(loaded.firstSeen.timeIntervalSince1970, 1_000, accuracy: 0.001)
        XCTAssertEqual(loaded.lastOpened?.timeIntervalSince1970, 3_000)
    }

    /// Both lookups have to agree, because a scan finds a repository by path
    /// and everything else refers to it by id.
    func testARepoIsFoundByPathAsWellAsByID() throws {
        let database = try makeDatabase()
        let repo = GitRepo(path: "/tmp/alpha", name: "alpha")
        try database.insert(repo)

        XCTAssertEqual(try database.repo(path: "/tmp/alpha")?.id, repo.id)
        XCTAssertNil(try database.repo(path: "/tmp/never-scanned"))
    }

    /// The path is the one thing two rows can never share: it is how a scan
    /// recognises a repository it already knows.
    func testTwoRowsCannotShareAPath() throws {
        let database = try makeDatabase()
        try database.insert(GitRepo(path: "/tmp/alpha", name: "alpha"))
        XCTAssertThrowsError(try database.insert(GitRepo(path: "/tmp/alpha", name: "alpha again")))
    }

    /// A folder can be a project and have a File Browser window: the kind is
    /// part of the key, each lookup finds its own row, and the project list
    /// never shows the File Browser one.
    func testAFileBrowserRowSharesAPathWithAProjectButIsNeverListed() throws {
        let database = try makeDatabase()
        let project = GitRepo(path: "/tmp/alpha", name: "alpha")
        let browser = GitRepo(path: "/tmp/alpha", name: "alpha", kind: .fileBrowser)
        try database.insert(project)
        try database.insertRow(browser)

        XCTAssertEqual(try database.repo(path: "/tmp/alpha")?.id, project.id)
        XCTAssertEqual(try database.repo(path: "/tmp/alpha", kind: .fileBrowser)?.id, browser.id)
        XCTAssertEqual(try database.allRepos().map(\.id), [project.id])
    }

    func testListingIsSortedByNameCaseInsensitively() throws {
        let database = try makeDatabase()
        try database.insert(GitRepo(path: "/tmp/one", name: "zebra"))
        try database.insert(GitRepo(path: "/tmp/two", name: "Apple"))
        try database.insert(GitRepo(path: "/tmp/three", name: "mango"))

        XCTAssertEqual(try database.allRepos().map(\.name), ["Apple", "mango", "zebra"])
    }

    func testMarkOpenedRecordsTheTimeWithoutTouchingAnythingElse() throws {
        let database = try makeDatabase()
        let repo = GitRepo(path: "/tmp/alpha", name: "alpha")
        try database.insert(repo)
        XCTAssertNil(try database.repo(id: repo.id)?.lastOpened)

        try database.markOpened(id: repo.id, at: Date(timeIntervalSince1970: 9_000))

        let loaded = try XCTUnwrap(database.repo(id: repo.id))
        XCTAssertEqual(loaded.lastOpened?.timeIntervalSince1970, 9_000)
        XCTAssertEqual(loaded.name, "alpha")
        XCTAssertEqual(loaded.path, "/tmp/alpha")
    }

    /// The user's name for a project is the one fact about it that no scan may
    /// overwrite, so it has to survive a move.
    func testRenamingAndMovingARepoKeepsItsIdentity() throws {
        let database = try makeDatabase()
        var repo = GitRepo(path: "/tmp/alpha", name: "alpha")
        try database.insert(repo)
        repo.name = "The Alpha Project"
        repo.path = "/tmp/moved/alpha"
        try database.update(repo)

        let loaded = try XCTUnwrap(database.repo(id: repo.id))
        XCTAssertEqual(loaded.name, "The Alpha Project")
        XCTAssertEqual(loaded.path, "/tmp/moved/alpha")
        XCTAssertEqual(try database.allRepos().count, 1)
    }

    func testSettingsAreScopedToTheirRepo() throws {
        let database = try makeDatabase()
        let alpha = GitRepo(path: "/tmp/alpha", name: "alpha")
        let beta = GitRepo(path: "/tmp/beta", name: "beta")
        try database.insert(alpha)
        try database.insert(beta)

        try database.setSetting(repoID: alpha.id, key: "terminal.shell", value: "/bin/zsh")
        try database.setSetting(repoID: beta.id, key: "terminal.shell", value: "/bin/bash")

        XCTAssertEqual(try database.setting(repoID: alpha.id, key: "terminal.shell"), "/bin/zsh")
        XCTAssertEqual(try database.settings(repoID: beta.id), ["terminal.shell": "/bin/bash"])
    }

    func testWritingASettingTwiceReplacesIt() throws {
        let database = try makeDatabase()
        let repo = GitRepo(path: "/tmp/alpha", name: "alpha")
        try database.insert(repo)

        try database.setSetting(repoID: repo.id, key: "theme", value: "dark")
        try database.setSetting(repoID: repo.id, key: "theme", value: "light")

        XCTAssertEqual(try database.settings(repoID: repo.id), ["theme": "light"])
    }

    /// "Unset" and "set to empty" are different answers, so `nil` removes the
    /// row rather than storing an empty string.
    func testWritingNilRemovesTheSetting() throws {
        let database = try makeDatabase()
        let repo = GitRepo(path: "/tmp/alpha", name: "alpha")
        try database.insert(repo)

        try database.setSetting(repoID: repo.id, key: "theme", value: "")
        XCTAssertEqual(try database.setting(repoID: repo.id, key: "theme"), "")

        try database.setSetting(repoID: repo.id, key: "theme", value: nil)
        XCTAssertNil(try database.setting(repoID: repo.id, key: "theme"))
    }

    /// Reopening the file has to find the same rows, and re-running migrations
    /// against an already-migrated file has to be a no-op (`idempotency`).
    func testReopeningTheSameFileFindsTheSameRows() throws {
        let path = tempRoot.appendingPathComponent("Reopen.db").path
        let repo = GitRepo(path: "/tmp/alpha", name: "alpha")
        do {
            let database = try ProjectDatabase(path: path)
            try database.insert(repo)
            try database.setSetting(repoID: repo.id, key: "theme", value: "dark")
            try database.checkpoint()
        }
        let reopened = try ProjectDatabase(path: path)
        XCTAssertEqual(try reopened.allRepos().map(\.id), [repo.id])
        XCTAssertEqual(try reopened.setting(repoID: repo.id, key: "theme"), "dark")
    }

    /// The database directory is created on demand: the app's dotfolder does
    /// not exist on a machine that has never run it.
    func testTheDatabaseDirectoryIsCreatedOnDemand() throws {
        let path = tempRoot
            .appendingPathComponent("not-yet-there", isDirectory: true)
            .appendingPathComponent("Projects.db").path
        _ = try ProjectDatabase(path: path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    /// The file is named for its contents, not for the app, so two display
    /// names differing only in capitalization resolve to one database rather
    /// than to a real one and an empty one beside it.
    func testDefaultPathIsUnchangedByTheCaseOfTheToken() {
        let home = URL(fileURLWithPath: "/tmp/home")
        XCTAssertEqual(
            ProjectDatabase.defaultPath(inHome: home, token: "COFFEEgrinder"),
            ProjectDatabase.defaultPath(inHome: home, token: "CoffeeGrinder"))
        XCTAssertEqual(
            ProjectDatabase.defaultPath(inHome: home, token: "CoffeeGrinder"),
            "/tmp/home/.coffeegrinder/Projects.db")
    }

    // MARK: - Helpers

    private func makeDatabase() throws -> ProjectDatabase {
        try ProjectDatabase(path: tempRoot.appendingPathComponent("Test.db").path)
    }
}
