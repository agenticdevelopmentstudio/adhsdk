import AgenticToolkitCore
import CryptoKit
import Foundation
import GRDB
import XCTest
@testable import AgenticToolkitDatabase

/// The records the legacy-split migration writes into `claude-raw.db` from the
/// old `stenographer.db` (`scripts/legacy_split.py convert`), and the resumable
/// replay (`ClaudeArchiveReplay`) that turns them into `events.db` rows:
///
/// - `hook-legacy` envelopes keyed `legacy-event-<event_log.id>`, carrying a
///   top-level `legacy` object the normalizer ignores;
/// - orphan transcript lines keyed `<session>:legacy-line-<id>:<hash>`, whose
///   payload has `byte_offset = -1` and an extra `legacy_line_id`.
final class ClaudeLegacyRecordTests: XCTestCase {

    private var tmpDir: URL!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-legacy-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Builders

    static let sessionID = "6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10"
    static let receivedAt = Date(timeIntervalSince1970: 1_793_400_000)
    static let transcriptFile =
        "/Users/dev/.claude/projects/-Users-dev-work-myapp/6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10.jsonl"

    /// One assistant line with a message id and real usage: one turn, one message.
    static let assistantLine = #"{"cwd":"/Users/dev/work/myapp","isSidechain":false,"#
        + #""message":{"content":[{"text":"Reading it now.","type":"text"}],"id":"msg_legacy_01","#
        + #""model":"claude-opus-4-1","role":"assistant","usage":{"cache_creation_input_tokens":0,"#
        + #""cache_read_input_tokens":100,"input_tokens":4,"output_tokens":12}},"parentUuid":null,"#
        + #""sessionId":"6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10","timestamp":"2026-10-30T12:00:05.000Z","#
        + #""type":"assistant","uuid":"0a1b2c3d-0002-4000-8000-000000000002"}"#

    static func json(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])
    }

    /// A `hook-legacy` record as `legacy_split.py convert` builds it.
    static func hookLegacy(
        id: Int, event: String, hookData: [String: Any], timestamp: String = "2026-10-30T12:00:01.000Z",
        context: [String: Any]? = nil
    ) throws -> RawRecord {
        var envelope: [String: Any] = [
            "event": event, "timestamp": timestamp, "hook_data": hookData,
            "account_email": "dev@example.com",
            "legacy": ["source": "event_log", "event_log_id": id, "lossy": true]
        ]
        envelope["context"] = context
        return RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.legacyHookKind,
            dedupKey: "legacy-event-\(id)", receivedAt: receivedAt, payload: try json(envelope))
    }

    /// An orphan transcript line as `legacy_split.py convert` builds it.
    static func orphanLine(legacyID: Int, line: String = assistantLine, lineNo: Int = 2) throws -> RawRecord {
        let hash = SHA256Hex.of(line)
        let payload: [String: Any] = [
            "byte_offset": -1, "file": transcriptFile, "line": line, "line_no": lineNo,
            "subagent_file": false, "legacy_line_id": legacyID
        ]
        return RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.transcriptKind,
            dedupKey: "\(sessionID):legacy-line-\(legacyID):\(hash)", receivedAt: receivedAt,
            payload: try json(payload))
    }

    /// The same line read live from the transcript at `offset`.
    static func liveLine(line: String = assistantLine, lineNo: Int = 2, offset: Int64) throws -> RawRecord {
        let payload = ClaudeTranscriptPayload(
            file: transcriptFile, lineNo: lineNo, subagentFile: false, line: line, byteOffset: offset)
        return RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.transcriptKind,
            dedupKey: ClaudeTranscriptPayload.dedupKey(line: line, file: transcriptFile, byteOffset: offset),
            receivedAt: receivedAt, payload: try ClaudeTranscriptPayload.encode(payload))
    }

    private func normalize(_ record: RawRecord, id: Int64 = 1) throws -> NormalizedBatch {
        try ClaudeNormalizer().normalize(ArchivedRecord(id: id, record: record))
    }

    private func files() throws -> ClaudePipelineFiles {
        try ClaudePipelineFiles(directory: tmpDir.appendingPathComponent("pipeline"))
    }

    // MARK: - Normalizer

    func testHookLegacyEnvelopeNormalizesLikeAHookAndIgnoresLegacy() throws {
        let record = try Self.hookLegacy(
            id: 41, event: "PreToolUse",
            hookData: ["session_id": Self.sessionID, "cwd": "/Users/dev/work/myapp", "tool_name": "Read",
                       "tool_use_id": "toolu_1"],
            context: ["pid": 123])
        let batch = try normalize(record)

        XCTAssertEqual(batch.events.count, 1)
        let event = try XCTUnwrap(batch.events.first)
        XCTAssertEqual(event.dedupKey, "legacy-event-41")
        XCTAssertEqual(event.kind, .toolCall)
        XCTAssertEqual(event.toolName, "Read")
        XCTAssertEqual(event.cwd, "/Users/dev/work/myapp")
        XCTAssertEqual(event.attrs["tool_use_id"], .string("toolu_1"))
        XCTAssertEqual(event.attrs["account_email"], .string("dev@example.com"))
        XCTAssertNil(event.attrs["legacy"])
        XCTAssertEqual(batch.sessions.first?.account, "dev@example.com")

        // The `legacy` object changes nothing: the same envelope without it is the same batch.
        var envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: record.payload) as? [String: Any])
        envelope["legacy"] = nil
        let plain = RawRecord(
            provider: record.provider, sourceKind: ClaudeProvider.hookKind, dedupKey: record.dedupKey,
            receivedAt: record.receivedAt, payload: try Self.json(envelope))
        XCTAssertEqual(try normalize(plain), batch)
    }

    func testHookLegacyWithOnlySessionAndCwdStillNormalizes() throws {
        let batch = try normalize(try Self.hookLegacy(
            id: 7, event: "Stop", hookData: ["session_id": Self.sessionID, "cwd": "/Users/dev/work/myapp"]))
        XCTAssertEqual(batch.events.map(\.providerType), ["Stop"])
        XCTAssertEqual(batch.sessions.map(\.sessionID), [Self.sessionID])
    }

    func testHookLegacyWithEmptySessionIsSkippedNotFailed() throws {
        let record = try Self.hookLegacy(id: 8, event: "StatusLine", hookData: ["session_id": "", "cwd": "/x"])
        let batch = try normalize(record)
        XCTAssertTrue(batch.isEmpty)
    }

    func testHookLegacyWithUnreadableTimestampFallsBackToReceivedAt() throws {
        let batch = try normalize(try Self.hookLegacy(
            id: 9, event: "Stop", hookData: ["session_id": Self.sessionID, "cwd": "/x"], timestamp: "not a time"))
        XCTAssertEqual(batch.events.first?.time, Self.receivedAt)
    }

    func testOrphanTranscriptPayloadDecodesAndNormalizes() throws {
        let record = try Self.orphanLine(legacyID: 900)
        let payload = try ClaudeTranscriptPayload.decode(record.payload)
        XCTAssertEqual(payload.byteOffset, -1)
        XCTAssertEqual(payload.lineNo, 2)

        let batch = try normalize(record)
        XCTAssertEqual(batch.turns.map(\.dedupKey), ["msg_legacy_01"])
        XCTAssertEqual(batch.messages.map(\.uuid), ["0a1b2c3d-0002-4000-8000-000000000002"])
        XCTAssertEqual(batch.messages.first?.text, "Reading it now.")
        XCTAssertEqual(batch.sessions.first?.sessionID, Self.sessionID)
    }

    // MARK: - Replay

    func testOrphanAndLiveCopiesOfOneLineYieldOneTurnAndOneMessage() throws {
        let files = try files()
        try files.archive.append([try Self.orphanLine(legacyID: 900), try Self.liveLine(offset: 4_321)])

        let result = try ClaudeArchiveReplay.run(files: files)

        XCTAssertEqual(result.records, 2)
        XCTAssertEqual(result.failed, 0)
        let counts = try files.store.counts()
        XCTAssertEqual(counts.turns, 1)
        XCTAssertEqual(counts.messages, 1)
    }

    func testReplayCountsResumesAndRecordsLastRawID() throws {
        let files = try files()
        try files.archive.append([
            try Self.hookLegacy(id: 1, event: "SessionStart", hookData: ["session_id": Self.sessionID, "cwd": "/x"]),
            try Self.hookLegacy(id: 2, event: "UserPromptSubmit",
                                hookData: ["session_id": Self.sessionID, "cwd": "/x", "prompt": "hi"]),
            try Self.hookLegacy(id: 3, event: "StatusLine", hookData: ["session_id": "", "cwd": "/x"]),
            try Self.orphanLine(legacyID: 900),
            RawRecord(provider: ClaudeProvider.name, sourceKind: ClaudeProvider.legacyHookKind,
                      dedupKey: "legacy-event-4", receivedAt: Self.receivedAt, payload: Data("{not json".utf8))
        ])

        let first = try ClaudeArchiveReplay.run(files: files, chunk: 2)
        XCTAssertEqual(first.records, 5)
        XCTAssertEqual(first.replayed, 3)
        XCTAssertEqual(first.skipped, 1)
        XCTAssertEqual(first.skippedIDs, [3])
        XCTAssertEqual(first.failed, 1)
        XCTAssertEqual(first.failures.map(\.rawID), [5])
        XCTAssertEqual(first.lastRawID, 5)
        XCTAssertEqual(try ClaudeArchiveReplay.lastRawID(in: files.store), 5)
        let counts = try files.store.counts()
        XCTAssertEqual(counts.events, 2)
        XCTAssertEqual(counts.turns, 1)
        XCTAssertEqual(counts.messages, 1)

        // Nothing new: nothing replayed again, but the earlier failure is still reported.
        let second = try ClaudeArchiveReplay.run(files: files)
        XCTAssertEqual(second.records, 0)
        XCTAssertEqual(second.lastRawID, 5)
        XCTAssertEqual(second.failedThisRun, 0)
        XCTAssertEqual(second.failures.map(\.rawID), [5])

        // One more record: only it is read.
        try files.archive.append([
            try Self.hookLegacy(id: 6, event: "Stop", hookData: ["session_id": Self.sessionID, "cwd": "/x"])
        ])
        let third = try ClaudeArchiveReplay.run(files: files)
        XCTAssertEqual(third.records, 1)
        XCTAssertEqual(third.replayed, 1)
        XCTAssertEqual(third.lastRawID, 6)
        XCTAssertEqual(try files.store.counts().events, 3)
    }

    func testReportJSONHasTheDocumentedKeys() throws {
        var result = ClaudeArchiveReplayResult()
        result.records = 3
        result.replayed = 1
        result.skipped = 1
        result.skippedIDs = [2]
        result.failed = 1
        result.failures = [.init(rawID: 3, error: "unparseable(\"k\")")]
        result.lastRawID = 3
        result.seconds = 0.5
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: result.jsonData()) as? [String: Any])
        XCTAssertEqual(Set(object.keys), [
            "records", "replayed", "skipped", "skipped_ids", "failed", "failed_this_run", "failures",
            "last_raw_id", "interrupted", "recovered_bulk_load", "seconds"
        ])
        XCTAssertEqual(object["last_raw_id"] as? Int, 3)
        let failures = try XCTUnwrap(object["failures"] as? [[String: Any]])
        XCTAssertEqual(failures.first?["raw_id"] as? Int, 3)
    }

    // MARK: - Stopping part-way

    /// Four good hook records and one unparseable one (id 1).
    private func appendFive(to files: ClaudePipelineFiles) throws {
        let hook: (Int, String) throws -> RawRecord = { id, event in
            try Self.hookLegacy(id: id, event: event, hookData: ["session_id": Self.sessionID, "cwd": "/x"])
        }
        try files.archive.append([
            RawRecord(provider: ClaudeProvider.name, sourceKind: ClaudeProvider.legacyHookKind,
                      dedupKey: "legacy-event-1", receivedAt: Self.receivedAt, payload: Data("{oops".utf8)),
            try hook(2, "SessionStart"), try hook(3, "UserPromptSubmit"), try hook(4, "PreToolUse"),
            try hook(5, "Stop")
        ])
    }

    func testStopAfterTheFirstChunkEndsBulkLoadAndTheResumeNeitherSkipsNorDoubles() throws {
        let files = try files()
        try appendFive(to: files)
        let expectedIndexes = try files.store.indexNames()
        let chunks = Counter()

        let first = try ClaudeArchiveReplay.run(
            files: files, chunk: 2, shouldContinue: { chunks.value < 1 }, progress: { _ in chunks.increment() })

        XCTAssertTrue(first.interrupted)
        XCTAssertEqual(first.records, 2)
        XCTAssertEqual(first.lastRawID, 2)
        XCTAssertEqual(try ClaudeArchiveReplay.lastRawID(in: files.store), 2)
        XCTAssertEqual(first.failures.map(\.rawID), [1])
        XCTAssertFalse(try files.store.isInBulkLoad())
        XCTAssertEqual(try files.store.indexNames(), expectedIndexes)
        XCTAssertEqual(try files.store.counts().events, 1)

        let second = try ClaudeArchiveReplay.run(files: files, chunk: 2)
        XCTAssertFalse(second.interrupted)
        XCTAssertEqual(second.records, 3)
        XCTAssertEqual(second.lastRawID, 5)
        XCTAssertEqual(second.failedThisRun, 0)
        XCTAssertEqual(second.failures.map(\.rawID), [1])

        // The same archive replayed in one go gives the same rows.
        let whole = try ClaudePipelineFiles(directory: tmpDir.appendingPathComponent("whole"))
        try appendFive(to: whole)
        _ = try ClaudeArchiveReplay.run(files: whole, chunk: 2)
        XCTAssertEqual(try files.store.canonicalDump(), try whole.store.canonicalDump())
        XCTAssertEqual(try files.store.counts().events, 4)
    }

    func testFailuresSurviveAStoreErrorAndALeftOverBulkLoadIsRecoveredOnOpen() throws {
        let directory = tmpDir.appendingPathComponent("pipeline")
        let files = try files()
        try appendFive(to: files)
        let eventsPath = directory.appendingPathComponent(EventStore.fileName).path
        let chunks = Counter()

        // After chunk 1 commits, take the events table away so chunk 2's write (and
        // the index rebuild) fails: the run stops with events.db still in bulk load.
        XCTAssertThrowsError(try ClaudeArchiveReplay.run(files: files, chunk: 2, progress: { _ in
            chunks.increment()
            guard chunks.value == 1 else { return }
            let queue = try? DatabaseQueue(path: eventsPath)
            try? queue?.write { try $0.execute(sql: "ALTER TABLE events RENAME TO events_away") }
        })) { error in
            let stopped = error as? ClaudeArchiveReplayStopped
            XCTAssertNotNil(stopped)
            XCTAssertEqual(stopped?.partial.interrupted, true)
            XCTAssertEqual(stopped?.partial.lastRawID, 2)
            XCTAssertEqual(stopped?.partial.failures.map(\.rawID), [1])
        }
        XCTAssertTrue(try files.store.isInBulkLoad())
        let queue = try DatabaseQueue(path: eventsPath)
        try queue.write { try $0.execute(sql: "ALTER TABLE events_away RENAME TO events") }

        // The next open finds the bulk load and rebuilds the indexes.
        let reopened = try ClaudePipelineFiles(directory: directory)
        XCTAssertTrue(reopened.store.recoveredBulkLoad)
        XCTAssertFalse(try reopened.store.isInBulkLoad())
        XCTAssertTrue(try reopened.store.indexNames().contains("events_session_time"))

        let resumed = try ClaudeArchiveReplay.run(files: reopened, chunk: 2)
        XCTAssertTrue(resumed.recoveredBulkLoad)
        XCTAssertEqual(resumed.records, 3)
        XCTAssertEqual(resumed.failedThisRun, 0)
        XCTAssertEqual(resumed.failed, 1)
        XCTAssertEqual(resumed.failures.map(\.rawID), [1])
        XCTAssertEqual(try reopened.store.counts().events, 4)

        // A fresh EventStore on a healthy file recovers nothing.
        XCTAssertFalse(try EventStore(path: eventsPath).recoveredBulkLoad)
    }

    // MARK: - Background backfill

    func testBackfillWithNoTargetDoesNothing() throws {
        let files = try files()
        try appendFive(to: files)
        let status = try ClaudeArchiveReplay.backfillStatus(in: files.store)
        XCTAssertNil(status.target)
        XCTAssertFalse(status.pending)
        let result = try ClaudeArchiveReplay.backfill(archive: files.archive, store: files.store)
        XCTAssertEqual(result.records, 0)
        XCTAssertEqual(try files.store.counts().events, 0)
    }

    func testBackfillReplaysInSlicesUpToTheTargetAndLeavesLaterRecordsToTheDrain() throws {
        let files = try files()
        try appendFive(to: files)
        // The cutover's target; record 6 arrives later and is the live drain's.
        try files.store.setMetaValue("5", forKey: ClaudeArchiveReplay.backfillTargetKey)
        try files.archive.append([
            try Self.hookLegacy(id: 6, event: "Stop", hookData: ["session_id": Self.sessionID, "cwd": "/x"])
        ])
        let expectedIndexes = try files.store.indexNames()
        XCTAssertEqual(try ClaudeArchiveReplay.backfillStatus(in: files.store),
                       ClaudeArchiveReplay.BackfillStatus(target: 5, lastRawID: 0))

        // A slice that ends after one chunk.
        let chunks = Counter()
        let first = try ClaudeArchiveReplay.backfill(
            archive: files.archive, store: files.store, chunk: 2,
            shouldContinue: { chunks.value < 1 }, progress: { _ in chunks.increment() })
        XCTAssertTrue(first.interrupted)
        XCTAssertEqual(first.lastRawID, 2)
        XCTAssertEqual(first.failures.map(\.rawID), [1])
        let midway = try ClaudeArchiveReplay.backfillStatus(in: files.store)
        XCTAssertTrue(midway.pending)
        XCTAssertEqual(midway.remaining, 3)
        XCTAssertEqual(try files.store.indexNames(), expectedIndexes)

        let second = try ClaudeArchiveReplay.backfill(archive: files.archive, store: files.store, chunk: 2)
        XCTAssertFalse(second.interrupted)
        XCTAssertEqual(second.records, 3)
        XCTAssertEqual(second.lastRawID, 5)
        XCTAssertEqual(second.failures.map(\.rawID), [1])
        XCTAssertFalse(try ClaudeArchiveReplay.backfillStatus(in: files.store).pending)
        // Records 2…5 only; record 6 was never read.
        XCTAssertEqual(try files.store.counts().events, 4)

        // Done: another call reads nothing.
        let third = try ClaudeArchiveReplay.backfill(archive: files.archive, store: files.store)
        XCTAssertEqual(third.records, 0)
        XCTAssertEqual(third.lastRawID, 5)
    }

    func testBackfillReachesATargetPastTheArchivesLastID() throws {
        let files = try files()
        try appendFive(to: files)
        try files.store.setMetaValue("9", forKey: ClaudeArchiveReplay.backfillTargetKey)
        let result = try ClaudeArchiveReplay.backfill(archive: files.archive, store: files.store)
        XCTAssertFalse(result.interrupted)
        XCTAssertEqual(result.lastRawID, 9)
        XCTAssertFalse(try ClaudeArchiveReplay.backfillStatus(in: files.store).pending)
    }

    func testPipelineFilesCreateAllThreeWithIncrementalVacuum() throws {
        let directory = tmpDir.appendingPathComponent("new/dir")
        _ = try ClaudePipelineFiles(directory: directory)
        for name in ["claude-raw.db", "claude-ingest.db", "events.db"] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent(name).path), name)
        }
        let queue = try DatabaseQueue(path: directory.appendingPathComponent("events.db").path)
        XCTAssertEqual(try queue.read { try Int.fetchOne($0, sql: "PRAGMA auto_vacuum") }, 2)
    }
}

/// A count shared with `@Sendable` callbacks.
private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() { lock.withLock { count += 1 } }
    var value: Int { lock.withLock { count } }
}

/// Lowercase hex SHA-256 of a string's UTF-8 bytes.
private enum SHA256Hex {
    static func of(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).hexString
    }
}
