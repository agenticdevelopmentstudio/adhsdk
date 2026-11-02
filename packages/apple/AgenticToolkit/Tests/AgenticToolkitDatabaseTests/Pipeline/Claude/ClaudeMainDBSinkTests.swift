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
            dedupKey: ClaudeTranscriptPayload.dedupKey(line: payload.line, file: payload.file),
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

    private func makeDatabase() throws -> DaemonDatabase {
        // A resolver pointed at a file that does not exist: no oauth fallback, so
        // the test never reads the real `~/.claude.json`.
        let resolver = AccountResolver(claudeJSONPath: tmpDir.appendingPathComponent("no-claude.json").path)
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

    private func makePipeline() throws -> Pipeline {
        let database = try makeDatabase()
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

        for table in ["sessions", "session_branches", "rate_limit_snapshots"] {
            XCTAssertEqual(try dump(pipeline.database, table: table), try dump(legacy, table: table), table)
        }
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
            XCTAssertEqual(try dump(pipeline.database, table: table), try dump(legacy, table: table), table)
        }
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
}
