import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

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
            claude: handles)
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
        XCTAssertFalse(handles.drainer.drainUntilEmpty().failed)
        let keys = try handles.archive.records(after: 0, limit: 10).map(\.record.dedupKey)
        XCTAssertEqual(keys, [ClaudePipelineHandles.quarantineDedupKey(file)])
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
}
