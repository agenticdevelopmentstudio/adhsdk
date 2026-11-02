import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// The session database's event readers over the event store and raw archive:
/// events go in through the Claude pipeline (`ClaudePipelineTestHarness`) and come
/// back through `fetchEvents`, `fetchRecentEvents`, `fetchEventDetail`, the
/// session event counts, `lastEventType` and the `claude*` read queries. Without
/// a store attached every one of them answers empty, even over legacy rows.
final class ClaudeEventReadsTests: XCTestCase {

    private var root: URL!
    private var harness: ClaudePipelineTestHarness!
    private var database: DaemonDatabase { harness.database }

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("event-reads-\(UUID().uuidString)", isDirectory: true)
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

    // MARK: - fetchEvents

    func testFetchEventsAnswersTheLegacyDTOShape() throws {
        try harness.ingest(hook("PreToolUse", "s1", "2026-06-01T12:00:00.750Z",
                                ["tool_name": "Read", "tool_input": ["file_path": "/tmp/a.swift"]]))
        try database.execute("UPDATE sessions SET git_branch = 'feature' WHERE session_id = ?", params: ["s1"])

        let event = try XCTUnwrap(try database.fetchEvents(sessionId: "s1").first)
        XCTAssertEqual(event.sessionId, "s1")
        XCTAssertEqual(event.eventType, "PreToolUse")
        XCTAssertEqual(event.timestamp, "2026-06-01T12:00:00Z", "whole seconds, UTC, Z")
        XCTAssertEqual(event.cwd, "/Users/dev/work/myapp")
        XCTAssertEqual(event.detail, computeDetail(
            eventType: "PreToolUse",
            hookData: ["tool_name": "Read", "tool_input": ["file_path": "/tmp/a.swift"]]))
        XCTAssertEqual(event.gitBranch, "feature")
        let row = try XCTUnwrap(try database.claudeEvent(id: Int64(event.id)), "id is the events row id")
        XCTAssertEqual(row.providerType, "PreToolUse")
    }

    func testFetchEventsFiltersByTypeSinceRootCwdAndPages() throws {
        try harness.ingest([
            hook("SessionStart", "s1", "2026-06-01T12:00:00Z"),
            hook("PreToolUse", "s1", "2026-06-01T12:01:00Z", ["tool_name": "Read"]),
            hook("PreToolUse", "s1", "2026-06-01T12:02:00Z", cwd: "/", ["tool_name": "Edit"]),
            hook("Stop", "s1", "2026-06-01T12:03:00Z"),
            hook("Stop", "other", "2026-06-01T12:04:00Z")
        ])

        XCTAssertEqual(try database.fetchEvents(sessionId: "s1").map(\.eventType),
                       ["Stop", "PreToolUse", "PreToolUse", "SessionStart"], "newest first")
        XCTAssertEqual(try database.fetchEvents(eventType: "Stop").map(\.sessionId), ["other", "s1"])
        XCTAssertEqual(try database.fetchEvents(sessionId: "s1", since: "2026-06-01T12:02:00.900Z").count, 2,
                       "since compares to the second")
        XCTAssertEqual(try database.fetchEvents(sessionId: "s1", since: "not a time").count, 0)
        XCTAssertEqual(try database.fetchEvents(sessionId: "s1", excludeRootCwd: true).count, 3)
        XCTAssertEqual(try database.fetchEvents(sessionId: "s1", limit: 2, offset: 1).map(\.timestamp),
                       ["2026-06-01T12:02:00Z", "2026-06-01T12:01:00Z"])
    }

    func testFetchRecentEventsSortsALateArrivalByItsTime() throws {
        try harness.ingest(hook("Stop", "s1", "2026-06-01T12:05:00Z"))
        try harness.ingest(hook("PreToolUse", "s1", "2026-06-01T12:00:00Z", ["tool_name": "Read"]))

        let recent = try database.fetchRecentEvents(sessionId: "s1", limit: 1)
        XCTAssertEqual(recent.map(\.eventType), ["Stop"], "a later-captured but earlier event sorts behind")
        XCTAssertEqual(try database.fetchRecentEvents(sessionId: "s1", limit: 10).count, 2)
    }

    // MARK: - fetchEventDetail

    func testHookDetailCarriesTypeFieldsToolInputAndResponse() throws {
        try harness.ingest([
            hook("PreToolUse", "s1", "2026-06-01T12:00:00Z",
                 ["tool_name": "CronCreate", "tool_use_id": "tu-1",
                  "tool_input": ["id": "in-1", "cron": "7 10 25 10 *"]]),
            hook("PostToolUse", "s1", "2026-06-01T12:00:01.500Z",
                 ["tool_name": "CronCreate", "tool_use_id": "tu-1",
                  "tool_input": ["id": "in-1", "cron": "7 10 25 10 *"],
                  "tool_response": ["id": "e96a2840", "recurring": "no"]])
        ])
        let post = try XCTUnwrap(try database.fetchEvents(sessionId: "s1", eventType: "PostToolUse").first)

        let detail = try XCTUnwrap(try database.fetchEventDetail(eventLogId: Int64(post.id)))
        XCTAssertEqual(detail["id"] as? Int, post.id)
        XCTAssertEqual(detail["session_id"] as? String, "s1")
        XCTAssertEqual(detail["event_type"] as? String, "PostToolUse")
        XCTAssertEqual(detail["timestamp"] as? String, "2026-06-01T12:00:01Z")
        XCTAssertEqual(detail["cwd"] as? String, "/Users/dev/work/myapp")
        XCTAssertEqual(detail["detail"] as? String, post.detail)

        let typeFields = try XCTUnwrap(detail["type_fields"] as? [String: Any])
        XCTAssertEqual(typeFields["tool_name"] as? String, "CronCreate")
        XCTAssertEqual(typeFields["tool_use_id"] as? String, "tu-1")
        XCTAssertEqual(typeFields["duration_ms"] as? Int, 1500)
        XCTAssertNil(typeFields["session_id"], "core fields are not repeated")
        XCTAssertNil(typeFields["cwd"])
        XCTAssertNil(typeFields["tool_input"], "the tool subtrees are their own keys")

        let input = try XCTUnwrap(detail["tool_input"] as? [String: Any])
        XCTAssertEqual(input["payload_id"] as? String, "in-1", "a row-owned name is kept as payload_<key>")
        XCTAssertEqual(input["cron"] as? String, "7 10 25 10 *")
        let response = try XCTUnwrap(detail["tool_response"] as? [String: Any])
        XCTAssertEqual(response["payload_id"] as? String, "e96a2840")
        XCTAssertEqual(response["recurring"] as? String, "no")
    }

    func testTranscriptDetailCarriesTheLinesFields() throws {
        let file = harness.transcriptFile(sessionId: "t1")
        try harness.ingestTranscript(
            lines: [#"{"type":"custom-title","customTitle":"Fix the build","sessionId":"t1"}"#], file: file)

        let event = try XCTUnwrap(try database.fetchEvents(sessionId: "t1").first)
        XCTAssertEqual(event.eventType, "custom-title")
        XCTAssertEqual(event.detail, "Fix the build")
        let detail = try XCTUnwrap(try database.fetchEventDetail(eventLogId: Int64(event.id)))
        let typeFields = try XCTUnwrap(detail["type_fields"] as? [String: Any])
        XCTAssertEqual(typeFields["customTitle"] as? String, "Fix the build")
        XCTAssertEqual(typeFields["type"] as? String, "custom-title")
        XCTAssertNil(detail["tool_input"])
    }

    func testDetailOfAnUnknownIdIsNil() throws {
        XCTAssertNil(try database.fetchEventDetail(eventLogId: 999_999))
    }

    // MARK: - Counts and last event

    func testSessionEventCountsComeFromTheStore() throws {
        try harness.ingest([
            hook("SessionStart", "s1", "2026-06-01T12:00:00Z"),
            hook("Stop", "s1", "2026-06-01T12:01:00Z"),
            hook("SessionStart", "s2", "2026-06-01T12:02:00Z")
        ])

        let sessions = try database.fetchSessions()
        let counts = Dictionary(uniqueKeysWithValues: sessions.map { ($0.sessionId, $0.eventCount) })
        XCTAssertEqual(counts, ["s1": 2, "s2": 1])
        XCTAssertEqual(try database.fetchSessions(includeEventCount: false).map(\.eventCount), [0, 0])
        XCTAssertEqual(try database.fetchSession(sessionId: "s1")?.eventCount, 2)
        XCTAssertEqual(try database.fetchSession(sessionId: "s1", includeEventCount: false)?.eventCount, 0)
        XCTAssertEqual(try database.totalEventCount(), 3)
        XCTAssertEqual(try database.claudeEventCounts(sessionIds: ["s1", "s2", "none"]), ["s1": 2, "s2": 1])
    }

    func testLastEventTypeOrdersByEventTimeNotCapture() throws {
        try harness.ingest(hook("Stop", "s1", "2026-06-01T12:05:00Z"))
        try harness.ingest(hook("PreToolUse", "s1", "2026-06-01T12:00:00Z", ["tool_name": "Read"]))

        XCTAssertEqual(try database.lastEventType(sessionId: "s1"), "Stop")
        XCTAssertEqual(try database.lastEventType(sessionId: "none"), "")
    }

    func testToolUseCountsArePerSessionAndTool() throws {
        try harness.ingest([
            hook("PreToolUse", "s1", "2026-06-01T12:00:00Z", ["tool_name": "Read"]),
            hook("PreToolUse", "s1", "2026-06-01T12:01:00Z", ["tool_name": "Read"]),
            hook("PostToolUse", "s1", "2026-06-01T12:01:01Z", ["tool_name": "Read"]),
            hook("PreToolUse", "s2", "2026-06-01T12:02:00Z", ["tool_name": "Edit"])
        ])

        let uses = try database.claudeToolUseCounts(sessionIds: ["s1", "s2"])
            .map { "\($0.sessionId)/\($0.toolName)=\($0.count)" }.sorted()
        XCTAssertEqual(uses, ["s1/Read=2", "s2/Edit=1"], "PreToolUse only")
    }

    // MARK: - Billing reads

    func testFirstEventTimeAndEventTimesAfterACursor() throws {
        try harness.ingest([
            hook("SessionStart", "s1", "2026-06-01T12:00:00Z"),
            hook("Stop", "s1", "2026-06-01T12:10:00Z")
        ])
        let start = try XCTUnwrap(TimestampParsing.parse("2026-06-01T12:00:00Z")).timeIntervalSince1970
        XCTAssertEqual(try database.claudeFirstEventTime(sessionId: "s1"), start)
        XCTAssertNil(try database.claudeFirstEventTime(sessionId: "none"))

        let all = try database.claudeEventTimes(sessionId: "s1", afterId: 0).sorted { $0.id < $1.id }
        XCTAssertEqual(all.map(\.providerType), ["SessionStart", "Stop"])
        XCTAssertEqual(all.map(\.time), [start, start + 600])
        let after = try database.claudeEventTimes(sessionId: "s1", afterId: all[0].id)
        XCTAssertEqual(after.map(\.providerType), ["Stop"])
    }

    // MARK: - No event store

    /// Without `attachEventReads` every reader answers empty — never throws, and
    /// never falls back to the legacy tables, even when they hold rows.
    func testEveryReaderIsEmptyWithoutAStore() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        defer { TestDaemonDatabase.remove(path: opened.path) }
        let bare = opened.db
        try bare.ingestEvent(eventType: "PreToolUse", timestamp: "2026-06-01T12:00:00Z",
                             hookData: ["session_id": "s1", "cwd": "/tmp", "tool_name": "Read",
                                        "tool_use_id": "tu-1"])
        try bare.ingestEvent(eventType: "Stop", timestamp: "2026-06-01T12:01:00Z",
                             hookData: ["session_id": "s1", "cwd": "/tmp"])

        XCTAssertNil(bare.eventReads)
        XCTAssertEqual(try bare.fetchEvents(sessionId: "s1").count, 0)
        XCTAssertEqual(try bare.fetchEvents().count, 0)
        XCTAssertEqual(try bare.fetchRecentEvents(sessionId: "s1", limit: 10).count, 0)
        XCTAssertNil(try bare.fetchEventDetail(eventLogId: 1))
        XCTAssertEqual(try bare.fetchSessions().map(\.eventCount), [0])
        XCTAssertEqual(try bare.fetchSession(sessionId: "s1")?.eventCount, 0)
        XCTAssertEqual(try bare.totalEventCount(), 0)
        XCTAssertEqual(try bare.lastEventType(sessionId: "s1"), "")
        XCTAssertEqual(try bare.claudeEventCounts(sessionIds: ["s1"]), [:])
        XCTAssertEqual(try bare.claudeEventTotal(), 0)
        XCTAssertTrue(try bare.claudeEvents(sessionId: "s1", limit: 10).isEmpty)
        XCTAssertNil(try bare.claudeEvent(id: 1))
        XCTAssertTrue(try bare.claudeToolUseCounts(sessionIds: ["s1"]).isEmpty)
        XCTAssertNil(try bare.claudeToolDurationMs(sessionId: "s1", toolUseId: "tu-1", postTime: 2e9))
        XCTAssertNil(try bare.claudeFirstEventTime(sessionId: "s1"))
        XCTAssertTrue(try bare.claudeEventTimes(sessionId: "s1", afterId: 0).isEmpty)
        let archived = bare.claudeArchivedPayload(rawRef: 1)
        XCTAssertNil(archived.hookData)
        XCTAssertNil(archived.line)
    }
}
