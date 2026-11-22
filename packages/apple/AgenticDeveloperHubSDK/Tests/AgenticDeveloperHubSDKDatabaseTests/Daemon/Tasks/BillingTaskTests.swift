import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// The task's own contract — not the billing rules, which Tasks 5–8 own.
/// What is tested here: it derives, then rolls, in that order; it honours the
/// live settings; it chunks; and a quiet database costs nothing.
final class BillingTaskTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!
    var harness: ClaudePipelineTestHarness!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "billing-task-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/billing-task.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
    }

    override func tearDownWithError() throws {
        harness = nil
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    // MARK: - Helpers

    private func runOnce(sessionsPerRun: Int = 50) async throws -> SessionTaskResult {
        let task = BillingTask(database: database, sessionsPerRun: sessionsPerRun)
        let context = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        return try await task.execute(context: context)
    }

    /// An ended session with two events five minutes apart, mapped to `project`.
    @discardableResult
    private func seedSession(_ id: String, root: String = "/src/app") throws -> String {
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, project_root, git_branch, started_at,
                                  last_activity_at, status)
            VALUES (?, ?, ?, 'main', '2026-09-22T09:00:00Z', '2026-09-22T09:05:00Z', 'ended')
        """, params: [id, root, root])
        for minute in [0, 5] {
            try harness.seed(sessionId: id, type: "PreToolUse", timestamp: "2026-09-22T09:0\(minute):00Z", cwd: root)
        }
        return id
    }

    @discardableResult
    private func mappedProject(root: String = "/src/app", name: String = "P") throws -> BillingProjectDTO {
        let project = try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: name, defaultRateCents: 10_000), database: database
        )
        _ = try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: project.id, projectRoot: root), database: database
        )
        return project
    }

    /// Every entry row, the zero-second ones the listing hides included.
    private func entries() throws -> [BillingEntryDTO] {
        var ids: [String] = []
        try database.query("SELECT id FROM billing_entry ORDER BY day DESC, created_at, id") { row in
            ids.append(row["id"] ?? "")
        }
        return try ids.compactMap { try database.billingEntry(id: $0) }
    }

    // MARK: - Per-project idle cutoff

    func testProjectCutoffOverridesTheGlobalForClaudeTime() async throws {
        let project = try mappedProject()
        try BillingStore.saveProject(project.replacing(idleCutoffMinutes: .some(60)), database: database)
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, project_root, git_branch, started_at, last_activity_at, status)
            VALUES ('s1', '/src/app', '/src/app', 'main', '2026-09-22T09:00:00Z', '2026-09-22T10:00:00Z', 'ended')
        """)
        for stamp in ["2026-09-22T09:00:00Z", "2026-09-22T09:30:00Z"] {
            try harness.seed(sessionId: "s1", type: "PreToolUse", timestamp: stamp)
        }
        try database.setSetting(database.billingSettingsKeys.idleCutoffMinutes, "15")
        _ = try await runOnce()
        XCTAssertEqual(try database.billingSegments(since: "", limit: 10).count, 1,
                       "the project's 60-minute cutoff keeps a 30-minute gap inside one run")
    }

    func testChangingProjectCutoffQueuesReDerivation() async throws {
        let project = try mappedProject()
        try seedSession("s1")
        _ = try await runOnce()
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty)
        try BillingStore.saveProject(project.replacing(idleCutoffMinutes: .some(30)), database: database)
        XCTAssertEqual(try database.sessionsNeedingBillingDerivation(limit: 10).map(\.sessionId), ["s1"])
    }

    func testAProjectRoundTripsItsCutoff() throws {
        let project = try mappedProject()
        let saved = try BillingStore.saveProject(project.replacing(idleCutoffMinutes: .some(25)), database: database)
        XCTAssertEqual(try database.billingProject(id: saved.id)?.idleCutoffMinutes, 25)
        let cleared = try BillingStore.saveProject(saved.replacing(idleCutoffMinutes: .some(nil)), database: database)
        XCTAssertNil(try database.billingProject(id: cleared.id)?.idleCutoffMinutes)
    }

    func testSaveRefusesAnOutOfRangeOverride() throws {
        for minutes in [481, 0] {
            XCTAssertThrowsError(try BillingStore.saveProject(
                BillingProjectDTO(id: "", name: "P", idleCutoffMinutes: minutes), database: database)
            ) { error in
                guard case BillingStore.BillingError.invalidIdleCutoff(let got) = error else {
                    return XCTFail("expected invalidIdleCutoff, got \(error)")
                }
                XCTAssertEqual(got, minutes)
            }
        }
        XCTAssertEqual(try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: "P", idleCutoffMinutes: 480), database: database).idleCutoffMinutes, 480)
    }

    // MARK: - The pass

    func testAQuietDatabaseDoesNothing() async throws {
        let result = try await runOnce()
        XCTAssertNil(result.nextRunSeconds)
        XCTAssertTrue(try database.billingSegments(since: "", limit: 10).isEmpty)
        XCTAssertTrue(try entries().isEmpty)
    }

    /// One pass must both derive the segment and roll it into an entry —
    /// otherwise every billable would be one scheduling interval late.
    func testOnePassDerivesThenRolls() async throws {
        _ = try mappedProject()
        try seedSession("s1")

        _ = try await runOnce()

        XCTAssertEqual(try database.billingSegments(since: "", limit: 10).count, 1)
        let entry = try XCTUnwrap(entries().first)
        XCTAssertEqual(entry.rawSeconds, 300)
        XCTAssertEqual(entry.status, BillingStatus.unbilled.rawValue)
    }

    func testASecondPassOverQuietDataChangesNothing() async throws {
        _ = try mappedProject()
        try seedSession("s1")
        _ = try await runOnce()
        _ = try await runOnce()

        XCTAssertEqual(try database.billingSegments(since: "", limit: 10).count, 1)
        XCTAssertEqual(try entries().count, 1)
    }

    /// Unmapped work is still tracked — that is the Unassigned bucket — but it
    /// produces no entry until someone assigns it.
    func testUnmappedSessionsAreTrackedButNotBilled() async throws {
        try seedSession("s1", root: "/src/unknown")
        _ = try await runOnce()

        XCTAssertEqual(try database.billingSegments(since: "", limit: 10).count, 1)
        XCTAssertTrue(try entries().isEmpty)
    }

    /// `track_unassigned = false` is the opt-out: no project, no segment.
    func testTrackUnassignedOffSkipsUnmappedSessions() async throws {
        try database.setSetting(database.billingSettingsKeys.trackUnassigned, "false")
        try seedSession("s1", root: "/src/unknown")
        _ = try await runOnce()

        XCTAssertTrue(try database.billingSegments(since: "", limit: 10).isEmpty)
    }

    // MARK: - Chunking

    func testMoreSessionsThanTheChunkRerunsImmediately() async throws {
        _ = try mappedProject()
        for index in 0..<5 { try seedSession("s\(index)") }

        let first = try await runOnce(sessionsPerRun: 2)
        XCTAssertEqual(first.nextRunSeconds, 0, "a full chunk means there is more to do")

        var result = first
        var passes = 1
        while result.nextRunSeconds != nil {
            result = try await runOnce(sessionsPerRun: 2)
            passes += 1
            XCTAssertLessThan(passes, 10, "the pass must converge")
        }
        XCTAssertEqual(try database.billingSegments(since: "", limit: 50).count, 5)
    }

    // MARK: - Live settings

    func testIdleCutoffIsReadLive() async throws {
        _ = try mappedProject()
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, project_root, git_branch, started_at,
                                  last_activity_at, status)
            VALUES ('s1', '/src/app', '/src/app', 'main', '2026-09-22T09:00:00Z',
                    '2026-09-22T10:00:00Z', 'ended')
        """)
        // 0, then 30 minutes later — one gap of 30 minutes.
        for stamp in ["2026-09-22T09:00:00Z", "2026-09-22T09:30:00Z"] {
            try harness.seed(sessionId: "s1", type: "PreToolUse", timestamp: stamp)
        }

        try database.setSetting(database.billingSettingsKeys.idleCutoffMinutes, "15")
        _ = try await runOnce()
        XCTAssertEqual(try database.billingSegments(since: "", limit: 10).count, 2,
                       "a 30-minute gap splits at a 15-minute cutoff")

        try database.setSetting(database.billingSettingsKeys.idleCutoffMinutes, "60")
        try database.markBillingDerived(sessionId: "s1", at: "")
        _ = try await runOnce()
        XCTAssertEqual(try database.billingSegments(since: "", limit: 10).count, 1,
                       "the same gap is one run at a 60-minute cutoff")
    }

    func testRunGranularitySettingIsHonoured() async throws {
        _ = try mappedProject()
        try database.setSetting(database.billingSettingsKeys.granularity, "run")
        try seedSession("s1")
        try seedSession("s2")

        _ = try await runOnce()
        XCTAssertEqual(try entries().count, 2, "per-run billing gives each run its own entry")
    }

    // MARK: - Prefs

    /// A settings read that fails is an error, not the defaults: a default
    /// rate of zero written onto today's entry would stay there.
    func testASettingsReadFailureThrowsInsteadOfFallingBackToDefaults() async throws {
        try database.execute("DROP TABLE settings")
        XCTAssertThrowsError(try BillingPrefs.snapshot(database))
        do {
            _ = try await runOnce()
            XCTFail("the pass must fail rather than bill at default settings")
        } catch {}
    }

    /// After its first pass the task recomputes only the entries its own
    /// derivation touched. An entry of a session it did not derive is left
    /// alone until the next daemon's first pass.
    func testLaterPassesRecomputeOnlyTheEntriesTheirSessionsTouched() async throws {
        try mappedProject(root: "/src/a")
        try mappedProject(root: "/src/b", name: "Q")
        try seedSession("a", root: "/src/a")
        try seedSession("b", root: "/src/b")
        let task = BillingTask(database: database)
        let context = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        _ = try await task.execute(context: context)
        let byRoot = { (root: String) throws -> BillingEntryDTO in
            let segment = try XCTUnwrap(self.database.billingSegments(since: "", limit: 10).first {
                $0.projectRoot == root
            })
            return try XCTUnwrap(self.database.billingEntry(id: XCTUnwrap(segment.entryId)))
        }
        let entryA = try byRoot("/src/a"), entryB = try byRoot("/src/b")
        for id in [entryA.id, entryB.id] {
            try database.execute("UPDATE billing_entry SET raw_seconds = 1 WHERE id = ?", params: [id])
        }

        try database.markBillingDerived(sessionId: "a", at: "")
        _ = try await task.execute(context: context)
        XCTAssertEqual(try database.billingEntry(id: entryA.id)?.rawSeconds, 300, "a's entry is recomputed")
        XCTAssertEqual(try database.billingEntry(id: entryB.id)?.rawSeconds, 1, "b's is not this pass's")

        let restarted = BillingTask(database: database)
        _ = try await restarted.execute(context: context)
        XCTAssertEqual(try database.billingEntry(id: entryB.id)?.rawSeconds, 300, "the first pass checks all")
    }

    func testPrefsFallBackToDefaultsAndClamp() throws {
        let fresh = try BillingPrefs.snapshot(database)
        XCTAssertEqual(fresh.idleCutoffSeconds, BillingDefaults.idleCutoffMinutes * 60)
        XCTAssertEqual(fresh.currency, BillingDefaults.currency)
        XCTAssertEqual(fresh.rollupOptions.granularity, .day)
        XCTAssertTrue(fresh.trackUnassigned)

        // A zero cutoff would make every event its own run; garbage is a default.
        try database.setSetting(database.billingSettingsKeys.idleCutoffMinutes, "0")
        try database.setSetting(database.billingSettingsKeys.granularity, "sideways")
        let clamped = try BillingPrefs.snapshot(database)
        XCTAssertEqual(clamped.idleCutoffSeconds, BillingLimits.idleCutoffMinutes.lowerBound * 60)
        XCTAssertEqual(clamped.rollupOptions.granularity, .day, "an unknown granularity is per-day")
    }

    // MARK: - Claude hold

    /// Held (no store, or a backfill replaying), a Claude session is neither
    /// derived nor stamped, and its existing segments stay; app spans derive.
    func testAHeldPassLeavesClaudeSessionsAloneAndStillDerivesAppSpans() async throws {
        _ = try mappedProject()
        try seedSession("s1")
        _ = try await runOnce()
        let before = try database.billingSegments(since: "", limit: 10).map(\.id)
        XCTAssertEqual(before.count, 1)

        try harness.deleteEvents(where: "session_id = 's1'")
        try database.markBillingDerived(sessionId: "s1", at: "")
        try seedSpan("x", start: "2026-09-22T11:00:00Z", end: "2026-09-22T11:20:00Z")
        let held = BillingTask(database: database, claudeHold: { _ in "history backfill" })
        _ = try await held.execute(context: context(held))

        let segments = try database.billingSegments(since: "", limit: 10)
        XCTAssertTrue(before.allSatisfy { id in segments.contains { $0.id == id } }, "the session's segment stays")
        XCTAssertTrue(segments.contains { $0.sessionId == "app:x" }, "app spans still derive")
        var stamp = "?"
        try database.query("SELECT billing_derived_at FROM sessions WHERE session_id = 's1'") { row in
            stamp = row["billing_derived_at"] ?? "?"
        }
        XCTAssertEqual(stamp, "", "the held session is not stamped, so it derives once released")
    }

    /// The default hold reads the backfill marker in `events.db`.
    func testTheDefaultHoldWaitsForAPendingBackfill() throws {
        XCTAssertNil(BillingTask.defaultClaudeHold(database))
        try harness.setStoreMeta("replay_target_raw_id", "10")
        XCTAssertEqual(BillingTask.defaultClaudeHold(database), "history backfill")
        try harness.setStoreMeta("replay_last_raw_id", "10")
        XCTAssertNil(BillingTask.defaultClaudeHold(database))
    }

    // MARK: - Final-review regressions

    func testTheTaskRunsEveryMinute() {
        XCTAssertEqual(BillingTask.defaultCheckInterval, 60)
        XCTAssertEqual(BillingTask(database: database).schedule.intervalSeconds, 60)
    }

    /// A session that fails every time must not be re-selected forever: after
    /// `maxDerivationAttempts` its watermark is stamped and the pass moves on.
    func testASessionThatAlwaysFailsIsStampedAfterThreeAttempts() async throws {
        struct Boom: Error {}
        try seedSession("bad")
        let ledger = BillingTask.FailureLedger()
        let task = BillingTask(database: database, failures: ledger) { _, _, _, _ in throw Boom() }
        let context = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)

        for attempt in 1..<BillingTask.maxDerivationAttempts {
            _ = try await task.execute(context: context)
            XCTAssertEqual(try database.sessionsNeedingBillingDerivation(limit: 10).map(\.sessionId), ["bad"],
                           "attempt \(attempt) leaves it queued for a retry")
        }
        _ = try await task.execute(context: context)

        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty,
                      "the third failure stamps the watermark")
        XCTAssertTrue(ledger.abandoned.contains("bad"), "and it stays out of the open-run re-selection")
    }

    func testASuccessResetsTheFailureCount() async throws {
        _ = try mappedProject()
        try seedSession("s1")
        let ledger = BillingTask.FailureLedger()
        _ = ledger.failed("s1", maxAttempts: BillingTask.maxDerivationAttempts)

        let task = BillingTask(database: database, failures: ledger)
        _ = try await task.execute(context: SessionTaskContext(taskName: task.name, consecutiveFailures: 0,
                                                        runReason: .scheduled))

        XCTAssertEqual(ledger.attempts("s1"), 0)
        XCTAssertEqual(try entries().count, 1)
    }

    // MARK: - App activity

    private func seedSpan(_ id: String, root: String = "/src/app", start: String, end: String) throws {
        try database.execute("""
            INSERT INTO activity_span (id, bundle_id, app_name, working_path, repo_root, branch,
                                       started_at, ended_at, tz)
            VALUES (?, 'com.apple.dt.Xcode', 'Xcode', ?, ?, 'main', ?, ?, 'UTC')
        """, params: [id, root, root, start, end])
    }

    func testAppSpanBecomesASegmentAndAnEntry() async throws {
        _ = try mappedProject()
        try seedSpan("x", start: "2026-09-22T11:00:00Z", end: "2026-09-22T11:20:00Z")
        _ = try await runOnce()
        let segment = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first)
        XCTAssertEqual(segment.sessionId, "app:x")
        XCTAssertEqual(try entries().first?.rawSeconds, 1200)
    }

    func testXcodeAndClaudeOverlapBillOnce() async throws {
        _ = try mappedProject()
        try seedSession("s1")
        try seedSpan("x", start: "2026-09-22T09:00:00Z", end: "2026-09-22T09:05:00Z")
        _ = try await runOnce()
        XCTAssertEqual(try entries().count, 1)
        XCTAssertEqual(try entries().first?.rawSeconds, 300)
    }

    func testThreeProjectsInParallelEachBillInFull() async throws {
        for (root, name) in [("/src/a", "A"), ("/src/b", "B"), ("/src/c", "C")] {
            try mappedProject(root: root, name: name)
            try seedSession("s" + name, root: root)
        }
        try seedSpan("x", root: "/src/b", start: "2026-09-22T09:00:00Z", end: "2026-09-22T09:05:00Z")
        _ = try await runOnce()
        XCTAssertEqual(try entries().map(\.rawSeconds).sorted(), [300, 300, 300])
    }

    func testProjectCutoffOverridesGlobalForAppSpans() async throws {
        let project = try mappedProject()
        try BillingStore.saveProject(project.replacing(idleCutoffMinutes: .some(60)), database: database)
        try seedSpan("x", start: "2026-09-22T09:00:00Z", end: "2026-09-22T10:00:00Z")
        try database.execute("INSERT INTO activity_presence (id, idle_from, idle_until) VALUES ('i', ?, ?)",
                             params: ["2026-09-22T09:10:00Z", "2026-09-22T09:40:00Z"])
        _ = try await runOnce()
        XCTAssertEqual(try entries().first?.rawSeconds, 3600, "a 30-minute idle is under the project's 60")
    }

    func testUnmappedAppTimeIsUnassignedAndRespectsTheOptOut() async throws {
        try seedSpan("x", root: "/src/unknown", start: "2026-09-22T09:00:00Z", end: "2026-09-22T09:10:00Z")
        try database.setSetting(database.billingSettingsKeys.trackUnassigned, "false")
        _ = try await runOnce()
        XCTAssertTrue(try database.billingSegments(since: "", limit: 10).isEmpty)
    }

    func testAppSegmentsUnderALockedEntrySurviveReDerivation() async throws {
        _ = try mappedProject()
        try seedSpan("x", start: "2026-09-22T09:00:00Z", end: "2026-09-22T09:10:00Z")
        _ = try await runOnce()
        let entry = try XCTUnwrap(entries().first)
        _ = try BillingRollup.setStatus(entryId: entry.id, to: .billed, source: "user", database: database)
        _ = try database.resetBillingDerivationOfDerivedSessions()
        _ = try await runOnce()
        XCTAssertEqual(try database.billingEntry(id: entry.id)?.rawSeconds, 600)
        XCTAssertEqual(try database.billingEntry(id: entry.id)?.status, BillingStatus.billed.rawValue)
    }

    func testDerivedActivityPastRetentionIsPruned() async throws {
        try seedSpan("old", start: "2020-01-01T09:00:00Z", end: "2020-01-01T09:10:00Z")
        _ = try await runOnce()    // derives it (Unassigned), then prunes it
        _ = try await runOnce()
        XCTAssertTrue(try database.activitySpans(since: "", limit: 10).isEmpty)
    }

    /// A span that always fails is attempted at most `maxDerivationAttempts`
    /// times. A closed one is stamped; an open one (whose stamp is "" and so
    /// stays pending) is kept out by the abandoned ledger.
    func testAFailingAppSpanIsAttemptedAtMostMaxAttempts() async throws {
        struct Boom: Error {}
        try seedSpan("closed", start: "2026-09-22T09:00:00Z", end: "2026-09-22T09:10:00Z")
        try seedSpan("open", root: "/src/other", start: "2026-09-22T10:00:00Z", end: "")
        let calls = Counter()
        let task = BillingTask(database: database, deriveApp: { span, _, _, _ in
            calls.bump(span.id)
            throw Boom()
        })
        let context = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        for _ in 0..<(BillingTask.maxDerivationAttempts + 4) { _ = try await task.execute(context: context) }
        XCTAssertEqual(calls.count("closed"), BillingTask.maxDerivationAttempts)
        XCTAssertEqual(calls.count("open"), BillingTask.maxDerivationAttempts)
    }

    // MARK: - Fix round 1

    private func context(_ task: BillingTask) -> SessionTaskContext {
        SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
    }

    func testAThrowingPruneDoesNotCostThePassItsRollup() async throws {
        struct Boom: Error {}
        _ = try mappedProject()
        try seedSession("s1")
        let task = BillingTask(database: database, prune: { _, _ in throw Boom() })
        _ = try await task.execute(context: context(task))
        XCTAssertEqual(try entries().count, 1)
    }

    func testPruneRunsOnTheFirstPassThenAtMostOncePerInterval() async throws {
        let calls = Counter()
        let task = BillingTask(database: database, prune: { _, _ in calls.bump("p"); return 0 })
        for _ in 0..<3 { _ = try await task.execute(context: context(task)) }
        XCTAssertEqual(calls.count("p"), 1)
        let throttle = BillingTask.PruneThrottle(interval: 3600)
        let origin = Date()
        XCTAssertTrue(throttle.take(now: origin))
        XCTAssertFalse(throttle.take(now: origin.addingTimeInterval(3599)))
        XCTAssertTrue(throttle.take(now: origin.addingTimeInterval(3600)))
    }

    func testAnExhaustedClosedSpanLeavesTheLedger() async throws {
        struct Boom: Error {}
        try seedSpan("c", start: "2026-09-22T09:00:00Z", end: "2026-09-22T09:10:00Z")
        let ledger = BillingTask.FailureLedger()
        let task = BillingTask(database: database, failures: ledger, deriveApp: { _, _, _, _ in throw Boom() })
        for _ in 0..<BillingTask.maxDerivationAttempts { _ = try await task.execute(context: context(task)) }
        XCTAssertTrue(ledger.abandoned.isEmpty)
        XCTAssertTrue(try database.billingAppSpansNeedingDerivation(limit: 10).isEmpty)
    }

    func testOpenSpansAloneNeverTriggerAnImmediateRerun() async throws {
        for (id, hour) in [("a", "09"), ("b", "10"), ("c", "11")] {
            try seedSpan(id, start: "2026-09-22T\(hour):00:00Z", end: "")
        }
        let task = BillingTask(database: database, sessionsPerRun: 2)
        let result = try await task.execute(context: context(task))
        XCTAssertNil(result.nextRunSeconds)
    }

    func testAFullChunkOfClosedSpansRerunsImmediately() async throws {
        try seedSpan("a", start: "2026-09-22T09:00:00Z", end: "2026-09-22T09:10:00Z")
        try seedSpan("b", start: "2026-09-22T10:00:00Z", end: "2026-09-22T10:10:00Z")
        let task = BillingTask(database: database, sessionsPerRun: 2)
        let result = try await task.execute(context: context(task))
        XCTAssertEqual(result.nextRunSeconds, 0)
    }

    func testSpansHeldPendingByAnOpenIdleNeverSpinTheRerun() async throws {
        // The task reads the wall clock, and an open idle holds spans pending
        // only while it is younger than the cutoff: stamp both near now.
        let now = Int(Date().timeIntervalSince1970)
        func ago(_ minutes: Int) -> String { UTCTimestamp.string(epochSeconds: now - minutes * 60) }
        try seedSpan("a", start: ago(30), end: ago(5))
        try seedSpan("b", start: ago(20), end: ago(4))
        try database.execute("INSERT INTO activity_presence (id, idle_from, idle_until) VALUES ('i', ?, '')",
                             params: [ago(6)])
        let task = BillingTask(database: database, sessionsPerRun: 2)
        let result = try await task.execute(context: context(task))
        XCTAssertEqual(try database.billingAppSpansNeedingDerivation(limit: 10).count, 2, "still pending")
        XCTAssertNil(result.nextRunSeconds)
    }

    func testAnAbandonedOpenSpanIsRetriedAndSettledAfterItCloses() async throws {
        struct Boom: Error {}
        try seedSpan("o", start: "2026-09-22T09:00:00Z", end: "")
        let ledger = BillingTask.FailureLedger()
        let failing = BillingTask(database: database, failures: ledger, deriveApp: { _, _, _, _ in throw Boom() })
        for _ in 0..<BillingTask.maxDerivationAttempts { _ = try await failing.execute(context: context(failing)) }
        XCTAssertTrue(ledger.abandoned.contains(ActivitySpanSession.sessionId(spanId: "o")))
        try database.execute("UPDATE activity_span SET ended_at = '2026-09-22T09:10:00Z' WHERE id = 'o'")
        let healthy = BillingTask(database: database, failures: ledger)
        _ = try await healthy.execute(context: context(healthy))
        XCTAssertEqual(
            try database.billingSegments(since: "", limit: 10).first?.sessionId,
            ActivitySpanSession.sessionId(spanId: "o")
        )
        XCTAssertTrue(ledger.abandoned.isEmpty)
        XCTAssertTrue(try database.billingAppSpansNeedingDerivation(limit: 10).isEmpty)
    }

    func testAbandonedOpenSpansCannotStarveHealthyOnes() async throws {
        try seedSpan("bad", start: "2026-09-22T08:00:00Z", end: "")
        try seedSpan("h1", start: "2026-09-22T09:00:00Z", end: "2026-09-22T09:10:00Z")
        try seedSpan("h2", start: "2026-09-22T10:00:00Z", end: "2026-09-22T10:10:00Z")
        let ledger = BillingTask.FailureLedger()
        for _ in 0..<BillingTask.maxDerivationAttempts {
            _ = ledger.failed(
                ActivitySpanSession.sessionId(spanId: "bad"), maxAttempts: BillingTask.maxDerivationAttempts
            )
        }
        let task = BillingTask(database: database, sessionsPerRun: 2, failures: ledger)
        _ = try await task.execute(context: context(task))
        let ids = Set(try database.billingSegments(since: "", limit: 10).map(\.sessionId))
        XCTAssertEqual(ids, Set(["h1", "h2"].map { ActivitySpanSession.sessionId(spanId: $0) }))
    }

    func testPruneKeepsOpenAndUnderivedSpans() async throws {
        struct Boom: Error {}
        try seedSpan("open", start: "2020-01-01T09:00:00Z", end: "")
        try seedSpan("old", start: "2020-01-02T09:00:00Z", end: "2020-01-02T09:10:00Z")
        // Positive control: derived (stamp == end) and past retention, so it goes.
        try seedSpan("done", start: "2020-01-03T09:00:00Z", end: "2020-01-03T09:10:00Z")
        try database.execute("UPDATE activity_span SET billing_derived_at = ended_at WHERE id = 'done'")
        let task = BillingTask(database: database, deriveApp: { _, _, _, _ in throw Boom() })
        _ = try await task.execute(context: context(task))
        let ids = Set(try database.activitySpans(since: "", limit: 10).map(\.id))
        XCTAssertEqual(ids, ["open", "old"])
    }

    private final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var counts: [String: Int] = [:]
        func bump(_ key: String) { lock.withLock { counts[key, default: 0] += 1 } }
        func count(_ key: String) -> Int { lock.withLock { counts[key, default: 0] } }
    }
}
