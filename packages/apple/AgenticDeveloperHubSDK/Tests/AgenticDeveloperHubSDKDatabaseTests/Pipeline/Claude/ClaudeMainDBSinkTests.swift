import AgenticToolkitCore
import Foundation
import GRDB
import XCTest
@testable import AgenticToolkitDatabase

/// `ClaudeMainDBSink` against the legacy writers it replaces: a hook batch must
/// leave the session database as `ingestEvent` does, a transcript batch as the
/// JSONL importer does, and a second delivery of any batch must change nothing.
final class ClaudeMainDBSinkTests: XCTestCase {

    private var tmpDir: URL!
    private var paths: [String] = []

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-claude-sink-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        paths.forEach { TestDaemonDatabase.remove(path: $0) }
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Fixtures

    private static let fixtures = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().appendingPathComponent("Fixtures")
    private static let sessionID = "6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10"
    private static let receivedAt = Date(timeIntervalSince1970: 1_793_400_000)

    /// A session's hooks in the order Claude Code fires them.
    private static let hookStems = [
        "SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse", "StatusLine",
        "SubagentStart", "SubagentStop", "Notification", "Stop", "SessionEnd"
    ]

    /// The transcript fixtures and their line numbers in one imagined file.
    private static let transcriptLines: [(stem: String, lineNo: Int)] = [
        ("user-string", 1), ("assistant", 2), ("assistant-repeat", 3), ("user-tool-result", 4),
        ("queued-prompt", 5), ("agent-dispatch", 6), ("custom-title", 7), ("ai-title", 8)
    ]

    private static func hookPayload(_ stem: String) throws -> Data {
        try Data(contentsOf: fixtures.appendingPathComponent("hooks/\(stem).json"))
    }

    private static func hookRecord(_ stem: String, id: Int64) throws -> ArchivedRecord {
        ArchivedRecord(id: id, record: RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.hookKind, dedupKey: stem,
            receivedAt: receivedAt, payload: try hookPayload(stem)))
    }

    /// A copy of a hook fixture under its own dedup key, restamped at `timestamp`
    /// and with `hookData` merged over its `hook_data`.
    private static func hookRecord(
        _ stem: String, id: Int64, key: String, timestamp: String, hookData: [String: Any] = [:]
    ) throws -> ArchivedRecord {
        var envelope = try XCTUnwrap(try JSONSerialization.jsonObject(with: try hookPayload(stem)) as? [String: Any])
        envelope["timestamp"] = timestamp
        var data = envelope["hook_data"] as? [String: Any] ?? [:]
        data.merge(hookData) { _, new in new }
        envelope["hook_data"] = data
        return ArchivedRecord(id: id, record: RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.hookKind, dedupKey: key,
            receivedAt: receivedAt, payload: try JSONSerialization.data(withJSONObject: envelope)))
    }

    /// Runs `records`' hook envelopes through `ingestEvent`, in order.
    private static func ingestLegacy(_ records: [ArchivedRecord], into database: DaemonDatabase) throws {
        for record in records {
            guard case .event(let parsed) = ParseResult.parse(
                envelopeJSON: String(bytes: record.record.payload, encoding: .utf8) ?? "") else {
                return XCTFail("record \(record.record.dedupKey) did not parse")
            }
            try database.ingestEvent(
                eventType: parsed.eventType, timestamp: parsed.timestamp, hookData: parsed.hookData,
                context: parsed.context, accountEmail: parsed.accountEmail,
                oauthAccountEmail: parsed.oauthAccountEmail)
        }
    }

    private static func transcriptLine(_ stem: String) throws -> String {
        try String(contentsOf: fixtures.appendingPathComponent("transcripts/\(stem).jsonl"), encoding: .utf8)
            .trimmingCharacters(in: .newlines)
    }

    /// The transcript file the lines are imagined in, under `<tmp>/projects`.
    private var transcriptFile: URL {
        tmpDir.appendingPathComponent("projects/-Users-dev-work-myapp/\(Self.sessionID).jsonl")
    }

    private func transcriptRecord(_ stem: String, lineNo: Int, id: Int64) throws -> ArchivedRecord {
        let payload = ClaudeTranscriptPayload(
            file: transcriptFile.path, lineNo: lineNo, subagentFile: false, line: try Self.transcriptLine(stem))
        return ArchivedRecord(id: id, record: RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.transcriptKind,
            dedupKey: ClaudeTranscriptPayload.dedupKey(
                line: payload.line, file: payload.file, byteOffset: Int64(payload.lineNo)),
            receivedAt: Self.receivedAt, payload: try ClaudeTranscriptPayload.encode(payload)))
    }

    private func transcriptRecords(_ stems: [String]? = nil, firstID: Int64 = 100) throws -> [ArchivedRecord] {
        var records: [ArchivedRecord] = []
        for (offset, entry) in Self.transcriptLines.enumerated() where stems?.contains(entry.stem) ?? true {
            records.append(try transcriptRecord(entry.stem, lineNo: entry.lineNo, id: firstID + Int64(offset)))
        }
        return records
    }

    // MARK: - Harness

    /// Counts StatusLines routed to the hook; inserts unconditionally, so only the
    /// sink's own guard keeps a redelivery from adding a row.
    private static let statusLineIngest: DaemonDatabase.StatusLineIngest = { database, sessionId, _, timestamp, _ in
        try database.execute(
            "INSERT INTO rate_limit_snapshots(timestamp, session_id) VALUES (?, ?)",
            params: [timestamp, sessionId])
    }

    /// - Parameter oauthEmail: the login a temp `.claude.json` reports; nil points
    ///   the resolver at a file that does not exist (no oauth fallback). Either
    ///   way the test never reads the real `~/.claude.json`.
    private func makeDatabase(oauthEmail: String? = nil) throws -> DaemonDatabase {
        let claudeJSON = tmpDir.appendingPathComponent(oauthEmail == nil ? "no-claude.json" : "claude.json")
        if let oauthEmail {
            let json = ["oauthAccount": ["emailAddress": oauthEmail]]
            try JSONSerialization.data(withJSONObject: json).write(to: claudeJSON)
        }
        let resolver = AccountResolver(claudeJSONPath: claudeJSON.path)
        let made = try TestDaemonDatabase.makeSessionDatabase(
            accountResolver: resolver, statusLineIngest: Self.statusLineIngest)
        paths.append(made.path)
        return made.db
    }

    private struct Pipeline {
        let database: DaemonDatabase
        let store: EventStore
        let sink: ClaudeMainDBSink

        /// What the drainer does with one pass: normalize, store, then the sink.
        func deliver(_ records: [ArchivedRecord]) throws {
            let normalizer = ClaudeNormalizer()
            var batch = NormalizedBatch()
            for record in records {
                let part = try normalizer.normalize(record)
                batch.events += part.events
                batch.sessions += part.sessions
                batch.turns += part.turns
                batch.messages += part.messages
            }
            _ = try store.write(batch, provider: ClaudeProvider.name)
            try sink.write(batch, records: records, provider: ClaudeProvider.name)
        }
    }

    private func makePipeline(oauthEmail: String? = nil) throws -> Pipeline {
        let database = try makeDatabase(oauthEmail: oauthEmail)
        let store = try EventStore(path: tmpDir.appendingPathComponent("events-\(UUID().uuidString).db").path)
        return Pipeline(database: database, store: store, sink: ClaudeMainDBSink(database: database, eventReads: store))
    }

    /// Every row of `table`, `updated_at` left out (it is the write's wall clock).
    private func dump(_ database: DaemonDatabase, table: String, excluding: Set<String> = []) throws -> [String] {
        try database.write { conn in
            let columns = try Row.fetchAll(conn, sql: "PRAGMA table_info(\(table))")
                .map { $0["name"] as String }
                .filter { $0 != "updated_at" && !excluding.contains($0) }
            let list = columns.map { "\"\($0)\"" }.joined(separator: ", ")
            return try Row.fetchAll(conn, sql: "SELECT \(list) FROM \(table) ORDER BY \(list)")
                .map { row in zip(columns, row.databaseValues).map { "\($0)=\($1)" }.joined(separator: " ") }
        }
    }

    /// Every user table of the session database.
    private func dumpAll(_ database: DaemonDatabase) throws -> [String: [String]] {
        let tables = try database.write { conn in
            try String.fetchAll(conn, sql: """
                SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name
                """)
        }
        var result: [String: [String]] = [:]
        for table in tables {
            result[table] = try dump(database, table: table)
        }
        return result
    }

    private func scalar(_ database: DaemonDatabase, _ sql: String) throws -> String? {
        try database.write { conn in try String.fetchOne(conn, sql: sql) }
    }

    // MARK: - Hooks

    func testHookBatchLeavesSessionStateAsIngestEventDoes() throws {
        let legacy = try makeDatabase()
        for stem in Self.hookStems {
            guard case .event(let parsed) = ParseResult.parse(
                envelopeJSON: String(bytes: try Self.hookPayload(stem), encoding: .utf8) ?? "") else {
                return XCTFail("fixture \(stem) did not parse")
            }
            try legacy.ingestEvent(
                eventType: parsed.eventType, timestamp: parsed.timestamp, hookData: parsed.hookData,
                context: parsed.context, accountEmail: parsed.accountEmail,
                oauthAccountEmail: parsed.oauthAccountEmail)
        }

        let pipeline = try makePipeline()
        let records = try Self.hookStems.enumerated().map { try Self.hookRecord($1, id: Int64($0 + 1)) }
        try pipeline.deliver(records)

        // `started_at` aside: the legacy path stamps it with the wall clock,
        // the sink with the session's earliest event time.
        for table in ["sessions", "session_branches", "rate_limit_snapshots"] {
            let excluding: Set<String> = table == "sessions" ? ["started_at"] : []
            XCTAssertEqual(
                try dump(pipeline.database, table: table, excluding: excluding),
                try dump(legacy, table: table, excluding: excluding), table)
        }
        XCTAssertEqual(
            try scalar(pipeline.database, "SELECT started_at FROM sessions WHERE session_id = '\(Self.sessionID)'"),
            "2026-10-30 12:00:00")
        // StatusLine's `model` is an object: neither path may overwrite the
        // SessionStart model with it.
        let model = "SELECT model FROM sessions WHERE session_id = '\(Self.sessionID)'"
        XCTAssertEqual(try scalar(pipeline.database, model), "claude-opus-4-1")
        XCTAssertEqual(try scalar(legacy, model), "claude-opus-4-1")
        // The events are in the event store, not the session database.
        XCTAssertEqual(try dump(pipeline.database, table: "event_log"), [])
    }

    func testStatusLineWritesOneSnapshotAndRedeliveryWritesNone() throws {
        let pipeline = try makePipeline()
        let statusLine = try Self.hookRecord("StatusLine", id: 1)
        let count = "SELECT COUNT(*) FROM rate_limit_snapshots"

        try pipeline.deliver([statusLine])
        XCTAssertEqual(try scalar(pipeline.database, count), "1")

        try pipeline.deliver([statusLine])
        XCTAssertEqual(try scalar(pipeline.database, count), "1")
    }

    func testStatusLineBranchComesFromStenographerGit() throws {
        // The StatusLine fixture has no `git_branch`, only `stenographer_git.branch`.
        let legacy = try makeDatabase()
        let pipeline = try makePipeline()
        for stem in ["SessionStart", "StatusLine"] {
            guard case .event(let parsed) = ParseResult.parse(
                envelopeJSON: String(bytes: try Self.hookPayload(stem), encoding: .utf8) ?? "") else {
                return XCTFail("fixture \(stem) did not parse")
            }
            try legacy.ingestEvent(
                eventType: parsed.eventType, timestamp: parsed.timestamp, hookData: parsed.hookData,
                accountEmail: parsed.accountEmail, oauthAccountEmail: parsed.oauthAccountEmail)
        }
        try pipeline.deliver([try Self.hookRecord("SessionStart", id: 1), try Self.hookRecord("StatusLine", id: 2)])
        for table in ["sessions", "session_branches"] {
            let excluding: Set<String> = table == "sessions" ? ["started_at"] : []
            XCTAssertEqual(
                try dump(pipeline.database, table: table, excluding: excluding),
                try dump(legacy, table: table, excluding: excluding), table)
        }
        // The legacy path stamps `started_at` with the wall clock; the sink
        // takes the SessionStart time.
        XCTAssertEqual(
            try scalar(pipeline.database, "SELECT started_at FROM sessions WHERE session_id = '\(Self.sessionID)'"),
            "2026-10-30 12:00:00")
    }

    // MARK: - Transcripts

    func testTranscriptBatchMatchesTheJSONLImporter() throws {
        let lines = try Self.transcriptLines.map { try Self.transcriptLine($0.stem) }
        try FileManager.default.createDirectory(
            at: transcriptFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try (lines.joined(separator: "\n") + "\n").write(to: transcriptFile, atomically: true, encoding: .utf8)
        let legacy = try makeDatabase()
        _ = try JSONLImporter(
            sourceDirectory: tmpDir.appendingPathComponent("projects"), database: legacy,
            options: .init(only: [transcriptFile])
        ).run()

        let pipeline = try makePipeline()
        try pipeline.deliver(try transcriptRecords())

        let sessionColumns = """
            SELECT session_id, cwd, model, started_at, last_activity_at, git_branch, account_email,
                   auth_method, status, transcript_title, title_source
            FROM sessions ORDER BY session_id
            """
        XCTAssertEqual(try rows(pipeline.database, sessionColumns), try rows(legacy, sessionColumns))
        XCTAssertEqual(try rows(pipeline.database, sessionColumns).count, 1)
        XCTAssertEqual(
            try dump(pipeline.database, table: "agent_dispatches"), try dump(legacy, table: "agent_dispatches"))
        XCTAssertEqual(try dump(pipeline.database, table: "agent_dispatches").count, 1)
        XCTAssertEqual(
            try dump(pipeline.database, table: "session_metrics"), try dump(legacy, table: "session_metrics"))
        XCTAssertEqual(try dump(pipeline.database, table: "session_metrics").count, 1)
    }

    private func rows(_ database: DaemonDatabase, _ sql: String) throws -> [String] {
        try database.write { conn in
            try Row.fetchAll(conn, sql: sql).map { $0.databaseValues.map(\.description).joined(separator: "|") }
        }
    }

    func testCustomTitleBeatsAITitleInEitherArrivalOrder() throws {
        let title = """
            SELECT transcript_title || '|' || title_source FROM sessions WHERE session_id = '\(Self.sessionID)'
            """
        for order in [["custom-title", "ai-title"], ["ai-title", "custom-title"]] {
            let pipeline = try makePipeline()
            try pipeline.deliver(try transcriptRecords(["user-string", "assistant"]))
            for stem in order {
                try pipeline.deliver(try transcriptRecords([stem]))
            }
            XCTAssertEqual(try scalar(pipeline.database, title), "Upload retry|custom", "\(order)")
        }
    }

    func testTitleArrivingBeforeTheSessionLandsOnceItExists() throws {
        let pipeline = try makePipeline()
        try pipeline.deliver(try transcriptRecords(["ai-title"]))
        XCTAssertEqual(try scalar(pipeline.database, "SELECT COUNT(*) FROM sessions"), "0")

        try pipeline.deliver(try transcriptRecords(["user-string"]))
        XCTAssertEqual(
            try scalar(pipeline.database, "SELECT transcript_title FROM sessions"), "Add retries to the upload client")
    }

    func testMetricsSumEveryBatchOfASession() throws {
        let whole = try makePipeline()
        try whole.deliver(try transcriptRecords())

        let split = try makePipeline()
        for record in try transcriptRecords() {
            try split.deliver([record])
        }
        XCTAssertEqual(
            try dump(split.database, table: "session_metrics"), try dump(whole.database, table: "session_metrics"))
    }

    // MARK: - Redelivery

    func testSecondDeliveryOfEveryBatchChangesNothing() throws {
        let pipeline = try makePipeline()
        let hooks = try Self.hookStems.enumerated().map { try Self.hookRecord($1, id: Int64($0 + 1)) }
        let batches = [hooks, try transcriptRecords()]
        for batch in batches {
            try pipeline.deliver(batch)
        }
        let before = try dumpAll(pipeline.database)
        for batch in batches {
            try pipeline.deliver(batch)
            XCTAssertEqual(try dumpAll(pipeline.database), before)
        }
    }

    func testOtherProvidersBatchesAreIgnored() throws {
        let pipeline = try makePipeline()
        let before = try dumpAll(pipeline.database)
        try pipeline.sink.write(
            NormalizedBatch(), records: [try Self.hookRecord("SessionStart", id: 1)], provider: "other")
        XCTAssertEqual(try dumpAll(pipeline.database), before)
    }

    // MARK: - Out-of-order and partial redelivery

    private static let snapshots = "SELECT timestamp FROM rate_limit_snapshots ORDER BY id"

    func testOlderStatusLineAfterANewerOneIsRecordedAsIngestEventRecordsIt() throws {
        let newer = try Self.hookRecord("StatusLine", id: 1)
        let older = try Self.hookRecord("StatusLine", id: 2, key: "StatusLine-older", timestamp: "2026-10-30T12:10:00Z")
        let legacy = try makeDatabase()
        try Self.ingestLegacy([newer, older], into: legacy)

        let pipeline = try makePipeline()
        try pipeline.deliver([newer])
        try pipeline.deliver([older])
        XCTAssertEqual(
            try rows(pipeline.database, Self.snapshots), [#""2026-10-30T12:20:00.750Z""#, #""2026-10-30T12:10:00Z""#])
        XCTAssertEqual(
            try dump(pipeline.database, table: "rate_limit_snapshots"), try dump(legacy, table: "rate_limit_snapshots"))

        // Redelivering either one, in any order, adds nothing.
        let before = try dumpAll(pipeline.database)
        try pipeline.deliver([older, newer])
        XCTAssertEqual(try dumpAll(pipeline.database), before)
    }

    func testTwoStatusLinesInOneBatchAreBothRecorded() throws {
        let first = try Self.hookRecord("StatusLine", id: 1, key: "StatusLine-1", timestamp: "2026-10-30T12:20:00Z")
        let second = try Self.hookRecord(
            "StatusLine", id: 2, key: "StatusLine-2", timestamp: "2026-10-30T12:20:00.500Z")
        let legacy = try makeDatabase()
        try Self.ingestLegacy([first, second], into: legacy)

        let pipeline = try makePipeline()
        try pipeline.deliver([first, second])
        XCTAssertEqual(
            try rows(pipeline.database, Self.snapshots), [#""2026-10-30T12:20:00Z""#, #""2026-10-30T12:20:00.500Z""#])
        XCTAssertEqual(
            try dump(pipeline.database, table: "rate_limit_snapshots"), try dump(legacy, table: "rate_limit_snapshots"))

        try pipeline.deliver([first, second])
        XCTAssertEqual(try rows(pipeline.database, "SELECT COUNT(*) FROM rate_limit_snapshots"), ["2"])
    }

    func testRedeliveredOlderHooksDoNotReEndTheSessionOrRegressLastTool() throws {
        let pipeline = try makePipeline()
        let hooks = try Self.hookStems.enumerated().map { try Self.hookRecord($1, id: Int64($0 + 1)) }
        try pipeline.deliver(hooks)
        let state = "SELECT status || '|' || last_tool FROM sessions WHERE session_id = '\(Self.sessionID)'"
        XCTAssertEqual(try scalar(pipeline.database, state), "ended|Read")

        // The session is resumed after it ended and runs another tool.
        try pipeline.deliver([
            try Self.hookRecord("UserPromptSubmit", id: 20, key: "resume-prompt", timestamp: "2026-10-30T14:00:00Z"),
            try Self.hookRecord(
                "PreToolUse", id: 21, key: "resume-tool", timestamp: "2026-10-30T14:00:05Z",
                hookData: ["tool_name": "Edit"])
        ])
        XCTAssertEqual(try scalar(pipeline.database, state), "active|Edit")
        let before = try dumpAll(pipeline.database)

        // A partial redelivery of the first batch, out of order: the old SessionEnd
        // and the old tool hooks must not end the session or bring back Read.
        let byStem = Dictionary(uniqueKeysWithValues: zip(Self.hookStems, hooks))
        for stem in ["SessionEnd", "PreToolUse", "PostToolUse"] {
            try pipeline.deliver([try XCTUnwrap(byStem[stem])])
            XCTAssertEqual(try scalar(pipeline.database, state), "active|Edit", stem)
        }
        try pipeline.deliver([try XCTUnwrap(byStem["SessionEnd"]), try XCTUnwrap(byStem["PreToolUse"])])
        XCTAssertEqual(try dumpAll(pipeline.database), before)
    }

    // MARK: - Accounts

    func testAccountIsFirstWinsAsTheLegacyWritersLeaveIt() throws {
        // The hooks carry a token login; the machine's current login differs.
        let hooks = try ["SessionStart", "PreToolUse"].enumerated().map { try Self.hookRecord($1, id: Int64($0 + 1)) }
        let lines = try Self.transcriptLines.map { try Self.transcriptLine($0.stem) }
        try FileManager.default.createDirectory(
            at: transcriptFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try (lines.joined(separator: "\n") + "\n").write(to: transcriptFile, atomically: true, encoding: .utf8)

        let legacy = try makeDatabase(oauthEmail: "current@example.com")
        try Self.ingestLegacy(hooks, into: legacy)
        _ = try JSONLImporter(
            sourceDirectory: tmpDir.appendingPathComponent("projects"), database: legacy,
            options: .init(only: [transcriptFile])
        ).run()

        let pipeline = try makePipeline(oauthEmail: "current@example.com")
        try pipeline.deliver(hooks)
        try pipeline.deliver(try transcriptRecords())

        let accounts = """
            SELECT s.account_email, s.auth_method, m.account_email
            FROM sessions s JOIN session_metrics m USING (session_id)
            """
        XCTAssertEqual(try rows(pipeline.database, accounts), [#""dev@example.com"|"token"|"dev@example.com""#])
        XCTAssertEqual(try rows(pipeline.database, accounts), try rows(legacy, accounts))
    }

    func testTranscriptOnlySessionTakesTheCurrentLoginAsTheImporterDoes() throws {
        let lines = try Self.transcriptLines.map { try Self.transcriptLine($0.stem) }
        try FileManager.default.createDirectory(
            at: transcriptFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try (lines.joined(separator: "\n") + "\n").write(to: transcriptFile, atomically: true, encoding: .utf8)
        let legacy = try makeDatabase(oauthEmail: "current@example.com")
        _ = try JSONLImporter(
            sourceDirectory: tmpDir.appendingPathComponent("projects"), database: legacy,
            options: .init(only: [transcriptFile])
        ).run()

        let pipeline = try makePipeline(oauthEmail: "current@example.com")
        try pipeline.deliver(try transcriptRecords())
        // A later token hook heals the import-time guess; the metrics keep theirs.
        let token = [try Self.hookRecord("PreToolUse", id: 1)]
        try Self.ingestLegacy(token, into: legacy)
        try pipeline.deliver(token)

        let accounts = """
            SELECT s.account_email, s.auth_method, m.account_email
            FROM sessions s JOIN session_metrics m USING (session_id)
            """
        XCTAssertEqual(try rows(pipeline.database, accounts), try rows(legacy, accounts))
        XCTAssertEqual(try rows(pipeline.database, accounts), [#""dev@example.com"|"token"|"current@example.com""#])
    }

    // MARK: - Session start

    private var startedAt: String {
        "SELECT started_at FROM sessions WHERE session_id = '\(Self.sessionID)'"
    }

    func testStartedAtIsTheEarliestEventTimeAndAnEarlierBatchLowersIt() throws {
        let pipeline = try makePipeline()
        try pipeline.deliver([try Self.hookRecord(
            "SessionStart", id: 1, key: "late", timestamp: "2026-10-01T10:00:00Z")])
        XCTAssertEqual(try scalar(pipeline.database, startedAt), "2026-10-01 10:00:00")

        try pipeline.deliver([try Self.hookRecord(
            "PreToolUse", id: 2, key: "early", timestamp: "2026-09-30T08:15:30Z")])
        XCTAssertEqual(try scalar(pipeline.database, startedAt), "2026-09-30 08:15:30")

        // A later batch never raises it.
        try pipeline.deliver([try Self.hookRecord(
            "PostToolUse", id: 3, key: "later", timestamp: "2026-10-02T09:00:00Z")])
        XCTAssertEqual(try scalar(pipeline.database, startedAt), "2026-09-30 08:15:30")
    }

    func testATimeBeforeTwoThousandNeverCountsAsTheStart() throws {
        let pipeline = try makePipeline()
        try pipeline.deliver([try Self.hookRecord(
            "SessionStart", id: 1, key: "real", timestamp: "2026-10-01T10:00:00Z")])
        try pipeline.deliver([try Self.hookRecord(
            "PreToolUse", id: 2, key: "zero", timestamp: "1970-01-01T00:00:00Z")])
        XCTAssertEqual(try scalar(pipeline.database, startedAt), "2026-10-01 10:00:00")
    }
}
