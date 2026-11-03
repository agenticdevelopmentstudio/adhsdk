import XCTest
import Foundation
import AgenticDeveloperHubSDKCore
import GRDB
@testable import AgenticDeveloperHubSDKDatabase

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

    private func makeRuntime(
        legacyWriterFallback: Bool = true,
        claudeOpener: SessionDaemonRuntime.ClaudeOpener? = nil,
        claudeOpenBackoff: SessionDaemonRuntime.ClaudeOpenBackoff = .standard
    ) throws -> SessionDaemonRuntime {
        let configuration = SessionDaemonConfiguration.test(port: 0, root: root)
        let dispatcher = root.appendingPathComponent("dispatch.sh")
        try "#!/bin/sh\n# claudehelpers-statusline-dispatch 1\n"
            .write(to: dispatcher, atomically: true, encoding: .utf8)
        var hook = configuration.hook
        hook.bundledDispatcher = dispatcher
        let installer = ClaudeHookInstaller(configuration: hook, helperIsExecutable: { _ in true })
        return SessionDaemonRuntime(
            configuration: configuration,
            behavior: .init(
                sink: NoSink(), decode: { _ in throw Undecodable() },
                legacyWriterFallback: legacyWriterFallback),
            secretStore: InMemorySecretStore(),
            hookInstaller: installer,
            claudeOpener: claudeOpener,
            claudeOpenBackoff: claudeOpenBackoff
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

    /// Review N3: a move that appended to the Claude spool but could not delete the
    /// legacy rows keeps the legacy drainer off, so those rows are not ingested twice.
    func testFailedLegacyDeleteKeepsTheLegacyDrainerOff() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        let claude = try XCTUnwrap(runtime.claudePipeline)
        try runtime.spool.enqueue(try hookEvent("SessionStart"))

        let allowed = SessionDaemonRuntime.prepareClaudeSpool(
            claude, legacy: runtime.spool, afterAppend: { throw Undecodable() })
        XCTAssertFalse(allowed, "the legacy drainer must stay off after a failed move")
        XCTAssertEqual(runtime.spool.pendingCount(), 1, "the legacy row stays for the next start")
        XCTAssertEqual(try claude.spool.pendingCount(), 1)
        XCTAssertTrue(SessionDaemonRuntime.prepareClaudeSpool(claude, legacy: runtime.spool))
        XCTAssertEqual(runtime.spool.pendingCount(), 0)
        await runtime.shutdown()
    }

    // MARK: - Legacy writers off (Stenographer)

    /// With the Claude pipeline open the legacy writers never run, whatever the
    /// fallback: a capture goes to the Claude spool and `event_log` stays empty.
    func testOpenPipelineKeepsTheLegacyWritersOff() async throws {
        let runtime = try makeRuntime()
        try await runtime.openPhaseA()
        let claude = try XCTUnwrap(runtime.claudePipeline)
        XCTAssertFalse(runtime.pipeline.legacyWriters)
        try runtime.migrate()
        await runtime.startDrainer()

        try runtime.pipeline.capture(try hookEvent("SessionStart"))
        XCTAssertTrue(try waitUntil { try claude.archive.count() == 1 }, "the capture did not reach the archive")
        XCTAssertEqual(runtime.spool.pendingCount(), 0)
        XCTAssertEqual(try eventLogCount(runtime.database), 0, "the legacy writer ingested a capture")
        await runtime.shutdown()
    }

    /// Fallback off and events.db unopenable: nothing reaches the legacy writer.
    /// The capture waits in the legacy spool (the next start that opens the
    /// pipeline adopts it), and a quarantine retry is held, not charged.
    func testLegacyFallbackOffHoldsCapturesWhenThePipelineCannotOpen() async throws {
        let runtime = try makeRuntime(legacyWriterFallback: false)
        try FileManager.default.createDirectory(
            atPath: runtime.configuration.eventStorePath, withIntermediateDirectories: true)

        try await runtime.openPhaseA()
        XCTAssertNil(runtime.claudePipeline)
        XCTAssertFalse(runtime.pipeline.legacyWriters)
        try runtime.migrate()
        await runtime.startDrainer()

        try runtime.pipeline.capture(try hookEvent("SessionStart"))
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(runtime.spool.pendingCount(), 1, "the capture must wait in the legacy spool")
        XCTAssertEqual(try eventLogCount(runtime.database), 0, "the legacy writer ingested a capture")
        XCTAssertThrowsError(try runtime.pipeline.retryIngest(try hookEvent("SessionStart"))) { error in
            XCTAssertTrue(error is QuarantineRetryHeld, "\(error)")
        }
        await runtime.shutdown()
    }

    // MARK: - Opening the Claude pipeline on a retry

    /// Counts opener calls and fails the first `failing` of them.
    private final class FlakyOpener: @unchecked Sendable {
        private let lock = NSLock()
        private var calls = 0
        private let failing: Int

        init(failing: Int) { self.failing = failing }

        var callCount: Int { lock.withLock { calls } }

        func open(_ configuration: SessionDaemonConfiguration) throws -> SessionDaemonRuntime.ClaudeFiles {
            let call: Int = lock.withLock { calls += 1; return calls }
            if call <= failing { throw Undecodable() }
            return .init(
                spool: try ProviderSpool(path: configuration.claudeSpoolPath, provider: ClaudeProvider.name),
                archive: try RawArchive(path: configuration.claudeArchivePath, provider: ClaudeProvider.name),
                store: try EventStore(path: configuration.eventStorePath))
        }
    }

    private func healthServices(_ runtime: SessionDaemonRuntime) -> SessionFeatureServices {
        runtime.services(
            .init(
                endpointIndex: [], startupDurationMs: { nil }, memorySample: { nil },
                parseQuarantinedEvent: { _ in .lostEvent }, buildHookEvent: { _, _ in nil },
                runImport: { _ in throw Undecodable() }),
            startTime: Date())
    }

    /// One minute after the first failure, doubling, never above thirty.
    func testTheStandardBackoffDoublesFromAMinuteToHalfAnHour() {
        let backoff = SessionDaemonRuntime.ClaudeOpenBackoff.standard
        let waits = (1...8).map { backoff.delay(afterFailures: $0).components.seconds }
        XCTAssertEqual(waits, [60, 120, 240, 480, 960, 1800, 1800, 1800])
    }

    /// Review F4: a pipeline that fails to open at startup is opened later in the
    /// run. Until then a capture waits in the legacy spool and `/health` says
    /// unavailable; the attempt that succeeds moves it into the Claude pipeline,
    /// starts the drainer and flips `/health` to open.
    func testAFailedOpenIsRetriedAndTakesOverTheHeldCaptures() async throws {
        let opener = FlakyOpener(failing: 3)  // phase A, then two retries
        let runtime = try makeRuntime(
            legacyWriterFallback: false,
            claudeOpener: { try opener.open($0) },
            claudeOpenBackoff: .init(initial: .milliseconds(20), cap: .milliseconds(40)))

        try await runtime.openPhaseA()
        XCTAssertNil(runtime.claudePipeline)
        XCTAssertEqual(runtime.claudePipelineSlot.state, .unavailable)
        XCTAssertEqual(healthServices(runtime).claudePipelineState?(), .unavailable)
        try runtime.migrate()
        try runtime.pipeline.capture(try hookEvent("SessionStart"))
        XCTAssertEqual(runtime.spool.pendingCount(), 1, "the capture waits in the legacy spool")

        await runtime.startDrainer()
        let opened = waitUntil { runtime.claudePipeline != nil }
        XCTAssertTrue(opened, "the retry never opened the pipeline")
        XCTAssertEqual(opener.callCount, 4)
        let claude = try XCTUnwrap(runtime.claudePipeline)
        XCTAssertEqual(healthServices(runtime).claudePipelineState?(), .open)
        XCTAssertEqual(runtime.spool.pendingCount(), 0, "the held capture was not moved")
        XCTAssertTrue(try waitUntil { try claude.store.counts().events == 1 },
                      "the drainer did not write the held capture")

        // From now on a capture and a retry go straight to the pipeline.
        try runtime.pipeline.capture(try hookEvent("UserPromptSubmit"))
        try runtime.pipeline.retryIngest(try hookEvent("Stop"))
        XCTAssertTrue(try waitUntil { try claude.archive.count() == 3 })
        XCTAssertEqual(runtime.spool.pendingCount(), 0)
        XCTAssertEqual(try eventLogCount(runtime.database), 0, "the legacy writer ingested a capture")
        await runtime.shutdown()
    }

    /// A retry still waiting when the runtime shuts down never opens anything.
    func testShutdownStopsTheOpenRetry() async throws {
        let opener = FlakyOpener(failing: 1)
        let runtime = try makeRuntime(
            legacyWriterFallback: false,
            claudeOpener: { try opener.open($0) },
            claudeOpenBackoff: .init(initial: .milliseconds(300), cap: .milliseconds(300)))
        try await runtime.openPhaseA()
        try runtime.migrate()
        await runtime.startDrainer()
        await runtime.shutdown()

        try await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertEqual(opener.callCount, 1, "the retry ran after shutdown")
        XCTAssertNil(runtime.claudePipeline)
    }

    /// With the fallback on, a failed open leaves the legacy writers on for the
    /// run: nothing retries the open underneath them.
    func testWithTheLegacyFallbackAFailedOpenIsNotRetried() async throws {
        let opener = FlakyOpener(failing: 1)
        let runtime = try makeRuntime(
            claudeOpener: { try opener.open($0) },
            claudeOpenBackoff: .init(initial: .milliseconds(20), cap: .milliseconds(20)))
        try await runtime.openPhaseA()
        try runtime.migrate()
        await runtime.startDrainer()

        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(opener.callCount, 1)
        XCTAssertTrue(runtime.pipeline.legacyWriters)
        await runtime.shutdown()
    }
}

/// The slot's "not open" throttle: one report per failed-open step.
final class ClaudePipelineSlotTests: XCTestCase {
    func testUnavailableIsReportedOncePerFailedOpen() {
        let slot = ClaudePipelineSlot()
        XCTAssertEqual(slot.state, .unavailable)
        XCTAssertTrue(slot.shouldReportUnavailable(), "the first wake reports")
        XCTAssertFalse(slot.shouldReportUnavailable(), "a second wake in the same step is quiet")
        XCTAssertFalse(slot.shouldReportUnavailable())
        slot.recordFailedOpen()
        XCTAssertTrue(slot.shouldReportUnavailable(), "a new step reports again")
        XCTAssertFalse(slot.shouldReportUnavailable())
    }

    /// Held work under the slot's lock is never lost to a fill: `held` runs
    /// before a fill's adoption, or `open` runs after it.
    func testRouteRunsHeldWhileEmpty() {
        let slot = ClaudePipelineSlot()
        let routed: String = slot.route(open: { _ in "open" }, held: { "held" })
        XCTAssertEqual(routed, "held")
        XCTAssertEqual(slot.quarantinedCount(), 0, "an empty slot has nothing quarantined")
    }
}
