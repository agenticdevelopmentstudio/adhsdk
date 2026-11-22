import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// Schema 48 and the billing reads over it: which spans a pass derives, which
/// idle intervals cut them, and how app segments stay out of the session paths.
final class BillingAppSpanTests: XCTestCase {
    var tmpPath: String!
    var database: DaemonDatabase!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "billing-app-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/billing-app.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    private func insertSpan(
        _ id: String, root: String = "/src/app", title: String = "a.swift", start: String, end: String
    ) throws {
        try database.execute("""
            INSERT INTO activity_span (id, bundle_id, app_name, window_title, working_path, repo_root, branch,
                                       started_at, ended_at, tz)
            VALUES (?, 'com.apple.dt.Xcode', 'Xcode', ?, ?, ?, 'main', ?, ?, 'UTC')
        """, params: [id, title, root + "/a.swift", root, start, end])
    }

    func testMigration048IsIdempotent() throws {
        try DaemonDatabase.migration1004(database.db)
        try DaemonDatabase.migration1004(database.db)
        XCTAssertTrue(try database.tableExists("activity_span"))
        XCTAssertTrue(try database.tableExists("activity_presence"))
    }

    func testPendingSelectionAndMark() throws {
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        try insertSpan("b", start: "2026-10-01T10:00:00Z", end: "")
        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).map(\.id), ["a", "b"])
        try database.markAppSpanBillingDerived(spanId: "a", at: "2026-10-01T09:30:00Z")
        try database.markAppSpanBillingDerived(spanId: "b", at: "")
        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).map(\.id), ["b"],
                       "an open span is re-derived every pass")
    }

    func testPendingRowCarriesEveryColumn() throws {
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        let row = try XCTUnwrap(database.billingAppSpansNeedingDerivation(limit: 1).first)
        XCTAssertEqual(row, BillingAppSpanRow(
            id: "a", bundleId: "com.apple.dt.Xcode", appName: "Xcode", windowTitle: "a.swift",
            workingPath: "/src/app/a.swift", repoRoot: "/src/app", branch: "main",
            startedAt: "2026-10-01T09:00:00Z", endedAt: "2026-10-01T09:30:00Z", tz: "UTC"))
        XCTAssertEqual(row.sessionId, ActivitySpanSession.sessionId(spanId: "a"))
    }

    func testIdleIntervalsOverlapQuery() throws {
        for (id, from, until) in [("1", "2026-10-01T08:00:00Z", "2026-10-01T08:30:00Z"),
                                  ("2", "2026-10-01T09:10:00Z", "2026-10-01T09:20:00Z"),
                                  ("3", "2026-10-01T09:50:00Z", "")] {
            try database.execute("INSERT INTO activity_presence (id, idle_from, idle_until) VALUES (?, ?, ?)",
                                 params: [id, from, until])
        }
        let hits = try database.billingIdleIntervals(from: "2026-10-01T09:00:00Z", to: "2026-10-01T10:00:00Z")
        XCTAssertEqual(hits.map(\.idleFrom), ["2026-10-01T09:10:00Z", "2026-10-01T09:50:00Z"])
        let openEnded = try database.billingIdleIntervals(from: "2026-10-01T09:15:00Z", to: "")
        XCTAssertEqual(openEnded.map(\.idleFrom), ["2026-10-01T09:10:00Z", "2026-10-01T09:50:00Z"],
                       "an open span takes every idle that ends after its start")
    }

    func testDeriveWritesAppSegmentsCutAtIdle() throws {
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T10:00:00Z")
        try database.execute("INSERT INTO activity_presence (id, idle_from, idle_until) VALUES (?, ?, ?)",
                             params: ["i", "2026-10-01T09:10:00Z", "2026-10-01T09:30:00Z"])
        let span = try XCTUnwrap(database.billingAppSpansNeedingDerivation(limit: 1).first)
        let written = try BillingStore.deriveAppSegments(for: span, defaultCutoffSeconds: 900, trackUnassigned: true,
                                                         now: "2026-10-01T12:00:00Z", database: database)
        XCTAssertEqual(written, 2)
        var segments: [(String, String, Int)] = []
        try database.query("""
            SELECT session_id, origin, seconds FROM billing_segment ORDER BY started_at
        """) { row in segments.append((row["session_id"] ?? "", row["origin"] ?? "", row["seconds"] ?? 0)) }
        XCTAssertEqual(segments.map(\.0), ["app:a", "app:a"])
        XCTAssertEqual(segments.map(\.1), ["auto", "auto"])
        XCTAssertEqual(segments.map(\.2), [600, 1800])
        XCTAssertTrue(try database.billingAppSpansNeedingDerivation(limit: 10).isEmpty, "the watermark is stamped")
    }

    private func segmentSeconds() throws -> [Int] {
        var seconds: [Int] = []
        try database.query("SELECT seconds FROM billing_segment ORDER BY started_at") { row in
            seconds.append(row["seconds"] ?? -1)
        }
        return seconds
    }

    private func derivePending(now: String) throws {
        for span in try database.billingAppSpansNeedingDerivation(limit: 10) {
            try BillingStore.deriveAppSegments(for: span, defaultCutoffSeconds: 900, trackUnassigned: true,
                                               now: now, database: database)
        }
    }

    /// A closed span overlapped by a still-open idle is billed through the
    /// idle while it is under the cutoff — but stays pending, so once the idle
    /// closes past the cutoff the idle stretch comes back out.
    func testClosedSpanWithOpenIdleStaysPendingUntilTheIdleCloses() throws {
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T10:00:00Z")
        try database.execute("INSERT INTO activity_presence (id, idle_from, idle_until) VALUES ('i', ?, '')",
                             params: ["2026-10-01T09:50:00Z"])

        try derivePending(now: "2026-10-01T10:01:00Z")
        XCTAssertEqual(try segmentSeconds(), [3600], "an 11-minute idle is under the cutoff")
        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).map(\.id), ["a"],
                       "the open idle keeps the span pending")

        try database.execute("UPDATE activity_presence SET idle_until = ? WHERE id = 'i'",
                             params: ["2026-10-01T11:00:00Z"])
        try derivePending(now: "2026-10-01T11:01:00Z")
        XCTAssertEqual(try segmentSeconds(), [3000], "9:50–10:00 is removed, with no duplicate segment")
        XCTAssertTrue(try database.billingAppSpansNeedingDerivation(limit: 10).isEmpty)
    }

    func testPendingQueryUsesThePartialIndex() throws {
        var plan: [String] = []
        try database.query("EXPLAIN QUERY PLAN " + DaemonDatabase.pendingAppSpansSQL, params: [10]) { row in
            plan.append(row["detail"] ?? "")
        }
        XCTAssertTrue(plan.contains { $0.contains("idx_activity_span_pending") }, plan.joined(separator: "\n"))
    }

    /// The claiming project's own cutoff applies to app time too: a 20-minute
    /// idle under a 30-minute override is not a gap.
    func testProjectCutoffOverrideAppliesToAppSpans() throws {
        let project = try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: "Alpha", defaultRateCents: 10_000, idleCutoffMinutes: 30),
            database: database)
        try BillingStore.saveRepo(BillingRepoDTO(id: "", projectId: project.id, projectRoot: "/src/app"),
                                  database: database)
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T10:00:00Z")
        try database.execute("INSERT INTO activity_presence (id, idle_from, idle_until) VALUES ('i', ?, ?)",
                             params: ["2026-10-01T09:10:00Z", "2026-10-01T09:30:00Z"])

        try derivePending(now: "2026-10-01T12:00:00Z")

        XCTAssertEqual(try segmentSeconds(), [3600], "one uncut run")
        var projectIds: [String] = []
        try database.query("SELECT project_id FROM billing_segment") { row in
            projectIds.append(row["project_id"] ?? "")
        }
        XCTAssertEqual(projectIds, [project.id])
    }

    func testOpenAppSegmentsDoNotSelectPhantomSessions() throws {
        try insertSpan("b", start: "2026-10-01T10:00:00Z", end: "")
        _ = try BillingStore.deriveAppSegments(
            for: XCTUnwrap(database.billingAppSpansNeedingDerivation(limit: 1).first),
            defaultCutoffSeconds: 900, trackUnassigned: true,
            now: "2026-10-01T10:05:00Z", database: database)
        XCTAssertEqual(try database.runningBillingSegments(origin: BillingSegmentDTO.autoOrigin).map(\.sessionId),
                       ["app:b"])
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty)
    }

    func testUnassignedWithTrackingOffClosesOpenRunsAndWritesNothingNew() throws {
        try insertSpan("b", start: "2026-10-01T10:00:00Z", end: "")
        let open = try XCTUnwrap(database.billingAppSpansNeedingDerivation(limit: 1).first)
        try BillingStore.deriveAppSegments(for: open, defaultCutoffSeconds: 900, trackUnassigned: true,
                                           now: "2026-10-01T10:05:00Z", database: database)
        try BillingStore.deriveAppSegments(for: open, defaultCutoffSeconds: 900, trackUnassigned: false,
                                           now: "2026-10-01T10:10:00Z", database: database)
        XCTAssertTrue(try database.runningBillingSegments(origin: BillingSegmentDTO.autoOrigin).isEmpty)
    }

    func testResetAlsoQueuesAppSpans() throws {
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        try database.markAppSpanBillingDerived(spanId: "a", at: "2026-10-01T09:30:00Z")
        XCTAssertEqual(try database.resetBillingDerivationOfDerivedSessions(), 1)
        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).map(\.id), ["a"])
    }

    func testAppSessionTitleIsTheAppName() throws {
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        try insertSpan("b", title: "", start: "2026-10-01T08:00:00Z", end: "2026-10-01T08:30:00Z")
        XCTAssertEqual(try database.billingSessionTitles(sessionIds: ["app:a"]).titles, ["Xcode", "in app"])
        XCTAssertEqual(try database.billingSessionTitles(sessionIds: ["app:a", "app:b"]).titles, ["Xcode", "in app"],
                       "one app is named once, however many spans it has")
    }

    /// Window titles can carry anything — a mail subject, a document name —
    /// so an invoice line names the apps and repos and nothing more.
    func testAppDescriptionNamesAppsAndReposNeverWindowTitles() throws {
        try insertSpan("x", title: "Secret.swift — Payroll",
                       start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        try database.execute("""
            INSERT INTO activity_span (id, bundle_id, app_name, window_title, working_path, repo_root, branch,
                                       started_at, ended_at, tz)
            VALUES ('t', 'com.apple.Terminal', 'Terminal', 'ssh prod — confidential', '/src/tools', '/src/tools',
                    'main', '2026-10-01T10:00:00Z', '2026-10-01T10:30:00Z', 'UTC')
        """)
        let titles = try database.billingSessionTitles(sessionIds: ["app:x", "app:t"]).titles
        XCTAssertEqual(titles, ["Terminal", "Xcode", "in app, tools"])
        let joined = titles.joined(separator: " ")
        XCTAssertFalse(joined.contains("Secret") || joined.contains("Payroll") || joined.contains("confidential"))
    }

    /// The reset that re-queues history must re-queue the app spans of that
    /// history too, or a cutoff change re-splits Claude time and not app time.
    func testResetSinceAlsoQueuesAppSpansEndedSinceAndOpenOnes() throws {
        try insertSpan("recent", start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        try insertSpan("ancient", start: "2020-01-01T09:00:00Z", end: "2020-01-01T09:30:00Z")
        try insertSpan("open", start: "2026-10-01T10:00:00Z", end: "")
        try database.markAppSpanBillingDerived(spanId: "recent", at: "2026-10-01T09:30:00Z")
        try database.markAppSpanBillingDerived(spanId: "ancient", at: "2020-01-01T09:30:00Z")
        try database.markAppSpanBillingDerived(spanId: "open", at: "2026-10-01T10:05:00Z")
        XCTAssertEqual(try database.resetBillingDerivation(since: "2025-01-01T00:00:00Z"), 2)
        var derived: [String: String] = [:]
        try database.query("SELECT id, billing_derived_at FROM activity_span") { row in
            derived[row["id"] ?? ""] = row["billing_derived_at"] ?? ""
        }
        XCTAssertEqual(derived, ["recent": "", "open": "", "ancient": "2020-01-01T09:30:00Z"])
    }

    /// A cutoff change and the reset it demands commit together or not at all.
    func testProjectCutoffChangeRollsBackWhenItsResetFails() throws {
        let project = try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: "P", idleCutoffMinutes: 15), database: database)
        _ = try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: project.id, projectRoot: "/src/app"), database: database)
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        try database.markAppSpanBillingDerived(spanId: "a", at: "2026-10-01T09:30:00Z")
        try database.execute("""
            CREATE TEMP TRIGGER fail_reset BEFORE UPDATE OF billing_derived_at ON activity_span
            BEGIN SELECT RAISE(ABORT, 'reset failed'); END
        """)
        let changed = BillingProjectDTO(id: project.id, name: "P", idleCutoffMinutes: 30)
        XCTAssertThrowsError(try BillingStore.saveProject(changed, database: database))
        XCTAssertEqual(try database.billingProject(id: project.id)?.idleCutoffMinutes, 15,
                       "the cutoff did not land without its reset")
        try database.execute("DROP TRIGGER fail_reset")
        XCTAssertEqual(try BillingStore.saveProject(changed, database: database).idleCutoffMinutes, 30)
        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).map(\.id), ["a"],
                       "the retry still sees the change and resets")
    }

    /// Review F42: a project's cutoff change re-derives only what that
    /// project claims — its spans and sessions — and leaves another project's
    /// alone.
    func testAProjectCutoffChangeResetsOnlyThatProjectsTime() throws {
        let mine = try BillingStore.saveProject(BillingProjectDTO(id: "", name: "A"), database: database)
        let other = try BillingStore.saveProject(BillingProjectDTO(id: "", name: "B"), database: database)
        _ = try BillingStore.saveRepo(BillingRepoDTO(id: "", projectId: mine.id, projectRoot: "/src/app"),
                                      database: database)
        _ = try BillingStore.saveRepo(BillingRepoDTO(id: "", projectId: other.id, projectRoot: "/src/other"),
                                      database: database)
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        try insertSpan("b", root: "/src/other", start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        for span in ["a", "b"] { try database.markAppSpanBillingDerived(spanId: span, at: "2026-10-01T09:30:00Z") }
        for (session, root) in [("sa", "/src/app"), ("sb", "/src/other")] {
            try database.execute("""
                INSERT INTO sessions (session_id, cwd, project_root, started_at, last_activity_at, status,
                                      billing_derived_at)
                VALUES (?, ?, ?, '2026-10-01 09:00:00', '2026-10-01 09:30:00', 'ended', '2026-10-01 09:30:00')
            """, params: [session, root, root])
        }

        _ = try BillingStore.saveProject(BillingProjectDTO(id: mine.id, name: "A", idleCutoffMinutes: 30),
                                         database: database)

        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).map(\.id), ["a"])
        var derived: [String: String] = [:]
        try database.query("SELECT session_id, billing_derived_at FROM sessions") { row in
            derived[row["session_id"] ?? ""] = row["billing_derived_at"] ?? ""
        }
        XCTAssertEqual(derived, ["sa": "", "sb": "2026-10-01 09:30:00"])
    }

    /// Review F43: the reset follows the cutoff in force, not the raw
    /// override. Setting the override to the global value changes no split.
    func testAnOverrideEqualToTheGlobalCutoffResetsNothing() throws {
        let global = try BillingPrefs.snapshot(database).idleCutoffSeconds / 60
        let project = try BillingStore.saveProject(BillingProjectDTO(id: "", name: "P"), database: database)
        _ = try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: project.id, projectRoot: "/src/app"), database: database)
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        try database.markAppSpanBillingDerived(spanId: "a", at: "2026-10-01T09:30:00Z")

        _ = try BillingStore.saveProject(BillingProjectDTO(id: project.id, name: "P", idleCutoffMinutes: global),
                                         database: database)
        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).map(\.id), [], "set to the same")
        _ = try BillingStore.saveProject(BillingProjectDTO(id: project.id, name: "P"), database: database)
        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).map(\.id), [], "cleared again")
        _ = try BillingStore.saveProject(BillingProjectDTO(id: project.id, name: "P", idleCutoffMinutes: global + 5),
                                         database: database)
        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).map(\.id), ["a"], "a real change")
    }

    /// Review F18: with unassigned time not tracked, a run an earlier pass
    /// left open is closed where its run ends, keeping the time it accrued —
    /// not at its own start with none.
    func testTheOptOutClosesAnOpenAppRunKeepingItsTime() throws {
        try insertSpan("u", root: "/src/nowhere", start: "2026-10-01T09:00:00Z", end: "")
        for span in try database.billingAppSpansNeedingDerivation(limit: 10) {
            try BillingStore.deriveAppSegments(for: span, defaultCutoffSeconds: 900, trackUnassigned: true,
                                               now: "2026-10-01T09:30:00Z", database: database)
        }
        XCTAssertEqual(try database.runningBillingSegments(origin: "auto").count, 1, "a running run")

        try database.execute("UPDATE activity_span SET ended_at = '2026-10-01T10:00:00Z' WHERE id = 'u'")
        for span in try database.billingAppSpansNeedingDerivation(limit: 10) {
            try BillingStore.deriveAppSegments(for: span, defaultCutoffSeconds: 900, trackUnassigned: false,
                                               now: "2026-10-01T10:05:00Z", database: database)
        }
        XCTAssertEqual(try database.runningBillingSegments(origin: "auto").count, 0)
        XCTAssertEqual(try segmentSeconds(), [3600], "09:00–10:00 kept")
    }

    /// Review F48: one read gives the titles and the ids with no row. A
    /// session that is there but untitled is not missing — it has nothing to
    /// lose — while a gone session or span is.
    func testTitlesReportOnlyTheIdsWithNoRowAsMissing() throws {
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, project_root, started_at, last_activity_at, status, summary)
            VALUES ('untitled', '/src/app', '/src/app', '2026-10-01 09:15:00', '2026-10-01 09:20:00', 'ended', '')
        """)
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        let result = try database.billingSessionTitles(sessionIds: ["untitled", "gone", "app:a", "app:gone"])
        XCTAssertEqual(Set(result.missing), ["gone", "app:gone"])
        XCTAssertEqual(result.titles, ["Xcode", "in app"])
    }

    func testAppAndClaudeTitlesShareOneOrdering() throws {
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, project_root, started_at, last_activity_at, status, summary)
            VALUES ('s1', '/src/app', '/src/app', '2026-10-01 09:15:00', '2026-10-01 09:20:00', 'ended', 'Claude work')
        """)
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T09:30:00Z")
        XCTAssertEqual(try database.billingSessionTitles(sessionIds: ["s1", "app:a"]).titles,
                       ["Claude work", "Xcode", "in app"])
    }

    /// An idle interval nobody closes would hold every span it overlaps pending
    /// until it outgrows the cutoff; recovery closing it settles them sooner.
    func testRecoveryClosingOpenIdleLetsPendingSpanSettle() throws {
        try insertSpan("a", start: "2026-10-01T09:00:00Z", end: "2026-10-01T10:00:00Z")
        try database.openIdleInterval(from: "2026-10-01T09:50:00Z")

        try derivePending(now: "2026-10-01T10:01:00Z")
        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).map(\.id), ["a"],
                       "an open idle keeps the span pending")

        XCTAssertEqual(try database.recoverActivity(now: "2026-10-01T11:00:00Z"), 0)
        try derivePending(now: "2026-10-01T11:00:00Z")
        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).map(\.id), [])
    }
}
