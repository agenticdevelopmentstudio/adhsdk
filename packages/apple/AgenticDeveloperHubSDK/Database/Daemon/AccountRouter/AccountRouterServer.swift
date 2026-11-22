#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import AIPluginKit
import Foundation

/// The account router as a daemon hosts it: one loopback listener that swaps a
/// saved Claude account's token (or a configured model provider) into the
/// requests Claude Code sends it, one account pool, one exchange recorder, and
/// the read side a daemon's routes and CLI serve.
///
/// A daemon builds one, with the one ``AccountQuotaProbe`` it owns as its
/// credential source, and calls ``start()`` once its database is migrated and
/// ``stop()`` on shutdown. Settings are rows in the daemon's database
/// (``AccountRouterSettings``), read on every request through a short cache, so
/// the router reads "off" until a client turns it on.
///
/// Fail-open at this level too: `start()` never throws (a port already in use
/// is logged and the daemon carries on), and a row that cannot be written is
/// logged and dropped; the exchange it describes has already been served.
/// Rows are written asynchronously on a utility queue, in order.
///
/// `stop()` closes the listener and drains the queued rows. Exchanges already
/// accepted finish (their rows may land after it returns), and
/// the upstream session is deliberately never invalidated: a connection
/// accepted just before `stop()` may still create its upstream task, and a
/// task on an invalidated session raises an exception that would take the
/// daemon down.
public final class AccountRouterServer: @unchecked Sendable {
    /// `status().port` before a successful bind.
    static let unboundPort = -1

    /// The widest report window, in hours: a century. A larger request, even one
    /// too big for an `Int`, is answered as this, so the cutoff date can't overflow.
    public static let maxReportHours = 24 * 365 * 100

    private let database: DaemonDatabase
    private let templateStore: ModelRouterTemplateStore
    private let source: any AccountRouterQuotaSource
    private let pool: AccountPool
    private let server: AccountRouterListener
    private let configuredPort: UInt16
    private let lock = NSLock()
    private var boundPort: UInt16?
    /// Bumped by every `stop()`, so a bind that completes after one is undone.
    private var stops = 0
    private let bindRetry: BindRetry
    private let settings: CachedSettings<AccountRouterSettings>
    private let modelSettings: CachedSettings<ModelRouterSettings>
    private let providers: any ModelProviderResolving
    private let clientVersions = ModelClientVersionMemory()
    /// The planner every request goes through; tests drive it directly.
    let modelPlanner: ModelRoutingPlanner

    /// The preference writer over this router's database and template store,
    /// so a write lands in the same template directory the router reads.
    public var preferences: AccountRouterPreferences {
        AccountRouterPreferences(database: database, templateStore: templateStore)
    }

    /// How long a request may use settings read by an earlier one. The hot
    /// path then reads the database at most once per interval instead of once
    /// per request; ``settingsChanged()`` invalidates it at once.
    static let settingsTTL: TimeInterval = 2

    /// Rows are written here, off the cooperative pool: GRDB blocks its
    /// caller, and the exchange the row describes has already been served.
    private let recordQueue: DispatchQueue

    /// - Parameters:
    ///   - port: the loopback port to listen on (0 asks the system for one).
    ///   - database: the daemon's database, migrated with `SessionSchema`; the
    ///     settings rows, provider registry and exchange log live there.
    ///   - credentials: the daemon's one credential holder, normally its
    ///     ``AccountQuotaProbe``. The router reads tokens only through it.
    ///   - configuration: the daemon's label, the upstream and the paths.
    public convenience init(
        port: UInt16,
        database: DaemonDatabase,
        credentials: any AccountRouterQuotaSource,
        configuration: AccountRouterConfiguration
    ) {
        AccountRouterLog.configure(label: configuration.label)
        self.init(
            database: database,
            source: credentials,
            port: port,
            upstream: configuration.upstream,
            fingerprintsPath: configuration.fingerprintsPath,
            providers: ModelProviderResolver(
                settings: database.aiProviderSettings, secret: configuration.providerSecret),
            templateStore: ModelRouterTemplateStore(
                directory: configuration.templateDirectory, database: database),
            label: configuration.label)
    }

    init(
        database: DaemonDatabase,
        source: any AccountRouterQuotaSource,
        port: UInt16,
        upstream: URL,
        fingerprintsPath: String,
        limits: RouterLimits = .standard,
        settingsTTL: TimeInterval = AccountRouterServer.settingsTTL,
        clock: @escaping @Sendable () -> Double = { Date().timeIntervalSince1970 },
        pool: AccountPool? = nil,
        providers: (any ModelProviderResolving)? = nil,
        templateStore: ModelRouterTemplateStore,
        bindRetry: BindRetry = BindRetry(),
        network: UpstreamNetwork = .current(),
        label: String = "account-router"
    ) {
        self.bindRetry = bindRetry
        self.configuredPort = port
        self.templateStore = templateStore
        let recordQueue = DispatchQueue(label: "\(label).account-router.record", qos: .utility)
        self.recordQueue = recordQueue
        self.database = database
        self.source = source
        // Tests pass their own pool to put entries in a known state; it must read `source`.
        let pool = pool ?? AccountPool(source: source, clock: clock)
        self.pool = pool
        let settings = CachedSettings(ttl: settingsTTL) { AccountRouterSettings.load(database) }
        self.settings = settings
        let store = self.templateStore
        let modelSettings = CachedSettings(ttl: settingsTTL) { ModelRouterSettings.load(database, store: store) }
        self.modelSettings = modelSettings
        let planner = AccountRoutingPlanner(
            settings: { settings.current() },
            fence: CredentialFence(source: source, fingerprintsPath: fingerprintsPath),
            pool: pool)
        // Provider configurations and their keys: the registry rows a client's
        // AI settings push to the daemon, and the default Keychain namespace.
        let providers: any ModelProviderResolving = providers ?? ModelProviderResolver(
            settings: database.aiProviderSettings, secret: { KeychainSecretStore().get(forKey: $0) })
        self.providers = providers
        let modelPlanner = ModelRoutingPlanner(
            settings: { modelSettings.current() }, providers: providers, versions: clientVersions)
        self.modelPlanner = modelPlanner
        let context = RouterContext(
            planner: planner,
            modelPlanner: modelPlanner,
            session: UpstreamCall.makeSession(network: network), upstream: upstream, limits: limits,
            record: { row in recordQueue.async { Self.record(row, in: database) } })
        server = AccountRouterListener(port: port, acceptLimit: limits.acceptLimit) { connection, ended in
            RouterConnection(connection: connection, context: context, ended: ended).start()
        }
    }

    /// How long a failed bind waits before trying again: `first`, doubling up
    /// to `cap`. Claude Code stays pointed at the router while it is down, so a
    /// port still held at start (another process, or the router's own closed
    /// exchanges in TIME_WAIT after a restart) must not leave it down for good.
    struct BindRetry: Sendable {
        var first: TimeInterval = 1
        var cap: TimeInterval = 30
    }

    /// A start ticket: the stop generation at the moment it was taken.
    struct StartToken: Sendable {
        fileprivate let generation: Int
    }

    /// Takes the ticket synchronously, so a `stop()` that lands before the
    /// asynchronous `start(_:)` even runs is honoured: that start binds nothing.
    func prepareStart() -> StartToken {
        lock.withLock { StartToken(generation: stops) }
    }

    public func start() async {
        await start(prepareStart())
    }

    /// Binds, trying again after every failure until it binds or a `stop()`
    /// ends it. A listener lost after it was ready starts this again.
    func start(_ token: StartToken) async {
        let generation = token.generation
        server.onLost = { [weak self] in self?.listenerLost() }
        var delay = bindRetry.first
        while lock.withLock({ stops == generation }) {
            do {
                let port = try await server.start(timeout: 5)
                // A `stop()` that ran while the bind was pending wins: no stale port.
                let current = lock.withLock { () -> Bool in
                    guard stops == generation else { return false }
                    boundPort = port
                    return true
                }
                guard current else {
                    server.stop()
                    return
                }
                AccountRouterLog.logger.info("Account router listening on 127.0.0.1:\(port, privacy: .public)")
                return
            } catch {
                let reason = AccountRouterLog.scrub(String(describing: error))
                AccountRouterLog.logger.error("""
                    Account router failed to start, trying again in \(delay, privacy: .public)s: \
                    \(reason, privacy: .public)
                    """)
            }
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            delay = min(delay * 2, bindRetry.cap)
        }
    }

    private func listenerLost() {
        let token = lock.withLock { () -> StartToken? in
            guard boundPort != nil else { return nil }
            boundPort = nil
            return StartToken(generation: stops)
        }
        guard let token else { return }
        AccountRouterLog.logger.warning("Account router lost its listener; binding again")
        Task { await self.start(token) }
    }

    /// The settings were written (a daemon's write path calls this): the next
    /// request reads them fresh instead of waiting out the cache.
    public func settingsChanged() {
        settings.invalidate()
        modelSettings.invalidate()
    }

    /// Ends every cool-down, so a rejected or rate-limited account is tried
    /// again on the next request rather than when its cool-down runs out.
    public func clearCooldowns() {
        pool.clearCooldowns()
    }

    /// Closes the listener, then waits for the rows already queued to be
    /// written, so a clean shutdown keeps the last exchanges in `report`.
    public func stop() {
        lock.withLock {
            stops += 1
            boundPort = nil
        }
        server.stop()
        drainRecords()
    }

    /// Returns once every row queued so far is written (or has failed and
    /// been logged). Never call it from the record queue itself.
    func drainRecords() {
        recordQueue.sync {}
    }

    /// Never a token: the pool snapshot and the saved list are item keys and readings.
    public func status() -> Sessions.AccountRouterStatusDTO {
        let settings = AccountRouterSettings.load(database)
        let port = lock.withLock { boundPort }.map(Int.init) ?? Self.unboundPort
        return Sessions.AccountRouterStatusDTO(
            enabled: settings.enabled,
            port: port,
            listening: server.isListening && port != Self.unboundPort,
            baseUrl: "http://127.0.0.1:\(port == Self.unboundPort ? Int(configuredPort) : port)",
            fiveHourCeiling: settings.fiveHourCeiling,
            pool: pool.snapshot(settings: settings),
            savedCredentials: source.savedItemKeys().sorted(),
            cooldownSeconds: settings.cooldownSeconds,
            expiryMarginSeconds: settings.expiryMarginSeconds,
            retry: settings.retry,
            sticky: settings.sticky,
            retentionDays: settings.retentionDays,
            models: modelStatus())
    }

    /// The model router's rows as stored (not the cached copy), and every
    /// configured provider with whether a route can be built for it. No key or URL leaves here.
    private func modelStatus() -> Sessions.ModelRouterStatusDTO {
        let stored = templateStore.load()
        let loaded = ModelRouterSettings.load(database, loaded: stored)
        let providerList = DaemonProviderResolver.configurations(database.aiProviderSettings).map { config in
            Sessions.ModelRouterProviderDTO(
                id: config.id.uuidString, name: config.name,
                model: DaemonProviderResolver.model(config: config.id, database.aiProviderSettings),
                usable: providers.route(config.id) != nil,
                models: AIModelCatalog.shared.offerings[config.templateId]?.keys.sorted())
        }
        let newest = clientVersions.newest
        let selection = Sessions.ModelRouterTemplateSelector.select(
            stored.templates, preferred: stored.preferred, version: newest)
        return Sessions.ModelRouterStatusDTO(
            enabled: loaded.enabled, providers: providerList,
            templates: stored.templates, preferred: stored.preferred.sorted(), skipped: stored.skipped,
            clientVersion: newest?.description, inUse: selection?.template.id,
            inUseIsFallback: selection?.isFallback)
    }

    /// `sinceHours` 0 is all time; anything above `maxReportHours` is clamped to it.
    public func report(sinceHours: Int) throws -> Sessions.AccountRouterReportDTO {
        try database.routerReport(sinceHours: min(max(0, sinceHours), Self.maxReportHours), now: Date())
    }

    /// One page of the routing log, newest first. Read-only.
    public func exchanges(
        _ query: Sessions.AccountRouterExchangeQueryDTO
    ) throws -> Sessions.AccountRouterExchangePageDTO {
        Sessions.AccountRouterExchangePageDTO(exchanges: try database.routerExchangePage(query, now: Date()))
    }

    private static func record(_ row: AccountRouterExchange, in database: DaemonDatabase) {
        guard database.isReady else { return }
        do {
            try database.insertRouterExchange(row)
        } catch {
            let reason = AccountRouterLog.scrub(error.localizedDescription)
            AccountRouterLog.logger.error("Could not record a routed exchange: \(reason, privacy: .public)")
        }
    }
}

/// Settings rows, re-read from the database at most once per `ttl`.
/// A `ttl` of 0 reads on every call.
final class CachedSettings<Value: Sendable>: @unchecked Sendable {
    private let ttl: TimeInterval
    private let load: @Sendable () -> Value
    private let lock = NSLock()
    private var cached: (value: Value, readAt: Date)?
    /// Bumped by `invalidate()`, so a read that began before one is not cached.
    private var generation = 0

    init(ttl: TimeInterval, load: @escaping @Sendable () -> Value) {
        self.ttl = ttl
        self.load = load
    }

    func current(now: Date = Date()) -> Value {
        let (hit, started) = lock.withLock { (cached, generation) }
        if let hit, now.timeIntervalSince(hit.readAt) < ttl { return hit.value }
        let fresh = load()
        lock.withLock { if generation == started { cached = (fresh, now) } }
        return fresh
    }

    func invalidate() {
        lock.withLock {
            cached = nil
            generation += 1
        }
    }
}
#endif
