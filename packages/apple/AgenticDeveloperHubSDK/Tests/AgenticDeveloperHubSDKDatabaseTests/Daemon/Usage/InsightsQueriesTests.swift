import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class InsightsQueriesTests: XCTestCase {

    var database: DaemonDatabase!
    var tmpDir: URL!

    override func setUpWithError() throws {
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("insights-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpDir.appendingPathComponent("test.db").path)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Seed helpers

    private func seed(
        event: String,
        session: String,
        timestamp: String,
        cwd: String = "/test",
        tool: String? = nil
    ) throws {
        var hookData: [String: Any] = [:]
        if let tool {
            hookData["tool_name"] = tool
            hookData["tool_use_id"] = "tu-\(UUID().uuidString)"
            hookData["tool_input"] = [String: Any]()
        }
        try pipeline().ingest(ClaudePipelineTestHarness.event(
            event, sessionId: session, timestamp: timestamp, cwd: cwd, hookData: hookData))
    }

    // MARK: - eventsPerDay

    func testEventsPerDayBucketsByDateAndType() throws {
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-10T10:00:00Z", tool: "Edit")
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-10T11:00:00Z", tool: "Read")
        try seed(event: "PostToolUse", session: "s1", timestamp: "2026-04-10T12:00:00Z", tool: "Edit")
        try seed(event: "PreToolUse", session: "s2", timestamp: "2026-04-11T09:00:00Z", tool: "Bash")

        let rows = try database.eventsPerDay()
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].day, "2026-04-10")
        XCTAssertEqual(rows[0].byType["PreToolUse"], 2)
        XCTAssertEqual(rows[0].byType["PostToolUse"], 1)
        XCTAssertEqual(rows[1].day, "2026-04-11")
        XCTAssertEqual(rows[1].byType["PreToolUse"], 1)
    }

    func testEventsPerDayFiltersBySince() throws {
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-10T10:00:00Z", tool: "E")
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-15T10:00:00Z", tool: "E")

        let rows = try database.eventsPerDay(since: "2026-04-12T00:00:00Z")
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].day, "2026-04-15")
    }

    // MARK: - toolUsage

    func testToolUsageCountsPreToolUse() throws {
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-10T10:00:00Z", tool: "Edit")
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-10T10:01:00Z", tool: "Edit")
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-10T10:02:00Z", tool: "Read")

        let rows = try database.toolUsage()
        XCTAssertEqual(rows.first?.toolName, "Edit")
        XCTAssertEqual(rows.first?.count, 2)
        XCTAssertEqual(rows.last?.toolName, "Read")
        XCTAssertEqual(rows.last?.count, 1)
    }

    func testToolUsageHonorsLimit() throws {
        for (idx, tool) in ["A", "B", "C", "D", "E"].enumerated() {
            // Ensure different counts so ordering is deterministic
            for _ in 0...idx {
                try seed(
                    event: "PreToolUse",
                    session: "s",
                    timestamp: "2026-04-10T\(String(format: "%02d", idx)):00:00Z",
                    tool: tool
                )
            }
        }
        let rows = try database.toolUsage(limit: 2)
        XCTAssertEqual(rows.count, 2)
        // "E" has the most, then "D"
        XCTAssertEqual(rows[0].toolName, "E")
        XCTAssertEqual(rows[1].toolName, "D")
    }

    // MARK: - projectActivity

    func testProjectActivityExtractsLastPathComponent() throws {
        try seed(
            event: "PreToolUse", session: "s1",
            timestamp: "2026-04-10T10:00:00Z", cwd: "/work/project-a", tool: "Edit"
        )
        try seed(
            event: "PostToolUse", session: "s1",
            timestamp: "2026-04-10T10:01:00Z", cwd: "/work/project-a"
        )
        try seed(
            event: "PreToolUse", session: "s2",
            timestamp: "2026-04-10T10:02:00Z", cwd: "/home/x/project-b", tool: "Read"
        )

        let rows = try database.projectActivity()
        let byProject = Dictionary(uniqueKeysWithValues: rows.map { ($0.project, $0) })
        XCTAssertEqual(byProject["project-a"]?.eventCount, 2)
        XCTAssertEqual(byProject["project-a"]?.sessionCount, 1)
        XCTAssertEqual(byProject["project-b"]?.eventCount, 1)
    }

    func testProjectActivityCountsDistinctSessions() throws {
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-10T10:00:00Z", cwd: "/a/shared", tool: "E")
        try seed(event: "PreToolUse", session: "s2", timestamp: "2026-04-10T10:01:00Z", cwd: "/a/shared", tool: "E")
        try seed(event: "PreToolUse", session: "s3", timestamp: "2026-04-10T10:02:00Z", cwd: "/a/shared", tool: "E")

        let rows = try database.projectActivity()
        let shared = rows.first { $0.project == "shared" }
        XCTAssertEqual(shared?.eventCount, 3)
        XCTAssertEqual(shared?.sessionCount, 3)
    }

    // MARK: - sessionsPerDay

    func testSessionsPerDayCountsSessionStartOnly() throws {
        try seed(event: "SessionStart", session: "s1", timestamp: "2026-04-10T10:00:00Z")
        try seed(event: "SessionStart", session: "s2", timestamp: "2026-04-10T11:00:00Z")
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-10T12:00:00Z", tool: "Edit")
        try seed(event: "SessionStart", session: "s3", timestamp: "2026-04-11T09:00:00Z")

        let rows = try database.sessionsPerDay()
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].day, "2026-04-10")
        XCTAssertEqual(rows[0].newSessions, 2)
        XCTAssertEqual(rows[1].day, "2026-04-11")
        XCTAssertEqual(rows[1].newSessions, 1)
    }

    // MARK: - insightsSummary

    func testInsightsSummaryWithEmptyDB() throws {
        let summary = try database.insightsSummary()
        XCTAssertEqual(summary.activeSessionCount, 0)
        XCTAssertEqual(summary.totalEventCount, 0)
        XCTAssertNil(summary.mostUsedTool)
        XCTAssertEqual(summary.longestSessionMinutes, 0)
    }

    func testInsightsSummaryReportsMostUsedTool() throws {
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-10T10:00:00Z", tool: "Edit")
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-10T10:01:00Z", tool: "Edit")
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-10T10:02:00Z", tool: "Read")

        let summary = try database.insightsSummary()
        XCTAssertEqual(summary.mostUsedTool, "Edit")
        XCTAssertEqual(summary.totalEventCount, 3)
    }

    func testInsightsSummarySinceIsApplied() throws {
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-01T10:00:00Z", tool: "Old")
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-15T10:00:00Z", tool: "New")

        let summary = try database.insightsSummary(since: "2026-04-10T00:00:00Z")
        XCTAssertEqual(summary.totalEventCount, 1)
        XCTAssertEqual(summary.mostUsedTool, "New")
    }

    // MARK: - Rollup-backed hybrid reads

    /// Freeze the given days into the rollup and set the finalized watermark, so
    /// reads take the frozen-history path for them and the live raw path for later
    /// days — mirroring a caught-up daemon.
    private func freeze(through day: String, days: [String]) throws {
        for day in days { try database.recomputeDailyMetrics(forDay: day) }
        try database.setRollupFinalizedThrough(day)
    }

    func testEventsPerDayMergesFrozenRollupAndLiveTail() throws {
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-10T10:00:00Z", tool: "Edit")
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-11T10:00:00Z", tool: "Read")
        try freeze(through: "2026-04-11", days: ["2026-04-10", "2026-04-11"])
        // A later event lands in the live tail (after the watermark).
        try seed(event: "PostToolUse", session: "s2", timestamp: "2026-04-12T10:00:00Z")

        let byDay = Dictionary(uniqueKeysWithValues: try database.eventsPerDay().map { ($0.day, $0.byType) })
        XCTAssertEqual(byDay["2026-04-10"]?["PreToolUse"], 1, "frozen day from rollup")
        XCTAssertEqual(byDay["2026-04-11"]?["PreToolUse"], 1, "frozen day from rollup")
        XCTAssertEqual(byDay["2026-04-12"]?["PostToolUse"], 1, "live tail from the event store")
    }

    func testEventsPerDayFrozenHistorySurvivesSourceDeletion() throws {
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-10T10:00:00Z", tool: "Edit")
        try freeze(through: "2026-04-10", days: ["2026-04-10"])
        // Retention removes the raw rows; the frozen rollup must still report them.
        try pipeline().deleteEvents()

        let byDay = Dictionary(uniqueKeysWithValues: try database.eventsPerDay().map { ($0.day, $0.byType) })
        XCTAssertEqual(byDay["2026-04-10"]?["PreToolUse"], 1, "rolled-up history survives raw deletion")
    }

    func testToolUsageMergesFrozenAndTail() throws {
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-10T10:00:00Z", tool: "Edit")
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-10T10:01:00Z", tool: "Edit")
        try freeze(through: "2026-04-10", days: ["2026-04-10"])
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-12T10:00:00Z", tool: "Edit")
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-12T10:01:00Z", tool: "Bash")

        let rows = try database.toolUsage()
        let byTool = Dictionary(uniqueKeysWithValues: rows.map { ($0.toolName, $0.count) })
        XCTAssertEqual(byTool["Edit"], 3, "2 frozen + 1 tail")
        XCTAssertEqual(byTool["Bash"], 1, "tail only")
        XCTAssertEqual(rows.first?.toolName, "Edit", "ordered by total count")
    }

    func testProjectActivityMergesFrozenAndTail() throws {
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-10T10:00:00Z", cwd: "/w/proj-a", tool: "Edit")
        try seed(event: "PostToolUse", session: "s1", timestamp: "2026-04-10T10:01:00Z", cwd: "/w/proj-a")
        try freeze(through: "2026-04-10", days: ["2026-04-10"])
        try seed(event: "PreToolUse", session: "s2", timestamp: "2026-04-12T10:00:00Z", cwd: "/w/proj-a", tool: "Read")
        try seed(event: "PreToolUse", session: "s3", timestamp: "2026-04-12T10:00:00Z", cwd: "/x/proj-b", tool: "Read")

        let byProject = Dictionary(uniqueKeysWithValues: try database.projectActivity().map { ($0.project, $0) })
        XCTAssertEqual(byProject["proj-a"]?.eventCount, 3, "2 frozen + 1 tail")
        XCTAssertEqual(byProject["proj-a"]?.sessionCount, 2, "s1 (frozen) + s2 (tail)")
        XCTAssertEqual(byProject["proj-b"]?.eventCount, 1)
        XCTAssertEqual(byProject["proj-b"]?.sessionCount, 1)
    }

    func testInsightsSummaryTotalMergesFrozenAndTail() throws {
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-10T10:00:00Z", tool: "Edit")
        try seed(event: "PreToolUse", session: "s", timestamp: "2026-04-10T10:01:00Z", tool: "Edit")
        try freeze(through: "2026-04-10", days: ["2026-04-10"])
        try seed(event: "PostToolUse", session: "s", timestamp: "2026-04-12T10:00:00Z")

        let summary = try database.insightsSummary()
        XCTAssertEqual(summary.totalEventCount, 3, "2 frozen + 1 tail")
        XCTAssertEqual(summary.mostUsedTool, "Edit")
    }

    // MARK: - project rollup metric

    func testRecomputeEmitsProjectMetric() throws {
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-10T10:00:00Z", cwd: "/w/proj-a", tool: "Edit")
        try seed(event: "PreToolUse", session: "s2", timestamp: "2026-04-10T10:01:00Z", cwd: "/w/proj-a", tool: "Read")
        try database.recomputeDailyMetrics(forDay: "2026-04-10")

        let projA = try database.dailyMetrics(metric: "project", from: "2026-04-10", to: "2026-04-10")
            .first { $0.dimension == "proj-a" }
        XCTAssertEqual(projA?.count, 2, "events")
        XCTAssertEqual(projA?.valueSum, 2, "distinct sessions")
    }

    /// `daily-metric-value-sum-zero`: `valueSum` is 0 on every metric but
    /// `project`, where it is the day's distinct sessions.
    func testRecomputeWritesValueSumOnlyOnProjectRows() throws {
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-10T10:00:00Z", cwd: "/w/proj-a", tool: "Edit")
        try seed(event: "PostToolUse", session: "s1", timestamp: "2026-04-10T10:00:30Z", cwd: "/w/proj-a", tool: "Edit")
        try seed(event: "PreToolUse", session: "s2", timestamp: "2026-04-10T10:01:00Z", cwd: "/w/proj-a", tool: "Read")
        try seed(event: "PreToolUse", session: "s3", timestamp: "2026-04-10T10:02:00Z", cwd: "/w/proj-b", tool: "Bash")
        try database.recomputeDailyMetrics(forDay: "2026-04-10")

        let rows = try database.dailyMetrics(from: "2026-04-10", to: "2026-04-10")
        let others = rows.filter { $0.metric != "project" }
        XCTAssertFalse(others.isEmpty)
        for row in others {
            XCTAssertEqual(row.valueSum, 0, "\(row.metric)/\(row.dimension)")
        }
        let projects = Dictionary(uniqueKeysWithValues: rows.filter { $0.metric == "project" }
            .map { ($0.dimension, $0) })
        XCTAssertEqual(projects["proj-a"]?.count, 3, "events")
        XCTAssertEqual(projects["proj-a"]?.valueSum, 2, "s1 and s2")
        XCTAssertEqual(projects["proj-b"]?.valueSum, 1, "s3")
    }

    func testBackfillProjectMetricFillsDaysLackingIt() throws {
        // Events present but never recomputed → no project rows yet (mimics days
        // finalized by a daemon that predated the project metric).
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-10T10:00:00Z", cwd: "/w/proj-a", tool: "Edit")
        try seed(event: "PreToolUse", session: "s2", timestamp: "2026-04-10T10:01:00Z", cwd: "/w/proj-a", tool: "Read")
        XCTAssertTrue(try database.dailyMetrics(metric: "project", from: "2026-04-10", to: "2026-04-10").isEmpty)

        XCTAssertEqual(try database.backfillProjectMetric(through: "2026-04-10", limit: 10), 1)
        let projA = try database.dailyMetrics(metric: "project", from: "2026-04-10", to: "2026-04-10")
            .first { $0.dimension == "proj-a" }
        XCTAssertEqual(projA?.count, 2)
        XCTAssertEqual(projA?.valueSum, 2)
        // Idempotent: the day now has project rows, so a second pass is a no-op.
        XCTAssertEqual(try database.backfillProjectMetric(through: "2026-04-10", limit: 10), 0)
    }

    /// The backfill walks forward from its marker in chunks of `limit` days,
    /// passes a day that yields no project (cwd "/") once instead of retrying
    /// it, and once it reaches the finalized day never rewalks history.
    func testBackfillProjectMetricWalksForwardFromItsMarker() throws {
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-01T10:00:00Z", cwd: "/w/a", tool: "Edit")
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-03T10:00:00Z", cwd: "/", tool: "Edit")
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-05T10:00:00Z", cwd: "/w/b", tool: "Edit")
        try seed(event: "PreToolUse", session: "s1", timestamp: "2026-04-09T10:00:00Z", cwd: "/w/c", tool: "Edit")
        let key = DaemonDatabase.projectBackfillMarkerKey

        XCTAssertEqual(try database.backfillProjectMetric(through: "2026-04-08", limit: 2), 2)
        XCTAssertEqual(try database.setting(for: key), "2026-04-03", "marker stops at the last day done")
        XCTAssertEqual(try database.backfillProjectMetric(through: "2026-04-08", limit: 2), 1)
        XCTAssertEqual(try database.setting(for: key), "2026-04-08", "an exhausted walk reaches the finalized day")
        XCTAssertEqual(try database.backfillProjectMetric(through: "2026-04-08", limit: 2), 0)

        let projects = try database.dailyMetrics(metric: "project").map { "\($0.day) \($0.dimension)" }
        XCTAssertEqual(projects, ["2026-04-01 a", "2026-04-05 b"], "04-09 is past the finalized day")

        // A project row deleted behind the marker is not revisited: the walk
        // starts after it.
        try database.execute("DELETE FROM daily_metric WHERE day = '2026-04-01'")
        XCTAssertEqual(try database.backfillProjectMetric(through: "2026-04-08", limit: 2), 0)
        // The finalized day moves on; only the newly finalized days are walked.
        XCTAssertEqual(try database.backfillProjectMetric(through: "2026-04-09", limit: 2), 1)
        XCTAssertEqual(try database.setting(for: key), "2026-04-09")
        XCTAssertTrue(try database.dailyMetrics(metric: "project", from: "2026-04-01", to: "2026-04-01").isEmpty)
    }

    // MARK: - cacheMisses

    /// One status-line tick. The `prompt_cache` counters are cumulative within a
    /// cache epoch and reset to zero on a cold rebuild, exactly as the real
    /// payload reports them.
    private func seedTick(
        session: String,
        timestamp: String,
        misses: Int,
        requests: Int,
        recacheTokens: Int?,
        causes: [String: Int]?,
        lastMissCause: [String: Any]? = nil,
        model: String = "claude-opus-5",
        ttl: String = "1h"
    ) throws {
        var promptCache: [String: Any] = [
            "misses": misses,
            "requests": requests,
            "ttl": ttl
        ]
        // `nil` means the status line omitted the field on this render, which is
        // not the same as reporting zero — see the island fill in `cacheMisses`.
        if let recacheTokens { promptCache["miss_recache_tokens"] = recacheTokens }
        if let causes { promptCache["miss_causes"] = causes }
        if let lastMissCause { promptCache["last_miss_cause"] = lastMissCause }
        try pipeline().ingest(ClaudePipelineTestHarness.event(
            "StatusLine", sessionId: session, timestamp: timestamp, cwd: "",
            hookData: ["model_id": model, "prompt_cache": promptCache]))
    }

    func testCacheMissesOnEmptyDBIsZero() throws {
        let report = try database.cacheMisses()
        XCTAssertEqual(report.misses, 0)
        XCTAssertEqual(report.requests, 0)
        XCTAssertEqual(report.missRate, 0)
        XCTAssertEqual(report.estimatedCostUsd, 0)
        XCTAssertTrue(report.causes.isEmpty)
        XCTAssertTrue(report.models.isEmpty)
    }

    /// The counters repeat unchanged on every tick until the next miss, so a
    /// row count is not a miss count — only the increases are.
    func testCacheMissesCountsIncreasesNotTicks() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 0, requests: 100, recacheTokens: 0, causes: [:])
        try seedTick(session: "s", timestamp: "2026-04-10T10:01:00Z",
                     misses: 1, requests: 110, recacheTokens: 100_000,
                     causes: ["ttl_expired_1h": 1],
                     lastMissCause: ["causes": ["ttl_expired_1h"]])
        // Five renders of that same miss.
        for minute in 2...6 {
            try seedTick(session: "s", timestamp: "2026-04-10T10:0\(minute):00Z",
                         misses: 1, requests: 110, recacheTokens: 100_000,
                         causes: ["ttl_expired_1h": 1],
                         lastMissCause: ["causes": ["ttl_expired_1h"]])
        }

        let report = try database.cacheMisses()
        XCTAssertEqual(report.misses, 1)
        XCTAssertEqual(report.requests, 10)
        XCTAssertEqual(report.recacheTokens, 100_000)
        XCTAssertEqual(report.causes.map(\.cause), ["ttl_expired_1h"])
        XCTAssertEqual(report.causes.first?.occurrences, 1)
    }

    /// A session's first tick describes misses from before the daemon was
    /// watching; counting them would import uncorroborated history.
    func testCacheMissesIgnoresTheFirstTicksInheritedCounters() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 9, requests: 900, recacheTokens: 900_000,
                     causes: ["messages_rewritten": 9])

        let report = try database.cacheMisses()
        XCTAssertEqual(report.misses, 0)
        XCTAssertEqual(report.requests, 0)
        XCTAssertEqual(report.recacheTokens, 0)
    }

    /// A cold rebuild zeroes the counters; the value after the reset is all new.
    func testCacheMissesTreatsACounterResetAsANewEpoch() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 0, requests: 10, recacheTokens: 0, causes: [:])
        try seedTick(session: "s", timestamp: "2026-04-10T10:01:00Z",
                     misses: 3, requests: 40, recacheTokens: 300_000,
                     causes: ["messages_rewritten": 3])
        try seedTick(session: "s", timestamp: "2026-04-10T11:00:00Z",
                     misses: 1, requests: 5, recacheTokens: 50_000,
                     causes: ["system_prompt_changed": 1])

        let report = try database.cacheMisses()
        XCTAssertEqual(report.misses, 4)          // 3 in the first epoch, 1 in the second
        XCTAssertEqual(report.requests, 35)       // +30, then the post-reset 5
        XCTAssertEqual(report.recacheTokens, 350_000)
        XCTAssertEqual(report.causes.first { $0.cause == "messages_rewritten" }?.occurrences, 3)
        XCTAssertEqual(report.causes.first { $0.cause == "system_prompt_changed" }?.occurrences, 1)
    }

    /// Three ticks read off the event store's `StatusLine` attrs: the first
    /// carries inherited counters and contributes nothing, the second is a
    /// counter reset whose whole value is new, and the third advances the
    /// cause object — a new key counts in full, a known key by its increase.
    func testCacheMissesReadsStatusLineAttrsAcrossAResetAndACauseObject() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 7, requests: 70, recacheTokens: 700_000,
                     causes: ["messages_rewritten": 7])
        try seedTick(session: "s", timestamp: "2026-04-10T10:05:00Z",
                     misses: 2, requests: 8, recacheTokens: 20_000,
                     causes: ["messages_rewritten": 2])
        try seedTick(session: "s", timestamp: "2026-04-10T10:10:00Z",
                     misses: 3, requests: 12, recacheTokens: 30_000,
                     causes: ["messages_rewritten": 2, "tools_changed": 1],
                     lastMissCause: ["causes": ["tools_changed"], "system_char_delta": 12])

        let report = try database.cacheMisses()
        XCTAssertEqual(report.misses, 3, "the reset's 2, then +1; the first tick's 7 is inherited")
        XCTAssertEqual(report.requests, 12, "8 after the reset, then +4")
        XCTAssertEqual(report.recacheTokens, 30_000, "20,000 after the reset, then +10,000")
        XCTAssertEqual(report.unattributedMisses, 0)
        XCTAssertEqual(report.models.map(\.model), ["claude-opus-5"])
        XCTAssertEqual(report.models.first?.ttl, "1h")
        XCTAssertEqual(report.causes.map(\.cause), ["messages_rewritten", "tools_changed"])
        XCTAssertEqual(report.causes.map(\.occurrences), [2, 1])
        XCTAssertEqual(report.systemPromptDeltas.map(\.chars), [12])
        XCTAssertEqual(report.coverageStart, "2026-04-10T10:00:00Z")
    }

    /// A cause key is absent from the object until its count leaves zero, so the
    /// previous value must be read out of the previous tick's whole object —
    /// partitioning per key would drop each cause's first occurrence.
    func testCacheMissesCountsACausesFirstAppearance() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 1, requests: 10, recacheTokens: 10_000,
                     causes: ["messages_rewritten": 1])
        try seedTick(session: "s", timestamp: "2026-04-10T10:01:00Z",
                     misses: 2, requests: 20, recacheTokens: 20_000,
                     causes: ["messages_rewritten": 1, "betas_changed": 1])

        let report = try database.cacheMisses()
        XCTAssertEqual(report.causes.first { $0.cause == "betas_changed" }?.occurrences, 1)
        XCTAssertNil(report.causes.first { $0.cause == "messages_rewritten" })
    }

    /// Misses are priced per (model, TTL): the write premium is 1.25x at 5m and
    /// 2x at 1h, over a base input rate that differs per model.
    func testCacheMissesPricesPerModelAndTTL() throws {
        try seedTick(session: "opus", timestamp: "2026-04-10T10:00:00Z",
                     misses: 0, requests: 0, recacheTokens: 0, causes: [:])
        try seedTick(session: "opus", timestamp: "2026-04-10T10:01:00Z",
                     misses: 1, requests: 10, recacheTokens: 1_000_000,
                     causes: ["ttl_expired_1h": 1])
        try seedTick(session: "fable", timestamp: "2026-04-10T10:00:00Z",
                     misses: 0, requests: 0, recacheTokens: 0, causes: [:],
                     model: "claude-fable-5-1", ttl: "5m")
        try seedTick(session: "fable", timestamp: "2026-04-10T10:01:00Z",
                     misses: 1, requests: 10, recacheTokens: 1_000_000,
                     causes: ["messages_rewritten": 1],
                     model: "claude-fable-5-1", ttl: "5m")

        let report = try database.cacheMisses()
        XCTAssertEqual(report.misses, 2)
        XCTAssertEqual(report.requests, 20)
        XCTAssertEqual(report.missRate, 0.1, accuracy: 0.0001)
        // opus-5 1M x $5 x 2.0 = $10; fable-5-1 1M x $10 x 1.25 = $12.50
        XCTAssertEqual(report.estimatedCostUsd, 22.50, accuracy: 0.001)
        XCTAssertEqual(
            report.models.first { $0.model == "claude-opus-5" }?.estimatedCostUsd ?? 0,
            10.00, accuracy: 0.001
        )
        XCTAssertEqual(
            report.models.first { $0.model == "claude-fable-5-1" }?.estimatedCostUsd ?? 0,
            12.50, accuracy: 0.001
        )
    }

    /// A repeating +N/-N pair is the signature of a system-prompt block that
    /// toggles between two renderings rather than one that grows.
    func testCacheMissesReportsOscillatingSystemPromptDeltas() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 0, requests: 0, recacheTokens: 0, causes: [:])
        for (index, delta) in [53, -53, 53].enumerated() {
            try seedTick(session: "s", timestamp: "2026-04-10T10:0\(index + 1):00Z",
                         misses: index + 1, requests: (index + 1) * 10,
                         recacheTokens: (index + 1) * 1000,
                         causes: ["system_prompt_changed": index + 1],
                         lastMissCause: [
                            "causes": ["system_prompt_changed"],
                            "system_char_delta": delta
                         ])
        }

        let report = try database.cacheMisses()
        XCTAssertEqual(report.systemPromptDeltas.first?.chars, 53)
        XCTAssertEqual(report.systemPromptDeltas.first?.occurrences, 2)
        XCTAssertEqual(report.systemPromptDeltas.first { $0.chars == -53 }?.occurrences, 1)
    }

    func testCacheMissesFiltersBySince() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 0, requests: 0, recacheTokens: 0, causes: [:])
        try seedTick(session: "s", timestamp: "2026-04-10T10:01:00Z",
                     misses: 1, requests: 10, recacheTokens: 10_000,
                     causes: ["ttl_expired_1h": 1])
        try seedTick(session: "s", timestamp: "2026-04-20T10:00:00Z",
                     misses: 2, requests: 20, recacheTokens: 20_000,
                     causes: ["ttl_expired_1h": 1, "betas_changed": 1])

        // `since` filters the *output*, never the window: every `LAG` runs over
        // the session's whole history and the bound is applied to the
        // differenced rows afterwards. So the 04-20 tick is differenced against
        // its real predecessor on 04-10 — one miss, ten requests, 10,000
        // recache tokens — and only the 04-10 tick's own delta is filtered out.
        //
        // Narrowing the window first would look tidier and be wrong: the first
        // tick inside any range would lose its predecessor and contribute
        // nothing, so a report over "the last day" would drop the first miss of
        // that day, every day, and nothing in the output would say so.
        let report = try database.cacheMisses(since: "2026-04-15T00:00:00Z")
        XCTAssertEqual(report.misses, 1)
        XCTAssertEqual(report.requests, 10)
        XCTAssertEqual(report.recacheTokens, 10_000)
        XCTAssertEqual(report.since, "2026-04-15T00:00:00Z")

        // …and the unfiltered report over the same three ticks sees both.
        let all = try database.cacheMisses()
        XCTAssertEqual(all.misses, 2)
    }

    /// A render that omits `miss_recache_tokens` is a missing observation, not a
    /// report of zero. Read literally it zeroes the delta on *both* sides of
    /// itself — the drop to null and the climb back out — so a real recache
    /// disappears from the bill entirely.
    func testATickThatOmitsRecacheTokensDoesNotZeroTheDeltaTwice() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 0, requests: 0, recacheTokens: 0, causes: [:])
        try seedTick(session: "s", timestamp: "2026-04-10T10:01:00Z",
                     misses: 1, requests: 10, recacheTokens: nil,
                     causes: ["ttl_expired_1h": 1])
        try seedTick(session: "s", timestamp: "2026-04-10T10:02:00Z",
                     misses: 1, requests: 10, recacheTokens: 30_000,
                     causes: ["ttl_expired_1h": 1])

        let report = try database.cacheMisses()
        XCTAssertEqual(report.recacheTokens, 30_000,
                       "the omitted tick swallowed a real recache")
        XCTAssertEqual(report.misses, 1)
    }

    /// A TTL spelling `TranscriptPricing` doesn't know is priced at the API
    /// default 1.25x. That is a fallback, not a measurement: a 1-hour write
    /// under an unrecognised spelling is understated by 37.5%, and `ttlKnown`
    /// is the only thing that says so.
    func testAnUnpricedTTLIsFlaggedRatherThanPassedOffAsAFiveMinuteWrite() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 0, requests: 0, recacheTokens: 0, causes: [:], ttl: "30m")
        try seedTick(session: "s", timestamp: "2026-04-10T10:01:00Z",
                     misses: 1, requests: 10, recacheTokens: 1_000_000,
                     causes: ["ttl_expired_1h": 1], ttl: "30m")

        let group = try XCTUnwrap(try database.cacheMisses().models.first)
        XCTAssertEqual(group.ttl, "30m")
        XCTAssertFalse(group.ttlKnown)
        XCTAssertEqual(group.estimatedCostUsd, 6.25, accuracy: 0.001)
    }

    func testAKnownTTLIsNotFlagged() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 0, requests: 0, recacheTokens: 0, causes: [:])
        try seedTick(session: "s", timestamp: "2026-04-10T10:01:00Z",
                     misses: 1, requests: 10, recacheTokens: 1_000_000,
                     causes: ["ttl_expired_1h": 1])

        XCTAssertTrue(try XCTUnwrap(try database.cacheMisses().models.first).ttlKnown)
    }

    // MARK: - coverage

    /// This report differences the event store's raw `StatusLine` rows; `RollupTask` has no
    /// status-line entry, so nothing survives a row that retention deletes. A
    /// window asking for more history than remains would otherwise answer with
    /// a total that is simply short, and look deliberate doing it.
    func testCoverageStartReportsTheOldestTickStillOnDisk() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 0, requests: 0, recacheTokens: 0, causes: [:])
        try seedTick(session: "s", timestamp: "2026-04-10T10:01:00Z",
                     misses: 1, requests: 10, recacheTokens: 10_000,
                     causes: ["ttl_expired_1h": 1])

        XCTAssertEqual(try database.cacheMisses().coverageStart, "2026-04-10T10:00:00Z")
    }

    func testCoverageStartIsEmptyWhenNoTickSurvives() throws {
        XCTAssertEqual(try database.cacheMisses().coverageStart, "")
    }

    func testCoverageStartExposesAWindowWiderThanTheHistoryLeft() throws {
        try seedTick(session: "s", timestamp: "2026-04-10T10:00:00Z",
                     misses: 0, requests: 0, recacheTokens: 0, causes: [:])
        try seedTick(session: "s", timestamp: "2026-04-10T10:01:00Z",
                     misses: 1, requests: 10, recacheTokens: 10_000,
                     causes: ["ttl_expired_1h": 1])

        // The caller asked for January; the oldest tick left is April.
        let report = try database.cacheMisses(since: "2026-01-01T00:00:00Z")
        XCTAssertEqual(report.since, "2026-01-01T00:00:00Z")
        XCTAssertGreaterThan(report.coverageStart, report.since,
                             "a narrowed window must be visible to the caller")
    }

    // MARK: - fableCostShare

    /// The Claude pipeline feeding `database`, made on first use; the usage
    /// readers read the event-store turns it holds.
    private var pipelineHarness: ClaudePipelineTestHarness?

    private func pipeline() throws -> ClaudePipelineTestHarness {
        if let pipelineHarness { return pipelineHarness }
        let made = try ClaudePipelineTestHarness(
            directory: tmpDir.appendingPathComponent("pipeline"), database: database)
        pipelineHarness = made
        return made
    }

    /// One assistant turn in the event store, priced by `TranscriptPricing` like
    /// any other. The turn carries no account (Design Ruling 4): `account` goes
    /// on the session's main row, made here unless the test already made it.
    private func seedTurn(
        model: String, at timestamp: String, account: String,
        outputTokens: Int, session: String = "s"
    ) throws {
        try pipeline().seedTurn(
            sessionId: session, timestamp: timestamp, model: model,
            dedupKey: "m-\(UUID().uuidString)", output: outputTokens, account: account)
    }

    func testFableCostShareIsNilWithoutAnEventStore() throws {
        try database.createSessionStubIfMissing(
            sessionId: "s", cwd: "/tmp", model: "fable",
            startedAt: "2026-04-10T10:00:00Z", lastActivityAt: "2026-04-10T10:00:00Z",
            accountEmail: "a@x.com")
        XCTAssertNil(database.eventReads)
        XCTAssertNil(try database.fableCostShare(
            account: "a@x.com", since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z"))
        XCTAssertNil(try database.fableCostShare(
            account: nil, credential: .oauth,
            since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z"))
    }

    func testFableCostShareIsNilOverAnEmptyEventStore() throws {
        try database.createSessionStubIfMissing(
            sessionId: "s", cwd: "/tmp", model: "fable",
            startedAt: "2026-04-10T10:00:00Z", lastActivityAt: "2026-04-10T10:00:00Z",
            accountEmail: "a@x.com")
        _ = try pipeline()
        XCTAssertNil(try database.fableCostShare(
            account: "a@x.com", since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z"))
    }

    func testFableCostShareWithNoAccountSplitsByCredential() throws {
        // With no account named, `.longLived` counts the token sessions and
        // `.oauth` every other session, including a turn with no session row.
        try database.createSessionStubIfMissing(
            sessionId: "tok", cwd: "/tmp", model: "fable",
            startedAt: "2026-04-10T10:00:00Z", lastActivityAt: "2026-04-10T10:00:00Z",
            accountEmail: "a@x.com", authMethod: "token")
        try seedTurn(model: "claude-fable-5-1", at: "2026-04-10T10:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000, session: "tok")
        try pipeline().seedTurn(
            sessionId: "orphan", timestamp: "2026-04-10T11:00:00Z", model: "claude-opus-5",
            output: 1_000_000)
        let window = (since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z")
        XCTAssertEqual(try database.fableCostShare(
            account: nil, credential: .longLived,
            since: window.since, until: window.until) ?? -1, 1, accuracy: 0.0001)
        XCTAssertEqual(try database.fableCostShare(
            account: nil, credential: .oauth,
            since: window.since, until: window.until) ?? -1, 0, accuracy: 0.0001)
        XCTAssertEqual(try database.fableCostShare(
            account: nil, since: window.since, until: window.until) ?? -1,
            50.0 / 75.0, accuracy: 0.0001)
    }

    func testFableCostShareIsFablesFractionOfTheWindowsCost() throws {
        // Fable bills $50/MTok output, Opus $25 — so equal output tokens are a
        // 2:1 cost split, and the share is a share of COST, not of turns. That
        // distinction is the whole point: a quota is spent in dollars.
        try seedTurn(model: "claude-fable-5-1", at: "2026-04-10T10:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000)
        try seedTurn(model: "claude-opus-5", at: "2026-04-10T11:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000)

        let share = try database.fableCostShare(
            account: "a@x.com",
            since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z"
        )
        XCTAssertEqual(share ?? -1, 50.0 / 75.0, accuracy: 0.0001)
    }

    func testFableCostShareCountsEveryModelInTheFableTier() throws {
        // Mythos is priced identically and metered against the same sub-limit;
        // a dated id is the form transcripts actually record.
        try seedTurn(model: "claude-mythos-5-1", at: "2026-04-10T10:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000)
        try seedTurn(model: "claude-fable-5-1-20260201", at: "2026-04-10T10:30:00Z",
                     account: "a@x.com", outputTokens: 1_000_000)
        try seedTurn(model: "claude-sonnet-5", at: "2026-04-10T11:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000)

        let share = try database.fableCostShare(
            account: "a@x.com",
            since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z"
        )
        XCTAssertEqual(share ?? -1, 100.0 / 110.0, accuracy: 0.0001)
    }

    func testFableCostShareIsZeroForAWindowWithNoFableTurns() throws {
        // Zero, not nil: the window WAS measured, and it found no Fable.
        try seedTurn(model: "claude-opus-5", at: "2026-04-10T10:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000)

        let share = try database.fableCostShare(
            account: "a@x.com",
            since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z"
        )
        XCTAssertEqual(share ?? -1, 0, accuracy: 0.0001)
    }

    func testFableCostShareIsNilWhenTheWindowCostNothing() throws {
        // Nothing priced landed in the window, so there is no denominator and
        // no share — which the row must be able to tell apart from a real zero.
        XCTAssertNil(try database.fableCostShare(
            account: "a@x.com",
            since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z"
        ))
    }

    func testFableCostShareIsScopedToOneAccountAndOneWindow() throws {
        // The share divides a per-account weekly reading, so a neighbouring
        // account's Fable — or last month's — must not enter into it.
        try seedTurn(model: "claude-fable-5-1", at: "2026-04-10T10:00:00Z",
                     account: "b@x.com", outputTokens: 1_000_000, session: "sb")
        try seedTurn(model: "claude-fable-5-1", at: "2026-03-01T10:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000, session: "sold")
        try seedTurn(model: "claude-opus-5", at: "2026-04-10T11:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000)

        let share = try database.fableCostShare(
            account: "a@x.com",
            since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z"
        )
        XCTAssertEqual(share ?? -1, 0, accuracy: 0.0001)
    }

    func testTheFableTierIsRecognizedByFamilyNotByExactID() throws {
        XCTAssertTrue(TranscriptPricing.isFableTier("claude-fable-5-1"))
        XCTAssertTrue(TranscriptPricing.isFableTier("claude-fable-5-1-20260201"))
        XCTAssertTrue(TranscriptPricing.isFableTier("claude-mythos-5"))
        XCTAssertTrue(TranscriptPricing.isFableTier("claude-fable-6"))
        // Provider-prefixed spellings of the same model still count.
        XCTAssertTrue(TranscriptPricing.isFableTier("us.anthropic.claude-fable-5-1-v1:0"))
        XCTAssertTrue(TranscriptPricing.isFableTier("anthropic/claude-mythos-5-1"))
        XCTAssertTrue(TranscriptPricing.isFableTier("Claude-Fable-5-1"))
        XCTAssertFalse(TranscriptPricing.isFableTier("claude-opus-5"))
        XCTAssertFalse(TranscriptPricing.isFableTier("claude-haiku-4-5-20251001"))
        XCTAssertFalse(TranscriptPricing.isFableTier(""))
    }

    func testTheFableTierIsNotASubstringMatch() throws {
        // A local model that merely contains the word is not Anthropic's tier,
        // and counting it would push the gauge toward a limit it cannot reach.
        XCTAssertFalse(TranscriptPricing.isFableTier("affable-coder-7b"))
        XCTAssertFalse(TranscriptPricing.isFableTier("mythos-llama-70b"))
        XCTAssertFalse(TranscriptPricing.isFableTier("fable"))
        XCTAssertFalse(TranscriptPricing.isFableTier("myclaude-fable-5"))
    }

    func testFableCostShareMatchesTheAccountWhateverItsCase() throws {
        // A probe names the account as the app stored it; transcripts carry it
        // as ~/.claude.json spells it. The two differ in case in the wild.
        try seedTurn(model: "claude-fable-5-1", at: "2026-04-10T10:00:00Z",
                     account: "A@X.com", outputTokens: 1_000_000)

        let share = try database.fableCostShare(
            account: "a@x.com",
            since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z"
        )
        XCTAssertEqual(share ?? -1, 1, accuracy: 0.0001)
    }

    func testFableCostShareIsScopedToOneCredential() throws {
        // A setup token and the same address's login are metered separately,
        // so each one's share counts only the sessions that billed it.
        try database.createSessionStubIfMissing(
            sessionId: "tok", cwd: "/tmp", model: "fable",
            startedAt: "2026-04-10T10:00:00Z", lastActivityAt: "2026-04-10T10:00:00Z",
            accountEmail: "a@x.com", authMethod: "token")
        try database.createSessionStubIfMissing(
            sessionId: "login", cwd: "/tmp", model: "opus",
            startedAt: "2026-04-10T10:00:00Z", lastActivityAt: "2026-04-10T10:00:00Z",
            accountEmail: "a@x.com", authMethod: "oauth")
        try seedTurn(model: "claude-fable-5-1", at: "2026-04-10T10:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000, session: "tok")
        try seedTurn(model: "claude-opus-5", at: "2026-04-10T11:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000, session: "login")

        let window = (since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z")
        XCTAssertEqual(try database.fableCostShare(
            account: "a@x.com", credential: .longLived,
            since: window.since, until: window.until) ?? -1, 1, accuracy: 0.0001)
        XCTAssertEqual(try database.fableCostShare(
            account: "a@x.com", credential: .oauth,
            since: window.since, until: window.until) ?? -1, 0, accuracy: 0.0001)
        XCTAssertEqual(try database.fableCostShare(
            account: "a@x.com",
            since: window.since, until: window.until) ?? -1, 50.0 / 75.0, accuracy: 0.0001)
    }

    func testFableCostShareCountsEveryModelNotJustTheBusiestFiveHundred() throws {
        // The share is a ratio over the whole window; a per-model cap would
        // drop the rarest models — and Fable is exactly the rare one.
        for index in 0..<501 {
            try seedTurn(model: "claude-opus-5-x\(index)", at: "2026-04-10T10:00:00Z",
                         account: "a@x.com", outputTokens: 0, session: "s\(index)")
            try seedTurn(model: "claude-opus-5-x\(index)", at: "2026-04-10T10:01:00Z",
                         account: "a@x.com", outputTokens: 0, session: "s\(index)")
        }
        try seedTurn(model: "claude-fable-5-1", at: "2026-04-10T10:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000)

        let share = try database.fableCostShare(
            account: "a@x.com",
            since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z"
        )
        XCTAssertEqual(share ?? -1, 1, accuracy: 0.0001)
    }

    func testTheCachedShareIsReusedWithinItsTTLAndRefreshedAfter() throws {
        // The Usage rows recompute every few seconds; the share only moves as
        // fast as turns land, so it is held for a minute rather than re-read.
        let window = (since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z")
        let start = Date(timeIntervalSince1970: 1_000_000)
        try seedTurn(model: "claude-opus-5", at: "2026-04-10T10:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000)
        XCTAssertEqual(database.cachedFableCostShare(
            account: "a@x.com", credential: nil,
            since: window.since, until: window.until, now: start) ?? -1, 0, accuracy: 0.0001)

        try seedTurn(model: "claude-fable-5-1", at: "2026-04-10T11:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000)
        XCTAssertEqual(database.cachedFableCostShare(
            account: "a@x.com", credential: nil,
            since: window.since, until: window.until,
            now: start.addingTimeInterval(30)) ?? -1, 0, accuracy: 0.0001)
        XCTAssertEqual(database.cachedFableCostShare(
            account: "a@x.com", credential: nil,
            since: window.since, until: window.until,
            now: start.addingTimeInterval(DaemonDatabase.fableShareCacheTTL + 1)) ?? -1,
            50.0 / 75.0, accuracy: 0.0001)
    }

    /// What both Usage call sites ask for a reading's Fable gauge: a
    /// credential with no turns of its own (often the setup token the card
    /// shows) takes its account's mix, and one with its own mix keeps it.
    func testAReadingWithoutItsOwnTurnsTakesTheAccountsFableMix() throws {
        try database.createSessionStubIfMissing(
            sessionId: "login", cwd: "/tmp", model: "opus",
            startedAt: "2026-04-10T10:00:00Z", lastActivityAt: "2026-04-10T10:00:00Z",
            accountEmail: "a@x.com", authMethod: "oauth")
        try seedTurn(model: "claude-fable-5-1", at: "2026-04-10T10:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000, session: "login")
        try seedTurn(model: "claude-opus-5", at: "2026-04-10T11:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000, session: "login")
        let window = (since: "2026-04-01T00:00:00Z", until: "2026-04-20T00:00:00Z")
        let start = Date(timeIntervalSince1970: 1_000_000)

        XCTAssertEqual(database.readingFableCostShare(
            account: "a@x.com", credential: .longLived,
            since: window.since, until: window.until, now: start) ?? -1, 50.0 / 75.0, accuracy: 0.0001)
        XCTAssertNil(database.readingFableCostShare(
            account: "b@x.com", credential: nil,
            since: window.since, until: window.until, now: start), "no turns anywhere is unknown")

        try database.createSessionStubIfMissing(
            sessionId: "tok", cwd: "/tmp", model: "opus",
            startedAt: "2026-04-10T10:00:00Z", lastActivityAt: "2026-04-10T10:00:00Z",
            accountEmail: "a@x.com", authMethod: "token")
        try seedTurn(model: "claude-opus-5", at: "2026-04-10T12:00:00Z",
                     account: "a@x.com", outputTokens: 1_000_000, session: "tok")
        XCTAssertEqual(database.readingFableCostShare(
            account: "a@x.com", credential: .longLived,
            since: window.since, until: window.until,
            now: start.addingTimeInterval(DaemonDatabase.fableShareCacheTTL + 1)) ?? -1, 0, accuracy: 0.0001)
    }
}
