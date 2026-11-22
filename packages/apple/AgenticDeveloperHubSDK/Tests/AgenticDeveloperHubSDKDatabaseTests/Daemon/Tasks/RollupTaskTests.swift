import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// Backstops the daily-rollup contract:
/// - chunked backfill (`> daysPerRun` finalizable days → `.rerunImmediately`),
/// - finalized days are frozen (late events / source deletion don't change them),
/// - the mutable tail (recent days) is recomputed each run,
/// - empty calendar gaps still advance the watermark.
final class RollupTaskTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "rollup-task-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/rollup-task.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    // MARK: - Helpers

    /// The Claude pipeline feeding `database`, made on first use; the rollup
    /// reads the event store it fills.
    private var pipelineHarness: ClaudePipelineTestHarness?

    private func pipeline() throws -> ClaudePipelineTestHarness {
        if let pipelineHarness { return pipelineHarness }
        let made = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        pipelineHarness = made
        return made
    }

    private func ingest(day: String, tool: String = "Bash", sessionId: String = "s") throws {
        try pipeline().ingest(ClaudePipelineTestHarness.event(
            "PreToolUse", sessionId: sessionId, timestamp: "\(day)T12:00:00Z", cwd: "/tmp",
            hookData: ["tool_name": tool, "tool_input": [String: Any]()]))
    }

    private func runOnce(finalizeAfterDays: Int = 2) async throws -> SessionTaskResult {
        let task = RollupTask(database: database, finalizeAfterDays: finalizeAfterDays)
        let ctx = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        return try await task.execute(context: ctx)
    }

    private func daysAgo(_ offset: Int) -> String {
        RollupTask.utcDay(Date().addingTimeInterval(-Double(offset) * 86400))
    }

    private func bashCount(on day: String) throws -> Int? {
        try database.dailyMetrics(metric: "tool_use", dimension: "Bash", from: day, to: day).first?.count
    }

    // MARK: - Empty DB

    func testEmptyDatabaseReturnsEmpty() async throws {
        let result = try await runOnce()
        XCTAssertNil(result.nextRunSeconds)
        XCTAssertNil(try database.rollupFinalizedThrough())
        XCTAssertTrue(try database.dailyMetrics().isEmpty)
    }

    // MARK: - Backfill chunking

    func testBackfillChunksAndFreezesThroughBoundary() async throws {
        // 35 distinct days, all older than the finalize boundary (today-2) so
        // they're all finalizable. 35 > daysPerRun (30) forces two chunks.
        for offset in 5...39 { try ingest(day: daysAgo(offset)) }

        let first = try await runOnce(finalizeAfterDays: 2)
        XCTAssertEqual(first.nextRunSeconds, 0, "more than daysPerRun finalizable days must reschedule")

        var result = first
        var calls = 1
        while result.nextRunSeconds != nil {
            result = try await runOnce(finalizeAfterDays: 2)
            calls += 1
            XCTAssertLessThan(calls, 10, "backfill must converge in bounded iterations")
        }

        XCTAssertEqual(try database.rollupFinalizedThrough(), daysAgo(2),
                       "watermark advances to the finalize boundary")
        XCTAssertEqual(try bashCount(on: daysAgo(39)), 1, "oldest day frozen")
        XCTAssertEqual(try bashCount(on: daysAgo(5)), 1, "newest finalizable day frozen")
    }

    // MARK: - Frozen-history regression

    func testFinalizedDayIgnoresLateEvents() async throws {
        let day = daysAgo(10)   // older than the finalize boundary
        try ingest(day: day)
        try ingest(day: day)
        _ = try await runOnce(finalizeAfterDays: 2)
        XCTAssertEqual(try bashCount(on: day), 2)
        XCTAssertEqual(try database.rollupFinalizedThrough(), daysAgo(2))

        // A late JSONL import lands 3 more events on the already-frozen day.
        try ingest(day: day)
        try ingest(day: day)
        try ingest(day: day)
        _ = try await runOnce(finalizeAfterDays: 2)

        XCTAssertEqual(try bashCount(on: day), 2, "frozen day must NOT be recomputed (stays 2, not 5)")
    }

    func testFinalizedDaySurvivesSourceDeletion() async throws {
        let day = daysAgo(10)
        try ingest(day: day)
        _ = try await runOnce(finalizeAfterDays: 2)
        XCTAssertEqual(try bashCount(on: day), 1)

        // Retention deletes the raw rows; a subsequent run must not zero the day.
        try pipeline().deleteEvents()
        _ = try await runOnce(finalizeAfterDays: 2)
        XCTAssertEqual(try bashCount(on: day), 1, "rolled-up history survives source deletion")
    }

    // MARK: - Mutable tail

    func testMutableTailRecomputesEachRun() async throws {
        let today = RollupTask.utcDay(Date())
        try ingest(day: today)
        _ = try await runOnce(finalizeAfterDays: 2)
        XCTAssertEqual(try bashCount(on: today), 1)
        XCTAssertNil(try database.rollupFinalizedThrough(), "today is not finalizable")

        try ingest(day: today)
        _ = try await runOnce(finalizeAfterDays: 2)
        XCTAssertEqual(try bashCount(on: today), 2, "mutable tail is recomputed from source each run")
    }

    func testNeverFinalizesTodayUnderShortRetention() async throws {
        // event_history_days=1 snaps to 7, and finalizeAfterDays 0 →
        // effectiveFinalize=max(1,min(0,6))=1 → maxFinalizable is yesterday, so
        // today (an incomplete day) is never frozen and stays mutable. Guards
        // against the eF=0 bug that froze today mid-day.
        try database.setSetting(StorageSettings.key, "1")
        let today = RollupTask.utcDay(Date())
        try ingest(day: today)
        _ = try await runOnce(finalizeAfterDays: 0)

        let finalized = try database.rollupFinalizedThrough()
        XCTAssertTrue(finalized == nil || finalized! < today,
                      "today must not be finalized under the shortest window")
        XCTAssertEqual(try bashCount(on: today), 1, "today is computed in the mutable tail")

        // A late same-day event must still be counted (today is not frozen).
        try ingest(day: today)
        _ = try await runOnce(finalizeAfterDays: 0)
        XCTAssertEqual(try bashCount(on: today), 2, "today stays mutable; late events counted")
    }

    // MARK: - Calendar gaps

    func testCalendarGapAdvancesWatermark() async throws {
        let dayA = daysAgo(20)
        let dayB = daysAgo(10)   // a gap of empty days sits between dayA and dayB
        try ingest(day: dayA)
        try ingest(day: dayB)

        _ = try await runOnce(finalizeAfterDays: 2)

        XCTAssertEqual(try database.rollupFinalizedThrough(), daysAgo(2),
                       "watermark jumps over empty calendar days to the boundary")
        XCTAssertEqual(try bashCount(on: dayA), 1)
        XCTAssertEqual(try bashCount(on: dayB), 1)
        XCTAssertTrue(try database.dailyMetrics(metric: "tool_use", from: daysAgo(15), to: daysAgo(15)).isEmpty,
                      "a gap day has no rows")
    }

    // MARK: - project metric

    func testRollupEmitsProjectMetric() async throws {
        let day = daysAgo(10)
        try ingest(day: day)   // ingest helper uses cwd "/tmp" → project "tmp"
        _ = try await runOnce(finalizeAfterDays: 2)
        XCTAssertEqual(
            try database.dailyMetrics(metric: "project", dimension: "tmp", from: day, to: day).first?.count, 1,
            "finalizing a day emits its project rollup"
        )
    }

    // MARK: - attr-dimension metrics end to end

    /// `subagent_run` and `notification` take their dimension from the attrs the
    /// Claude normalizer writes (`agent_type`, `notification_type`). Hook
    /// payloads go in through the pipeline and a scheduled run rolls them up,
    /// on a day it freezes and on the mutable tail alike.
    func testRollupCountsSubagentRunsAndNotificationsFromNormalizedAttrs() async throws {
        let frozen = daysAgo(10)
        let tail = daysAgo(0)
        for day in [frozen, tail] {
            for (session, agent) in [("a", "Explore"), ("b", "Explore"), ("c", "Plan")] {
                try pipeline().ingest(ClaudePipelineTestHarness.event(
                    "SubagentStart", sessionId: session, timestamp: "\(day)T12:00:00Z", cwd: "/tmp",
                    hookData: ["agent_type": agent, "agent_id": "agent-\(session)"]))
            }
            for (session, kind) in [("a", "idle_prompt"), ("b", "permission_prompt"), ("c", "idle_prompt")] {
                try pipeline().ingest(ClaudePipelineTestHarness.event(
                    "Notification", sessionId: session, timestamp: "\(day)T13:00:00Z", cwd: "/tmp",
                    hookData: ["notification_type": kind, "message": "m"]))
            }
        }

        let result = try await runOnce(finalizeAfterDays: 2)
        XCTAssertNil(result.nextRunSeconds)
        XCTAssertEqual(try database.rollupFinalizedThrough(), daysAgo(2))

        for day in [frozen, tail] {
            let runs = try database.dailyMetrics(metric: "subagent_run", from: day, to: day)
                .map { "\($0.dimension) \($0.count)" }
            XCTAssertEqual(runs, ["Explore 2", "Plan 1"], day)
            let notes = try database.dailyMetrics(metric: "notification", from: day, to: day)
                .map { "\($0.dimension) \($0.count)" }
            XCTAssertEqual(notes, ["idle_prompt 2", "permission_prompt 1"], day)
        }
    }
}
