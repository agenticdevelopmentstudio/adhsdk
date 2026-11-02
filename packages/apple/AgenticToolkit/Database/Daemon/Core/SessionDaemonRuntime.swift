#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
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

        public init(
            sink: any SessionEventSink,
            decode: @escaping @Sendable (Data) throws -> ParsedEvent,
            summarizeOnStop: (@Sendable (String) async -> Void)? = nil,
            footprintSuffix: @escaping @Sendable () -> String = { "" }
        ) {
            self.sink = sink
            self.decode = decode
            self.summarizeOnStop = summarizeOnStop
            self.footprintSuffix = footprintSuffix
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

    public let configuration: SessionDaemonConfiguration
    public let hookInstaller: ClaudeHookInstaller
    public let secretStore: any SecretStoring

    private let migrations: [DaemonMigration]
    private let postMigration: [@Sendable (DaemonDatabase) throws -> Void]
    private let statusLineIngest: DaemonDatabase.StatusLineIngest?
    private let sessionUpsertHook: DaemonDatabase.SessionUpsertHook?
    private let behavior: Behavior

    private struct Opened {
        var spool: IngestSpool
        var database: DaemonDatabase
        var pipeline: IngestionPipeline
        var hookDisabled: Bool
        var preferences: PreferencesService
        /// Nil when its files could not be opened: the daemon then runs on the
        /// legacy capture and ingest path.
        var claude: ClaudePipelineHandles?
        /// Held here because the drainer holds its observers weakly.
        var claudeObserver: ClaudeLiveObserver?
    }
    private let lock = NSLock()
    private var opened: Opened?
    private var isShutDown = false

    /// - Parameters:
    ///   - migrations: the schema: unique versions, shared ones 1-45 or 1001 and up, the daemon's own 46-1000.
    ///   - postMigration: ensure steps run after every migration pass.
    ///   - hookInstaller: defaults to one driven by `configuration.hook`.
    public init(
        configuration: SessionDaemonConfiguration,
        migrations: [DaemonMigration] = SessionSchema.migrations,
        postMigration: [@Sendable (DaemonDatabase) throws -> Void] = SessionSchema.postMigration,
        statusLineIngest: DaemonDatabase.StatusLineIngest? = nil,
        sessionUpsertHook: DaemonDatabase.SessionUpsertHook? = nil,
        behavior: Behavior,
        secretStore: any SecretStoring,
        hookInstaller: ClaudeHookInstaller? = nil
    ) {
        self.configuration = configuration
        self.migrations = migrations
        self.postMigration = postMigration
        self.statusLineIngest = statusLineIngest
        self.sessionUpsertHook = sessionUpsertHook
        self.behavior = behavior
        self.secretStore = secretStore
        self.hookInstaller = hookInstaller ?? ClaudeHookInstaller(configuration: configuration.hook)
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
    /// sources), or nil before ``openPhaseA()`` and when its files could not be
    /// opened (the daemon then captures and ingests on the legacy path).
    public var claudePipeline: ClaudePipelineHandles? { lock.withLock { opened?.claude } }

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
            pipelineQuarantine: opened.claude
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
    /// at fault level, ``claudePipeline`` stays nil and the daemon captures and
    /// ingests on the legacy path, as it did before the pipeline existed. The
    /// next start tries them again.
    public func openPhaseA() async throws {
        let configuration = configuration
        let installer = hookInstaller
        let migrations = migrations
        let postMigration = postMigration
        let statusLineIngest = statusLineIngest
        let sessionUpsertHook = sessionUpsertHook

        try FileManager.default.createDirectory(
            at: configuration.supportDirectory, withIntermediateDirectories: true
        )
        async let spoolTask: IngestSpool = Self.openSpool(path: configuration.spoolPath)
        async let dbTask: DaemonDatabase = Self.openDatabase(
            configuration: configuration, migrations: migrations, postMigration: postMigration,
            statusLineIngest: statusLineIngest, sessionUpsertHook: sessionUpsertHook
        )
        async let hookDisabledTask: Bool = Self.checkHookDisabled(installer: installer)
        async let claudeSpoolTask: ProviderSpool = Self.openClaudeSpool(path: configuration.claudeSpoolPath)
        async let archiveTask: RawArchive = Self.openClaudeArchive(path: configuration.claudeArchivePath)
        async let storeTask: EventStore = Self.openEventStore(path: configuration.eventStorePath)

        let spool = try await spoolTask
        let database = try await dbTask
        let hookDisabled = await hookDisabledTask

        var claude: ClaudePipelineHandles?
        do {
            let claudeSpool = try await claudeSpoolTask
            let archive = try await archiveTask
            let store = try await storeTask
            claude = try ClaudePipelineHandles(
                spool: claudeSpool, archive: archive, store: store, database: database,
                dropDirectory: configuration.dropDirectory,
                projectsDirectory: configuration.claudeProjectsDirectory
            )
            database.attachEventReads(store, archive: archive)
        } catch {
            Self.logger.fault("""
                Claude pipeline failed to open (\(error.localizedDescription, privacy: .public)); \
                capturing on the legacy path
                """)
        }

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
            claude: claude
        )
        // One enrichment, shared with the legacy ingestor, so both paths drive the
        // same transcript tailer and summarizer.
        var observer: ClaudeLiveObserver?
        if let claude {
            let live = ClaudeLiveObserver(
                eventReads: claude.store, sink: behavior.sink, enrichment: pipeline.ingestor.enrichment
            )
            claude.drainer.addObserver(live)
            observer = live
        }
        let preferences = PreferencesService(
            database: database, secretStore: secretStore, hookInstaller: installer,
            summariesDefaultEnabled: configuration.summariesDefaultEnabled,
            managesHooks: configuration.managesHooks
        )
        lock.withLock {
            opened = Opened(
                spool: spool, database: database, pipeline: pipeline,
                hookDisabled: hookDisabled, preferences: preferences,
                claude: claude, claudeObserver: observer
            )
        }
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
    /// then starts over what is left: nothing, unless that move failed, in which
    /// case it ingests the rows the old way rather than leaving them.
    public func startDrainer() async {
        let opened = requireOpened("startDrainer")
        if let claude = opened.claude {
            Self.prepareClaudeSpool(claude, legacy: opened.spool)
        }
        opened.pipeline.startDraining()
        opened.claude?.drainer.start()
    }

    private static func prepareClaudeSpool(_ claude: ClaudePipelineHandles, legacy: IngestSpool) {
        do {
            let requeued = try claude.requeueTransientQuarantine()
            if requeued > 0 {
                logger.info("Requeued \(requeued, privacy: .public) quarantined Claude record(s)")
            }
        } catch {
            logger.error("Claude quarantine requeue failed: \(error.localizedDescription, privacy: .public)")
        }
        do {
            let moved = try claude.adoptLegacySpool(legacy)
            if moved > 0 {
                logger.info("Moved \(moved, privacy: .public) legacy spool row(s) into the Claude spool")
            }
        } catch {
            logger.error("""
                Legacy spool move failed (\(error.localizedDescription, privacy: .public)); \
                the legacy drainer ingests what is left
                """)
        }
    }

    /// Stops the ingestion pipeline: a batch already in flight finishes against
    /// the database, and anything still spooled drains on the next launch.
    /// Idempotent. The hook registration is deliberately left in place — see
    /// the daemon's own uninstall path.
    public func shutdown() async {
        let current: Opened? = lock.withLock {
            let current = isShutDown ? nil : opened
            isShutDown = true
            return current
        }
        guard let current else { return }
        // The Claude drainer first: a pass in flight finishes (stop waits up to
        // 5 s), and anything still spooled drains on the next launch.
        current.claude?.drainer.stop()
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

    private static func openEventStore(path: String) throws -> EventStore {
        try EventStore(path: path)
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
