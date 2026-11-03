import AgenticToolkitCore
import Foundation
import GRDB
import XCTest
@testable import AgenticToolkitDatabase

/// The Claude pipeline as the runtime assembles it: drop files and transcript lines
/// in, through the spool, the archive and the event store, out to the session
/// database and the live observer. Nothing reaches the legacy `event_log`.
final class ClaudePipelineEndToEndTests: XCTestCase {

    private var tmpDir: URL!
    private var paths: [String] = []

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-claude-e2e-\(suffix)")
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
    private static let hookStems = ["SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop"]
    private static let transcriptStems = ["user-string", "assistant"]

    /// Records every enrichment call.
    private final class EnrichmentLog: @unchecked Sendable {
        private let lock = NSLock()
        private var entries: [String] = []
        var calls: [String] { lock.withLock { entries } }
        func add(_ entry: String) { lock.withLock { entries.append(entry) } }

        var hooks: ClaudeEnrichmentHooks {
            ClaudeEnrichmentHooks(
                noteTranscriptActivity: { _, sessionId in self.add("tail \(sessionId)") },
                enrichOnStart: { sessionId, _, _ in self.add("start \(sessionId)") },
                onStopOrEnd: { sessionId, _ in self.add("stop \(sessionId)") },
                healProjectRoot: { _ in })
        }
    }

    private struct Assembly {
        let root: URL
        let database: DaemonDatabase
        let handles: ClaudePipelineHandles
        let sink: RecordingSink
        let log: EnrichmentLog
        let observer: ClaudeLiveObserver

        var dropDirectory: URL { root.appendingPathComponent("drop") }
        var projectsDirectory: URL { root.appendingPathComponent("projects") }
    }

    /// The runtime's `openPhaseA` wiring, rooted in its own directory.
    private func assemble(_ name: String,
                          fault: (@Sendable (DrainStep) throws -> Void)? = nil) throws -> Assembly {
        let root = tmpDir.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let resolver = AccountResolver(claudeJSONPath: root.appendingPathComponent("no-claude.json").path)
        let made = try TestDaemonDatabase.makeSessionDatabase(accountResolver: resolver)
        paths.append(made.path)
        let harness = try ClaudePipelineTestHarness(directory: root, database: made.db, drainerFaultInjector: fault)
        let sink = RecordingSink()
        let log = EnrichmentLog()
        let observer = ClaudeLiveObserver(eventReads: harness.store, sink: sink, enrichment: log.hooks)
        harness.handles.drainer.addObserver(observer)
        return Assembly(root: root, database: made.db, handles: harness.handles, sink: sink, log: log,
                        observer: observer)
    }

    /// A fresh drainer over the same files: what a restarted daemon builds.
    private func restarted(_ assembly: Assembly) throws -> ClaudePipelineHandles {
        try ClaudePipelineHandles(
            spool: assembly.handles.spool, archive: assembly.handles.archive, store: assembly.handles.store,
            database: assembly.database, dropDirectory: assembly.dropDirectory,
            projectsDirectory: assembly.projectsDirectory)
    }

    /// Writes the hook fixtures as drop files (named as the hook helper names them,
    /// old enough to be ready) and the transcript fixtures as one session file.
    private func writeInput(_ assembly: Assembly) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: assembly.dropDirectory, withIntermediateDirectories: true)
        let past = Date().addingTimeInterval(-60)
        for (index, stem) in Self.hookStems.enumerated() {
            let data = try Data(contentsOf: Self.fixtures.appendingPathComponent("hooks/\(stem).json"))
            let file = assembly.dropDirectory.appendingPathComponent(
                "\(1_793_400_000_000 + index)-\(String(format: "%08x", index)).json")
            try data.write(to: file)
            try fileManager.setAttributes([.modificationDate: past], ofItemAtPath: file.path)
        }
        let lines = try Self.transcriptStems.map { stem in
            try String(contentsOf: Self.fixtures.appendingPathComponent("transcripts/\(stem).jsonl"), encoding: .utf8)
                .trimmingCharacters(in: .newlines)
        }
        let folder = assembly.projectsDirectory.appendingPathComponent("-Users-dev-work-myapp")
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        try (lines.joined(separator: "\n") + "\n")
            .write(to: folder.appendingPathComponent("\(Self.sessionID).jsonl"), atomically: true, encoding: .utf8)
    }

    private func pollInput(_ handles: ClaudePipelineHandles) throws {
        XCTAssertEqual(try handles.pollHookDrops(), Self.hookStems.count)
        XCTAssertEqual(try handles.pollTranscripts(), Self.transcriptStems.count)
    }

    // MARK: - Dumps

    /// Main-database columns stamped with the wall clock when the row is written
    /// (`datetime('now')`), so two databases built a second apart differ there and
    /// nowhere else. `updated_at` is that in every table that has one; otherwise only
    /// these. `sessions.started_at` is the column default: the hook insert never
    /// sets it. Event-time columns elsewhere (`agent_dispatches.started_at`) are compared.
    private static let wallClockColumns: [String: Set<String>] = [
        "sessions": ["started_at"],
        "schema_migrations": ["applied_at"]
    ]

    private static func isWallClock(table: String, column: String) -> Bool {
        column == "updated_at" || wallClockColumns[table]?.contains(column) == true
    }

    private func dump(_ database: DaemonDatabase, table: String) throws -> [String] {
        try database.write { conn in
            let columns = try Row.fetchAll(conn, sql: "PRAGMA table_info(\(table))")
                .map { $0["name"] as String }
                .filter { !Self.isWallClock(table: table, column: $0) }
            let list = columns.map { "\"\($0)\"" }.joined(separator: ", ")
            return try Row.fetchAll(conn, sql: "SELECT \(list) FROM \(table) ORDER BY \(list)")
                .map { row in zip(columns, row.databaseValues).map { "\($0)=\($1)" }.joined(separator: " ") }
        }
    }

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

    private func count(_ database: DaemonDatabase, _ sql: String) throws -> Int {
        try database.write { conn in try Int.fetchOne(conn, sql: sql) ?? 0 }
    }

    // MARK: - Tests

    func testDropFilesAndTranscriptLinesReachEveryStoreAndNotTheLegacyLog() throws {
        let assembly = try assemble("clean")
        try writeInput(assembly)
        try pollInput(assembly.handles)

        let outcome = assembly.handles.drainer.drainUntilEmpty()
        XCTAssertFalse(outcome.failed, outcome.failureReason ?? "")
        XCTAssertEqual(try assembly.handles.spool.pendingCount(), 0)
        XCTAssertEqual(try assembly.handles.spool.quarantinedCount(), 0)

        // The drop files are consumed; the raw archive keeps every record.
        let leftover = try FileManager.default.contentsOfDirectory(atPath: assembly.dropDirectory.path)
            .filter { $0.hasSuffix(".json") }
        XCTAssertEqual(leftover, [])
        XCTAssertEqual(try assembly.handles.archive.count(), Self.hookStems.count + Self.transcriptStems.count)

        // events.db holds the events, the assistant turn and the messages.
        let counts = try assembly.handles.store.counts()
        XCTAssertGreaterThanOrEqual(counts.events, Self.hookStems.count)
        XCTAssertGreaterThanOrEqual(counts.turns, 1)
        XCTAssertGreaterThanOrEqual(counts.messages, 1)

        // The session database has the session, and the legacy writers wrote nothing.
        XCTAssertEqual(try count(
            assembly.database, "SELECT COUNT(*) FROM sessions WHERE session_id = '\(Self.sessionID)'"), 1)
        XCTAssertEqual(try count(assembly.database, "SELECT COUNT(*) FROM event_log"), 0)

        // The observer published the hook events and ran their enrichment.
        XCTAssertTrue(Set(Self.hookStems).isSubset(of: Set(assembly.sink.eventTypes)),
                      "published: \(assembly.sink.eventTypes)")
        XCTAssertTrue(assembly.log.calls.contains("start \(Self.sessionID)"))
        XCTAssertTrue(assembly.log.calls.contains("stop \(Self.sessionID)"))

        // The database hands Tasks 6-9 the same store and archive.
        XCTAssertTrue(assembly.database.eventReads === assembly.handles.store)
        XCTAssertTrue(assembly.database.rawArchive === assembly.handles.archive)

        // Review M8: session_metrics carries the transcript's token totals, and a
        // second batch adds to them rather than replacing them. turn_count counts
        // the user line's turn too, as the legacy transcript_turns count does.
        XCTAssertEqual(try metrics(assembly.database), Metrics(
            input: 4, output: 12, cacheRead: 18_000, cacheCreation: 2_400, turns: 2, model: "claude-opus-4-1"))
        try appendSecondAssistantTurn(assembly)
        XCTAssertEqual(try assembly.handles.pollTranscripts(), 1)
        XCTAssertFalse(assembly.handles.drainer.drainUntilEmpty().failed)
        XCTAssertEqual(try metrics(assembly.database), Metrics(
            input: 8, output: 24, cacheRead: 36_000, cacheCreation: 4_800, turns: 3, model: "claude-opus-4-1"))
    }

    // MARK: - Session metrics

    private struct Metrics: Equatable {
        let input: Int
        let output: Int
        let cacheRead: Int
        let cacheCreation: Int
        let turns: Int
        let model: String
    }

    private func metrics(_ database: DaemonDatabase) throws -> Metrics? {
        try database.write { conn in
            try Row.fetchOne(conn, sql: """
                SELECT total_input_tokens, total_output_tokens, cache_read_tokens, cache_creation_tokens,
                       turn_count, model
                FROM session_metrics WHERE session_id = ?
                """, arguments: [Self.sessionID]).map { row in
                Metrics(input: row["total_input_tokens"], output: row["total_output_tokens"],
                        cacheRead: row["cache_read_tokens"], cacheCreation: row["cache_creation_tokens"],
                        turns: row["turn_count"], model: row["model"])
            }
        }
    }

    /// Appends the assistant fixture again as a new message (its own message id,
    /// uuid and a later timestamp) to the session's transcript.
    private func appendSecondAssistantTurn(_ assembly: Assembly) throws {
        let line = try String(
            contentsOf: Self.fixtures.appendingPathComponent("transcripts/assistant.jsonl"), encoding: .utf8)
            .trimmingCharacters(in: .newlines)
            .replacingOccurrences(of: "msg_01XyZAbCdEfGhIjKlMnOpQrS", with: "msg_02XyZAbCdEfGhIjKlMnOpQrS")
            .replacingOccurrences(of: "0a1b2c3d-0002-4000-8000-000000000002",
                                  with: "0a1b2c3d-0003-4000-8000-000000000003")
            .replacingOccurrences(of: "2026-10-30T12:00:05.000Z", with: "2026-10-30T12:00:09.000Z")
        let file = assembly.projectsDirectory
            .appendingPathComponent("-Users-dev-work-myapp/\(Self.sessionID).jsonl")
        let handle = try FileHandle(forWritingTo: file)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data((line + "\n").utf8))
    }

    func testCaptureSpoolsAHookRecordAndWakesTheDrainer() throws {
        let assembly = try assemble("capture")
        let payload = try Data(contentsOf: Self.fixtures.appendingPathComponent("hooks/SessionStart.json"))
        guard case .event(let parsed) = ParseResult.parse(
            envelopeJSON: String(bytes: payload, encoding: .utf8) ?? "") else {
            return XCTFail("fixture did not parse")
        }

        try assembly.handles.capture(parsed)
        XCTAssertEqual(try assembly.handles.spool.pendingCount(), 1)
        XCTAssertFalse(assembly.handles.drainer.drainUntilEmpty().failed)
        let archived = try assembly.handles.archive.records(after: 0, limit: 10)
        XCTAssertEqual(archived.map(\.record.sourceKind), [ClaudeProvider.legacyHookKind])
        XCTAssertEqual(try count(
            assembly.database, "SELECT COUNT(*) FROM sessions WHERE session_id = '\(Self.sessionID)'"), 1)
        XCTAssertEqual(try count(assembly.database, "SELECT COUNT(*) FROM event_log"), 0)
    }

    /// Review Focus 1: a crash after the archive append (and after the store, and
    /// after the sinks) leaves the records spooled; the restarted drainer redelivers
    /// them and the session database ends byte-for-byte as a run that never
    /// crashed: no duplicate snapshot, no regressed `last_activity_at`.
    func testCrashAfterArchiveThenRedeliveryLeavesTheSameSessionDatabase() throws {
        let clean = try assemble("reference")
        try writeInput(clean)
        try pollInput(clean.handles)
        XCTAssertFalse(clean.handles.drainer.drainUntilEmpty().failed)
        let expected = try dumpAll(clean.database)

        struct Crash: Error {}
        for step in [DrainStep.afterArchive, .afterStore, .afterSinks] {
            let crashed = try assemble("crash-\(step.rawValue)", fault: { if $0 == step { throw Crash() } })
            try writeInput(crashed)
            try pollInput(crashed.handles)

            let first = crashed.handles.drainer.drainOnce()
            XCTAssertTrue(first.failed, "\(step): the injected crash did not fire")
            XCTAssertEqual(try crashed.handles.spool.pendingCount(),
                           Self.hookStems.count + Self.transcriptStems.count, "\(step): records left the spool")

            let restart = try restarted(crashed)
            let outcome = restart.drainer.drainUntilEmpty()
            XCTAssertFalse(outcome.failed, "\(step): \(outcome.failureReason ?? "")")
            XCTAssertEqual(try restart.spool.pendingCount(), 0, "\(step)")
            XCTAssertEqual(try restart.archive.count(), Self.hookStems.count + Self.transcriptStems.count, "\(step)")
            XCTAssertEqual(try dumpAll(crashed.database), expected, "\(step): session database differs")
        }
    }
}

// MARK: - Recovery: legacy spool, quarantine, deferred drop files

extension ClaudePipelineEndToEndTests {

    private func parsedHook(_ stem: String) throws -> ParsedEvent {
        let data = try Data(contentsOf: Self.fixtures.appendingPathComponent("hooks/\(stem).json"))
        guard case .event(let parsed) = ParseResult.parse(envelopeJSON: String(bytes: data, encoding: .utf8) ?? "")
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return parsed
    }

    /// Appends one record to the spool and quarantines it with `reason`.
    private func quarantine(_ record: RawRecord, reason: String, in spool: ProviderSpool) throws {
        try spool.append([record])
        let pending = try spool.pendingBatch(limit: 100)
        let id = try XCTUnwrap(pending.last(where: { $0.record.dedupKey == record.dedupKey })?.id)
        try spool.quarantine(id: id, reason: reason)
    }

    private func hookRecord(_ key: String, payload: Data) -> RawRecord {
        RawRecord(provider: ClaudeProvider.name, sourceKind: ClaudeProvider.legacyHookKind,
                  dedupKey: key, receivedAt: Date(timeIntervalSince1970: 1_793_400_000), payload: payload)
    }

    /// Review F3: a crash between the Claude-spool append and the legacy delete
    /// leaves the rows in both; adopting again re-appends them under the same keys,
    /// and the archive keeps one copy of each.
    func testLegacySpoolAdoptionIsSafeAcrossACrashBetweenAppendAndDelete() throws {
        let assembly = try assemble("legacy")
        let legacy = try IngestSpool(path: assembly.root.appendingPathComponent("ingest.db").path)
        for stem in ["SessionStart", "UserPromptSubmit", "Stop"] {
            try legacy.enqueue(try parsedHook(stem))
        }

        struct Crash: Error {}
        XCTAssertThrowsError(try assembly.handles.adoptLegacySpool(legacy, afterAppend: { throw Crash() }))
        XCTAssertEqual(legacy.pendingCount(), 3, "the legacy rows went before the crash")
        XCTAssertEqual(try assembly.handles.spool.pendingCount(), 3)

        XCTAssertEqual(try assembly.handles.adoptLegacySpool(legacy), 3)
        XCTAssertEqual(legacy.pendingCount(), 0)
        XCTAssertEqual(try assembly.handles.spool.pendingCount(), 6)
        XCTAssertEqual(try assembly.handles.adoptLegacySpool(legacy), 0, "nothing left to move")

        let outcome = assembly.handles.drainer.drainUntilEmpty()
        XCTAssertFalse(outcome.failed, outcome.failureReason ?? "")
        XCTAssertEqual(try assembly.handles.spool.quarantinedCount(), 0)
        XCTAssertEqual(try assembly.handles.archive.count(), 3)
        let keys = try assembly.handles.archive.records(after: 0, limit: 10).map(\.record.dedupKey)
        XCTAssertTrue(keys.allSatisfy { $0.hasPrefix("cap-legacy-") }, "\(keys)")
        XCTAssertEqual(try count(
            assembly.database, "SELECT COUNT(*) FROM sessions WHERE session_id = '\(Self.sessionID)'"), 1)
        XCTAssertEqual(try count(assembly.database, "SELECT COUNT(*) FROM event_log"), 0)
    }

    func testLegacyDedupKeyIsDerivedFromTheRowAlone() {
        let event = SpooledEvent(id: 42, eventType: "Stop", envelope: Data(), attempts: 0,
                                 receivedAt: Date(timeIntervalSince1970: 1_793_400_000.1234))
        XCTAssertEqual(ClaudePipelineHandles.legacyDedupKey(event), "cap-legacy-42-1793400000123")
        XCTAssertEqual(ClaudePipelineHandles.legacyDedupKey(event), ClaudePipelineHandles.legacyDedupKey(event))
    }

    /// Review F1(b): the startup requeue takes back what a destination outage
    /// quarantined (a sink, the events.db write) and leaves what was refused for
    /// itself; the manual retry (F1(c)) takes back everything, and a record that
    /// fails again is quarantined again, never lost.
    func testTransientRequeueTakesBackOnlyOutageFailures() throws {
        let assembly = try assemble("requeue")
        let spool = assembly.handles.spool
        let start = try parsedHook("SessionStart").envelopeJSON()
        let stop = try parsedHook("Stop").envelopeJSON()
        try quarantine(hookRecord("sink-1", payload: start),
                       reason: "\(PipelineDrainer.sinkFailurePrefix)ClaudeMainDBSink failed: busy", in: spool)
        try quarantine(hookRecord("store-1", payload: stop),
                       reason: "\(PipelineDrainer.storeFailurePrefix)disk I/O error", in: spool)
        try quarantine(hookRecord("bad-1", payload: Data("not json".utf8)),
                       reason: "invalid JSON", in: spool)
        try quarantine(hookRecord("conflict-1", payload: start),
                       reason: "dedup-key conflict: conflict-1", in: spool)
        XCTAssertEqual(assembly.handles.quarantinedCount(), 4)

        XCTAssertEqual(try assembly.handles.requeueTransientQuarantine(), 2)
        XCTAssertEqual(try spool.pendingCount(), 2)
        let reasons = try spool.quarantined(limit: 10).map(\.reason)
        XCTAssertEqual(reasons, ["invalid JSON", "dedup-key conflict: conflict-1"])
        XCTAssertFalse(assembly.handles.drainer.drainUntilEmpty().failed)
        XCTAssertNotNil(try assembly.handles.archive.id(forDedupKey: "sink-1"))
        XCTAssertNotNil(try assembly.handles.archive.id(forDedupKey: "store-1"))

        XCTAssertEqual(assembly.handles.requeueAllQuarantined(), 2)
        XCTAssertEqual(assembly.handles.quarantinedCount(), 0)
        // A record that keeps failing burns one attempt per call, so drain once per
        // attempt it has.
        for _ in 0..<ProviderSpool.maxAttempts {
            XCTAssertFalse(assembly.handles.drainer.drainUntilEmpty().failed)
        }
        // The bad record fails again and is parked again; the other one drains.
        XCTAssertEqual(try spool.quarantined(limit: 10).map(\.record.dedupKey), ["bad-1"])
        XCTAssertEqual(try spool.pendingCount(), 0)
    }

    /// Review F1(d): clear deletes a quarantined record only when the archive holds
    /// its key with the same bytes; one never archived, or archived with different
    /// bytes, stays.
    func testClearDeletesOnlyQuarantinedRecordsTheArchiveHoldsVerbatim() throws {
        let assembly = try assemble("clear")
        let spool = assembly.handles.spool
        try assembly.handles.capture(try parsedHook("SessionStart"))
        XCTAssertFalse(assembly.handles.drainer.drainUntilEmpty().failed)
        let archived = try XCTUnwrap(try assembly.handles.archive.records(after: 0, limit: 1).first?.record)

        try quarantine(archived, reason: "normalize failed: y", in: spool)
        try quarantine(hookRecord(archived.dedupKey, payload: Data("other bytes".utf8)),
                       reason: "dedup-key conflict: x", in: spool)
        try quarantine(hookRecord("never-archived", payload: archived.payload),
                       reason: "invalid JSON", in: spool)

        XCTAssertEqual(assembly.handles.clearArchivedQuarantine(), 1)
        let kept = try spool.quarantined(limit: 10)
        XCTAssertEqual(kept.map(\.record.dedupKey), [archived.dedupKey, "never-archived"])
        XCTAssertEqual(kept.first?.record.payload, Data("other bytes".utf8))
        XCTAssertEqual(assembly.handles.clearArchivedQuarantine(), 0)
    }

    /// Final review finding 2: a record parked by a sink or events.db outage is
    /// archived verbatim but applied nowhere, so clear must never delete it. It is
    /// requeued instead, and the drainer then applies it.
    func testClearRequeuesOutageFailuresInsteadOfDeletingThem() throws {
        let assembly = try assemble("clear-transient")
        let spool = assembly.handles.spool
        try assembly.handles.capture(try parsedHook("SessionStart"))
        XCTAssertFalse(assembly.handles.drainer.drainUntilEmpty().failed)
        let archived = try XCTUnwrap(try assembly.handles.archive.records(after: 0, limit: 1).first?.record)
        let stop = hookRecord("store-outage", payload: try parsedHook("Stop").envelopeJSON())
        XCTAssertEqual(try archive(stop, in: assembly), 1)

        try quarantine(archived, reason: "\(PipelineDrainer.sinkFailurePrefix)ClaudeMainDBSink failed: busy",
                       in: spool)
        try quarantine(stop, reason: "\(PipelineDrainer.storeFailurePrefix)disk I/O error", in: spool)
        XCTAssertEqual(assembly.handles.quarantinedCount(), 2)

        XCTAssertEqual(assembly.handles.clearArchivedQuarantine(), 0)
        XCTAssertEqual(assembly.handles.quarantinedCount(), 0)
        XCTAssertEqual(try spool.pendingCount(), 2)
        XCTAssertFalse(assembly.handles.drainer.drainUntilEmpty().failed)
        XCTAssertEqual(try spool.pendingCount(), 0)
        XCTAssertEqual(assembly.handles.quarantinedCount(), 0)
    }

    private func archive(_ record: RawRecord, in assembly: Assembly) throws -> Int {
        try assembly.handles.archive.append([record]).outcomes.count
    }

    func testOnlySinkAndStoreReasonsAreTransient() {
        XCTAssertTrue(ClaudePipelineHandles.isTransientFailure("sink ClaudeMainDBSink failed: busy"))
        XCTAssertTrue(ClaudePipelineHandles.isTransientFailure("store write failed: disk I/O error"))
        XCTAssertFalse(ClaudePipelineHandles.isTransientFailure("invalid JSON"))
        XCTAssertFalse(ClaudePipelineHandles.isTransientFailure("dedup-key conflict: x"))
    }

    /// Review M6: a drop file too young on the watcher's poll is spooled by the one
    /// re-wake scheduled after `minimumAge`, with no further poll from outside.
    func testDeferredDropFileIsSpooledByTheScheduledRewake() throws {
        let assembly = try assemble("rewake")
        try FileManager.default.createDirectory(at: assembly.dropDirectory, withIntermediateDirectories: true)
        let data = try Data(contentsOf: Self.fixtures.appendingPathComponent("hooks/SessionStart.json"))
        try data.write(to: assembly.dropDirectory.appendingPathComponent("1793400000000-00000000.json"))

        XCTAssertEqual(try assembly.handles.pollHookDrops(), 0, "a fresh file must wait for minimumAge")
        XCTAssertEqual(try assembly.handles.spool.pendingCount(), 0)

        let deadline = Date().addingTimeInterval(assembly.handles.hookSource.minimumAge + 5)
        var pending = 0
        while Date() < deadline {
            pending = try assembly.handles.spool.pendingCount()
            if pending > 0 { break }
            Thread.sleep(forTimeInterval: 0.05)
        }
        XCTAssertEqual(pending, 1, "the deferred file was not picked up by the re-wake")
    }
}
