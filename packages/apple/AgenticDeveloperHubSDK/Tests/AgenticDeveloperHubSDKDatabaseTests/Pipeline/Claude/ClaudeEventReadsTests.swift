import AgenticToolkitCore
import CryptoKit
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

    // MARK: - File fingerprints (stamped at capture)

    /// A file under `root` holding `text`, and the fingerprint capture should stamp for it.
    private func fingerprintedFile(_ text: String) throws -> (path: String, size: Int, sha: String) {
        let url = root.appendingPathComponent("CLAUDE-\(UUID().uuidString).md")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let data = Data(text.utf8)
        try data.write(to: url)
        let sha = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return (url.path, data.count, sha)
    }

    private func assertFingerprint(
        sessionId: String, eventType: String, size: Int, sha: String,
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        let event = try XCTUnwrap(try database.fetchEvents(sessionId: sessionId, eventType: eventType).first,
                                  file: file, line: line)
        let row = try XCTUnwrap(try database.claudeEvent(id: Int64(event.id)), file: file, line: line)
        let attrs = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: Data(row.attrs.utf8)) as? [String: Any], file: file, line: line)
        XCTAssertEqual(attrs["file_size_bytes"] as? Int, size, "attrs", file: file, line: line)
        XCTAssertEqual(attrs["file_sha256"] as? String, sha, "attrs", file: file, line: line)

        let detail = try XCTUnwrap(try database.fetchEventDetail(eventLogId: Int64(event.id)), file: file, line: line)
        let typeFields = try XCTUnwrap(detail["type_fields"] as? [String: Any], file: file, line: line)
        XCTAssertEqual(typeFields["file_size_bytes"] as? Int, size, "type_fields", file: file, line: line)
        XCTAssertEqual(typeFields["file_sha256"] as? String, sha, "type_fields", file: file, line: line)
    }

    func testCaptureStampsTheFingerprintOfAnInstructionsLoadedFile() throws {
        let target = try fingerprintedFile("# Project rules\n")
        try harness.ingest(hook("InstructionsLoaded", "s1", "2026-06-01T12:00:00Z", ["file_path": target.path]))
        // The file changing later does not change what was captured.
        try Data("rewritten after capture".utf8).write(to: URL(fileURLWithPath: target.path))

        try assertFingerprint(sessionId: "s1", eventType: "InstructionsLoaded", size: target.size, sha: target.sha)
    }

    func testDropFileOfAConfigChangeIsStampedBeforeTheSpool() throws {
        let target = try fingerprintedFile(#"{"theme":"dark"}"#)
        let envelope = try hook("ConfigChange", "s2", "2026-06-01T12:00:00Z", ["file_path": target.path])
            .envelopeJSON()
        let drop = harness.dropDirectory.appendingPathComponent("1780000000000-0000abcd.json")
        try FileManager.default.createDirectory(at: harness.dropDirectory, withIntermediateDirectories: true)
        try envelope.write(to: drop)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -60)],
                                              ofItemAtPath: drop.path)

        XCTAssertEqual(try harness.handles.pollHookDrops(), 1)
        try harness.drain()

        try assertFingerprint(sessionId: "s2", eventType: "ConfigChange", size: target.size, sha: target.sha)
    }

    func testOnlyFingerprintedHooksChangeTheirEnvelopeBytes() throws {
        let target = try fingerprintedFile("contents")
        let other = try hook("PreToolUse", "s1", "2026-06-01T12:00:00Z",
                             ["tool_name": "Read", "file_path": target.path]).envelopeJSON()
        XCTAssertEqual(ClaudeFileFingerprint.stamped(envelope: other), other, "any other hook stays verbatim")

        let missing = try hook("ConfigChange", "s1", "2026-06-01T12:00:00Z",
                               ["file_path": root.appendingPathComponent("gone.json").path]).envelopeJSON()
        XCTAssertEqual(ClaudeFileFingerprint.stamped(envelope: missing), missing, "nothing to measure")

        let stamped = ClaudeFileFingerprint.stamped(["file_path": target.path, "file_sha256": "first"],
                                                    eventType: "ConfigChange")
        XCTAssertEqual(stamped["file_sha256"] as? String, "first", "an existing fingerprint is kept")
        XCTAssertEqual(stamped["file_size_bytes"] as? Int, target.size)
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

    // MARK: - Turns

    private var turnSeq: Int64 = 0

    /// Writes one Claude turn straight into the store, as the normalizer would.
    private func turn(
        _ key: String, _ session: String, _ stamp: String?, model: String? = "claude-sonnet-4-6",
        tool: String? = nil, agent: String? = nil, input: Int = 0, output: Int = 0, cacheRead: Int = 0,
        cacheWrite: Int = 0, cache1h: Int = 0, kind: String = "assistant", subagent: Bool = false
    ) throws {
        turnSeq += 1
        let time = try stamp.map { try XCTUnwrap(TimestampParsing.parse($0)) } ?? Date(timeIntervalSince1970: 0)
        var batch = NormalizedBatch()
        batch.turns = [TurnRow(
            dedupKey: key, sessionID: session, time: time, model: model, agent: agent, toolName: tool,
            inputTokens: input, outputTokens: output, cacheReadTokens: cacheRead, cacheWriteTokens: cacheWrite,
            attrs: ["kind": .string(kind), "cache_creation_1h_tokens": .number(Double(cache1h)),
                    "is_subagent": .bool(subagent)],
            rawRef: turnSeq)]
        try harness.store.write(batch, provider: ClaudeProvider.name)
    }

    private func epoch(_ stamp: String) throws -> Double {
        try XCTUnwrap(TimestampParsing.parse(stamp)).timeIntervalSince1970
    }

    private func describe(_ rows: [ClaudeTurnTotals]) -> [String] {
        rows.map {
            "\($0.key)|\($0.model)|n\($0.turnCount)|i\($0.inputTokens)|o\($0.outputTokens)"
                + "|r\($0.cacheReadTokens)|w\($0.cacheCreationTokens)|h\($0.cacheCreation1hTokens)"
        }.sorted()
    }

    func testTurnTotalsGroupByModelSessionAndAll() throws {
        try turn("a", "s1", "2026-06-01T12:00:00Z", tool: "Edit", input: 10, output: 1, cacheRead: 100)
        try turn("b", "s1", "2026-06-01T12:01:00Z", input: 20, output: 2, cacheWrite: 50, cache1h: 30)
        try turn("c", "s1", "2026-06-01T12:02:00Z", model: "claude-opus-4-1", input: 5, output: 5)
        try turn("d", "s2", "2026-06-01T13:00:00Z", input: 1, output: 1)

        XCTAssertEqual(describe(try database.claudeTurnTotals()), [
            "all|claude-opus-4-1|n1|i5|o5|r0|w0|h0",
            "all|claude-sonnet-4-6|n3|i31|o4|r100|w50|h30"
        ], "the 1h cache tokens come from attrs")
        XCTAssertEqual(describe(try database.claudeTurnTotals(groupBy: .model)).count, 2)
        XCTAssertEqual(describe(try database.claudeTurnTotals(groupBy: .session)), [
            "s1|claude-opus-4-1|n1|i5|o5|r0|w0|h0",
            "s1|claude-sonnet-4-6|n2|i30|o3|r100|w50|h30",
            "s2|claude-sonnet-4-6|n1|i1|o1|r0|w0|h0"
        ])
        XCTAssertEqual(Set(try database.claudeTurnTotals(groupBy: .session, topKeys: 1).map(\.key)), ["s1"],
                       "the top key by turn count keeps every model row")
        XCTAssertEqual(describe(try database.claudeTurnTotals(toolName: "Edit")),
                       ["all|claude-sonnet-4-6|n1|i10|o1|r100|w0|h0"])
        XCTAssertEqual(describe(try database.claudeTurnTotals(
            since: try epoch("2026-06-01T12:01:00Z"), until: try epoch("2026-06-01T13:00:00Z"))), [
            "all|claude-opus-4-1|n1|i5|o5|r0|w0|h0",
            "all|claude-sonnet-4-6|n1|i20|o2|r0|w50|h30"
        ], "since is inclusive, until exclusive")
        XCTAssertEqual(describe(try database.claudeTurnTotals(sessionIds: ["s2", "none"])),
                       ["all|claude-sonnet-4-6|n1|i1|o1|r0|w0|h0"])
        XCTAssertTrue(try database.claudeTurnTotals(sessionIds: []).isEmpty, "no sessions, no turns")
    }

    func testTurnTotalsLeaveUntimedTurnsOutOfARange() throws {
        try turn("timed", "s1", "2026-06-01T12:00:00Z", input: 7)
        try turn("untimed", "s1", nil, input: 3)

        XCTAssertEqual(try database.claudeTurnTotals(since: 0).map(\.inputTokens), [7])
        XCTAssertEqual(try database.claudeTurnTotals(until: 2e9).map(\.inputTokens), [7])
        XCTAssertEqual(try database.claudeTurnTotals().map(\.inputTokens), [10], "an unranged read counts both")
        XCTAssertEqual(try database.claudeTurnTimes(since: 0, until: 2e9, sessionIds: nil).count, 1)
    }

    func testTurnTotalsAndTimesCoverMoreSessionsThanOneChunk() throws {
        var batch = NormalizedBatch()
        let base = try epoch("2026-06-01T12:00:00Z")
        let ids = (0..<520).map { "chunk-\($0)" }
        batch.turns = ids.enumerated().map { index, id in
            TurnRow(dedupKey: "k-\(id)", sessionID: id, time: Date(timeIntervalSince1970: base + Double(index)),
                    model: "claude-sonnet-4-6", inputTokens: 1, rawRef: Int64(index + 1))
        }
        try harness.store.write(batch, provider: ClaudeProvider.name)
        try turn("outside", "other", "2026-06-01T12:00:00Z", input: 1000)

        let all = try database.claudeTurnTotals(sessionIds: ids)
        XCTAssertEqual(all.map(\.turnCount), [520])
        XCTAssertEqual(all.map(\.inputTokens), [520])
        XCTAssertEqual(try database.claudeTurnTotals(sessionIds: ids, groupBy: .session).count, 520)
        XCTAssertEqual(try database.claudeTurnTotals(sessionIds: ids, groupBy: .session, topKeys: 500).count, 500)
        XCTAssertEqual(try database.claudeTurnTimes(since: base, until: base + 1e6, sessionIds: ids).count, 520)
    }

    func testTurnTimesAreOrderedBySessionThenTime() throws {
        try turn("b2", "b", "2026-06-01T12:05:00.500Z")
        try turn("a1", "a", "2026-06-01T12:03:00Z")
        try turn("b1", "b", "2026-06-01T12:01:00Z")
        try turn("late", "a", "2026-06-02T00:00:00Z")

        let times = try database.claudeTurnTimes(
            since: try epoch("2026-06-01T00:00:00Z"), until: try epoch("2026-06-02T00:00:00Z"), sessionIds: nil)
        XCTAssertEqual(times.map(\.sessionId), ["a", "b", "b"])
        XCTAssertEqual(times.map(\.time), [try epoch("2026-06-01T12:03:00Z"), try epoch("2026-06-01T12:01:00Z"),
                                           try epoch("2026-06-01T12:05:00.500Z")], "fractional seconds kept")
        XCTAssertEqual(try database.claudeTurnTimes(since: 0, until: 2e9, sessionIds: ["a"]).count, 2)
        XCTAssertTrue(try database.claudeTurnTimes(since: 0, until: 2e9, sessionIds: []).isEmpty)
    }

    func testTranscriptTurnIsLookedUpByItsMessageId() throws {
        let file = harness.transcriptFile(sessionId: "t1")
        try harness.ingestTranscript(lines: [
            #"{"type":"assistant","sessionId":"t1","timestamp":"2026-06-01T12:00:00.250Z","cwd":"/w","#
                + #""message":{"id":"msg-1","model":"claude-sonnet-4-6","#
                + #""usage":{"input_tokens":10,"output_tokens":5,"cache_read_input_tokens":7,"#
                + #""cache_creation_input_tokens":3},"content":[{"type":"tool_use","name":"Edit","input":{}}]}}"#
        ], file: file)

        let row = try XCTUnwrap(try database.transcriptTurn(messageId: "msg-1"))
        XCTAssertEqual(row.sessionId, "t1")
        XCTAssertEqual(row.timestamp, "2026-06-01T12:00:00.250Z")
        XCTAssertEqual(row.kind, "assistant")
        XCTAssertEqual(row.model, "claude-sonnet-4-6")
        XCTAssertEqual([row.inputTokens, row.outputTokens, row.cacheReadTokens, row.cacheCreationTokens],
                       [10, 5, 7, 3])
        XCTAssertEqual(row.toolName, "Edit")
        XCTAssertFalse(row.isSubagent)
        XCTAssertEqual(row.agentId, "")
        XCTAssertNil(try database.transcriptTurn(messageId: "msg-unknown"))
        XCTAssertEqual(try database.transcriptTurnCount(sessionId: "t1"), 1)
    }

    func testTranscriptTurnCarriesSubagentAgentAndUntimedStamp() throws {
        try turn("sub", "s1", nil, model: nil, agent: "agent-7", kind: "assistant", subagent: true)
        try turn("other", "s2", "2026-06-01T12:00:00Z")

        let row = try XCTUnwrap(try database.transcriptTurn(messageId: "sub"))
        XCTAssertTrue(row.isSubagent)
        XCTAssertEqual(row.agentId, "agent-7")
        XCTAssertEqual(row.model, "")
        XCTAssertEqual(row.timestamp, "", "a line with no timestamp reads back empty, as the legacy row stored it")
        XCTAssertEqual(try database.transcriptTurnCount(), 2)
        XCTAssertEqual(try database.transcriptTurnCount(sessionId: "s1"), 1)
        XCTAssertEqual(try database.transcriptTurnCount(sessionId: "none"), 0)
    }

    // MARK: - Repricing

    private static let pricingRevisionKey = "transcript_pricing_revision"

    /// Stores `cost` as the session's `session_metrics` cost, stubbing its session row first.
    private func storeCost(_ cost: Double, session: String, in target: DaemonDatabase) throws {
        _ = try target.createSessionStubIfMissing(
            sessionId: session, cwd: "/tmp", model: "", startedAt: "2026-06-01T12:00:00Z",
            lastActivityAt: "2026-06-01T12:00:00Z", accountEmail: "")
        try target.upsertSessionMetrics(SessionMetricsDTO(
            sessionId: session, totalInputTokens: 0, totalOutputTokens: 0, cacheReadTokens: 0,
            cacheCreationTokens: 0, totalCostUsd: cost, turnCount: 0, model: "", firstTurnAt: "",
            lastTurnAt: "", updatedAt: ""), accountEmail: "")
    }

    func testRepricingRecomputesSessionCostsFromTheStore() throws {
        try turn("a", "s1", "2026-06-01T12:00:00Z", input: 1000, output: 2000, cacheRead: 300, cacheWrite: 40,
                 cache1h: 10)
        try turn("b", "s1", "2026-06-01T12:01:00Z", model: "claude-opus-4-1", output: 500)
        try turn("c", "untracked", nil, output: 9)
        try storeCost(999, session: "s1", in: database)
        try storeCost(4.5, session: "legacy-only", in: database)

        database.repriceSessionMetricsIfNeeded()

        let expected = TranscriptPricing.cost(
            model: "claude-sonnet-4-6", inputTokens: 1000, outputTokens: 2000, cacheReadTokens: 300,
            cacheCreationTokens: 40, cacheCreation1hTokens: 10)
            + TranscriptPricing.cost(
                model: "claude-opus-4-1", inputTokens: 0, outputTokens: 500, cacheReadTokens: 0,
                cacheCreationTokens: 0, cacheCreation1hTokens: 0)
        XCTAssertEqual(try XCTUnwrap(try database.metricsForSession(sessionId: "s1")).totalCostUsd,
                       expected, accuracy: 1e-9)
        XCTAssertEqual(try database.metricsForSession(sessionId: "legacy-only")?.totalCostUsd, 4.5,
                       "a session with no store turns keeps its cost")
        XCTAssertEqual(try database.setting(for: Self.pricingRevisionKey), String(TranscriptPricing.revision))

        // Recorded: a second pass at the same revision changes nothing.
        try storeCost(1, session: "s1", in: database)
        database.repriceSessionMetricsIfNeeded()
        XCTAssertEqual(try database.metricsForSession(sessionId: "s1")?.totalCostUsd, 1)
    }

    func testRepricingWithoutAStoreDoesNothingAndRecordsNothing() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        defer { TestDaemonDatabase.remove(path: opened.path) }
        let bare = opened.db
        try storeCost(999, session: "s1", in: bare)

        bare.repriceSessionMetricsIfNeeded()

        XCTAssertEqual(try bare.metricsForSession(sessionId: "s1")?.totalCostUsd, 999)
        XCTAssertNil(try bare.setting(for: Self.pricingRevisionKey), "a later pass with a store must still run")
    }

    // MARK: - An empty store

    /// A store that is attached but holds no events answers empty, not with the
    /// legacy rows and not with an error: events, session counts and last type.
    func testAnAttachedButEmptyStoreAnswersEmpty() throws {
        try database.ingestEvent(eventType: "SessionStart", timestamp: "2026-06-01T12:00:00Z",
                                 hookData: ["session_id": "s1", "cwd": "/tmp"])
        XCTAssertNotNil(database.eventReads)
        XCTAssertEqual(try database.claudeEventTotal(), 0, "the legacy write left the store empty")

        XCTAssertEqual(try database.fetchEvents().count, 0)
        XCTAssertEqual(try database.fetchEvents(sessionId: "s1").count, 0)
        XCTAssertEqual(try database.fetchRecentEvents(sessionId: "s1", limit: 10).count, 0)
        XCTAssertNil(try database.fetchEventDetail(eventLogId: 1))
        XCTAssertEqual(try database.fetchSessions().map(\.eventCount), [0])
        XCTAssertEqual(try database.fetchSession(sessionId: "s1")?.eventCount, 0)
        XCTAssertEqual(try database.totalEventCount(), 0)
        XCTAssertEqual(try database.claudeEventCounts(sessionIds: ["s1"]), [:])
        XCTAssertEqual(try database.lastEventType(sessionId: "s1"), "")
        XCTAssertNil(try database.claudeFirstEventTime(sessionId: "s1"))
        XCTAssertTrue(try database.claudeEventTimes(sessionId: "s1", afterId: 0).isEmpty)
        XCTAssertEqual(try database.eventIdHighWater(), 0)
        XCTAssertTrue(try database.claudeTurnTotals().isEmpty)
        XCTAssertTrue(try database.claudeTurnTimes(since: 0, until: 2e9, sessionIds: nil).isEmpty)
        XCTAssertNil(try database.transcriptTurn(messageId: "m1"))
        XCTAssertEqual(try database.transcriptTurnCount(), 0)
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
        XCTAssertNil(try bare.eventIdHighWater())
        try bare.insertTranscriptTurn(
            sessionId: "s1", timestamp: "2026-06-01T12:00:00Z", kind: "assistant", model: "claude-sonnet-4-6",
            messageId: "m1", inputTokens: 10, outputTokens: 1, cacheReadTokens: 0, cacheCreationTokens: 0,
            toolName: "", cwd: "/tmp", accountEmail: "")
        XCTAssertEqual(try bare.legacyTranscriptTurnCount(sessionId: "s1"), 1, "the legacy row is there")
        XCTAssertTrue(try bare.claudeTurnTotals().isEmpty)
        XCTAssertTrue(try bare.claudeTurnTotals(sessionIds: ["s1"], groupBy: .session).isEmpty)
        XCTAssertTrue(try bare.claudeTurnTimes(since: 0, until: 2e9, sessionIds: nil).isEmpty)
        XCTAssertNil(try bare.transcriptTurn(messageId: "m1"))
        XCTAssertEqual(try bare.transcriptTurnCount(sessionId: "s1"), 0)
        let archived = bare.claudeArchivedPayload(rawRef: 1)
        XCTAssertNil(archived.hookData)
        XCTAssertNil(archived.line)
    }
}
