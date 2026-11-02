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
        let spool = try ProviderSpool(
            path: root.appendingPathComponent(ProviderSpool.fileName(provider: ClaudeProvider.name)).path,
            provider: ClaudeProvider.name)
        let archive = try RawArchive(
            path: root.appendingPathComponent(RawArchive.fileName(provider: ClaudeProvider.name)).path,
            provider: ClaudeProvider.name)
        let store = try EventStore(path: root.appendingPathComponent(EventStore.fileName).path)
        made.db.attachEventReads(store, archive: archive)
        let handles = try ClaudePipelineHandles(
            spool: spool, archive: archive, store: store, database: made.db,
            dropDirectory: root.appendingPathComponent("drop"),
            projectsDirectory: root.appendingPathComponent("projects"),
            drainerFaultInjector: fault)
        let sink = RecordingSink()
        let log = EnrichmentLog()
        let observer = ClaudeLiveObserver(eventReads: store, sink: sink, enrichment: log.hooks)
        handles.drainer.addObserver(observer)
        return Assembly(root: root, database: made.db, handles: handles, sink: sink, log: log, observer: observer)
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

    private func dump(_ database: DaemonDatabase, table: String) throws -> [String] {
        try database.write { conn in
            let columns = try Row.fetchAll(conn, sql: "PRAGMA table_info(\(table))")
                .map { $0["name"] as String }
                .filter { $0 != "updated_at" }
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
