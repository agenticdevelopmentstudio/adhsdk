import XCTest
import SQLite3
import AgenticDeveloperHubSDKMacOS

/// The project registry's storage contract: a repository is a row, its
/// settings hang off that row, and nothing about it is a file on disk.
@MainActor
final class ProjectDatabaseTests: XCTestCase {

    private var tempRoot: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("project-db-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempRoot)
        try await super.tearDown()
    }

    // MARK: - Repositories

    /// v1 kept a repository the scan could not find, marked `missing_since`.
    /// v2 drops the column — and deliberately keeps every row, marked or not:
    /// the scan that follows is what decides which of them are really gone, and
    /// it can only keep a project's id and settings if the row is still there.
    func testOpeningAV1DatabaseDropsMissingSinceAndKeepsEveryRow() throws {
        let path = tempRoot.appendingPathComponent("v1.db").path
        try writeV1Database(at: path)

        let database = try ProjectDatabase(path: path)
        let names = try database.allRepos().map(\.name)
        XCTAssertEqual(names, ["gone", "here"])
        // The column is gone, so every write goes through the v2 shape.
        var repo = try XCTUnwrap(database.repo(path: "/tmp/gone"))
        repo.name = "renamed"
        try database.update(repo)
        XCTAssertEqual(try database.repo(id: repo.id)?.name, "renamed")
    }

    /// v3 is what makes a reopened window look like it did: a size per pane,
    /// and a bag of state per pane. An older file has to gain both on the way
    /// in, or the first save writes to columns that are not there.
    func testOpeningAnOlderDatabaseGainsPaneSizesAndPaneState() throws {
        let path = tempRoot.appendingPathComponent("v1-to-v3.db").path
        try writeV1Database(at: path)

        let database = try ProjectDatabase(path: path)
        let repo = try XCTUnwrap(database.repo(path: "/tmp/here"))
        let leaf = LayoutNode.leaf(contentType: ComposableTabsViewID("test.editor"), thicknessFraction: 0.4)
        let tab = TabRecord(title: "Code", root: leaf)
        try database.saveTabs([tab], activeTabID: tab.id, repoID: repo.id)

        let loaded = try XCTUnwrap(database.loadTabs(repoID: repo.id).tabs.first).root
        XCTAssertEqual(try XCTUnwrap(loaded.thicknessFraction), 0.4, accuracy: 0.0001)

        try database.setPaneState(repoID: repo.id, nodeID: leaf.id, key: "selected", value: "/tmp/a.swift")
        XCTAssertEqual(try database.paneState(repoID: repo.id, nodeID: leaf.id, key: "selected"),
                       "/tmp/a.swift")
    }

    /// The state an older, un-transacted build could leave behind: a schema
    /// statement that landed and the `INSERT` recording it that did not. The
    /// next launch re-ran the schema statement, `ALTER TABLE ... ADD COLUMN`
    /// failed with `duplicate column name`, and every project, tab and pane in
    /// the file became permanently unreachable. Each migration checks before
    /// it alters, so the re-run is a no-op instead (`idempotency`).
    func testAMigrationWhoseVersionRowIsMissingReRunsWithoutFailing() throws {
        let path = tempRoot.appendingPathComponent("half-migrated.db").path
        let repo = GitRepo(path: "/tmp/half", name: "half")
        try autoreleasepool {
            let database = try ProjectDatabase(path: path)
            try database.insert(repo)
        }
        // The schema is current; only the bookkeeping is behind it.
        try executeRaw("DELETE FROM schema_migrations WHERE version = 4", at: path)

        let reopened = try ProjectDatabase(path: path)
        XCTAssertEqual(try reopened.repo(id: repo.id)?.name, "half")
        let tab = TabRecord(title: "Code", root: LayoutNode.leaf(contentType: ComposableTabsViewID("test.editor")))
        try reopened.saveTabs([tab], activeTabID: tab.id, repoID: repo.id)
        XCTAssertEqual(try reopened.loadTabs(repoID: repo.id).tabs.map(\.title), ["Code"])
    }

    /// A project saved before the global tab position wrote `'top'` as the
    /// old default, which read as a choice; migration 7 makes it follow the
    /// global position, and leaves a real multi-edge choice alone (final
    /// review C-I1).
    func testOldDefaultTopEdgesFollowTheGlobalPositionAfterUpgrade() throws {
        let path = tempRoot.appendingPathComponent("edges.db").path
        let defaulted = GitRepo(path: "/tmp/defaulted", name: "defaulted")
        let chosen = GitRepo(path: "/tmp/chosen", name: "chosen")
        try autoreleasepool {
            let database = try ProjectDatabase(path: path)
            try database.insert(defaulted)
            try database.insert(chosen)
            for repo in [defaulted, chosen] {
                let leaf = LayoutNode.leaf(contentType: ComposableTabsViewID("test.editor"))
                let tab = TabRecord(title: "Code", root: leaf)
                try database.saveTabs([tab], activeTabID: tab.id, repoID: repo.id)
            }
        }
        // As the pre-branch build left them: the default written out.
        let update = "UPDATE project_state SET enabled_edges"
        try executeRaw("\(update) = 'top' WHERE repo_id = '\(defaulted.id.uuidString)'", at: path)
        try executeRaw("\(update) = 'top,left' WHERE repo_id = '\(chosen.id.uuidString)'", at: path)
        try executeRaw("DELETE FROM schema_migrations WHERE version = 7", at: path)

        let reopened = try ProjectDatabase(path: path)
        XCTAssertNil(try reopened.loadTabs(repoID: defaulted.id).enabledEdges)
        XCTAssertEqual(try reopened.loadTabs(repoID: chosen.id).enabledEdges, [.top, .left])
        // After the upgrade, choosing top alone is a choice and stays one.
        let leaf = LayoutNode.leaf(contentType: ComposableTabsViewID("test.editor"))
        let tab = TabRecord(title: "Code", root: leaf)
        try reopened.saveTabs([tab], activeTabID: tab.id, enabledEdges: [.top], repoID: defaulted.id)
        XCTAssertEqual(try reopened.loadTabs(repoID: defaulted.id).enabledEdges, [.top])
    }

    /// The same thing at its limit: every version row gone, so the whole chain
    /// re-runs over a schema that already has all of it.
    func testTheWholeMigrationChainIsSafeToReRunOverACurrentSchema() throws {
        let path = tempRoot.appendingPathComponent("rewound.db").path
        let repo = GitRepo(path: "/tmp/rewound", name: "rewound")
        try autoreleasepool {
            let database = try ProjectDatabase(path: path)
            try database.insert(repo)
        }
        try executeRaw("DELETE FROM schema_migrations", at: path)

        let reopened = try ProjectDatabase(path: path)
        XCTAssertEqual(try reopened.repo(id: repo.id)?.name, "rewound")
    }

    // MARK: - Settings

    /// Deleting a project takes its configuration with it — there is no file to
    /// throw away, so the cascade is the whole cleanup.
    func testDeletingARepoCascadesToItsSettingsAndDirectories() throws {
        let database = try makeDatabase()
        let repo = GitRepo(path: "/tmp/alpha", name: "alpha")
        try database.insert(repo)
        try database.setSetting(repoID: repo.id, key: "theme", value: "dark")
        try database.saveProjectDirectories(["/tmp/notes"], repoID: repo.id)

        try database.delete(id: repo.id)

        XCTAssertNil(try database.repo(id: repo.id))
        XCTAssertTrue(try database.settings(repoID: repo.id).isEmpty)
        XCTAssertEqual(try database.loadProjectDirectories(repoID: repo.id), [])
    }

    // MARK: - Helpers

    private func makeDatabase() throws -> ProjectDatabase {
        try ProjectDatabase(path: tempRoot.appendingPathComponent("Test.db").path)
    }

    /// Edits a database behind `ProjectDatabase`'s back, which is the only way
    /// to produce the half-applied states an older build could leave on disk.
    private func executeRaw(_ sql: String, at path: String) throws {
        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open(path, &handle), SQLITE_OK)
        defer { sqlite3_close(handle) }
        XCTAssertEqual(sqlite3_exec(handle, sql, nil, nil, nil), SQLITE_OK, sql)
    }

    /// The v1 tables the later migrations touch — `git_repo`, and the
    /// v1's tables, plus two repository rows: one the scan had written off and
    /// one it had not. Hand-written rather than produced by the app, because
    /// the app can no longer make a v1 file — which is exactly why the whole
    /// schema is here and not just the one table a given test reads.
    private func writeV1Database(at path: String) throws {
        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open(path, &handle), SQLITE_OK)
        defer { sqlite3_close(handle) }

        for sql in [
            """
            CREATE TABLE schema_migrations (
                version INTEGER PRIMARY KEY,
                applied_at TEXT NOT NULL DEFAULT (datetime('now'))
            )
            """,
            """
            CREATE TABLE git_repo (
                id TEXT PRIMARY KEY,
                path TEXT NOT NULL UNIQUE,
                name TEXT NOT NULL,
                remote TEXT,
                first_seen REAL NOT NULL,
                last_seen REAL NOT NULL,
                last_opened REAL,
                missing_since REAL
            )
            """,
            """
            CREATE TABLE layout_nodes (
                id TEXT PRIMARY KEY,
                repo_id TEXT NOT NULL REFERENCES git_repo(id) ON DELETE CASCADE,
                parent_id TEXT REFERENCES layout_nodes(id) ON DELETE CASCADE,
                position INTEGER NOT NULL,
                kind TEXT NOT NULL CHECK(kind IN ('split','leaf')),
                orientation TEXT,
                content_type TEXT,
                pane_label TEXT
            )
            """,
            """
            CREATE TABLE project_setting (
                repo_id TEXT NOT NULL REFERENCES git_repo(id) ON DELETE CASCADE,
                key TEXT NOT NULL,
                value TEXT NOT NULL,
                PRIMARY KEY (repo_id, key)
            )
            """,
            """
            CREATE TABLE project_tabs (
                id TEXT PRIMARY KEY,
                repo_id TEXT NOT NULL REFERENCES git_repo(id) ON DELETE CASCADE,
                position INTEGER NOT NULL,
                title TEXT NOT NULL,
                edge TEXT NOT NULL DEFAULT 'top',
                group_id TEXT,
                root_node_id TEXT REFERENCES layout_nodes(id),
                focused_node_id TEXT REFERENCES layout_nodes(id)
            )
            """,
            """
            CREATE TABLE project_state (
                repo_id TEXT PRIMARY KEY REFERENCES git_repo(id) ON DELETE CASCADE,
                active_tab_id TEXT REFERENCES project_tabs(id),
                enabled_edges TEXT NOT NULL DEFAULT 'top'
            )
            """,
            """
            CREATE TABLE project_directories (
                repo_id TEXT NOT NULL REFERENCES git_repo(id) ON DELETE CASCADE,
                position INTEGER NOT NULL,
                path TEXT NOT NULL,
                PRIMARY KEY (repo_id, position)
            )
            """,
            """
            INSERT INTO git_repo (id, path, name, first_seen, last_seen, missing_since)
            VALUES ('\(UUID().uuidString)', '/tmp/gone', 'gone', 1, 1, 5000)
            """,
            """
            INSERT INTO git_repo (id, path, name, first_seen, last_seen)
            VALUES ('\(UUID().uuidString)', '/tmp/here', 'here', 1, 1)
            """,
            "INSERT INTO schema_migrations (version) VALUES (1)"
        ] {
            XCTAssertEqual(sqlite3_exec(handle, sql, nil, nil, nil), SQLITE_OK, sql)
        }
    }
}
