#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import AIPluginKit
import Foundation
import OSLog

/// The objects a session daemon needs before it can capture and serve events,
/// and the steps that bring them up and down, written once.
///
/// The runtime owns the spool, the database, the ingestion pipeline and the hook
/// installer. It does **not** sequence them: the daemon's controller calls the
/// steps in the order its own transport needs. That order is the one every
/// session daemon shares:
///
/// 1. ``openPhaseA()`` — spool and database opened in parallel, the schema
///    *not* migrated yet, the support directory created and the user's
///    tracking choice read.
/// 2. Start the listener, then ``startIngress()`` — the capture socket and the
///    hook registration. Capture is live from here, into the spool.
/// 3. ``migrate()`` — one attempt at the schema. A controller that wants to
///    survive a failing migration wraps it in its own retry (the retry belongs
///    to the process-lifecycle library, which this module does not import).
/// 4. ``startDrainer()`` — empties the spool into the migrated database.
/// 5. ``shutdown()`` — stops the pipeline; safe to call more than once.
///
/// Splitting the migration from the open is the point: the listener and the
/// spool can be up while a long migration runs, so a migration turns capture
/// from lossy into merely late.
public final class SessionDaemonRuntime: @unchecked Sendable {

    /// What a daemon supplies for turning raw deliveries into stored events.
    public struct Behavior: Sendable {
        /// Where live events are announced (SSE, XPC subscribers).
        public var sink: any SessionEventSink
        /// Decodes one hook-socket payload.
        public var decode: @Sendable (Data) throws -> ParsedEvent
        /// Called with the session id after `Stop` / `SessionEnd`.
        public var summarizeOnStop: (@Sendable (String) async -> Void)?
        /// Appended to the ingestor's backfill log lines.
        public var footprintSuffix: @Sendable () -> String
        /// Whether the legacy writers (`ingestEvent`, `JSONLImporter`) take over
        /// when the Claude pipeline fails to open. False for a daemon whose events
        /// live in the Claude pipeline only: captures then wait in the legacy spool
        /// for the next start that opens it (`IngestionPipeline`).
        public var legacyWriterFallback: Bool

        public init(
            sink: any SessionEventSink,
            decode: @escaping @Sendable (Data) throws -> ParsedEvent,
            summarizeOnStop: (@Sendable (String) async -> Void)? = nil,
            footprintSuffix: @escaping @Sendable () -> String = { "" },
            legacyWriterFallback: Bool = true
        ) {
            self.sink = sink
            self.decode = decode
            self.summarizeOnStop = summarizeOnStop
            self.footprintSuffix = footprintSuffix
            self.legacyWriterFallback = legacyWriterFallback
        }
    }

    /// The daemon-only closures `SessionFeatureServices` needs on top of what
    /// the runtime owns.
    public struct ServiceWiring: Sendable {
        public var endpointIndex: [String]
        public var startupDurationMs: @Sendable () -> Int?
        public var memorySample: @Sendable () -> SessionFeatureServices.MemorySample?
        public var parseQuarantinedEvent: @Sendable (String) -> ParseResult
        public var buildHookEvent: @Sendable (_ event: String, _ payload: Data) -> ParsedEvent?
        public var runImport: @Sendable (ImportRequestDTO) throws -> ImportSummary

        public init(
            endpointIndex: [String],
            startupDurationMs: @escaping @Sendable () -> Int?,
            memorySample: @escaping @Sendable () -> SessionFeatureServices.MemorySample?,
            parseQuarantinedEvent: @escaping @Sendable (String) -> ParseResult,
            buildHookEvent: @escaping @Sendable (_ event: String, _ payload: Data) -> ParsedEvent?,
            runImport: @escaping @Sendable (ImportRequestDTO) throws -> ImportSummary
        ) {
            self.endpointIndex = endpointIndex
            self.startupDurationMs = startupDurationMs
            self.memorySample = memorySample
            self.parseQuarantinedEvent = parseQuarantinedEvent
            self.buildHookEvent = buildHookEvent
            self.runImport = runImport
        }
    }

    /// The three files the Claude pipeline runs on.
    public struct ClaudeFiles: Sendable {
        public var spool: ProviderSpool
        public var archive: RawArchive
        public var store: EventStore

        public init(spool: ProviderSpool, archive: RawArchive, store: EventStore) {
            self.spool = spool
            self.archive = archive
            self.store = store
        }
    }

    /// Opens the Claude pipeline's files. Injected by tests; the default opens
    /// the three at their configured paths in parallel.
    public typealias ClaudeOpener = @Sendable (SessionDaemonConfiguration) throws -> ClaudeFiles

    /// How long to wait before each new attempt at opening the Claude pipeline
    /// after a failure: `initial` after the first, doubling, never above `cap`.
    public struct ClaudeOpenBackoff: Sendable {
        public var initial: Duration
        public var cap: Duration

        /// One minute, doubling, capped at thirty.
        public static let standard = ClaudeOpenBackoff(initial: .seconds(60), cap: .seconds(1800))

        public init(initial: Duration, cap: Duration) {
            self.initial = initial
            self.cap = cap
        }

        /// The wait before the next attempt once `failures` (1 or more) have failed.
        public func delay(afterFailures failures: Int) -> Duration {
            var delay = initial
            for _ in 1..<max(failures, 1) {
                delay *= 2
                if delay >= cap { return cap }
            }
            return min(delay, cap)
        }
    }

    public let configuration: SessionDaemonConfiguration
    public let hookInstaller: ClaudeHookInstaller
    public let secretStore: any SecretStoring

    private let migrations: [DaemonMigration]
    private let postMigration: [@Sendable (DaemonDatabase) throws -> Void]
    private let statusLineIngest: DaemonDatabase.StatusLineIngest?
    private let sessionUpsertHook: DaemonDatabase.SessionUpsertHook?
    private let behavior: Behavior
    private let claudeOpener: ClaudeOpener?
    private let claudeOpenBackoff: ClaudeOpenBackoff

    private struct Opened {
        var spool: IngestSpool
        var database: DaemonDatabase
        var pipeline: IngestionPipeline
        var hookDisabled: Bool
        var preferences: PreferencesService
        /// Held here because the drainer holds its observers weakly.
        var claudeObserver: ClaudeLiveObserver?
    }
    private let lock = NSLock()
    private var opened: Opened?
    private var isShutDown = false
    /// The Claude pipeline: empty while its files could not be opened, filled at
    /// ``openPhaseA()`` or by the open retry ``startDrainer()`` starts.
    private let claudeSlot = ClaudePipelineSlot()
    private var claudeOpenRetry: Task<Void, Never>?

    /// - Parameters:
    ///   - migrations: the schema: unique versions, shared ones 1-45 or 1001 and up, the daemon's own 46-1000.
    ///   - postMigration: ensure steps run after every migration pass.
    ///   - hookInstaller: defaults to one driven by `configuration.hook`.
    ///   - claudeOpener: opens the Claude pipeline's files; nil opens them at the
    ///     configured paths. For tests.
    ///   - claudeOpenBackoff: the waits between attempts at opening the Claude
    ///     pipeline after a failure.
    public init(
        configuration: SessionDaemonConfiguration,
        migrations: [DaemonMigration] = SessionSchema.migrations,
        postMigration: [@Sendable (DaemonDatabase) throws -> Void] = SessionSchema.postMigration,
        statusLineIngest: DaemonDatabase.StatusLineIngest? = nil,
        sessionUpsertHook: DaemonDatabase.SessionUpsertHook? = nil,
        behavior: Behavior,
        secretStore: any SecretStoring,
        hookInstaller: ClaudeHookInstaller? = nil,
        claudeOpener: ClaudeOpener? = nil,
        claudeOpenBackoff: ClaudeOpenBackoff = .standard
    ) {
        self.configuration = configuration
        self.migrations = migrations
        self.postMigration = postMigration
        self.statusLineIngest = statusLineIngest
        self.sessionUpsertHook = sessionUpsertHook
        self.behavior = behavior
        self.secretStore = secretStore
        self.hookInstaller = hookInstaller ?? ClaudeHookInstaller(configuration: configuration.hook)
        self.claudeOpener = claudeOpener
        self.claudeOpenBackoff = claudeOpenBackoff
    }

    // MARK: - Opened objects

    private func requireOpened(_ what: String) -> Opened {
        lock.lock()
        defer { lock.unlock() }
        guard let opened else {
            preconditionFailure("SessionDaemonRuntime.\(what) read before openPhaseA()")
        }
        return opened
    }

    /// Valid after ``openPhaseA()``.
    public var database: DaemonDatabase { requireOpened("database").database }
    /// Valid after ``openPhaseA()``.
    public var spool: IngestSpool { requireOpened("spool").spool }
    /// Valid after ``openPhaseA()``.
    public var pipeline: IngestionPipeline { requireOpened("pipeline").pipeline }
    /// Whether the user had turned tracking off when the runtime opened.
    public var hookDisabled: Bool { requireOpened("hookDisabled").hookDisabled }
    /// The Claude provider pipeline (spool, archive, event store, drainer and
    /// sources), or nil while it is not open: before ``openPhaseA()``, and while
    /// its files cannot be opened. Then, with `Behavior.legacyWriterFallback`, the
    /// legacy writers run for the whole run; without it, captures wait in the
    /// legacy spool and the open is retried (``startDrainer()``). A snapshot:
    /// anything that must see a pipeline opening later reads ``claudePipelineSlot``.
    public var claudePipeline: ClaudePipelineHandles? { claudeSlot.current }

    /// The Claude pipeline as it is at call time: what the drop-directory wake,
    /// the transcript sweep, the import route and the quarantine routes read.
    public var claudePipelineSlot: ClaudePipelineSlot { claudeSlot }

    /// The conversations feed over the runtime's database.
    public var conversations: ConversationStore { ConversationStore(database: database) }

    /// The one preferences service over the runtime's database, built once in
    /// ``openPhaseA()``. HTTP and XPC must share it: its sync lock only serializes
    /// callers of the same instance. Valid after ``openPhaseA()``.
    public var preferences: PreferencesService { requireOpened("preferences").preferences }

    /// The daemon's name, as the HTTP routes report it.
    public var daemonName: String { configuration.hook.name }

    /// The summarizer every daemon task uses, with the default taken from
    /// ``SessionDaemonConfiguration/summariesDefaultEnabled`` and nowhere else.
    public var summarizer: DaemonSessionSummarizer {
        DaemonSessionSummarizer(defaultEnabled: configuration.summariesDefaultEnabled,
                                pluginRuntime: pluginRuntime)
    }

    /// How this daemon loads AI plugins: the default folders plus
    /// ``SessionDaemonConfiguration/pluginSearchPaths``. Summaries, oversight and the
    /// summarize route all load through it.
    public var pluginRuntime: DaemonAIChat.PluginRuntime {
        .live(additionalSearchPaths: configuration.pluginSearchPaths)
    }

    /// Everything the shared HTTP routes read. Valid after ``openPhaseA()``.
    public func services(_ wiring: ServiceWiring, startTime: Date) -> SessionFeatureServices {
        let opened = requireOpened("services")
        return SessionFeatureServices(
            database: opened.database,
            conversations: ConversationStore(database: opened.database),
            quarantine: opened.pipeline.quarantine,
            spool: opened.spool,
            preferences: preferences,
            secretStore: secretStore,
            hookInstaller: hookInstaller,
            daemonName: daemonName,
            daemonVersion: configuration.daemonVersion,
            startTime: startTime,
            endpointIndex: wiring.endpointIndex,
            startupDurationMs: wiring.startupDurationMs,
            memorySample: wiring.memorySample,
            parseQuarantinedEvent: wiring.parseQuarantinedEvent,
            retryIngest: opened.pipeline.retryIngest,
            buildHookEvent: wiring.buildHookEvent,
            captureHook: opened.pipeline.capture,
            runImport: wiring.runImport,
            pluginRuntime: pluginRuntime,
            pipelineQuarantine: claudeSlot,
            claudePipelineState: { [claudeSlot] in claudeSlot.state }
        )
    }

    // MARK: - Steps

    /// Phase A: opens the spool and the database in parallel (the schema is NOT
    /// migrated), creates the support directory and reads the tracking choice,
    /// then assembles the capture path. Nothing here needs the main schema,
    /// which is what lets the listener come up before the migration.
    ///
    /// Throws when the spool or the database cannot be opened: without the
    /// spool there is nowhere to put a delivery, and without the pool there is
    /// no database at all. Neither is a migration failure.
    ///
    /// The Claude pipeline's files (its spool, raw archive and events.db) are
    /// opened beside them but are not fatal: if any fails, the failure is logged
    /// at fault level and ``claudePipeline`` stays nil. With
    /// `Behavior.legacyWriterFallback` the daemon then captures and ingests on the
    /// legacy path for this run; without it, captures wait in the legacy spool
    /// and ``startDrainer()`` retries the open with a backoff.
    public func openPhaseA() async throws {
        let configuration = configuration
        let installer = hookInstaller
        let migrations = migrations
        let postMigration = postMigration
        let statusLineIngest = statusLineIngest
        let sessionUpsertHook = sessionUpsertHook
        let claudeOpener = claudeOpener

        try FileManager.default.createDirectory(
            at: configuration.supportDirectory, withIntermediateDirectories: true
        )
        async let spoolTask: IngestSpool = Self.openSpool(path: configuration.spoolPath)
        async let dbTask: DaemonDatabase = Self.openDatabase(
            configuration: configuration, migrations: migrations, postMigration: postMigration,
            statusLineIngest: statusLineIngest, sessionUpsertHook: sessionUpsertHook
        )
        async let hookDisabledTask: Bool = Self.checkHookDisabled(installer: installer)
        async let claudeFilesTask: ClaudeFiles = Self.openClaudeFiles(configuration, opener: claudeOpener)

        let spool = try await spoolTask
        let database = try await dbTask
        let hookDisabled = await hookDisabledTask

        var claude: ClaudePipelineHandles?
        do {
            let files = try await claudeFilesTask
            claude = try Self.makeHandles(files, database: database, configuration: configuration)
            database.attachEventReads(files.store, archive: files.archive)
        } catch {
            claudeSlot.recordFailedOpen()
            let meanwhile = behavior.legacyWriterFallback
                ? "capturing on the legacy path"
                : "captures wait in the legacy spool and the open is retried"
            Self.logger.fault("""
                Claude pipeline failed to open (\(error.localizedDescription, privacy: .public)); \
                \(meanwhile, privacy: .public)
                """)
        }
        if let claude { claudeSlot.fill(claude) }

        let pipeline = IngestionPipeline(
            paths: .init(
                dropDirectory: configuration.dropDirectory,
                errorsDirectory: configuration.errorsDirectory,
                socketPath: configuration.socketPath
            ),
            spool: spool,
            database: database,
            sink: behavior.sink,
            queueLabel: { "\(configuration.subsystem).\($0)" },
            decode: behavior.decode,
            summarizeOnStop: behavior.summarizeOnStop,
            footprintSuffix: behavior.footprintSuffix,
            claude: claudeSlot,
            legacyWriterFallback: behavior.legacyWriterFallback
        )
        // One enrichment, shared with the legacy ingestor, so both paths drive the
        // same transcript tailer and summarizer.
        let observer = claude.map { Self.observe($0, sink: behavior.sink, pipeline: pipeline) }
        let preferences = PreferencesService(
            database: database, secretStore: secretStore, hookInstaller: installer,
            summariesDefaultEnabled: configuration.summariesDefaultEnabled,
            managesHooks: configuration.managesHooks
        )
        lock.withLock {
            opened = Opened(
                spool: spool, database: database, pipeline: pipeline,
                hookDisabled: hookDisabled, preferences: preferences,
                claudeObserver: observer
            )
        }
    }

    /// Builds the pipeline's handles over its opened files.
    private static func makeHandles(
        _ files: ClaudeFiles, database: DaemonDatabase, configuration: SessionDaemonConfiguration
    ) throws -> ClaudePipelineHandles {
        try ClaudePipelineHandles(
            spool: files.spool, archive: files.archive, store: files.store, database: database,
            dropDirectory: configuration.dropDirectory,
            projectsDirectory: configuration.claudeProjectsDirectory
        )
    }

    /// The live observer (SSE, session status, enrichment) on the pipeline's drainer.
    private static func observe(
        _ claude: ClaudePipelineHandles, sink: any SessionEventSink, pipeline: IngestionPipeline
    ) -> ClaudeLiveObserver {
        let live = ClaudeLiveObserver(
            eventReads: claude.store, sink: sink, enrichment: pipeline.ingestor.enrichment
        )
        claude.drainer.addObserver(live)
        return live
    }

    /// Phase B: binds the capture socket and reconciles the hook registration
    /// with the user's tracking choice, in parallel. Neither failure is fatal:
    /// every registration is the capture-script `command` hook, which writes a
    /// drop file whether or not the daemon is up, so capture stays intact and
    /// the drop directory is ingested once a later start binds.
    public func startIngress() async {
        let opened = requireOpened("startIngress")
        let installer = hookInstaller
        let managesHooks = configuration.managesHooks
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do { try opened.pipeline.startAcceptingCaptures() } catch {
                    Self.logger.error(
                        "Ingest socket failed to start: \(error.localizedDescription, privacy: .public)"
                    )
                }
            }
            // A passive daemon leaves `settings.json` to the copy that owns it.
            guard managesHooks else { return }
            group.addTask {
                Self.applyHookState(installer: installer, disabled: opened.hookDisabled)
            }
        }
    }

    /// Phase B½: one attempt at the migration; idempotent once it has succeeded.
    public func migrate() throws {
        try database.migrateNow()
    }

    /// Starts emptying the spools into the migrated database.
    ///
    /// With the Claude pipeline, first: its quarantined records that failed on a
    /// destination outage (a sink or the events.db write) go back into its spool,
    /// and the legacy capture spool's leftovers move into it too, so they reach the
    /// raw archive and events.db rather than only `event_log`. The legacy drainer
    /// never starts beside the Claude pipeline: captures go to the Claude spool, so
    /// the legacy spool only holds leftovers, and if their move fails they stay
    /// there for the next start rather than reaching `event_log` alone.
    ///
    /// Without the Claude pipeline the legacy drainer starts when
    /// `Behavior.legacyWriterFallback` allows it (`IngestionPipeline.startDraining()`)
    /// and runs for the whole run. Otherwise captures wait in the legacy spool
    /// and the open is retried in the background (`ClaudeOpenBackoff`: a minute
    /// after the first failure, doubling, capped at thirty); the attempt that
    /// succeeds fills ``claudePipelineSlot``, moves the legacy spool across and
    /// starts the drainer, exactly as a start that opened it would have.
    public func startDrainer() async {
        let opened = requireOpened("startDrainer")
        guard let claude = claudeSlot.current else {
            if opened.pipeline.legacyWriters {
                opened.pipeline.startDraining()
            } else {
                Self.logger.fault("""
                    Claude pipeline not open and the legacy writers are off; \
                    captures wait in the legacy spool while the open is retried
                    """)
                startClaudeOpenRetry()
            }
            return
        }
        Self.prepareClaudeSpool(claude, legacy: opened.spool)
        claude.drainer.start()
    }

    /// Retries the Claude pipeline's open until it succeeds or the runtime shuts
    /// down. Each failure bumps the slot's step, which is what throttles the
    /// "not open" logs elsewhere to one per wait.
    private func startClaudeOpenRetry() {
        let backoff = claudeOpenBackoff
        let task = Task.detached { [weak self] in
            var failures = 1
            while !Task.isCancelled {
                let delay = backoff.delay(afterFailures: failures)
                do { try await Task.sleep(for: delay) } catch { return }
                guard let self else { return }
                do {
                    try await self.openClaudeLate()
                    return
                } catch is CancellationError {
                    return
                } catch {
                    failures += 1
                    self.claudeSlot.recordFailedOpen()
                    let next = backoff.delay(afterFailures: failures)
                    Self.logger.error("""
                        Claude pipeline still failed to open (\(error.localizedDescription, privacy: .public)); \
                        next attempt in \(next.components.seconds, privacy: .public)s
                        """)
                }
            }
        }
        let keep: Bool = lock.withLock {
            guard !isShutDown else { return false }
            claudeOpenRetry = task
            return true
        }
        if !keep { task.cancel() }
    }

    /// One late attempt: opens the files, fills the slot (attaching events.db for
    /// reads and moving the legacy spool across while captures are held off) and
    /// starts the drainer. Throws when the files still cannot be opened.
    private func openClaudeLate() async throws {
        let opened = requireOpened("openClaudeLate")
        let files = try await Self.openClaudeFiles(configuration, opener: claudeOpener)
        let handles = try Self.makeHandles(files, database: opened.database, configuration: configuration)
        let observer = Self.observe(handles, sink: behavior.sink, pipeline: opened.pipeline)
        let filled = claudeSlot.fill(handles) {
            opened.database.attachEventReads(files.store, archive: files.archive)
            Self.prepareClaudeSpool(handles, legacy: opened.spool)
        }
        guard filled else { return }
        // Started under the lock `shutdown` takes, so a shutdown either sees
        // nothing to stop or stops this drainer.
        let started: Bool = lock.withLock {
            guard !isShutDown else { return false }
            self.opened?.claudeObserver = observer
            handles.drainer.start()
            return true
        }
        guard started else { return }
        Self.logger.info("Claude pipeline opened on a retry; draining")
        // Drop files that arrived while it was closed wait for a directory event;
        // read them now rather than on the next one.
        do { _ = try handles.pollHookDrops() } catch {
            Self.logger.error("Drop-file spool failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Requeues the transient quarantine and moves the legacy spool into the Claude
    /// spool. Returns whether the move succeeded; on false the rows stay in the
    /// legacy spool for the next start. `afterAppend` is for tests; it fires
    /// between append and delete.
    @discardableResult
    static func prepareClaudeSpool(
        _ claude: ClaudePipelineHandles, legacy: IngestSpool, afterAppend: (() throws -> Void)? = nil
    ) -> Bool {
        do {
            let requeued = try claude.requeueTransientQuarantine()
            if requeued > 0 {
                logger.info("Requeued \(requeued, privacy: .public) quarantined Claude record(s)")
            }
        } catch {
            logger.error("Claude quarantine requeue failed: \(error.localizedDescription, privacy: .public)")
        }
        do {
            let moved = try claude.adoptLegacySpool(legacy, afterAppend: afterAppend)
            if moved > 0 {
                logger.info("Moved \(moved, privacy: .public) legacy spool row(s) into the Claude spool")
            }
            return true
        } catch {
            logger.error("""
                Legacy spool move failed (\(error.localizedDescription, privacy: .public)); \
                the legacy drainer stays off this run and the next start moves the rest
                """)
            return false
        }
    }

    /// Stops the ingestion pipeline: a batch already in flight finishes against
    /// the database, and anything still spooled drains on the next launch.
    /// Idempotent. The hook registration is deliberately left in place — see
    /// the daemon's own uninstall path.
    public func shutdown() async {
        let (current, retry): (Opened?, Task<Void, Never>?) = lock.withLock {
            let current = isShutDown ? nil : opened
            isShutDown = true
            let retry = claudeOpenRetry
            claudeOpenRetry = nil
            return (current, retry)
        }
        retry?.cancel()
        guard let current else { return }
        // The Claude drainer first: a pass in flight finishes (stop waits up to
        // 5 s), and anything still spooled drains on the next launch.
        claudeSlot.current?.drainer.stop()
        await current.pipeline.stop()
    }

    // MARK: - Sendable helpers (called from child tasks)

    private static func openSpool(path: String) throws -> IngestSpool {
        try IngestSpool(path: path)
    }

    private static func openClaudeSpool(path: String) throws -> ProviderSpool {
        try ProviderSpool(path: path, provider: ClaudeProvider.name)
    }

    private static func openClaudeArchive(path: String) throws -> RawArchive {
        try RawArchive(path: path, provider: ClaudeProvider.name)
    }

    /// Opening finishes a bulk load a killed or crashed replay (`stenographerd
    /// --replay`) left behind: the indexes are rebuilt before the open returns.
    private static func openEventStore(path: String) throws -> EventStore {
        let store = try EventStore(path: path)
        if store.recoveredBulkLoad {
            logger.warning("events.db was left in bulk load by an interrupted replay; its indexes were rebuilt")
        }
        return store
    }

    /// The Claude pipeline's three files, through `opener` when one is injected
    /// and otherwise opened at their configured paths in parallel.
    ///
    /// Every open runs on ``claudeOpenQueue``, never on a cooperative-pool thread:
    /// the events.db open can rebuild indexes for a long time, and a blocked pool
    /// thread would starve the rest of startup. Callers only await.
    private static func openClaudeFiles(
        _ configuration: SessionDaemonConfiguration, opener: ClaudeOpener?
    ) async throws -> ClaudeFiles {
        if let opener { return try await offCooperativePool { try opener(configuration) } }
        async let spool: ProviderSpool = offCooperativePool {
            try openClaudeSpool(path: configuration.claudeSpoolPath)
        }
        async let archive: RawArchive = offCooperativePool {
            try openClaudeArchive(path: configuration.claudeArchivePath)
        }
        async let store: EventStore = offCooperativePool {
            try openEventStore(path: configuration.eventStorePath)
        }
        return try await ClaudeFiles(spool: spool, archive: archive, store: store)
    }

    /// Where the Claude pipeline's blocking SQLite opens run. Concurrent, so the
    /// three files still open in parallel.
    private static let claudeOpenQueue = DispatchQueue(
        label: "SessionDaemonRuntime.claudeOpen", qos: .utility, attributes: .concurrent)

    /// Runs `body` on ``claudeOpenQueue`` and resumes with its result, so the
    /// awaiting task suspends instead of holding a cooperative thread.
    private static func offCooperativePool<Value: Sendable>(
        _ body: @escaping @Sendable () throws -> Value
    ) async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            claudeOpenQueue.async {
                continuation.resume(with: Result { try body() })
            }
        }
    }

    /// Opens the pool only; the migration is ``migrate()``'s.
    private static func openDatabase(
        configuration: SessionDaemonConfiguration,
        migrations: [DaemonMigration],
        postMigration: [@Sendable (DaemonDatabase) throws -> Void],
        statusLineIngest: DaemonDatabase.StatusLineIngest?,
        sessionUpsertHook: DaemonDatabase.SessionUpsertHook?
    ) throws -> DaemonDatabase {
        try DaemonDatabase(
            path: configuration.databasePath,
            accountResolver: AccountResolver(claudeJSONPath: configuration.claudeJSONPath),
            deferMigrations: true,
            migrations: migrations,
            postMigration: postMigration,
            statusLineIngest: statusLineIngest,
            sessionUpsertHook: sessionUpsertHook
        )
    }

    private static func checkHookDisabled(installer: ClaudeHookInstaller) -> Bool {
        installer.isTrackingDisabled()
    }

    /// Reconciles `settings.json` with the user's tracking choice: uninstall
    /// when disabled, otherwise install (or upgrade to) the bundled hooks.
    private static func applyHookState(installer: ClaudeHookInstaller, disabled: Bool) {
        if disabled {
            let removed = installer.uninstallHooks()
            let msg = removed ? "removed leftover" : "no hooks to remove"
            logger.info("Tracking disabled by user; \(msg, privacy: .public)")
        } else {
            switch installer.installHooks() {
            case .installed:        logger.info("Hooks installed")
            case .alreadyInstalled: logger.info("Hooks already present")
            case .failed(let msg):  logger.warning("Hook install failed: \(msg, privacy: .public)")
            }
        }
    }
}

extension SessionDaemonRuntime: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
