import XCTest
import Foundation
import AgenticToolkitCore
import GRDB
@testable import AgenticToolkitDatabase

/// The runtime's steps over a temporary root, with the hook installer pointed at
/// a `settings.json` inside it — never the real Claude Code settings.
final class SessionDaemonRuntimeTests: XCTestCase {

    private struct NoSink: SessionEventSink {
        func broadcast(eventType: String, payload: Data, sessionId: String?) {}
        func broadcastSessionStatus(sessionId: String, status: SessionStatus) {}
    }

    private struct Undecodable: Error {}

    private var root: URL!

    override func setUpWithError() throws {
        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("session-runtime-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func makeRuntime() throws -> SessionDaemonRuntime {
        let configuration = SessionDaemonConfiguration.test(port: 0, root: root)
        let dispatcher = root.appendingPathComponent("dispatch.sh")
        try "#!/bin/sh\n# claudehelpers-statusline-dispatch 1\n"
            .write(to: dispatcher, atomically: true, encoding: .utf8)
        var hook = configuration.hook
        hook.bundledDispatcher = dispatcher
        let installer = ClaudeHookInstaller(configuration: hook, helperIsExecutable: { _ in true })
        return SessionDaemonRuntime(
            configuration: configuration,
            behavior: .init(sink: NoSink(), decode: { _ in throw Undecodable() }),
            secretStore: InMemorySecretStore(),
            hookInstaller: installer
        )
    }

    func testOpenPhaseALeavesTheDatabaseNotReady() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        XCTAssertFalse(runtime.database.isReady)
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtime.configuration.databasePath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: runtime.configuration.spoolPath))
        await runtime.shutdown()
    }

    func testMigrateMakesTheDatabaseReady() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        try runtime.migrate()
        XCTAssertTrue(runtime.database.isReady)
        try runtime.migrate()  // idempotent once it has succeeded
        await runtime.shutdown()
    }

    func testServicesAreReachableAfterOpen() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        let services = runtime.services(
            .init(
                endpointIndex: ["GET /health"],
                startupDurationMs: { nil },
                memorySample: { nil },
                parseQuarantinedEvent: { _ in .lostEvent },
                buildHookEvent: { _, _ in nil },
                runImport: { _ in throw Undecodable() }
            ),
            startTime: Date()
        )
        XCTAssertEqual(services.daemonVersion, "0.0.0-test")
        XCTAssertEqual(services.endpointIndex, ["GET /health"])
        XCTAssertNotNil(services.spool)
        XCTAssertFalse(services.database.isReady)
        await runtime.shutdown()
    }

    func testPreferencesIsOneInstanceSharedWithTheServices() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        let services = runtime.services(
            .init(
                endpointIndex: [],
                startupDurationMs: { nil },
                memorySample: { nil },
                parseQuarantinedEvent: { _ in .lostEvent },
                buildHookEvent: { _, _ in nil },
                runImport: { _ in throw Undecodable() }
            ),
            startTime: Date()
        )
        XCTAssertTrue(runtime.preferences === runtime.preferences, "one sync lock for HTTP and XPC")
        XCTAssertTrue(services.preferences === runtime.preferences)
        XCTAssertEqual(services.daemonName, runtime.daemonName)
        XCTAssertEqual(
            runtime.summarizer.defaultEnabled, runtime.configuration.summariesDefaultEnabled,
            "the summaries default has one source: the configuration"
        )
        await runtime.shutdown()
    }

    func testStartIngressInstallsHooksIntoTheTempSettings() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        await runtime.startIngress()
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: runtime.configuration.hook.settingsURL.path)
                || runtime.hookDisabled
        )
        await runtime.shutdown()
    }

    func testShutdownIsIdempotent() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        try runtime.migrate()
        await runtime.startDrainer()
        await runtime.shutdown()
        await runtime.shutdown()
    }

    func testShutdownBeforeOpenIsHarmless() async throws {
        let runtime = try makeRuntime()
        await runtime.shutdown()
    }

    // MARK: - Claude pipeline open failure and legacy spool adoption

    private static let hookFixtures = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Pipeline/Claude/Fixtures/hooks")

    private func hookEvent(_ stem: String) throws -> ParsedEvent {
        let data = try Data(contentsOf: Self.hookFixtures.appendingPathComponent("\(stem).json"))
        guard case .event(let parsed) = ParseResult.parse(envelopeJSON: String(bytes: data, encoding: .utf8) ?? "")
        else {
            throw Undecodable()
        }
        return parsed
    }

    private func eventLogCount(_ database: DaemonDatabase) throws -> Int {
        try database.write { conn in try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM event_log") ?? 0 }
    }

    /// Polls `condition` until it holds or `timeout` passes.
    private func waitUntil(timeout: TimeInterval = 10, _ condition: () throws -> Bool) rethrows -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if try condition() { return true }
            Thread.sleep(forTimeInterval: 0.05)
        }
        return try condition()
    }

    /// Review F2: an events.db that cannot be opened (a directory at its path) no
    /// longer stops the daemon. The runtime opens without the Claude pipeline and a
    /// capture is ingested on the legacy path, into `event_log`.
    func testUnopenableEventStoreFallsBackToTheLegacyPath() async throws {
        let runtime = try makeRuntime()
        try FileManager.default.createDirectory(
            atPath: runtime.configuration.eventStorePath, withIntermediateDirectories: true)

        try await runtime.openPhaseA()
        XCTAssertNil(runtime.claudePipeline, "the pipeline must stay off when events.db cannot open")
        try runtime.migrate()
        await runtime.startDrainer()

        try runtime.pipeline.capture(try hookEvent("SessionStart"))
        let ingested = try waitUntil { try eventLogCount(runtime.database) == 1 }
        XCTAssertTrue(ingested, "the legacy drainer did not ingest the capture")
        XCTAssertEqual(runtime.spool.pendingCount(), 0)
        await runtime.shutdown()
    }

    /// Review F3: rows a pre-pipeline daemon left in the legacy capture spool move
    /// into the Claude spool at startDrainer, under keys derived from each row, and
    /// reach the raw archive. The legacy writer never sees them.
    func testStartDrainerMovesLegacySpoolRowsIntoTheClaudePipeline() async throws {
        let runtime = try makeRuntime()
        try FileManager.default.createDirectory(
            at: runtime.configuration.supportDirectory, withIntermediateDirectories: true)
        do {
            let legacy = try IngestSpool(path: runtime.configuration.spoolPath)
            try legacy.enqueue(try hookEvent("SessionStart"))
            try legacy.enqueue(try hookEvent("UserPromptSubmit"))
            XCTAssertEqual(legacy.pendingCount(), 2)
        }

        try await runtime.openPhaseA()
        let claude = try XCTUnwrap(runtime.claudePipeline)
        try runtime.migrate()
        await runtime.startDrainer()

        XCTAssertEqual(runtime.spool.pendingCount(), 0, "the legacy rows were not moved")
        let archived = try waitUntil { try claude.archive.count() == 2 }
        XCTAssertTrue(archived, "the moved rows did not reach the raw archive")
        let keys = try claude.archive.records(after: 0, limit: 10).map(\.record.dedupKey)
        XCTAssertTrue(keys.allSatisfy { $0.hasPrefix("cap-legacy-") }, "\(keys)")
        XCTAssertEqual(try eventLogCount(runtime.database), 0, "the legacy writer ingested a moved row")
        await runtime.shutdown()
    }
}
