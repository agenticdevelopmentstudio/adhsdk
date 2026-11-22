import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// schema 46 must arrive intact on a brand-new DB *and* on one that already
/// records version 46 — a branch that re-runs an unguarded ALTER has taken the
/// daemon down silently before.
final class BillingMigrationTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "billing-migration-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/billing-migration.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    private func columns(of table: String) throws -> Set<String> {
        var names: Set<String> = []
        try database.query("PRAGMA table_info(\(table))") { row in
            names.insert(row[1] ?? "")
        }
        return names
    }

    func testAllSixTablesExist() throws {
        for table in [
            "billing_client", "billing_project", "billing_repo",
            "billing_segment", "billing_entry", "billing_entry_audit"
        ] {
            var count = 0
            try database.query("SELECT COUNT(*) FROM \(table)") { row in count = row[0] ?? -1 }
            XCTAssertEqual(count, 0, "\(table) exists and is empty on a fresh DB")
        }
    }

    func testMigration047AddsIdleCutoffAndIsIdempotent() throws {
        // Put the table into its pre-047 state, then upgrade it.
        try database.execute("ALTER TABLE billing_project DROP COLUMN idle_cutoff_minutes")
        XCTAssertFalse(try columns(of: "billing_project").contains("idle_cutoff_minutes"))
        try DaemonDatabase.migration1003(database.db)
        XCTAssertTrue(try columns(of: "billing_project").contains("idle_cutoff_minutes"))
        XCTAssertNoThrow(try DaemonDatabase.migration1003(database.db), "a second run is a no-op")
    }

    private func indexes(of table: String) throws -> Set<String> {
        var names: Set<String> = []
        try database.query(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = ?", params: [table]
        ) { row in names.insert(row["name"] ?? "") }
        return names
    }

    private func recordedVersions() throws -> Set<Int> {
        var versions: Set<Int> = []
        try database.query("SELECT version FROM schema_migrations") { row in versions.insert(row[0] ?? 0) }
        return versions
    }

    /// The upgrade path: a database at 047 — no activity tables, no record of
    /// 48 — gains both tables and all three indexes when the daemon opens it,
    /// records 48, and keeps the billing data it already held.
    func testMigration048UpgradesADatabaseAt047() throws {
        try database.execute("INSERT INTO billing_project(id, name, idle_cutoff_minutes) VALUES ('p1', 'Alpha', 20)")
        try database.execute("DROP TABLE activity_span")
        try database.execute("DROP TABLE activity_presence")
        try database.execute("DELETE FROM schema_migrations WHERE version >= 48")
        XCTAssertFalse(try database.tableExists("activity_span"))
        XCTAssertEqual(try recordedVersions().max(), 47)

        database = nil
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)

        XCTAssertTrue(try recordedVersions().contains(48))
        XCTAssertEqual(try columns(of: "activity_span"), [
            "id", "bundle_id", "app_name", "window_title", "working_path", "repo_root", "branch",
            "started_at", "ended_at", "tz", "last_seen_at", "billing_derived_at"
        ])
        XCTAssertEqual(try columns(of: "activity_presence"), ["id", "idle_from", "idle_until"])
        XCTAssertTrue(try indexes(of: "activity_span").isSuperset(of: [
            "idx_activity_span_started", "idx_activity_span_pending"
        ]))
        XCTAssertTrue(try indexes(of: "activity_presence").contains("idx_activity_presence_from"))
        XCTAssertEqual(try database.billingProject(id: "p1")?.idleCutoffMinutes, 20, "047 data survives")
    }

    /// Branch divergence: the tables exist (with rows) but 48 is not recorded,
    /// so the runner re-runs 048 over them. It must neither throw nor touch
    /// the rows.
    func testMigration048RerunOverExistingTablesKeepsTheirRows() throws {
        try database.execute("""
            INSERT INTO activity_span (id, bundle_id, app_name, started_at, tz)
            VALUES ('s1', 'com.apple.dt.Xcode', 'Xcode', '2026-10-01T09:00:00Z', 'UTC')
        """)
        try database.execute("DELETE FROM schema_migrations WHERE version >= 48")

        database = nil
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)

        XCTAssertTrue(try recordedVersions().contains(48))
        var count = 0
        try database.query("SELECT COUNT(*) FROM activity_span") { row in count = row[0] ?? -1 }
        XCTAssertEqual(count, 1)
        XCTAssertNoThrow(try DaemonDatabase.migration1004(database.db))
    }

    func testSessionsGainsTheDerivationWatermarkColumn() throws {
        XCTAssertTrue(try columns(of: "sessions").contains("billing_derived_at"))
    }

    /// Sessions that predate the upgrade are marked consumed, so the first
    /// billing pass derives nothing from history. Simulated by dropping the
    /// column and re-running the migration over a session that already exists.
    func testExistingSessionsAreNotBackfilledAutomatically() throws {
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, started_at, last_activity_at, status)
            VALUES ('old', '/src/app', '2026-01-01T09:00:00Z', '2026-01-01T10:00:00Z', 'ended')
        """)
        try database.execute("DROP INDEX IF EXISTS idx_sessions_billing_pending")
        try database.execute("ALTER TABLE sessions DROP COLUMN billing_derived_at")

        try DaemonDatabase.migration1002(database.db)

        var watermark = ""
        try database.query(
            "SELECT billing_derived_at FROM sessions WHERE session_id = 'old'"
        ) { row in watermark = row["billing_derived_at"] ?? "" }
        XCTAssertEqual(watermark, "2026-01-01T10:00:00Z")
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty)
    }

    /// The column and its backfill are one step. If the backfill fails after
    /// the column is added, a retry would find the column, skip the backfill
    /// and leave every old session looking unconsumed — so the first pass
    /// would derive all of history. The failure must roll the column back.
    func testAFailedBackfillLeavesNoColumnBehind() throws {
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, started_at, last_activity_at, status)
            VALUES ('old', '/src/app', '2026-01-01T09:00:00Z', '2026-01-01T10:00:00Z', 'ended')
        """)
        try database.execute("DROP INDEX IF EXISTS idx_sessions_billing_pending")
        try database.execute("ALTER TABLE sessions DROP COLUMN billing_derived_at")
        try database.execute("""
            CREATE TRIGGER fail_backfill BEFORE UPDATE ON sessions
            BEGIN SELECT RAISE(ABORT, 'database or disk is full'); END
        """)

        XCTAssertThrowsError(try DaemonDatabase.migration1002(database.db))
        XCTAssertFalse(try columns(of: "sessions").contains("billing_derived_at"),
                       "a retry must find no column, so it runs the backfill too")

        try database.execute("DROP TRIGGER fail_backfill")
        try DaemonDatabase.migration1002(database.db)
        var watermark = ""
        try database.query(
            "SELECT billing_derived_at FROM sessions WHERE session_id = 'old'"
        ) { row in watermark = row["billing_derived_at"] ?? "" }
        XCTAssertEqual(watermark, "2026-01-01T10:00:00Z")
    }

    /// The covering index is only a speed-up. Failing to build it must not
    /// keep the daemon from opening — here the name is taken by a table, so
    /// the `CREATE INDEX` throws every launch.
    func testAFailedTurnTokenIndexBuildDoesNotStopTheDatabaseOpening() throws {
        try database.execute("DROP INDEX IF EXISTS idx_transcript_turns_time_tokens")
        try database.execute("CREATE TABLE idx_transcript_turns_time_tokens (x INTEGER)")

        database = nil
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        XCTAssertTrue(database.isReady)
    }

    func testEntryCarriesBothRawAndBilledSeconds() throws {
        let entry = try columns(of: "billing_entry")
        XCTAssertTrue(entry.contains("raw_seconds"), "raw survives rounding")
        XCTAssertTrue(entry.contains("billed_seconds"))
        XCTAssertTrue(entry.contains("rate_cents"), "the rate is snapshotted onto the row")
        XCTAssertTrue(entry.contains("supplements_entry_id"))
        XCTAssertTrue(entry.contains("locked"))
    }

    /// A repo-and-branch pair resolves to exactly one project, deterministically.
    func testRepoRootAndBranchAreUnique() throws {
        try database.execute(
            "INSERT INTO billing_project(id, name) VALUES ('p1', 'Alpha')"
        )
        try database.execute("""
            INSERT INTO billing_repo(id, project_id, project_root, branch)
            VALUES ('r1', 'p1', '/Users/me/app', '')
        """)
        XCTAssertThrowsError(
            try database.execute("""
                INSERT INTO billing_repo(id, project_id, project_root, branch)
                VALUES ('r2', 'p1', '/Users/me/app', '')
            """),
            "a second row for the same (root, branch) must be rejected"
        )
    }

    /// Status is constrained at the storage layer, not just in Swift.
    func testEntryStatusIsConstrained() throws {
        try database.execute("INSERT INTO billing_project(id, name) VALUES ('p1', 'Alpha')")
        XCTAssertThrowsError(try database.execute("""
            INSERT INTO billing_entry(
                id, project_id, day, raw_seconds, billed_seconds,
                rate_cents, amount_cents, status
            ) VALUES ('e1', 'p1', '2026-09-22', 60, 900, 12500, 3125, 'invoiced')
        """))
    }

    /// Re-running the migration on a DB that already has it is a no-op, not a
    /// throw. This is the regression that took the daemon down silently.
    func testMigrationIsIdempotent() throws {
        try DaemonDatabase.migration1002(database.db)
        try DaemonDatabase.migration1002(database.db)
        XCTAssertTrue(try columns(of: "sessions").contains("billing_derived_at"))
    }

    /// Reopening the DB re-runs `runMigrations` against a recorded version 46.
    func testReopeningAnAlreadyMigratedDatabaseSucceeds() throws {
        database = nil
        let reopened = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        var count = 0
        try reopened.query("SELECT COUNT(*) FROM billing_client") { row in count = row[0] ?? -1 }
        XCTAssertEqual(count, 0)
    }

    /// The live DB recorded version 46 from an earlier build of this branch,
    /// before `billing_entry` gained `description_edited`. The version gate
    /// skips migration1002 there, so the column must arrive another way — or
    /// every rollup after the first throws "no such column".
    func testAVersion46DatabaseWithoutTheDescriptionFlagGainsItAndRolls() throws {
        try database.execute("ALTER TABLE billing_entry DROP COLUMN description_edited")
        XCTAssertFalse(try columns(of: "billing_entry").contains("description_edited"))

        database = nil
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)

        XCTAssertTrue(try columns(of: "billing_entry").contains("description_edited"))
        let project = try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: "P", defaultRateCents: 10_000), database: database
        )
        let timer = try BillingTimer.start(
            BillingTimerStartDTO(projectId: project.id), now: "2026-09-22T09:00:00Z", database: database
        )
        _ = try BillingTimer.stop(id: timer.id, now: "2026-09-22T09:30:00Z", database: database)
        XCTAssertGreaterThan(try BillingRollup.run(options: BillingRollupOptions(), database: database), 0)
        _ = try BillingRollup.run(options: BillingRollupOptions(), database: database)
        XCTAssertEqual(try database.billingEntries(projectId: nil, status: nil, since: "").count, 1)
    }

    /// The same for `billing_entry.billed_ranges`, the ranges each entry
    /// owns: a version-46 database without it gains it on open, an entry
    /// rolled there records what it bills, and gaining it twice is a no-op.
    func testAVersion46DatabaseWithoutTheEntryBilledRangesGainsItAndRecordsThem() throws {
        // Version 46 had neither the column nor the indexes built on it.
        try database.execute("DROP INDEX idx_billing_entry_project_billed_start")
        try database.execute("DROP INDEX idx_billing_entry_project_billed_span")
        try database.execute("ALTER TABLE billing_entry DROP COLUMN billed_ranges")
        XCTAssertFalse(try columns(of: "billing_entry").contains("billed_ranges"))

        database = nil
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        XCTAssertTrue(try columns(of: "billing_entry").contains("billed_ranges"))
        XCTAssertTrue(try indexes(of: "billing_entry").isSuperset(of: [
            "idx_billing_entry_project_billed_start", "idx_billing_entry_project_billed_span"
        ]))
        try DaemonDatabase.ensureBillingEntryBilledRangesColumn(database.db)
        XCTAssertTrue(try columns(of: "billing_entry").contains("billed_ranges"))

        let project = try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: "P", defaultRateCents: 10_000), database: database
        )
        let timer = try BillingTimer.start(
            BillingTimerStartDTO(projectId: project.id), now: "2026-09-22T09:00:00Z", database: database
        )
        _ = try BillingTimer.stop(id: timer.id, now: "2026-09-22T09:30:00Z", database: database)
        _ = try BillingRollup.run(options: BillingRollupOptions(), database: database)
        let entry = try XCTUnwrap(database.billingEntries(projectId: nil, status: nil, since: "").first)
        let stored = try XCTUnwrap(
            database.billingEntriesOnDay(projectId: project.id, day: entry.day).first { $0.entry.id == entry.id }
        )
        let start = try XCTUnwrap(UTCTimestamp.epochSeconds("2026-09-22T09:00:00Z"))
        XCTAssertEqual(stored.billedRanges, "\(start)-\(start + 1800)")
    }

    /// The first frozen-range index, by range end alone, is dropped on open:
    /// it served a query no longer made.
    func testTheRangeEndIndexIsDroppedOnOpen() throws {
        try database.execute("""
            CREATE INDEX idx_billing_entry_project_billed_end
            ON billing_entry(project_id, \(DaemonDatabase.billedEndSQL)) WHERE \(DaemonDatabase.frozenWithRangesSQL)
        """)
        try DaemonDatabase.ensureBillingIndexes(database.db)
        XCTAssertFalse(try indexes(of: "billing_entry").contains("idx_billing_entry_project_billed_end"))
    }

    /// Settling a day reads every entry of a project on that day and every
    /// entry overlapping its window, whatever the status: both are indexed
    /// for all rows, and an index dropped by hand comes back on reopening.
    func testEveryEntryOfAProjectDayAndItsStartAreIndexed() throws {
        let wanted: Set<String> = [
            "idx_billing_entry_project_day_all", "idx_billing_entry_project_started",
            "idx_billing_entry_project_length", "idx_billing_entry_project_billed_start",
            "idx_billing_entry_project_billed_span"
        ]
        XCTAssertTrue(wanted.isSubset(of: try indexes(of: "billing_entry")))
        for index in wanted { try database.execute("DROP INDEX \(index)") }
        try DaemonDatabase.ensureBillingIndexes(database.db)
        try DaemonDatabase.ensureBillingIndexes(database.db)
        XCTAssertTrue(wanted.isSubset(of: try indexes(of: "billing_entry")))
    }

    private func plan(_ sql: String, _ params: [any Sendable]) throws -> String {
        var plan: [String] = []
        try database.query("EXPLAIN QUERY PLAN " + sql, params: params) { row in plan.append(row["detail"] ?? "") }
        return plan.joined(separator: "\n")
    }

    /// Review F4/F41: the lookbacks are read off the end of a length index —
    /// the longest segment, entry and closed idle row — and come back when
    /// dropped by hand.
    func testTheLookbackLengthIndexesExistAndServeTheirReads() throws {
        let segment = ["idx_billing_segment_project_length"]
        let presence = ["idx_activity_presence_length", "idx_activity_presence_open"]
        XCTAssertTrue(Set(segment).isSubset(of: try indexes(of: "billing_segment")))
        XCTAssertTrue(Set(presence).isSubset(of: try indexes(of: "activity_presence")))
        for index in segment + presence { try database.execute("DROP INDEX \(index)") }
        try DaemonDatabase.ensureBillingIndexes(database.db)
        XCTAssertTrue(Set(segment).isSubset(of: try indexes(of: "billing_segment")))
        XCTAssertTrue(Set(presence).isSubset(of: try indexes(of: "activity_presence")))

        for table in ["billing_segment", "billing_entry"] {
            let text = try plan(DaemonDatabase.longestSQL(table), ["p"])
            XCTAssertTrue(text.contains("_project_length"), text)
            XCTAssertFalse(text.contains("TEMP B-TREE"), "no sort: \(text)")
        }
        let idle = try plan(DaemonDatabase.longestIdleSQL, [])
        XCTAssertTrue(idle.contains("idx_activity_presence_length"), idle)
        XCTAssertFalse(idle.contains("TEMP B-TREE"), "no sort: \(idle)")
    }

    /// Review F41: the idle-row read seeks open rows through their partial
    /// index and closed rows through a start range bounded on both sides.
    func testTheIdleRowReadIsABoundedRange() throws {
        let text = try plan(DaemonDatabase.idleIntervalsSQL, [
            "2026-10-01T10:00:00Z", "2026-10-01T09:00:00Z", "2026-10-01T08:00:00Z", "2026-10-01T10:00:00Z"
        ])
        XCTAssertTrue(text.contains("idx_activity_presence_open (idle_from<?)"), text)
        XCTAssertTrue(text.contains("idx_activity_presence_from (idle_from>? AND idle_from<?)"), text)
        XCTAssertFalse(text.contains("SCAN activity_presence"), text)
    }
}
