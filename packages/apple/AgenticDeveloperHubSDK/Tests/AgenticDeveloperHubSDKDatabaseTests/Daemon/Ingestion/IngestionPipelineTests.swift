import CryptoKit
import AgenticDeveloperHubSDKCore
import XCTest
import Foundation
@testable import AgenticDeveloperHubSDKDatabase

/// The composed capture-to-database path: a captured event is spooled, the drain
/// writes it, and the sink hears about it. Nothing is written to the main
/// database before the drain starts.
final class IngestionPipelineTests: XCTestCase {

    private var tmpDir: URL!
    private var database: DaemonDatabase!
    private var sink: RecordingSink!
    private var pipeline: IngestionPipeline!

    override func setUpWithError() throws {
        // Unix socket paths cap at 104 bytes on macOS, so keep the directory short.
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: "/tmp/pipe-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        database = try TestDaemonDatabase.makeSessionDatabase(
            path: tmpDir.appendingPathComponent("t.db").path
        ).db
        sink = RecordingSink()
        let drop = tmpDir.appendingPathComponent("drop")
        pipeline = IngestionPipeline(
            paths: .init(
                dropDirectory: drop,
                errorsDirectory: drop.appendingPathComponent("errors"),
                socketPath: tmpDir.appendingPathComponent("s").path
            ),
            spool: try IngestSpool(path: tmpDir.appendingPathComponent("ingest.db").path),
            database: database,
            sink: sink,
            queueLabel: { "test.\($0)" },
            decode: { _ in throw SocketDecodeFailure.malformed }
        )
    }

    override func tearDown() async throws {
        await pipeline.stop()
        pipeline = nil
        database = nil
        try? FileManager.default.removeItem(at: tmpDir)
    }

    /// The rows the legacy writer put in `event_log` for `sessionId` (the session
    /// readers now read the event store, which this writer does not feed).
    private func eventLogCount(sessionId: String) throws -> Int {
        var count = 0
        try database.query(
            "SELECT COUNT(*) FROM event_log WHERE session_id = ?", params: [sessionId]
        ) { count = database.int($0, 0) }
        return count
    }

    private func event(session: String) -> ParsedEvent {
        ParsedEvent(
            eventType: "PreToolUse", timestamp: "2026-01-01T00:00:00Z",
            hookData: ["session_id": session, "tool_name": "Bash"],
            context: nil, accountEmail: ""
        )
    }

    func testACapturedEventIsSpooledAndNotWrittenUntilTheDrainStarts() throws {
        try pipeline.capture(event(session: "s-p1"))

        XCTAssertEqual(pipeline.spool.pendingCount(), 1)
        XCTAssertEqual(try eventLogCount(sessionId: "s-p1"), 0)
        XCTAssertTrue(sink.events.isEmpty)
    }

    func testTheDrainWritesASpooledEventAndPublishesIt() async throws {
        try pipeline.capture(event(session: "s-p2"))
        pipeline.startDraining()

        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while ContinuousClock.now < deadline {
            if try eventLogCount(sessionId: "s-p2") == 1 { break }
            try await Task.sleep(for: .milliseconds(20))
        }

        XCTAssertEqual(try eventLogCount(sessionId: "s-p2"), 1)
        XCTAssertEqual(sink.events.first?.sessionId, "s-p2")
    }

    func testRetryIngestWritesStraightToTheDatabase() throws {
        try pipeline.retryIngest(event(session: "s-p3"))

        XCTAssertEqual(try eventLogCount(sessionId: "s-p3"), 1)
        XCTAssertEqual(pipeline.spool.pendingCount(), 0)
    }

    func testWriteDropFileFallbackLeavesAReadableEnvelope() throws {
        let dir = tmpDir.appendingPathComponent("spill")
        try IngestionPipeline.writeDropFile(event(session: "s-p4"), into: dir)

        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertEqual(files.count, 1)
        XCTAssertTrue(files[0].hasPrefix("spill-"))
        let raw = try String(contentsOf: dir.appendingPathComponent(files[0]), encoding: .utf8)
        guard case .event(let reread) = EventIngestor.parseEventFile(rawJson: raw) else {
            return XCTFail("the spill file must parse back into an event")
        }
        XCTAssertEqual(reread.eventType, "PreToolUse")
    }

    // MARK: - With the Claude pipeline

    private func claudePipeline() throws -> (IngestionPipeline, ClaudePipelineHandles) {
        let root = tmpDir.appendingPathComponent("claude")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let handles = try ClaudePipelineHandles(
            spool: try ProviderSpool(path: root.appendingPathComponent("claude-ingest.db").path,
                                     provider: ClaudeProvider.name),
            archive: try RawArchive(path: root.appendingPathComponent("claude-raw.db").path,
                                    provider: ClaudeProvider.name),
            store: try EventStore(path: root.appendingPathComponent("events.db").path),
            database: database,
            dropDirectory: root.appendingPathComponent("drop"),
            projectsDirectory: root.appendingPathComponent("projects"))
        let drop = root.appendingPathComponent("drop")
        let pipeline = IngestionPipeline(
            paths: .init(dropDirectory: drop, errorsDirectory: drop.appendingPathComponent("errors"),
                         socketPath: root.appendingPathComponent("s").path),
            spool: try IngestSpool(path: root.appendingPathComponent("ingest.db").path),
            database: database, sink: sink, queueLabel: { "test.claude.\($0)" },
            decode: { _ in throw SocketDecodeFailure.malformed },
            claude: ClaudePipelineSlot(handles))
        return (pipeline, handles)
    }

    func testWithClaudeACaptureGoesToTheClaudeSpoolNotTheLegacyOne() async throws {
        let (pipeline, handles) = try claudePipeline()
        try pipeline.capture(event(session: "s-c1"))

        XCTAssertEqual(try handles.spool.pendingCount(), 1)
        XCTAssertEqual(pipeline.spool.pendingCount(), 0)
        XCTAssertFalse(handles.drainer.drainUntilEmpty().failed)
        XCTAssertEqual(try handles.store.counts().events, 1)
        XCTAssertEqual(try eventLogCount(sessionId: "s-c1"), 0)
        await pipeline.stop()
    }

    func testWithClaudeARetryIsRecapturedIntoTheClaudeSpool() async throws {
        let (pipeline, handles) = try claudePipeline()
        try pipeline.retryIngest(event(session: "s-c2"))

        XCTAssertEqual(try handles.spool.pendingCount(), 1)
        XCTAssertEqual(try eventLogCount(sessionId: "s-c2"), 0)
        await pipeline.stop()
    }

    /// With the Claude pipeline, clearing the quarantine keeps every file's bytes
    /// in the raw archive under `quarantine-<name>` before deleting it.
    func testWithClaudeClearingTheQuarantinePreservesTheFilesInTheArchive() async throws {
        let (pipeline, handles) = try claudePipeline()
        let errors = pipeline.quarantine.errorsDirectory
        try FileManager.default.createDirectory(at: errors, withIntermediateDirectories: true)
        let file = errors.appendingPathComponent("error-keep.json")
        try Data(#"{"event":"Stop","hook_data":{}}"#.utf8).write(to: file)

        pipeline.quarantine.clear()

        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        let records = try handles.archive.records(after: 0, limit: 10).map(\.record)
        XCTAssertEqual(records.map(\.dedupKey), [ClaudePipelineHandles.quarantineDedupKey(file)],
                       "archived before the delete, with no drain needed")
        XCTAssertEqual(records.map(\.sourceKind), [ClaudeProvider.quarantineKind])
        XCTAssertEqual(records.first?.payload, Data(#"{"event":"Stop","hook_data":{}}"#.utf8))
        await pipeline.stop()
    }

    /// A cleared file is archive-only: a valid envelope adds no events.db row and
    /// no session, an unparseable one is not quarantined again, and neither goes
    /// through the spool.
    func testWithClaudeAClearedFileIsArchiveOnly() async throws {
        let (pipeline, handles) = try claudePipeline()
        let errors = pipeline.quarantine.errorsDirectory
        try FileManager.default.createDirectory(at: errors, withIntermediateDirectories: true)
        let valid = """
            {"event":"SessionStart","timestamp":"2026-01-01T00:00:00Z",\
            "hook_data":{"session_id":"s-cleared","cwd":"/tmp"}}
            """
        try Data(valid.utf8).write(to: errors.appendingPathComponent("error-valid.json"))
        try Data("not json at all".utf8).write(to: errors.appendingPathComponent("error-garbage.json"))

        pipeline.quarantine.clear()
        XCTAssertFalse(handles.drainer.drainUntilEmpty().failed)

        XCTAssertEqual(pipeline.quarantine.count(), 0)
        XCTAssertEqual(try handles.archive.count(), 2, "both files' bytes are in the archive")
        XCTAssertEqual(try handles.spool.pendingCount(), 0, "nothing went through the spool")
        XCTAssertEqual(handles.quarantinedCount(), 0, "nothing is quarantined again")
        XCTAssertEqual(try handles.store.counts(), EventStoreCounts(sessions: 0, events: 0, turns: 0, messages: 0))
        XCTAssertNil(try database.fetchSession(sessionId: "s-cleared"), "never applied to the main db")
        await pipeline.stop()
    }

    /// The archive-only kind normalizes to nothing, so a replay of the archive
    /// never turns a preserved file into an event.
    func testTheQuarantineKindNormalizesToNothing() throws {
        let record = RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.quarantineKind, dedupKey: "quarantine-x",
            receivedAt: Date(), payload: Data(#"{"event":"Stop","hook_data":{"session_id":"s"}}"#.utf8))
        XCTAssertTrue(try ClaudeNormalizer().normalize(ArchivedRecord(id: 1, record: record)).isEmpty)
    }

    /// An unreadable drop file is quarantined with a reason (listed, not "unknown"),
    /// and clearing the quarantine deletes it: it has no bytes to preserve.
    func testWithClaudeAnUnreadableDropIsQuarantinedWithAReasonAndClears() async throws {
        let (pipeline, handles) = try claudePipeline()
        let drop = handles.hookSource.dropDirectory
        try FileManager.default.createDirectory(at: drop, withIntermediateDirectories: true)
        let file = drop.appendingPathComponent("1793361600000-aaaaaaaa.json")
        try Data(#"{"event":"Stop","hook_data":{"session_id":"s"}}"#.utf8).write(to: file)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o000, .modificationDate: Date().addingTimeInterval(-60)], ofItemAtPath: file.path)
        try XCTSkipIf(FileManager.default.isReadableFile(atPath: file.path), "running with read override")

        XCTAssertEqual(try handles.pollHookDrops(), 0)
        let listed = pipeline.quarantine.list()
        XCTAssertEqual(listed.map(\.filename), ["error-1793361600000-aaaaaaaa.json"])
        XCTAssertTrue(listed.first?.reason.hasPrefix("unreadable drop file: ") ?? false, "\(listed)")

        pipeline.quarantine.clear()
        XCTAssertEqual(pipeline.quarantine.count(), 0, "nothing to preserve, so nothing holds it")
        XCTAssertEqual(try handles.archive.count(), 0)
        await pipeline.stop()
    }

    /// An empty drop file on the pipeline path leaves a terminal `lost` row in the
    /// ingestion-error log, as the legacy path does, and lights no badge.
    func testWithClaudeAnEmptyDropIsLoggedAsLost() async throws {
        let (pipeline, handles) = try claudePipeline()
        let drop = handles.hookSource.dropDirectory
        try FileManager.default.createDirectory(at: drop, withIntermediateDirectories: true)
        let file = drop.appendingPathComponent("1793361600000-aaaaaaaa.json")
        try Data().write(to: file)
        try FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(-60)], ofItemAtPath: file.path)

        XCTAssertEqual(try handles.pollHookDrops(), 1)
        let rows = try database.recentIngestionErrors()
        XCTAssertEqual(rows.map(\.filename), ["1793361600000-aaaaaaaa.json"])
        XCTAssertEqual(rows.first?.status, "lost")
        XCTAssertEqual(pipeline.quarantine.count(), 0)
        await pipeline.stop()
    }

    /// A hook record the normalizer refuses is listed from the spool quarantine
    /// with its event, session and reason, once it is out of attempts.
    func testWithClaudeASpoolQuarantinedHookIsListed() async throws {
        let (pipeline, handles) = try claudePipeline()
        try handles.spool.append([RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.hookKind,
            dedupKey: "1793361600000-aaaaaaaa", receivedAt: Date(),
            payload: Data(#"{"event":"Stop","hook_data":{"session_id":"s1"},"timestamp":5}"#.utf8))])
        try handles.spool.quarantine(id: try XCTUnwrap(handles.spool.pendingBatch(limit: 1).first?.id),
                                     reason: "refused")

        let listed = handles.quarantinedErrors()
        XCTAssertEqual(listed.map(\.filename), ["1793361600000-aaaaaaaa"])
        XCTAssertEqual(listed.first?.eventType, "Stop")
        XCTAssertEqual(listed.first?.sessionId, "s1")
        XCTAssertEqual(listed.first?.reason, "refused")
        XCTAssertEqual(listed.first?.exhausted, true)
        XCTAssertEqual(handles.quarantinedCount(), listed.count)
        await pipeline.stop()
    }

    /// Preserving a file whose key already holds other bytes (a reused file name)
    /// keeps the new bytes under the key with their sha256 appended.
    func testWithClaudeAReusedFileNameIsPreservedUnderAFallbackKey() async throws {
        let (pipeline, handles) = try claudePipeline()
        let errors = pipeline.quarantine.errorsDirectory
        try FileManager.default.createDirectory(at: errors, withIntermediateDirectories: true)
        let file = errors.appendingPathComponent("error-reused.json")
        try Data("first".utf8).write(to: file)
        try handles.preserveQuarantinedFile(file)
        try Data("second".utf8).write(to: file)
        try handles.preserveQuarantinedFile(file)
        try handles.preserveQuarantinedFile(file)

        let records = try handles.archive.records(after: 0, limit: 10).map(\.record)
        XCTAssertEqual(records.map { String(bytes: $0.payload, encoding: .utf8) }, ["first", "second"],
                       "both versions kept, the second once")
        XCTAssertTrue(records[1].dedupKey.hasPrefix(ClaudePipelineHandles.quarantineDedupKey(file) + "-"))
        await pipeline.stop()
    }

    /// A retried quarantine file's exact bytes go to the archive under
    /// `quarantine-<name>` before the file is deleted, and the re-captured event
    /// reaches events.db; retrying the same bytes again adds no archive row.
    func testWithClaudeARetriedFileIsArchivedVerbatimBeforeItIsDeleted() async throws {
        let (pipeline, handles) = try claudePipeline()
        let errors = pipeline.quarantine.errorsDirectory
        try FileManager.default.createDirectory(at: errors, withIntermediateDirectories: true)
        let bytes = """
            {"event":"PreToolUse","timestamp":"2026-01-01T00:00:00Z","unknown_top_level":1,\
            "hook_data":{"session_id":"s-retry","cwd":"/tmp","tool_name":"Bash"}}
            """
        let file = errors.appendingPathComponent("error-retry.json")
        try Data(bytes.utf8).write(to: file)
        pipeline.quarantine.recordInitialQuarantine(eventURL: file, reason: "r", code: nil, parsed: nil)

        let result = pipeline.quarantine.retryDueBatch(
            limit: 10, parse: { EventIngestor.parseEventFile(rawJson: $0) }, ingest: pipeline.retryIngest)
        XCTAssertEqual(result.recovered, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))

        let keyed = try XCTUnwrap(try handles.archive.id(forDedupKey: ClaudePipelineHandles.quarantineDedupKey(file)))
        let archived = try XCTUnwrap(try handles.archive.record(id: keyed))
        XCTAssertEqual(archived.record.payload, Data(bytes.utf8), "the exact bytes, unknown keys and all")
        XCTAssertEqual(archived.record.sourceKind, ClaudeProvider.quarantineKind)
        XCTAssertFalse(handles.drainer.drainUntilEmpty().failed)
        XCTAssertEqual(try handles.store.counts().events, 1, "the retried event itself still reaches events.db")

        // The same file retried again (a crash before its delete) keeps one row.
        let before = try handles.archive.count()
        try Data(bytes.utf8).write(to: file)
        try handles.preserveQuarantinedFile(file)
        XCTAssertEqual(try handles.archive.count(), before)
        await pipeline.stop()
    }

    /// The import walks the transcripts into the Claude spool; a dry run only
    /// counts the files. Neither touches the legacy tables.
    func testImportTranscriptsSpoolsLinesAndADryRunOnlyCounts() async throws {
        let (pipeline, handles) = try claudePipeline()
        let project = handles.transcriptSource.projectsDirectory.appendingPathComponent("-work")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        let line = """
            {"type":"user","sessionId":"imp-1","uuid":"u1","timestamp":"2026-04-14T10:00:00Z",\
            "cwd":"/work","message":{"role":"user","content":"hi"}}

            """
        try line.write(to: project.appendingPathComponent("imp-1.jsonl"), atomically: true, encoding: .utf8)

        let dry = handles.importTranscripts(ImportRequestDTO(dryRun: true))
        XCTAssertEqual(dry.filesScanned, 1)
        XCTAssertEqual(dry.linesSeen, 0)
        XCTAssertEqual(try handles.spool.pendingCount(), 0, "a dry run spools nothing")

        let real = handles.importTranscripts(ImportRequestDTO())
        XCTAssertEqual(real.filesScanned, 1)
        XCTAssertEqual(real.linesInserted, 1)
        XCTAssertTrue(real.errors.isEmpty, "\(real.errors)")
        XCTAssertEqual(try handles.spool.pendingCount(), 1)
        XCTAssertFalse(handles.drainer.drainUntilEmpty().failed)
        XCTAssertEqual(try handles.archive.count(), 1)
        XCTAssertEqual(try eventLogCount(sessionId: "imp-1"), 0)
        await pipeline.stop()
    }

    // MARK: - Legacy writers off

    /// No Claude pipeline and the fallback off: a capture waits in the legacy
    /// spool, the legacy drain does not start, and a retry is held.
    func testWithoutClaudeAndNoFallbackNothingReachesTheLegacyWriter() async throws {
        let root = tmpDir.appendingPathComponent("nofallback")
        let drop = root.appendingPathComponent("drop")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let held = IngestionPipeline(
            paths: .init(dropDirectory: drop, errorsDirectory: drop.appendingPathComponent("errors"),
                         socketPath: root.appendingPathComponent("s").path),
            spool: try IngestSpool(path: root.appendingPathComponent("ingest.db").path),
            database: database, sink: sink, queueLabel: { "test.held.\($0)" },
            decode: { _ in throw SocketDecodeFailure.malformed },
            legacyWriterFallback: false)
        XCTAssertFalse(held.legacyWriters)

        try held.capture(event(session: "s-held"))
        held.startDraining()
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(held.spool.pendingCount(), 1, "the capture must wait in the legacy spool")
        XCTAssertEqual(try eventLogCount(sessionId: "s-held"), 0)
        XCTAssertThrowsError(try held.retryIngest(event(session: "s-held"))) { error in
            XCTAssertTrue(error is QuarantineRetryHeld, "\(error)")
        }
        await held.stop()
    }

    /// A ConfigChange captured while the Claude pipeline is closed waits in the
    /// legacy spool already stamped with its file's fingerprint at event time.
    func testACaptureHeldInTheLegacySpoolIsStampedAtCapture() async throws {
        let root = tmpDir.appendingPathComponent("heldstamp")
        let drop = root.appendingPathComponent("drop")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let file = root.appendingPathComponent("settings.json")
        let contents = Data(#"{"theme":"dark"}"#.utf8)
        try contents.write(to: file)
        let held = IngestionPipeline(
            paths: .init(dropDirectory: drop, errorsDirectory: drop.appendingPathComponent("errors"),
                         socketPath: root.appendingPathComponent("s").path),
            spool: try IngestSpool(path: root.appendingPathComponent("ingest.db").path),
            database: database, sink: sink, queueLabel: { "test.heldstamp.\($0)" },
            decode: { _ in throw SocketDecodeFailure.malformed },
            legacyWriterFallback: false)

        try held.capture(ParsedEvent(
            eventType: "ConfigChange", timestamp: "2026-06-01T12:00:00Z",
            hookData: ["session_id": "s-stamp", "file_path": file.path], context: nil, accountEmail: ""))
        // The file changes before the pipeline opens; the stamp is the old one.
        try Data("rewritten".utf8).write(to: file)

        let spooled = try XCTUnwrap(try held.spool.pendingBatch(limit: 10).first)
        let envelope = try XCTUnwrap(try JSONSerialization.jsonObject(with: spooled.envelope) as? [String: Any])
        let hookData = try XCTUnwrap(envelope["hook_data"] as? [String: Any])
        XCTAssertEqual(hookData["file_size_bytes"] as? Int, contents.count)
        XCTAssertEqual(hookData["file_sha256"] as? String,
                       SHA256.hash(data: contents).map { String(format: "%02x", $0) }.joined())
        await held.stop()
    }
}
