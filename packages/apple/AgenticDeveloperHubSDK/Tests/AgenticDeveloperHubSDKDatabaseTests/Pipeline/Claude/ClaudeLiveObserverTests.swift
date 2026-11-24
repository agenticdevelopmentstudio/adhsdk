import AgenticDeveloperHubSDKCore
import Foundation
import GRDB
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// `ClaudeLiveObserver` publishes each stored hook event once, as `EventIngestor`
/// does, with the event store's row id, and runs the shared enrichment for it.
final class ClaudeLiveObserverTests: XCTestCase {

    private var tmpDir: URL!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-claude-obs-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private static let fixtures = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().appendingPathComponent("Fixtures")
    private static let sessionID = "6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10"
    private static let transcriptPath =
        "/Users/dev/.claude/projects/-Users-dev-work-myapp/6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10.jsonl"

    private static func hookRecord(_ stem: String, id: Int64) throws -> ArchivedRecord {
        ArchivedRecord(id: id, record: RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.hookKind, dedupKey: stem,
            receivedAt: Date(timeIntervalSince1970: 1_793_400_000),
            payload: try Data(contentsOf: fixtures.appendingPathComponent("hooks/\(stem).json"))))
    }

    private static func transcriptRecord(_ stem: String, lineNo: Int, id: Int64) throws -> ArchivedRecord {
        let line = try String(
            contentsOf: fixtures.appendingPathComponent("transcripts/\(stem).jsonl"), encoding: .utf8
        ).trimmingCharacters(in: .newlines)
        let payload = ClaudeTranscriptPayload(file: transcriptPath, lineNo: lineNo, subagentFile: false, line: line)
        return ArchivedRecord(id: id, record: RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.transcriptKind,
            dedupKey: ClaudeTranscriptPayload.dedupKey(line: line, file: transcriptPath, byteOffset: Int64(lineNo)),
            receivedAt: Date(timeIntervalSince1970: 1_793_400_000),
            payload: try ClaudeTranscriptPayload.encode(payload)))
    }

    /// Normalizes and stores `records`, returning the batch as the drainer hands
    /// it to observers.
    private func store(_ records: [ArchivedRecord], in store: EventStore) throws -> NormalizedBatch {
        var batch = NormalizedBatch()
        for record in records {
            let part = try ClaudeNormalizer().normalize(record)
            batch.events += part.events
            batch.sessions += part.sessions
            batch.turns += part.turns
            batch.messages += part.messages
        }
        return try store.write(batch, provider: ClaudeProvider.name)
    }

    /// Records every enrichment call, in order.
    private final class EnrichmentLog: @unchecked Sendable {
        private let lock = NSLock()
        private var entries: [String] = []
        var calls: [String] { lock.withLock { entries } }
        func add(_ entry: String) { lock.withLock { entries.append(entry) } }

        var hooks: ClaudeEnrichmentHooks {
            ClaudeEnrichmentHooks(
                noteTranscriptActivity: { path, sessionId in self.add("tail \(sessionId) \(path)") },
                enrichOnStart: { sessionId, cwd, path in self.add("start \(sessionId) \(cwd) \(path ?? "-")") },
                onStopOrEnd: { sessionId, path in self.add("stop \(sessionId) \(path ?? "-")") },
                healProjectRoot: { sessionId in self.add("heal \(sessionId)") })
        }
    }

    private struct Harness {
        let events: EventStore
        let sink: RecordingSink
        let log: EnrichmentLog
        let observer: ClaudeLiveObserver
    }

    private func makeHarness() throws -> Harness {
        let events = try EventStore(path: tmpDir.appendingPathComponent("events.db").path)
        let sink = RecordingSink()
        let log = EnrichmentLog()
        let observer = ClaudeLiveObserver(eventReads: events, sink: sink, enrichment: log.hooks)
        return Harness(events: events, sink: sink, log: log, observer: observer)
    }

    private func storedID(_ key: String, in events: EventStore) throws -> Int64? {
        try events.read { conn in
            try Int64.fetchOne(
                conn, sql: "SELECT id FROM events WHERE provider = 'claude' AND dedup_key = ?", arguments: [key])
        }
    }

    private func decode(_ payload: Data) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: payload) as? [String: Any])
    }

    /// The payload `EventIngestor` broadcasts for `stem`: legacy `ingestEvent` on a
    /// temp session db, with the event store's row id in place of event_log's.
    private func legacyPayload(_ stem: String, id: Int64) throws -> [String: Any] {
        let made = try TestDaemonDatabase.makeSessionDatabase(
            accountResolver: AccountResolver(claudeJSONPath: tmpDir.appendingPathComponent("no-claude.json").path))
        defer { TestDaemonDatabase.remove(path: made.path) }
        let fixture = try Data(contentsOf: Self.fixtures.appendingPathComponent("hooks/\(stem).json"))
        guard case .event(let parsed) = ParseResult.parse(envelopeJSON: String(bytes: fixture, encoding: .utf8) ?? "")
        else { throw XCTSkip("fixture \(stem) did not parse") }
        let legacy = try made.db.ingestEvent(
            eventType: parsed.eventType, timestamp: parsed.timestamp, hookData: parsed.hookData,
            context: parsed.context, accountEmail: parsed.accountEmail, oauthAccountEmail: parsed.oauthAccountEmail)
        let rebuilt = IngestedEvent(
            id: id, event: legacy.event, sessionId: legacy.sessionId, timestamp: legacy.timestamp,
            cwd: legacy.cwd, detail: legacy.detail, toolName: legacy.toolName, model: legacy.model,
            source: legacy.source)
        return try decode(try XCTUnwrap(SessionEventEncoding.encode(rebuilt)))
    }

    // MARK: - Tests

    func testBroadcastsEachHookEventOnceWithItsStoredID() throws {
        let harness = try makeHarness()
        let stems = ["SessionStart", "PreToolUse", "StatusLine", "Stop", "SessionEnd"]
        let batch = try store(stems.enumerated().map { try Self.hookRecord($1, id: Int64($0 + 1)) }, in: harness.events)

        harness.observer.pipelineDidStore(batch, provider: ClaudeProvider.name)

        XCTAssertEqual(harness.sink.eventTypes, stems)
        for (stem, event) in zip(stems, harness.sink.events) {
            let payload = try decode(event.payload)
            XCTAssertEqual(event.sessionId, Self.sessionID)
            XCTAssertEqual((payload["id"] as? NSNumber)?.int64Value, try storedID(stem, in: harness.events), stem)
            XCTAssertEqual(payload["event"] as? String, stem)
            XCTAssertEqual(payload["session_id"] as? String, Self.sessionID)
        }
    }

    func testPayloadMatchesWhatEventIngestorBroadcasts() throws {
        let harness = try makeHarness()
        let batch = try store([try Self.hookRecord("SessionStart", id: 1)], in: harness.events)
        harness.observer.pipelineDidStore(batch, provider: ClaudeProvider.name)
        let payload = try decode(try XCTUnwrap(harness.sink.events.first).payload)

        let fixture = try Data(contentsOf: Self.fixtures.appendingPathComponent("hooks/SessionStart.json"))
        guard case .event(let parsed) = ParseResult.parse(envelopeJSON: String(bytes: fixture, encoding: .utf8) ?? "")
        else { return XCTFail("fixture did not parse") }
        let expected = IngestedEvent(
            id: try XCTUnwrap(try storedID("SessionStart", in: harness.events)),
            event: "SessionStart", sessionId: Self.sessionID, timestamp: parsed.timestamp,
            cwd: "/Users/dev/work/myapp", detail: computeDetail(eventType: "SessionStart", hookData: parsed.hookData),
            toolName: "", model: "claude-opus-4-1", source: "startup")
        let expectedPayload = try decode(try XCTUnwrap(SessionEventEncoding.encode(expected)))
        XCTAssertEqual(NSDictionary(dictionary: payload), NSDictionary(dictionary: expectedPayload))
    }

    func testTimestampKeepsMillisecondsOnlyWhenPresent() throws {
        let harness = try makeHarness()
        // SessionStart is "…12:00:00Z"; StatusLine is "…12:20:00.750Z".
        let batch = try store(
            [try Self.hookRecord("SessionStart", id: 1), try Self.hookRecord("StatusLine", id: 2)], in: harness.events)
        harness.observer.pipelineDidStore(batch, provider: ClaudeProvider.name)
        let stamps = try harness.sink.events.map { try decode($0.payload)["timestamp"] as? String }
        XCTAssertEqual(stamps, ["2026-10-30T12:00:00Z", "2026-10-30T12:20:00.750Z"])
    }

    func testRunsEnrichmentForStartStopEndAndTranscriptPath() throws {
        let harness = try makeHarness()
        let stems = ["SessionStart", "PreToolUse", "Stop", "SessionEnd"]
        let batch = try store(stems.enumerated().map { try Self.hookRecord($1, id: Int64($0 + 1)) }, in: harness.events)
        harness.observer.pipelineDidStore(batch, provider: ClaudeProvider.name)

        let sid = Self.sessionID
        let path = Self.transcriptPath
        var expected = ["heal \(sid)", "tail \(sid) \(path)", "start \(sid) /Users/dev/work/myapp \(path)"]
        for stem in stems.dropFirst() {
            let hookData = try XCTUnwrap(try decode(
                try Data(contentsOf: Self.fixtures.appendingPathComponent("hooks/\(stem).json")))["hook_data"]
                as? [String: Any])
            let eventPath = hookData["transcript_path"] as? String
            expected.append("heal \(sid)")
            if let eventPath { expected.append("tail \(sid) \(eventPath)") }
            if stem != "PreToolUse" { expected.append("stop \(sid) \(eventPath ?? "-")") }
        }
        XCTAssertEqual(harness.log.calls, expected)
    }

    func testTranscriptEventsAreNotBroadcast() throws {
        let harness = try makeHarness()
        let batch = try store([
            try Self.transcriptRecord("agent-dispatch", lineNo: 6, id: 1),
            try Self.transcriptRecord("custom-title", lineNo: 7, id: 2),
            try Self.transcriptRecord("ai-title", lineNo: 8, id: 3)
        ], in: harness.events)
        XCTAssertFalse(batch.events.isEmpty)

        harness.observer.pipelineDidStore(batch, provider: ClaudeProvider.name)
        XCTAssertEqual(harness.sink.eventTypes, [])
        XCTAssertEqual(harness.log.calls, [])
    }

    func testOtherProvidersAreIgnored() throws {
        let harness = try makeHarness()
        let batch = try store([try Self.hookRecord("SessionStart", id: 1)], in: harness.events)
        harness.observer.pipelineDidStore(batch, provider: "other")
        XCTAssertEqual(harness.sink.eventTypes, [])
        XCTAssertEqual(harness.log.calls, [])
    }

    func testEventIngestorRunsTheSharedEnrichment() throws {
        // EventIngestor's enrichment is the same `ClaudeEnrichmentHooks` type the
        // observer runs; its `run` routes Start/Stop/End as the observer's does.
        let log = EnrichmentLog()
        log.hooks.run(eventType: "Stop", sessionId: "s1", cwd: "/x", transcriptPath: nil)
        log.hooks.run(eventType: "Notification", sessionId: "s1", cwd: "/x", transcriptPath: "/t.jsonl")
        XCTAssertEqual(log.calls, ["heal s1", "stop s1 -", "heal s1", "tail s1 /t.jsonl"])
    }

    /// StatusLine's `model` is an object, so legacy broadcasts `model: ""`, and the
    /// tool events carry `tool_name` and a computed detail — the payloads must match.
    func testStatusLineAndToolPayloadsMatchWhatIngestEventBroadcasts() throws {
        for stem in ["StatusLine", "PreToolUse", "PostToolUse"] {
            let harness = try makeHarness()
            let batch = try store([try Self.hookRecord(stem, id: 1)], in: harness.events)
            harness.observer.pipelineDidStore(batch, provider: ClaudeProvider.name)
            let payload = try decode(try XCTUnwrap(harness.sink.events.first, stem).payload)
            let expected = try legacyPayload(stem, id: try XCTUnwrap(try storedID(stem, in: harness.events)))
            XCTAssertEqual(NSDictionary(dictionary: payload), NSDictionary(dictionary: expected), stem)
        }
    }

    func testFailedIDReadSkipsTheBroadcastButStillEnriches() throws {
        let harness = try makeHarness()
        let batch = try store([try Self.hookRecord("SessionStart", id: 1)], in: harness.events)
        // A different, empty store: the id read finds no events table.
        let emptyPath = tmpDir.appendingPathComponent("empty.db").path
        let empty = try EventStore(path: emptyPath)
        try DatabaseQueue(path: emptyPath).write { conn in try conn.execute(sql: "DROP TABLE events") }
        let observer = ClaudeLiveObserver(eventReads: empty, sink: harness.sink, enrichment: harness.log.hooks)

        observer.pipelineDidStore(batch, provider: ClaudeProvider.name)

        XCTAssertTrue(harness.sink.events.isEmpty)
        XCTAssertFalse(harness.log.calls.isEmpty, "enrichment ran despite the failed read")
    }
}
