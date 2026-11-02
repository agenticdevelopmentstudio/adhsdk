import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// The insights and daily-rollup reads over the event store: events go in
/// through the Claude pipeline and come back counted per UTC day, hook type,
/// dimension and (cwd, session). An event whose time is unknown never counts,
/// and without a store every read answers empty.
final class ClaudeInsightReadsTests: XCTestCase {

    private var root: URL!
    private var harness: ClaudePipelineTestHarness!
    private var database: DaemonDatabase { harness.database }

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("insight-reads-\(UUID().uuidString)", isDirectory: true)
        harness = try ClaudePipelineTestHarness(directory: root)
    }

    override func tearDownWithError() throws {
        harness = nil
        try? FileManager.default.removeItem(at: root)
    }

    private func hook(
        _ type: String, _ session: String, _ stamp: String,
        cwd: String = "/Users/dev/work/myapp", _ extra: [String: Any] = [:]
    ) -> ParsedEvent {
        ClaudePipelineTestHarness.event(type, sessionId: session, timestamp: stamp, cwd: cwd, hookData: extra)
    }

    private func epoch(_ iso: String) throws -> Double {
        try XCTUnwrap(TimestampParsing.parse(iso)).timeIntervalSince1970
    }

    private func statusTick(
        _ session: String, _ stamp: String, misses: Int, requests: Int, recache: Int,
        model: String = "claude-sonnet-4-6", ttl: String = "5m", causes: [String: Int]? = nil,
        lastMissChars: Int? = nil
    ) -> ParsedEvent {
        var cache: [String: Any] = [
            "misses": misses, "requests": requests, "miss_recache_tokens": recache, "ttl": ttl
        ]
        if let causes { cache["miss_causes"] = causes }
        if let lastMissChars { cache["last_miss_cause"] = ["system_char_delta": lastMissChars] }
        return hook("StatusLine", session, stamp, ["model_id": model, "prompt_cache": cache])
    }

    // MARK: - Counts by day

    func testTypeCountsAreBucketedByUTCDayAndSkipUnknownTimes() throws {
        try harness.ingest([
            hook("SessionStart", "s1", "2026-06-01T23:59:59Z"),
            hook("PreToolUse", "s1", "2026-06-01T12:00:00Z", ["tool_name": "Read"]),
            hook("PreToolUse", "s1", "2026-06-02T00:00:00Z", ["tool_name": "Edit"]),
            hook("Stop", "s1", "1970-01-01T00:00:00Z")
        ])
        let counts = try database.claudeEventTypeCountsByDay()
            .map { "\($0.day) \($0.providerType) \($0.count)" }.sorted()
        XCTAssertEqual(counts, [
            "2026-06-01 PreToolUse 1", "2026-06-01 SessionStart 1", "2026-06-02 PreToolUse 1"
        ])
        XCTAssertEqual(try database.claudeEventCount(), 3, "the unknown-time Stop is left out")
        let june2 = try epoch("2026-06-02T00:00:00Z")
        XCTAssertEqual(try database.claudeEventCount(from: june2), 1, "from is inclusive")
        XCTAssertEqual(try database.claudeEventCount(until: june2), 2, "until is exclusive")
        XCTAssertEqual(try database.claudeEventTypeCountsByDay(from: june2).map(\.day), ["2026-06-02"])
    }

    func testDimensionCountsReadToolNameOrAnAttrAndSkipEmptyValues() throws {
        try harness.ingest([
            hook("PreToolUse", "s1", "2026-06-01T12:00:00Z", ["tool_name": "Read"]),
            hook("PreToolUse", "s1", "2026-06-01T12:01:00Z", ["tool_name": "Read"]),
            hook("PreToolUse", "s1", "2026-06-01T12:02:00Z", ["tool_name": "Bash"]),
            hook("PreToolUse", "s1", "2026-06-01T12:03:00Z"),
            hook("PostToolUse", "s1", "2026-06-01T12:04:00Z", ["tool_name": "Read"]),
            hook("PreCompact", "s1", "2026-06-01T12:05:00Z", ["trigger": "auto"]),
            hook("PreCompact", "s1", "2026-06-02T12:05:00Z", ["trigger": "manual"])
        ])
        let tools = try database.claudeDimensionCountsByDay(providerType: "PreToolUse", dimension: .toolName)
            .map { "\($0.day) \($0.dimension) \($0.count)" }.sorted()
        XCTAssertEqual(tools, ["2026-06-01 Bash 1", "2026-06-01 Read 2"])
        let triggers = try database.claudeDimensionCountsByDay(providerType: "PreCompact",
                                                               dimension: .attr("trigger"))
            .map { "\($0.day) \($0.dimension) \($0.count)" }.sorted()
        XCTAssertEqual(triggers, ["2026-06-01 auto 1", "2026-06-02 manual 1"])
    }

    func testCwdSessionCountsNewSessionsAndDays() throws {
        try harness.ingest([
            hook("SessionStart", "s1", "2026-06-01T12:00:00Z", cwd: "/a/myapp"),
            hook("SessionStart", "s1", "2026-06-01T13:00:00Z", cwd: "/a/myapp"),
            hook("SessionStart", "s2", "2026-06-03T12:00:00Z", cwd: "/a/other"),
            hook("Stop", "s2", "2026-06-03T12:30:00Z", cwd: "/a/other"),
            hook("SessionStart", "s3", "1970-01-01T00:00:00Z", cwd: "/a/old")
        ])
        let cwds = try database.claudeCwdSessionCounts()
            .map { "\($0.cwd) \($0.sessionId) \($0.count)" }.sorted()
        XCTAssertEqual(cwds, ["/a/myapp s1 2", "/a/other s2 2"])
        XCTAssertEqual(try database.claudeNewSessionsPerDay().map { "\($0.day) \($0.count)" },
                       ["2026-06-01 1", "2026-06-03 1"])
        XCTAssertEqual(try database.claudeEventDays(), ["2026-06-01", "2026-06-03"])
        XCTAssertEqual(try database.claudeEventDays(limit: 1), ["2026-06-01"])
        XCTAssertEqual(try database.claudeEventDays(from: try epoch("2026-06-02T00:00:00Z")), ["2026-06-03"])
        XCTAssertEqual(try database.claudeEarliestEventTime(), try epoch("2026-06-01T12:00:00Z"))
    }

    // MARK: - Prompt-cache misses

    /// Three ticks of one session: the first contributes nothing, the second
    /// is a counter reset (its whole value is new), and the third advances
    /// the causes object.
    func testCacheMissReadsDifferenceTicksAcrossAReset() throws {
        try harness.ingest([
            statusTick("s1", "2026-06-01T12:00:00Z", misses: 4, requests: 40, recache: 4000,
                       causes: ["system_changed": 4], lastMissChars: 10),
            statusTick("s1", "2026-06-01T12:01:00Z", misses: 1, requests: 5, recache: 300,
                       causes: ["system_changed": 1], lastMissChars: 20),
            statusTick("s1", "2026-06-01T12:02:00Z", misses: 3, requests: 9, recache: 900,
                       causes: ["system_changed": 2, "tools_changed": 1], lastMissChars: 20)
        ])
        let groups = try database.claudeCacheMissGroups()
        XCTAssertEqual(groups, [ClaudeCacheMissGroup(
            attributed: true, model: "claude-sonnet-4-6", ttl: "5m",
            misses: 1 + 2, requests: 5 + 4, recacheTokens: 300 + 600)])
        let causes = try database.claudeCacheMissCauses(limit: 10).map { "\($0.cause) \($0.count)" }
        XCTAssertEqual(causes, ["system_changed 2", "tools_changed 1"])
        let deltas = try database.claudeSystemPromptDeltas(limit: 10).map { "\($0.chars) \($0.count)" }
        XCTAssertEqual(deltas, ["20 2"])
        XCTAssertEqual(try database.claudeStatusLineCoverageStart(), try epoch("2026-06-01T12:00:00Z"))

        let late = try database.claudeCacheMissGroups(since: try epoch("2026-06-01T12:02:00Z"))
        XCTAssertEqual(late.map(\.misses), [2], "since filters the differenced ticks, not the window")
    }

    // MARK: - No store

    func testEveryInsightReadIsEmptyWithoutAStore() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        defer { TestDaemonDatabase.remove(path: opened.path) }
        let bare = opened.db
        try bare.ingestEvent(eventType: "PreToolUse", timestamp: "2026-06-01T12:00:00Z",
                             hookData: ["session_id": "s1", "cwd": "/tmp", "tool_name": "Read"])
        XCTAssertNil(bare.eventReads)
        XCTAssertTrue(try bare.claudeEventTypeCountsByDay().isEmpty)
        XCTAssertTrue(try bare.claudeDimensionCountsByDay(providerType: "PreToolUse", dimension: .toolName).isEmpty)
        XCTAssertEqual(try bare.claudeEventCount(), 0)
        XCTAssertTrue(try bare.claudeCwdSessionCounts().isEmpty)
        XCTAssertTrue(try bare.claudeNewSessionsPerDay().isEmpty)
        XCTAssertNil(try bare.claudeEarliestEventTime())
        XCTAssertTrue(try bare.claudeEventDays().isEmpty)
        XCTAssertNil(try bare.claudeStatusLineCoverageStart())
        XCTAssertTrue(try bare.claudeCacheMissGroups().isEmpty)
        XCTAssertTrue(try bare.claudeCacheMissCauses(limit: 10).isEmpty)
        XCTAssertTrue(try bare.claudeSystemPromptDeltas(limit: 10).isEmpty)
    }
}
