import AgenticDeveloperHubSDKCore
import CryptoKit
import Foundation
import GRDB
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The Claude transcript adapter against one real-shaped line per kind
/// (`Fixtures/transcripts/*.jsonl`, one line per file; the test assigns each its
/// line number in a single imagined transcript).
final class ClaudeTranscriptNormalizerTests: XCTestCase {

    private var tmpDir: URL!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-claude-tx-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Fixtures

    private static let fixtureDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().appendingPathComponent("Fixtures/transcripts")

    private static let sessionID = "6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10"
    private static let receivedAt = Date(timeIntervalSince1970: 1_793_400_000)
    /// 2026-10-30T12:00:00Z
    private static let noon: TimeInterval = 1_793_361_600
    private static let mainFile =
        "/Users/dev/.claude/projects/-Users-dev-work-myapp/6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10.jsonl"
    private static let subagentFile = "/Users/dev/.claude/projects/-Users-dev-work-myapp/"
        + "6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10/subagents/agent-a4f9e2c1b7d3.jsonl"

    /// Each fixture's line number; `sidechain` is line 1 of the subagent's own file.
    private static let lineNumbers: [String: Int] = [
        "user-string": 1, "assistant": 2, "assistant-repeat": 3, "user-tool-result": 4, "queued-prompt": 5,
        "agent-dispatch": 6, "custom-title": 7, "ai-title": 8, "system": 9, "summary": 10, "malformed": 11,
        "sidechain": 1
    ]

    private static func line(_ stem: String) throws -> String {
        let text = try String(contentsOf: fixtureDir.appendingPathComponent("\(stem).jsonl"), encoding: .utf8)
        return text.trimmingCharacters(in: .newlines)
    }

    private static func payload(_ stem: String) throws -> ClaudeTranscriptPayload {
        let subagent = stem == "sidechain"
        return ClaudeTranscriptPayload(
            file: subagent ? subagentFile : mainFile, lineNo: try XCTUnwrap(lineNumbers[stem]),
            subagentFile: subagent, line: try line(stem))
    }

    private static func record(_ payload: ClaudeTranscriptPayload) throws -> RawRecord {
        RawRecord(provider: ClaudeProvider.name, sourceKind: ClaudeProvider.transcriptKind,
                  dedupKey: ClaudeTranscriptPayload.dedupKey(
                      line: payload.line, file: payload.file, byteOffset: Int64(payload.lineNo)),
                  receivedAt: receivedAt, payload: try ClaudeTranscriptPayload.encode(payload))
    }

    private static func rawRecord(_ stem: String) throws -> RawRecord {
        try record(try payload(stem))
    }

    private static func archived(_ stem: String, id: Int64 = 7) throws -> ArchivedRecord {
        ArchivedRecord(id: id, record: try rawRecord(stem))
    }

    private static func normalize(_ stem: String) throws -> NormalizedBatch {
        try ClaudeTranscriptNormalizer().normalize(try archived(stem))
    }

    private static func key(_ stem: String) throws -> String {
        try rawRecord(stem).dedupKey
    }

    private static func contentKey(_ line: String) -> String {
        ClaudeTranscriptPayload.contentKey(line: line, file: mainFile)
    }

    // MARK: - Payload and dedup key (Ruling 3)

    func testPayloadEncodesSortedSnakeCaseKeysAndRoundTrips() throws {
        let payload = ClaudeTranscriptPayload(file: "/a/b.jsonl", lineNo: 3, subagentFile: false, line: #"{"x":1}"#)
        let text = try XCTUnwrap(String(data: try ClaudeTranscriptPayload.encode(payload), encoding: .utf8))
        XCTAssertEqual(text, #"{"file":"/a/b.jsonl","line":"{\"x\":1}","line_no":3,"subagent_file":false}"#)
        XCTAssertEqual(try ClaudeTranscriptPayload.decode(Data(text.utf8)), payload)
        // Same input, same bytes.
        XCTAssertEqual(try ClaudeTranscriptPayload.encode(payload), try ClaudeTranscriptPayload.encode(payload))
        // The source's payloads carry the line's offset too.
        let placed = ClaudeTranscriptPayload(
            file: "/a/b.jsonl", lineNo: 3, subagentFile: false, line: #"{"x":1}"#, byteOffset: 42)
        let placedText = try XCTUnwrap(String(data: try ClaudeTranscriptPayload.encode(placed), encoding: .utf8))
        XCTAssertEqual(
            placedText, #"{"byte_offset":42,"file":"/a/b.jsonl","line":"{\"x\":1}","line_no":3,"subagent_file":false}"#)
        XCTAssertEqual(try ClaudeTranscriptPayload.decode(Data(placedText.utf8)), placed)
    }

    func testDedupKeyIsSessionFileOffsetAndLineHash() throws {
        let line = try Self.line("user-string")
        let hash = SHA256.hash(data: Data(line.utf8)).map { String(format: "%02x", $0) }.joined()
        let stem = Self.sessionID
        XCTAssertEqual(ClaudeTranscriptPayload.dedupKey(line: line, file: Self.mainFile, byteOffset: 120),
                       "\(Self.sessionID):\(stem)@120:\(hash)")
        // The file is named by its stem, so another directory's copy shares the key.
        XCTAssertEqual(
            ClaudeTranscriptPayload.dedupKey(line: line, file: "/elsewhere/\(stem).jsonl", byteOffset: 120),
            "\(Self.sessionID):\(stem)@120:\(hash)")
        // The same line at another offset, or in another file, is another occurrence.
        XCTAssertNotEqual(ClaudeTranscriptPayload.dedupKey(line: line, file: Self.mainFile, byteOffset: 0),
                          ClaudeTranscriptPayload.dedupKey(line: line, file: Self.mainFile, byteOffset: 120))
        XCTAssertNotEqual(ClaudeTranscriptPayload.dedupKey(line: line, file: Self.subagentFile, byteOffset: 120),
                          ClaudeTranscriptPayload.dedupKey(line: line, file: Self.mainFile, byteOffset: 120))
        // No sessionId on the line: the file stem stands in.
        let summary = try Self.line("summary")
        XCTAssertTrue(ClaudeTranscriptPayload.dedupKey(line: summary, file: Self.mainFile, byteOffset: 0)
            .hasPrefix("\(Self.sessionID):"))
        XCTAssertTrue(ClaudeTranscriptPayload.dedupKey(line: summary, file: Self.subagentFile, byteOffset: 0)
            .hasPrefix("agent-a4f9e2c1b7d3:agent-a4f9e2c1b7d3@0:"))
        XCTAssertEqual(ClaudeTranscriptPayload.fileStem(Self.mainFile), Self.sessionID)
    }

    // MARK: - Turns (Ruling 5)

    func testUserStringLine() throws {
        let batch = try Self.normalize("user-string")
        let time = Date(timeIntervalSince1970: Self.noon + 1)
        let turn = try XCTUnwrap(batch.turns.first)
        XCTAssertEqual(batch.turns.count, 1)
        XCTAssertEqual(turn.dedupKey, "user:\(Self.sessionID):2026-10-30T12:00:01.000Z")
        XCTAssertEqual(turn.sessionID, Self.sessionID)
        XCTAssertEqual(turn.time, time)
        XCTAssertEqual(try XCTUnwrap(turn.asOf).timeIntervalSince1970, Self.noon + 1 + 1e-6, accuracy: 1e-7)
        XCTAssertEqual(turn.attrs["kind"], .string("user"))
        XCTAssertEqual(turn.inputTokens + turn.outputTokens + turn.cacheReadTokens + turn.cacheWriteTokens, 0)
        XCTAssertNil(turn.model)
        XCTAssertNil(turn.account, "transcripts carry no account (Ruling 4)")
        XCTAssertNil(turn.attrs["message_id"])
        XCTAssertEqual(turn.rawRef, 7)

        let message = try XCTUnwrap(batch.messages.first)
        XCTAssertEqual(batch.messages.count, 1)
        XCTAssertEqual(message.dedupKey, try Self.key("user-string"))
        XCTAssertEqual(message.uuid, "0a1b2c3d-0001-4000-8000-000000000001")
        XCTAssertNil(message.parentUUID)
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.text, "Add a retry to the upload client")
        XCTAssertNil(message.attrs["blocks"], "string content has no blocks")
        XCTAssertEqual(message.time, time)

        let session = try XCTUnwrap(batch.sessions.first)
        XCTAssertEqual(batch.sessions.count, 1)
        XCTAssertEqual(session.sessionID, Self.sessionID)
        XCTAssertEqual(session.cwd, "/Users/dev/work/myapp")
        XCTAssertEqual(session.startedAt, time)
        XCTAssertEqual(session.asOf, turn.asOf)
        XCTAssertNil(session.account)
        XCTAssertEqual(session.attrs["git_branch"], .string("feature/upload-retry"))
        XCTAssertEqual(session.attrs["transcript_path"], .string(Self.mainFile))
        XCTAssertTrue(batch.events.isEmpty, "no synthesized UserPromptSubmit (Ruling 7)")
    }

    func testAssistantTurnFields() throws {
        let batch = try Self.normalize("assistant")
        let turn = try XCTUnwrap(batch.turns.first)
        XCTAssertEqual(batch.turns.count, 1)
        XCTAssertEqual(turn.dedupKey, "msg_01XyZAbCdEfGhIjKlMnOpQrS")
        XCTAssertEqual(turn.time, Date(timeIntervalSince1970: Self.noon + 5))
        XCTAssertEqual(try XCTUnwrap(turn.asOf).timeIntervalSince1970, Self.noon + 5 + 2e-6, accuracy: 1e-7)
        XCTAssertEqual(turn.model, "claude-opus-4-1")
        XCTAssertEqual(turn.inputTokens, 4)
        XCTAssertEqual(turn.outputTokens, 12)
        XCTAssertEqual(turn.cacheReadTokens, 18000)
        XCTAssertEqual(turn.cacheWriteTokens, 2400)
        XCTAssertEqual(turn.toolName, "Read")
        XCTAssertNil(turn.agent)
        XCTAssertNil(turn.account)
        XCTAssertNil(turn.costUSD)
        XCTAssertEqual(turn.attrs, [
            "kind": .string("assistant"),
            "cache_creation_1h_tokens": .number(2000),
            "is_subagent": .bool(false),
            "message_id": .string("msg_01XyZAbCdEfGhIjKlMnOpQrS"),
            "cwd": .string("/Users/dev/work/myapp"),
            "git_branch": .string("feature/upload-retry")
        ])
        let session = try XCTUnwrap(batch.sessions.first)
        XCTAssertEqual(session.model, "claude-opus-4-1")
        XCTAssertTrue(batch.events.isEmpty, "no synthesized PreToolUse (Ruling 7)")
    }

    func testAssistantWithoutMessageIDUsesTheFallbackKey() throws {
        let line = #"{"type":"assistant","sessionId":"s1","timestamp":"2026-10-30T12:00:00Z","uuid":"u1","#
            + #""message":{"role":"assistant","model":"m","content":[{"type":"tool_use","name":"Bash"}],"#
            + #""usage":{"input_tokens":1,"output_tokens":2}}}"#
        let payload = ClaudeTranscriptPayload(file: "/p/s1.jsonl", lineNo: 1, subagentFile: false, line: line)
        let batch = try ClaudeTranscriptNormalizer().normalize(ArchivedRecord(id: 1, record: try Self.record(payload)))
        XCTAssertEqual(batch.turns.first?.dedupKey, "asst:s1:2026-10-30T12:00:00Z:Bash")
        XCTAssertNil(batch.turns.first?.attrs["message_id"])
    }

    func testStreamingRepeatLeavesOneTurnWithTheLargerTokensInEitherOrder() throws {
        let first = try ClaudeTranscriptNormalizer().normalize(try Self.archived("assistant", id: 1))
        let repeated = try ClaudeTranscriptNormalizer().normalize(try Self.archived("assistant-repeat", id: 2))
        for (index, order) in [[first, repeated], [repeated, first]].enumerated() {
            let store = try EventStore(path: tmpDir.appendingPathComponent("events-\(index).db").path)
            for batch in order { _ = try store.write(batch, provider: ClaudeProvider.name) }
            let rows = try store.read { conn in
                try Row.fetchAll(conn, sql: """
                    SELECT dedup_key, output_tokens, input_tokens, cache_write_tokens, tool_name, raw_ref
                    FROM turns WHERE provider = 'claude'
                    """)
            }
            XCTAssertEqual(rows.count, 1, "order \(index)")
            let row = try XCTUnwrap(rows.first)
            XCTAssertEqual(row["dedup_key"] as String?, "msg_01XyZAbCdEfGhIjKlMnOpQrS")
            XCTAssertEqual(row["output_tokens"] as Int?, 187, "order \(index)")
            XCTAssertEqual(row["input_tokens"] as Int?, 4)
            XCTAssertEqual(row["cache_write_tokens"] as Int?, 2400)
            XCTAssertEqual(row["tool_name"] as String?, "Grep", "the later line's tool")
            XCTAssertEqual(row["raw_ref"] as Int?, 2)
            // Both lines are their own messages.
            let messages = try store.read { conn in
                try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM messages WHERE provider = 'claude'")
            }
            XCTAssertEqual(messages, 2)
        }
    }

    func testZeroUsageRepeatNeverOverwritesTurnTokensInEitherOrder() throws {
        // A later streamed line of the same message with empty usage emits no
        // turn, but still its message and session upsert.
        let zeroLine = #"{"type":"assistant","sessionId":"6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10","#
            + #""timestamp":"2026-10-30T12:00:09.000Z","uuid":"0a1b2c3d-0009-4000-8000-000000000009","#
            + #""message":{"id":"msg_01XyZAbCdEfGhIjKlMnOpQrS","role":"assistant","model":"claude-opus-4-1","#
            + #""content":[{"type":"text","text":"done"}],"usage":{"input_tokens":0,"output_tokens":0}}}"#
        let zeroPayload = ClaudeTranscriptPayload(file: Self.mainFile, lineNo: 12, subagentFile: false, line: zeroLine)
        let zero = try ClaudeTranscriptNormalizer().normalize(
            ArchivedRecord(id: 3, record: try Self.record(zeroPayload)))
        XCTAssertTrue(zero.turns.isEmpty)
        XCTAssertEqual(zero.messages.count, 1)
        XCTAssertEqual(zero.sessions.count, 1)

        let real = try ClaudeTranscriptNormalizer().normalize(try Self.archived("assistant", id: 1))
        for (index, order) in [[real, zero], [zero, real]].enumerated() {
            let store = try EventStore(path: tmpDir.appendingPathComponent("zero-\(index).db").path)
            for batch in order { _ = try store.write(batch, provider: ClaudeProvider.name) }
            let rows = try store.read { conn in
                try Row.fetchAll(conn, sql: """
                    SELECT input_tokens, output_tokens, cache_read_tokens, cache_write_tokens FROM turns
                    WHERE provider = 'claude' AND dedup_key = 'msg_01XyZAbCdEfGhIjKlMnOpQrS'
                    """)
            }
            XCTAssertEqual(rows.count, 1, "order \(index)")
            let row = try XCTUnwrap(rows.first)
            XCTAssertEqual(row["input_tokens"] as Int?, 4, "order \(index)")
            XCTAssertEqual(row["output_tokens"] as Int?, 12, "order \(index)")
            XCTAssertEqual(row["cache_read_tokens"] as Int?, 18000, "order \(index)")
            XCTAssertEqual(row["cache_write_tokens"] as Int?, 2400, "order \(index)")
        }
    }

    func testIdlessZeroUsageUserLineKeepsItsTurn() throws {
        let turn = try XCTUnwrap(try Self.normalize("user-tool-result").turns.first)
        XCTAssertEqual(turn.inputTokens + turn.outputTokens + turn.cacheReadTokens + turn.cacheWriteTokens, 0)
        XCTAssertTrue(turn.dedupKey.hasPrefix("user:"))
    }

    func testSidechainLineIsASubagentTurn() throws {
        let batch = try Self.normalize("sidechain")
        let turn = try XCTUnwrap(batch.turns.first)
        XCTAssertEqual(turn.dedupKey, "msg_01SubAgEnTtUrNaBcDeFgHiJ")
        XCTAssertEqual(turn.sessionID, Self.sessionID, "a subagent's lines belong to the parent session")
        XCTAssertEqual(turn.agent, "a4f9e2c1b7d3")
        XCTAssertEqual(turn.model, "claude-haiku-4-5")
        XCTAssertEqual(turn.attrs["is_subagent"], .bool(true))
        XCTAssertEqual(turn.attrs["cache_creation_1h_tokens"], .number(0))
        let message = try XCTUnwrap(batch.messages.first)
        XCTAssertTrue(message.isSidechain)
        XCTAssertEqual(message.role, "assistant")
        XCTAssertEqual(message.text, "")
        // The subagent's file and model must not overwrite the parent session's.
        let session = try XCTUnwrap(batch.sessions.first)
        XCTAssertNil(session.attrs["transcript_path"])
        XCTAssertNil(session.model)
        XCTAssertEqual(session.cwd, "/Users/dev/work/myapp")
    }

    func testMissingTimestampUsesZeroPlusLineNumber() throws {
        // Ambiguity resolution 1: a turn/message line with no timestamp sits at the
        // epoch, with as_of = 0 + line_no * 1e-6, so any timestamped observation
        // outranks it; it never claims a session start.
        let line = #"{"type":"assistant","sessionId":"s1","uuid":"u9","#
            + #""message":{"id":"msg_x","role":"assistant","model":"m","content":"hi","#
            + #""usage":{"input_tokens":1,"output_tokens":2}}}"#
        let payload = ClaudeTranscriptPayload(file: "/p/s1.jsonl", lineNo: 42, subagentFile: false, line: line)
        let batch = try ClaudeTranscriptNormalizer().normalize(ArchivedRecord(id: 1, record: try Self.record(payload)))
        let turn = try XCTUnwrap(batch.turns.first)
        XCTAssertEqual(turn.time, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(try XCTUnwrap(turn.asOf).timeIntervalSince1970, 42e-6, accuracy: 1e-7)
        XCTAssertEqual(batch.messages.first?.time, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(batch.messages.first?.text, "hi")
        let session = try XCTUnwrap(batch.sessions.first)
        XCTAssertNil(session.startedAt)
        XCTAssertEqual(session.asOf.timeIntervalSince1970, 42e-6, accuracy: 1e-7)
    }

    // MARK: - Messages (Ruling 6)

    func testMessageBlocksAreVerbatimAndTextIsFlattened() throws {
        let message = try XCTUnwrap(try Self.normalize("assistant").messages.first)
        XCTAssertEqual(message.dedupKey, try Self.key("assistant"))
        XCTAssertEqual(message.uuid, "0a1b2c3d-0002-4000-8000-000000000002")
        XCTAssertEqual(message.parentUUID, "0a1b2c3d-0001-4000-8000-000000000001")
        XCTAssertEqual(message.role, "assistant")
        XCTAssertFalse(message.isSidechain)
        XCTAssertEqual(message.text, "I'll look at the upload client. Reading it now.")
        XCTAssertEqual(message.attrs["blocks"], .array([
            .object(["type": .string("thinking"), "thinking": .string("The client lives in Sources/Upload."),
                     "signature": .string("EqQBCkYIBxgCKkB")]),
            .object(["type": .string("text"), "text": .string("I'll look at the upload client. ")]),
            .object(["type": .string("text"), "text": .string("Reading it now.")]),
            .object(["type": .string("tool_use"), "id": .string("toolu_01A2B3C4D5E6F7G8H9J0K1L2"),
                     "name": .string("Read"),
                     "input": .object(["file_path": .string("/Users/dev/work/myapp/Sources/Upload.swift")])])
        ]))
        XCTAssertNil(message.attrs["queued_prompt"])
        XCTAssertNil(message.attrs["stop_reason"], "a null stop_reason is no stop_reason")
        XCTAssertNil(message.attrs["entrypoint"])
        XCTAssertNil(message.attrs["is_meta"])

        let result = try XCTUnwrap(try Self.normalize("user-tool-result").messages.first)
        XCTAssertEqual(result.role, "user")
        XCTAssertEqual(result.text, "", "a tool_result block is not text")
        XCTAssertEqual(result.attrs["blocks"], .array([.object([
            "tool_use_id": .string("toolu_01A2B3C4D5E6F7G8H9J0K1L2"), "type": .string("tool_result"),
            "content": .string("import Foundation\nstruct Upload {}")])]))
    }

    func testMessageKeepsTheFactsTheConversationFeedJudgesBy() throws {
        let line = #"{"type":"assistant","sessionId":"s1","timestamp":"2026-10-30T12:00:00Z","uuid":"f1","#
            + #""entrypoint":"sdk-cli","isMeta":false,"turnOrigin":"task_notification","isCompactSummary":true,"#
            + #""message":{"role":"assistant","stop_reason":"end_turn","content":[{"type":"text","text":"hi"}]}}"#
        let payload = ClaudeTranscriptPayload(file: "/p/s1.jsonl", lineNo: 1, subagentFile: false, line: line)
        let batch = try ClaudeTranscriptNormalizer().normalize(ArchivedRecord(id: 1, record: try Self.record(payload)))
        let message = try XCTUnwrap(batch.messages.first)
        XCTAssertEqual(message.attrs["stop_reason"], .string("end_turn"))
        XCTAssertEqual(message.attrs["entrypoint"], .string("sdk-cli"))
        XCTAssertEqual(message.attrs["is_meta"], .bool(false))
        XCTAssertEqual(message.attrs["turn_origin"], .string("task_notification"))
        XCTAssertEqual(message.attrs["is_compact_summary"], .bool(true))
    }

    func testQueuedPromptIsFlagged() throws {
        let batch = try Self.normalize("queued-prompt")
        let message = try XCTUnwrap(batch.messages.first)
        XCTAssertEqual(batch.messages.count, 1)
        XCTAssertEqual(message.dedupKey, try Self.key("queued-prompt"))
        XCTAssertEqual(message.uuid, "0a1b2c3d-0005-4000-8000-000000000005")
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.text, "also cap retries at three")
        XCTAssertEqual(message.attrs["queued_prompt"], .bool(true))
        XCTAssertEqual(message.time, Date(timeIntervalSince1970: Self.noon + 9))
        XCTAssertTrue(batch.turns.isEmpty, "a queued prompt is not a turn")
        XCTAssertTrue(batch.events.isEmpty)
        // A task notification under the same attachment type is not the human speaking.
        let notification = #"{"type":"attachment","sessionId":"s1","timestamp":"2026-10-30T12:00:00Z","uuid":"n1","#
            + #""attachment":{"type":"queued_command","prompt":"done","commandMode":"task-notification"}}"#
        let payload = ClaudeTranscriptPayload(file: "/p/s1.jsonl", lineNo: 1, subagentFile: false, line: notification)
        let other = try ClaudeTranscriptNormalizer().normalize(ArchivedRecord(id: 1, record: try Self.record(payload)))
        XCTAssertTrue(other.messages.isEmpty)
    }

    /// A line without a uuid is keyed by its session and content, not its place:
    /// the same line archived from two files (a resumed transcript's copy) or at
    /// two offsets is one message in the store.
    func testUuidlessLineKeepsOneMessageIdentityWhereverItSits() throws {
        let line = #"{"type":"attachment","sessionId":"s1","timestamp":"2026-10-30T12:00:00Z","#
            + #""attachment":{"type":"queued_command","prompt":"cap retries","commandMode":"prompt"}}"#
        let first = ClaudeTranscriptPayload(file: "/p/s1.jsonl", lineNo: 3, subagentFile: false, line: line)
        let copy = ClaudeTranscriptPayload(file: "/p/s2.jsonl", lineNo: 9, subagentFile: false, line: line)
        let firstRecord = try Self.record(first)
        let copyRecord = try Self.record(copy)
        XCTAssertNotEqual(firstRecord.dedupKey, copyRecord.dedupKey, "each occurrence is its own raw record")

        let normalizer = ClaudeTranscriptNormalizer()
        let one = try XCTUnwrap(normalizer.normalize(ArchivedRecord(id: 1, record: firstRecord)).messages.first)
        let two = try XCTUnwrap(normalizer.normalize(ArchivedRecord(id: 2, record: copyRecord)).messages.first)
        XCTAssertEqual(one.uuid, two.uuid)
        XCTAssertEqual(one.uuid, ClaudeTranscriptPayload.contentKey(line: line, file: first.file))
        XCTAssertTrue(one.uuid.hasPrefix("s1:"))
    }

    // MARK: - Events (Ruling 7)

    func testTitlesBecomeEventsAndASessionTitle() throws {
        let cases: [(stem: String, title: String, source: String)] = [
            ("custom-title", "Upload retry", "custom"), ("ai-title", "Add retries to the upload client", "ai")
        ]
        for (stem, title, source) in cases {
            let batch = try Self.normalize(stem)
            let event = try XCTUnwrap(batch.events.first, stem)
            XCTAssertEqual(batch.events.count, 1, stem)
            XCTAssertEqual(event.dedupKey, Self.contentKey(try Self.line(stem)), stem)
            XCTAssertTrue(event.keepsLatestTime, stem)
            XCTAssertEqual(event.kind, .other, stem)
            XCTAssertEqual(event.providerType, stem)
            XCTAssertEqual(event.summary, title)
            XCTAssertEqual(event.attrs["title"], .string(title))
            XCTAssertEqual(event.attrs["title_source"], .string(source))
            XCTAssertEqual(event.sessionID, Self.sessionID)
            // Title lines carry no timestamp, so the event takes the capture
            // time plus line_no * 1e-6 (never the epoch: the session's title is
            // read back from these events newest first). The session upsert
            // keeps 0 + line_no * 1e-6, so a timed observation outranks it.
            let lineNo = Double(try XCTUnwrap(Self.lineNumbers[stem]))
            XCTAssertEqual(
                event.time.timeIntervalSince1970, Self.receivedAt.timeIntervalSince1970 + lineNo * 1e-6,
                accuracy: 1e-6)
            let session = try XCTUnwrap(batch.sessions.first, stem)
            XCTAssertEqual(batch.sessions.count, 1, stem)
            XCTAssertEqual(session.title, title)
            XCTAssertEqual(session.asOf.timeIntervalSince1970, lineNo * 1e-6, accuracy: 1e-7)
            XCTAssertNil(session.startedAt)
            XCTAssertTrue(batch.turns.isEmpty && batch.messages.isEmpty, stem)
        }
    }

    /// A title or dispatch line copied into another file (a resumed transcript)
    /// or moved by a rewrite is the same event, not a second one.
    func testCopiedTitleAndDispatchLinesKeepOneEventKey() throws {
        for stem in ["custom-title", "ai-title", "agent-dispatch"] {
            let original = try Self.payload(stem)
            let copy = ClaudeTranscriptPayload(
                file: "/Users/dev/.claude/projects/-Users-dev-work-myapp/resumed.jsonl",
                lineNo: original.lineNo + 40, subagentFile: false, line: original.line)
            let normalizer = ClaudeTranscriptNormalizer()
            let one = try XCTUnwrap(normalizer.normalize(
                ArchivedRecord(id: 1, record: try Self.record(original))).events.first, stem)
            let two = try XCTUnwrap(normalizer.normalize(
                ArchivedRecord(id: 2, record: try Self.record(copy))).events.first, stem)
            XCTAssertNotEqual(try Self.record(original).dedupKey, try Self.record(copy).dedupKey, stem)
            XCTAssertEqual(one.dedupKey, two.dedupKey, stem)
        }
    }

    func testAgentDispatchResultIsASubagentStopEvent() throws {
        let batch = try Self.normalize("agent-dispatch")
        let event = try XCTUnwrap(batch.events.first)
        XCTAssertEqual(batch.events.count, 1)
        XCTAssertEqual(event.dedupKey, Self.contentKey(try Self.line("agent-dispatch")) + "#agent-dispatch")
        XCTAssertFalse(event.keepsLatestTime, "a copied dispatch line carries the same timestamp")
        XCTAssertEqual(event.kind, .subagentStop)
        XCTAssertEqual(event.providerType, "agent-dispatch")
        XCTAssertEqual(event.sessionID, Self.sessionID)
        XCTAssertEqual(event.time, Date(timeIntervalSince1970: Self.noon + 90))
        XCTAssertEqual(event.cwd, "/Users/dev/work/myapp")
        XCTAssertEqual(event.attrs, [
            "agent_id": .string("a4f9e2c1b7d3"), "agent_type": .string("Explore"),
            "status": .string("completed"), "total_tokens": .number(23817),
            "total_duration_ms": .number(41250), "total_tool_use_count": .number(7)
        ])
        // It is still a user line: one turn and one message.
        XCTAssertEqual(batch.turns.first?.dedupKey, "user:\(Self.sessionID):2026-10-30T12:01:30.000Z")
        XCTAssertEqual(batch.messages.first?.text, "")
        XCTAssertEqual(batch.messages.first?.dedupKey, try Self.key("agent-dispatch"))
    }

    func testUserAndAssistantLinesSynthesizeNoEvents() throws {
        for stem in ["user-string", "assistant", "assistant-repeat", "user-tool-result", "sidechain", "queued-prompt"] {
            XCTAssertTrue(try Self.normalize(stem).events.isEmpty, stem)
        }
    }

    // MARK: - Session-only, empty and malformed

    func testSummaryLineIsAnEmptyBatch() throws {
        XCTAssertTrue(try Self.normalize("summary").isEmpty, "no session id, no timestamp: nothing to say")
    }

    func testSystemLineIsOnlyASessionUpsert() throws {
        let batch = try Self.normalize("system")
        XCTAssertTrue(batch.events.isEmpty && batch.turns.isEmpty && batch.messages.isEmpty)
        let session = try XCTUnwrap(batch.sessions.first)
        XCTAssertEqual(batch.sessions.count, 1)
        XCTAssertEqual(session.sessionID, Self.sessionID)
        XCTAssertEqual(session.cwd, "/Users/dev/work/myapp")
        XCTAssertEqual(session.startedAt, Date(timeIntervalSince1970: Self.noon + 120))
        XCTAssertEqual(session.asOf.timeIntervalSince1970, Self.noon + 120 + 9e-6, accuracy: 1e-6)
        XCTAssertEqual(session.attrs["git_branch"], .string("feature/upload-retry"))
        XCTAssertNil(session.title)
        XCTAssertNil(session.model)
    }

    func testMalformedLineThrowsUnparseable() throws {
        let key = try Self.key("malformed")
        XCTAssertThrowsError(try Self.normalize("malformed")) { error in
            XCTAssertEqual(error as? ClaudeNormalizerError, .unparseable(key))
        }
        // A payload that is not the Ruling 3 object.
        let junk = ArchivedRecord(id: 1, record: RawRecord(
            provider: "claude", sourceKind: "transcript", dedupKey: "junk", receivedAt: Self.receivedAt,
            payload: Data(#"{"line":"x"}"#.utf8)))
        XCTAssertThrowsError(try ClaudeTranscriptNormalizer().normalize(junk)) { error in
            XCTAssertEqual(error as? ClaudeNormalizerError, .unparseable("junk"))
        }
        // A JSON line that is not an object.
        let array = ClaudeTranscriptPayload(file: "/p/s1.jsonl", lineNo: 1, subagentFile: false, line: "[1,2]")
        let arrayRecord = try Self.record(array)
        XCTAssertThrowsError(try ClaudeTranscriptNormalizer().normalize(ArchivedRecord(id: 1, record: arrayRecord))) {
            XCTAssertEqual($0 as? ClaudeNormalizerError, .unparseable(arrayRecord.dedupKey))
        }
    }

    func testNormalizingTwiceGivesEqualBatches() throws {
        for stem in Self.lineNumbers.keys where stem != "malformed" {
            XCTAssertEqual(try Self.normalize(stem), try Self.normalize(stem), stem)
        }
    }

    // MARK: - Composite

    func testCompositeRoutesTranscripts() throws {
        XCTAssertEqual(ClaudeTranscriptNormalizer().provider, "claude")
        for stem in Self.lineNumbers.keys where stem != "malformed" {
            let record = try Self.archived(stem)
            XCTAssertEqual(try ClaudeNormalizer().normalize(record),
                           try ClaudeTranscriptNormalizer().normalize(record), stem)
        }
        let key = try Self.key("malformed")
        XCTAssertThrowsError(try ClaudeNormalizer().normalize(try Self.archived("malformed"))) { error in
            XCTAssertEqual(error as? ClaudeNormalizerError, .unparseable(key))
        }
    }

    // MARK: - Conformance

    /// Every transcript fixture that leaves a row keyed by its record, plus the
    /// malformed one. `summary` (an empty batch) and `system` (a session upsert
    /// only, which the conformance check does not count as a keyed row) are left
    /// out and covered by their own tests above.
    func testClaudeNormalizerConformsOverTranscripts() throws {
        let stems = ["user-string", "assistant", "assistant-repeat", "user-tool-result", "queued-prompt",
                     "agent-dispatch", "custom-title", "ai-title", "sidechain", "malformed"]
        let fixtures = try stems.map { try Self.rawRecord($0) }
        let failures = try ProviderConformance.check(
            normalizer: ClaudeNormalizer(), fixtures: fixtures, malformedKeys: [try Self.key("malformed")],
            workDirectory: tmpDir.appendingPathComponent("w"))
        XCTAssertEqual(failures, [], "\(failures)")
    }
}
