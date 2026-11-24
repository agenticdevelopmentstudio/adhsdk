import AgenticDeveloperHubSDKCore
import Foundation
import GRDB
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The Claude hook adapter against one real-shaped envelope per hook type
/// (`Fixtures/hooks/*.json`, one file per hook; the file stem is the dedup key).
final class ClaudeHookNormalizerTests: XCTestCase {

    private var tmpDir: URL!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-claude-hook-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Fixtures

    private static let fixtureDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().appendingPathComponent("Fixtures/hooks")

    private static let sessionID = "6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10"
    private static let receivedAt = Date(timeIntervalSince1970: 1_793_400_000)

    /// Hook name → the kind Design Ruling 8 maps it to.
    private static let expectedKinds: [String: EventKind] = [
        "SessionStart": .sessionStart, "SessionEnd": .sessionEnd, "UserPromptSubmit": .prompt,
        "PreToolUse": .toolCall, "PostToolUse": .toolResult, "PostToolUseFailure": .toolResult,
        "Stop": .stop, "PreCompact": .compaction, "PostCompact": .compaction,
        "SubagentStart": .subagentStart, "SubagentStop": .subagentStop, "Notification": .notification,
        "PermissionRequest": .permission, "StatusLine": .other, "ConfigChange": .other
    ]

    private static let malformedStems: Set<String> = ["invalid-json", "no-session-id", "empty"]

    private static func payload(_ stem: String) throws -> Data {
        try Data(contentsOf: fixtureDir.appendingPathComponent("\(stem).json"))
    }

    private static func rawRecord(_ stem: String, sourceKind: String = ClaudeProvider.hookKind,
                                  key: String? = nil) throws -> RawRecord {
        RawRecord(provider: ClaudeProvider.name, sourceKind: sourceKind, dedupKey: key ?? stem,
                  receivedAt: receivedAt, payload: try payload(stem))
    }

    private static func archived(_ stem: String, id: Int64 = 7, sourceKind: String = ClaudeProvider.hookKind)
        throws -> ArchivedRecord {
        ArchivedRecord(id: id, record: try rawRecord(stem, sourceKind: sourceKind))
    }

    /// Every fixture stem on disk.
    private static func allStems() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: fixtureDir.path)
            .filter { $0.hasSuffix(".json") }
            .map { String($0.dropLast(".json".count)) }
            .sorted()
    }

    private static func normalize(_ stem: String) throws -> NormalizedBatch {
        try ClaudeHookNormalizer().normalize(try archived(stem))
    }

    private static func onlyEvent(_ stem: String, file: StaticString = #filePath, line: UInt = #line)
        throws -> NormalizedEvent {
        let batch = try normalize(stem)
        XCTAssertEqual(batch.events.count, 1, "\(stem)", file: file, line: line)
        return try XCTUnwrap(batch.events.first, file: file, line: line)
    }

    private static func onlySession(_ stem: String, file: StaticString = #filePath, line: UInt = #line)
        throws -> SessionUpsert {
        let batch = try normalize(stem)
        XCTAssertEqual(batch.sessions.count, 1, "\(stem)", file: file, line: line)
        return try XCTUnwrap(batch.sessions.first, file: file, line: line)
    }

    /// The envelope as JSONSerialization reads it.
    private static func envelope(_ stem: String) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: try payload(stem)) as? [String: Any])
    }

    // MARK: - Provider constants

    func testProviderConstants() {
        XCTAssertEqual(ClaudeProvider.name, "claude")
        XCTAssertEqual(ClaudeProvider.hookKind, "hook")
        XCTAssertEqual(ClaudeProvider.legacyHookKind, "hook-legacy")
        XCTAssertEqual(ClaudeProvider.transcriptKind, "transcript")
        XCTAssertEqual(ClaudeHookNormalizer().provider, "claude")
        XCTAssertEqual(ClaudeNormalizer().provider, "claude")
    }

    func testEveryHookTypeHasAFixture() throws {
        let stems = Set(try Self.allStems())
        XCTAssertEqual(stems.subtracting(Self.malformedStems), Set(Self.expectedKinds.keys))
        XCTAssertTrue(Self.malformedStems.isSubset(of: stems))
    }

    // MARK: - Events

    func testEachHookTypeMapsToItsKind() throws {
        for (hook, kind) in Self.expectedKinds {
            let event = try Self.onlyEvent(hook)
            XCTAssertEqual(event.kind, kind, hook)
            XCTAssertEqual(event.providerType, hook, hook)
            XCTAssertEqual(event.sessionID, Self.sessionID, hook)
            XCTAssertEqual(event.dedupKey, hook, "one event per envelope, keyed by the record")
            XCTAssertEqual(event.rawRef, 7, hook)
            XCTAssertEqual(event.cwd, "/Users/dev/work/myapp", hook)
        }
    }

    func testSummaryEqualsComputeDetail() throws {
        for hook in Self.expectedKinds.keys {
            let hookData = try XCTUnwrap(try Self.envelope(hook)["hook_data"] as? [String: Any])
            let event = try Self.onlyEvent(hook)
            XCTAssertEqual(event.summary, computeDetail(eventType: hook, hookData: hookData), hook)
        }
        // Spot-check that the formatter really ran (not just two empty strings).
        XCTAssertEqual(try Self.onlyEvent("PreToolUse").summary?.hasPrefix("Bash"), true)
        XCTAssertEqual(try Self.onlyEvent("UserPromptSubmit").summary?.hasPrefix("Add a retry"), true)
    }

    func testTimeIsTheEnvelopeTimestamp() throws {
        // 2026-10-30T12:00:00Z
        XCTAssertEqual(try Self.onlyEvent("SessionStart").time.timeIntervalSince1970, 1_793_361_600)
        // Fractional seconds survive.
        XCTAssertEqual(try Self.onlyEvent("SessionEnd").time.timeIntervalSince1970,
                       1_793_361_600 + 6310.5, accuracy: 0.0001)
        for hook in Self.expectedKinds.keys {
            let stamp = try XCTUnwrap(try Self.envelope(hook)["timestamp"] as? String)
            let expected = try XCTUnwrap(TimestampParsing.parse(stamp))
            XCTAssertEqual(try Self.onlyEvent(hook).time, expected, hook)
            XCTAssertNotEqual(try Self.onlyEvent(hook).time, Self.receivedAt, hook)
        }
    }

    func testToolNameAndToolUseID() throws {
        let pre = try Self.onlyEvent("PreToolUse")
        XCTAssertEqual(pre.toolName, "Bash")
        XCTAssertEqual(pre.attrs["tool_use_id"], .string("toolu_01A2B3C4D5E6F7G8H9J0K1L2"))
        let failure = try Self.onlyEvent("PostToolUseFailure")
        XCTAssertEqual(failure.attrs["tool_use_id"], pre.attrs["tool_use_id"], "readers pair on tool_use_id")
        XCTAssertNil(failure.attrs["duration_ms"], "duration is a reader's job")
        XCTAssertNil(try Self.onlyEvent("Stop").toolName)
    }

    func testRuling8aAttrs() throws {
        let start = try Self.onlyEvent("SessionStart")
        XCTAssertEqual(start.attrs["source"], .string("startup"))
        XCTAssertEqual(start.attrs["model"], .string("claude-opus-4-1"))
        XCTAssertEqual(start.attrs["pid"], .number(48213))
        XCTAssertEqual(start.attrs["permission_mode"], .string("default"))
        XCTAssertEqual(start.attrs["term_program"], .string("iTerm.app"))
        XCTAssertEqual(start.attrs["term_session_id"], .string("w0t1p0:9B1D0C2E-1111-4A4A-8888-0123456789AB"))
        XCTAssertEqual(start.attrs["transcript_path"], .string(
            "/Users/dev/.claude/projects/-Users-dev-work-myapp/6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10.jsonl"))
        guard case .object(let context)? = start.attrs["context_json"] else {
            return XCTFail("context_json must be the envelope's context object: \(String(describing: start.attrs))")
        }
        XCTAssertEqual(context["process"], .object([
            "ppid": .number(48213), "uid": .number(501), "euid": .number(501), "gid": .number(20)]))
        XCTAssertEqual(context["claude"], .object([
            "entrypoint": .string("cli"), "project_dir": .string("/Users/dev/work/myapp"), "running": .bool(true)]))

        XCTAssertEqual(try Self.onlyEvent("SessionEnd").attrs["reason"], .string("prompt_input_exit"))
        XCTAssertEqual(try Self.onlyEvent("PreCompact").attrs["trigger"], .string("auto"))
        XCTAssertEqual(try Self.onlyEvent("Notification").attrs["notification_type"], .string("idle_prompt"))
        let subagent = try Self.onlyEvent("SubagentStop")
        XCTAssertEqual(subagent.attrs["agent_id"], .string("a4f9e2c1b7d3"))
        XCTAssertEqual(subagent.attrs["agent_type"], .string("Explore"))
        XCTAssertEqual(try Self.onlyEvent("StatusLine").attrs["git_branch"], .string("feature/upload-retry"))
        XCTAssertNil(try Self.onlyEvent("Stop").attrs["context_json"], "Stop's envelope has no context")
    }

    func testAbsentKeysAreOmittedNeverNull() throws {
        let allowed: Set<String> = [
            "tool_use_id", "agent_type", "agent_id", "notification_type", "trigger", "model",
            "transcript_path", "git_branch", "term_program", "term_session_id", "pid", "permission_mode",
            "source", "reason", "auth_method", "account_email", "oauth_account_email", "context_json",
            "prompt_cache_misses", "prompt_cache_requests", "prompt_cache_miss_recache_tokens", "model_id",
            "prompt_cache_ttl", "prompt_cache_miss_causes", "prompt_cache_last_miss_cause", "context_used_pct",
            "context_window_size", "project_dir", "claude_version"
        ]
        for hook in Self.expectedKinds.keys {
            let event = try Self.onlyEvent(hook)
            XCTAssertTrue(Set(event.attrs.keys).isSubset(of: allowed),
                          "\(hook): \(Set(event.attrs.keys).subtracting(allowed))")
            for (key, value) in event.attrs {
                XCTAssertNotEqual(value, .null, "\(hook).\(key)")
                XCTAssertNotEqual(value, .string(""), "\(hook).\(key)")
            }
        }
        let stop = try Self.onlyEvent("Stop")
        for key in ["tool_use_id", "agent_id", "reason", "source", "account_email", "oauth_account_email",
                    "auth_method", "prompt_cache_misses"] {
            XCTAssertNil(stop.attrs[key], key)
        }
    }

    func testStatusLineCarriesAllElevenKeys() throws {
        let attrs = try Self.onlyEvent("StatusLine").attrs
        let expected: [String: NormalizedValue] = [
            "prompt_cache_misses": .number(3),
            "prompt_cache_requests": .number(120),
            "prompt_cache_miss_recache_tokens": .number(45000),
            "model_id": .string("claude-opus-4-1"),
            "prompt_cache_ttl": .string("1h"),
            "prompt_cache_miss_causes": .object(["ttl_expired_5m": .number(2), "model_changed": .number(1)]),
            "prompt_cache_last_miss_cause": .object([
                "cause": .string("ttl_expired_5m"), "idle_seconds": .number(412), "recache_tokens": .number(15000)]),
            "context_used_pct": .number(38),
            "context_window_size": .number(200_000),
            "project_dir": .string("/Users/dev/work/myapp"),
            "claude_version": .string("2.1.302")
        ]
        for (key, value) in expected {
            XCTAssertEqual(attrs[key], value, key)
        }
        // StatusLine's `model` is an object, so it is reported as model_id, never as `model`.
        XCTAssertNil(attrs["model"])
        // Status-line keys stay on StatusLine.
        for key in expected.keys {
            XCTAssertNil(try Self.onlyEvent("PreToolUse").attrs[key], key)
        }
    }

    // MARK: - Sessions

    func testAuthAttributionFollowsRuling4() {
        let token = ClaudeHookNormalizer.authAttribution(accountEmail: "dev@example.com",
                                                         oauthEmail: "owner@example.com")
        XCTAssertEqual(token.account, "dev@example.com")
        XCTAssertEqual(token.authMethod, "token")
        let oauth = ClaudeHookNormalizer.authAttribution(accountEmail: "", oauthEmail: "owner@example.com")
        XCTAssertEqual(oauth.account, "owner@example.com")
        XCTAssertEqual(oauth.authMethod, "oauth")
        let neither = ClaudeHookNormalizer.authAttribution(accountEmail: "", oauthEmail: nil)
        XCTAssertNil(neither.account)
        XCTAssertNil(neither.authMethod)
        let emptyOAuth = ClaudeHookNormalizer.authAttribution(accountEmail: "", oauthEmail: "")
        XCTAssertNil(emptyOAuth.account)
        XCTAssertNil(emptyOAuth.authMethod)
    }

    func testSessionAccountFollowsRuling4InAllThreeCases() throws {
        // Token wins even though the envelope also carries an oauth login.
        let token = try Self.onlySession("SessionStart")
        XCTAssertEqual(token.account, "dev@example.com")
        XCTAssertEqual(token.attrs["auth_method"], .string("token"))
        let tokenEvent = try Self.onlyEvent("SessionStart")
        XCTAssertEqual(tokenEvent.attrs["auth_method"], .string("token"))
        XCTAssertEqual(tokenEvent.attrs["account_email"], .string("dev@example.com"))
        XCTAssertEqual(tokenEvent.attrs["oauth_account_email"], .string("owner@example.com"))

        // No token: the oauth login captured with the event.
        let oauth = try Self.onlySession("UserPromptSubmit")
        XCTAssertEqual(oauth.account, "owner@example.com")
        XCTAssertEqual(oauth.attrs["auth_method"], .string("oauth"))
        XCTAssertNil(try Self.onlyEvent("UserPromptSubmit").attrs["account_email"])

        // Neither: no account and no auth method — never resolved at normalize time.
        let neither = try Self.onlySession("Stop")
        XCTAssertNil(neither.account)
        XCTAssertNil(neither.attrs["auth_method"])
    }

    func testSessionStartAndEnd() throws {
        let start = try Self.onlySession("SessionStart")
        XCTAssertEqual(start.sessionID, Self.sessionID)
        XCTAssertEqual(start.status, "active")
        XCTAssertEqual(start.startedAt, try Self.onlyEvent("SessionStart").time)
        XCTAssertNil(start.endedAt)
        XCTAssertEqual(start.asOf, start.startedAt)
        XCTAssertEqual(start.cwd, "/Users/dev/work/myapp")
        XCTAssertEqual(start.model, "claude-opus-4-1")

        let end = try Self.onlySession("SessionEnd")
        XCTAssertEqual(end.status, "ended")
        XCTAssertEqual(end.endedAt, try Self.onlyEvent("SessionEnd").time)
        XCTAssertNil(end.startedAt)

        let middle = try Self.onlySession("PreToolUse")
        XCTAssertNil(middle.status)
        XCTAssertNil(middle.startedAt)
        XCTAssertNil(middle.endedAt)
        XCTAssertNil(try Self.onlySession("StatusLine").model, "StatusLine's model is an object")
    }

    func testHookBatchesCarryNoTurnsOrMessages() throws {
        for hook in Self.expectedKinds.keys {
            let batch = try Self.normalize(hook)
            XCTAssertTrue(batch.turns.isEmpty, hook)
            XCTAssertTrue(batch.messages.isEmpty, hook)
        }
    }

    // MARK: - Skips and errors

    func testEnvelopeWithoutSessionIDIsAnEmptyBatch() throws {
        XCTAssertTrue(try Self.normalize("no-session-id").isEmpty)
    }

    func testEmptyPayloadIsAnEmptyBatch() throws {
        XCTAssertTrue(try Self.payload("empty").isEmpty, "fixture must be zero bytes")
        XCTAssertTrue(try Self.normalize("empty").isEmpty)
        let whitespace = ArchivedRecord(id: 1, record: RawRecord(
            provider: "claude", sourceKind: "hook", dedupKey: "ws", receivedAt: Self.receivedAt,
            payload: Data(" \n".utf8)))
        XCTAssertTrue(try ClaudeHookNormalizer().normalize(whitespace).isEmpty)
    }

    func testInvalidJSONThrowsUnparseable() throws {
        XCTAssertThrowsError(try Self.normalize("invalid-json")) { error in
            XCTAssertEqual(error as? ClaudeNormalizerError, .unparseable("invalid-json"))
        }
        // An object without an event name is unparseable too (ParseResult parity).
        let noEvent = ArchivedRecord(id: 1, record: RawRecord(
            provider: "claude", sourceKind: "hook", dedupKey: "no-event", receivedAt: Self.receivedAt,
            payload: Data(#"{"hook_data":{"session_id":"s"}}"#.utf8)))
        XCTAssertThrowsError(try ClaudeHookNormalizer().normalize(noEvent)) { error in
            XCTAssertEqual(error as? ClaudeNormalizerError, .unparseable("no-event"))
        }
        // Bytes that are not UTF-8.
        let binary = ArchivedRecord(id: 1, record: RawRecord(
            provider: "claude", sourceKind: "hook", dedupKey: "binary", receivedAt: Self.receivedAt,
            payload: Data([0xFF, 0xFE, 0x00, 0x7B])))
        XCTAssertThrowsError(try ClaudeHookNormalizer().normalize(binary)) { error in
            XCTAssertEqual(error as? ClaudeNormalizerError, .unparseable("binary"))
        }
    }

    func testUnparseableTimestampFallsBackToReceivedAt() throws {
        let record = ArchivedRecord(id: 3, record: RawRecord(
            provider: "claude", sourceKind: "hook", dedupKey: "no-time", receivedAt: Self.receivedAt,
            payload: Data(#"{"event":"Stop","timestamp":"","hook_data":{"session_id":"s"}}"#.utf8)))
        let batch = try ClaudeHookNormalizer().normalize(record)
        XCTAssertEqual(batch.events.first?.time, Self.receivedAt)
        XCTAssertEqual(batch.sessions.first?.asOf, Self.receivedAt)
    }

    func testNormalizingTwiceGivesEqualBatches() throws {
        for stem in try Self.allStems() where stem != "invalid-json" {
            XCTAssertEqual(try Self.normalize(stem), try Self.normalize(stem), stem)
        }
    }

    // MARK: - Composite

    func testCompositeDispatchesOnSourceKind() throws {
        let hook = try Self.archived("PreToolUse")
        XCTAssertEqual(try ClaudeNormalizer().normalize(hook), try ClaudeHookNormalizer().normalize(hook))
        let legacy = try Self.archived("PreToolUse", sourceKind: ClaudeProvider.legacyHookKind)
        XCTAssertEqual(try ClaudeNormalizer().normalize(legacy), try ClaudeHookNormalizer().normalize(legacy))
        XCTAssertEqual(try ClaudeNormalizer().normalize(legacy).events.first?.kind, .toolCall)

        // Transcripts now have their own normalizer: a hook envelope under that
        // kind is not a transcript payload.
        let transcript = try Self.archived("PreToolUse", sourceKind: ClaudeProvider.transcriptKind)
        XCTAssertThrowsError(try ClaudeNormalizer().normalize(transcript)) { error in
            XCTAssertEqual(error as? ClaudeNormalizerError, .unparseable(transcript.record.dedupKey))
        }
        let unknown = try Self.archived("PreToolUse", sourceKind: "mystery")
        XCTAssertThrowsError(try ClaudeNormalizer().normalize(unknown)) { error in
            XCTAssertEqual(error as? ClaudeNormalizerError, .unsupportedSourceKind("mystery"))
        }
        XCTAssertThrowsError(try ClaudeNormalizer().normalize(try Self.archived("invalid-json"))) { error in
            XCTAssertEqual(error as? ClaudeNormalizerError, .unparseable("invalid-json"))
        }
    }

    // MARK: - Conformance

    /// Every well-formed hook fixture, a legacy capture of one, a duplicate delivery
    /// and the malformed one. The no-session and empty envelopes are left out: the
    /// conformance check requires every non-malformed fixture to yield rows, and those
    /// two deliberately yield none (they are archived, never normalized into rows).
    func testClaudeNormalizerConforms() throws {
        var fixtures = try Self.expectedKinds.keys.sorted().map { try Self.rawRecord($0) }
        fixtures.append(try Self.rawRecord("PreToolUse", sourceKind: ClaudeProvider.legacyHookKind,
                                           key: "cap-5B0C3D2E-7A41-4F7E-9C1B-2D3E4F5A6B7C"))
        fixtures.append(try Self.rawRecord("SessionStart"))
        fixtures.append(try Self.rawRecord("invalid-json"))
        let failures = try ProviderConformance.check(
            normalizer: ClaudeNormalizer(), fixtures: fixtures, malformedKeys: ["invalid-json"],
            workDirectory: tmpDir.appendingPathComponent("w"))
        XCTAssertEqual(failures, [], "\(failures)")
    }

    // MARK: - EventStore.read

    func testEventStoreReadSeesWrittenRows() throws {
        let store = try EventStore(path: tmpDir.appendingPathComponent(EventStore.fileName).path)
        var batch = NormalizedBatch()
        for (index, hook) in Self.expectedKinds.keys.sorted().enumerated() {
            batch.append(try ClaudeHookNormalizer().normalize(try Self.archived(hook, id: Int64(index + 1))))
        }
        _ = try store.write(batch, provider: ClaudeProvider.name)

        let (events, statusLineMisses) = try store.read { conn -> (Int, String?) in
            let count = try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM events WHERE provider = ?",
                                         arguments: [ClaudeProvider.name]) ?? 0
            let misses = try String.fetchOne(conn, sql: """
                SELECT json_extract(attrs, '$.prompt_cache_miss_causes') FROM events
                WHERE provider = ? AND provider_type = 'StatusLine'
                """, arguments: [ClaudeProvider.name])
            return (count, misses)
        }
        XCTAssertEqual(events, Self.expectedKinds.count)
        XCTAssertEqual(statusLineMisses, #"{"model_changed":1,"ttl_expired_5m":2}"#)
    }

    func testEventStoreReadIsReadOnly() throws {
        let store = try EventStore(path: tmpDir.appendingPathComponent(EventStore.fileName).path)
        XCTAssertThrowsError(try store.read { conn in
            try conn.execute(sql: "DELETE FROM events")
        })
    }
}
