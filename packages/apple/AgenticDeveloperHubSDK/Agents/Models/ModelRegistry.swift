import Foundation
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDatabase
import AIPluginKit
import GRDB

/// The suite's shared list of model configurations: one SQLite file every app
/// and daemon on the Mac opens, secrets in the shared Keychain group, and a
/// Darwin notification after every write so each process re-reads.
public final class ModelRegistry: Sendable {

    /// The Darwin notification every write posts.
    public static let changeNotificationName = "com.agenticdevelopmentstudio.models.changed"

    /// `~/Library/Application Support/com.agenticdevelopmentstudio.models/models.sqlite`
    public static var defaultStoreURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent("com.agenticdevelopmentstudio.models", isDirectory: true)
            .appendingPathComponent("models.sqlite")
    }

    private let database: BoundedDatabase
    private let secrets: any ModelSecretStore
    private let runtime: DaemonAIChat.PluginRuntime
    /// Where plugins are looked for; the agent host loads from the same places.
    let searchPaths: [URL]
    private let signal: any CrossProcessSignal
    private let makeSignal: @Sendable () -> any CrossProcessSignal

    /// Opens (creating when absent) the registry at `storeURL`.
    public convenience init(
        storeURL: URL = ModelRegistry.defaultStoreURL,
        secrets: any ModelSecretStore = SharedGroupModelSecrets(),
        runtime: DaemonAIChat.PluginRuntime = .live
    ) throws {
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try self.init(
            database: BoundedDatabase(path: storeURL.path), secrets: secrets, runtime: runtime)
    }

    /// The registry on an open database (a test passes `:memory:`).
    /// - Parameters:
    ///   - searchPaths: where plugins are looked for; the daemon's defaults.
    ///   - makeSignal: the change signal; one instance posts, and each
    ///     `changes` stream observes its own.
    public init(
        database: BoundedDatabase,
        secrets: any ModelSecretStore,
        runtime: DaemonAIChat.PluginRuntime = .live,
        searchPaths: [URL] = DaemonAIChat.pluginSearchPaths(),
        makeSignal: @escaping @Sendable () -> any CrossProcessSignal = {
            DarwinNotificationSignal(name: ModelRegistry.changeNotificationName)
        }
    ) throws {
        self.database = database
        self.secrets = secrets
        self.runtime = runtime
        self.searchPaths = searchPaths
        self.makeSignal = makeSignal
        self.signal = makeSignal()
        try Self.migrator().migrate(database.writer)
    }

    // MARK: - Entries

    /// Every entry, by name (case-insensitive), then id.
    public func list() throws -> [ModelEntry] {
        let rows = try database.read { conn in
            try String.fetchAll(conn, sql: "SELECT json FROM model_entries")
        }
        return try rows.map { try AgentsJSON.decode(ModelEntry.self, from: $0) }.sorted(by: Self.byName)
    }

    public func get(_ id: UUID) throws -> ModelEntry? {
        let row = try database.read { conn in
            try String.fetchOne(conn, sql: "SELECT json FROM model_entries WHERE id = ?", arguments: [id.uuidString])
        }
        return try row.map { try AgentsJSON.decode(ModelEntry.self, from: $0) }
    }

    /// Inserts or replaces `entry`. `secrets` nil leaves the stored secrets
    /// (and `secretFields`) as they are; a dictionary replaces them, an empty
    /// value or a field left out removing that secret. `createdAt` is kept from
    /// the stored entry, and `updatedAt` is now. The stored row is read and
    /// written in one transaction, so concurrent upserts of one id are
    /// last-writer-wins and never lose `createdAt`. A secret that cannot be
    /// removed stays listed in `secretFields`, and the call throws after the
    /// row is written.
    public func upsert(_ entry: ModelEntry, secrets newSecrets: [String: String]?) throws {
        try Self.validate(entry)
        var entry = entry
        entry.updatedAt = Date()
        var failedRemoval: Error?
        var newFields: [String]?
        if let newSecrets {
            let kept = newSecrets.filter { !$0.value.isEmpty }
            for (field, value) in kept {
                try secrets.set(value, for: entry.id, field: field)
            }
            var fields = Set(kept.keys)
            let stale = Set(try get(entry.id)?.secretFields ?? []).subtracting(kept.keys)
            for field in stale.sorted() {
                do {
                    try secrets.remove(for: entry.id, field: field)
                } catch {
                    fields.insert(field)
                    failedRemoval = failedRemoval ?? error
                }
            }
            newFields = fields.sorted()
        }
        try database.write { conn in
            let row = try String.fetchOne(
                conn, sql: "SELECT json FROM model_entries WHERE id = ?", arguments: [entry.id.uuidString])
            let existing = try row.map { try AgentsJSON.decode(ModelEntry.self, from: $0) }
            entry.createdAt = existing?.createdAt ?? entry.createdAt
            entry.secretFields = newFields ?? existing?.secretFields ?? entry.secretFields
            try conn.execute(
                sql: """
                    INSERT INTO model_entries (id, json, updated_at) VALUES (?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET json = excluded.json, updated_at = excluded.updated_at
                    """,
                arguments: [entry.id.uuidString, try AgentsJSON.encodeString(entry),
                            entry.updatedAt.timeIntervalSince1970])
        }
        signal.post()
        if let failedRemoval { throw failedRemoval }
    }

    /// Removes the entry and its secrets. Removing an absent id is not an
    /// error. The secrets go first: one that cannot be removed throws and
    /// leaves the entry stored, so the removal can be retried.
    public func remove(_ id: UUID) throws {
        let existing = try get(id)
        for field in existing?.secretFields ?? [] {
            try secrets.remove(for: id, field: field)
        }
        try database.write { conn in
            try conn.execute(sql: "DELETE FROM model_entries WHERE id = ?", arguments: [id.uuidString])
        }
        signal.post()
    }

    // MARK: - Resolution

    /// The first enabled entry holding `role`, by name.
    public func resolve(role: String) throws -> ModelEntry? {
        try list().first { $0.enabled && $0.roles.contains(role) }
    }

    /// The entry, model and secrets a selector names, or nil when no enabled
    /// entry matches. A `.config` selector naming a disabled entry resolves to
    /// nil too: disabling an entry takes it out of service everywhere.
    public func resolve(_ selector: ModelSelector) throws -> ResolvedModel? {
        let entry: ModelEntry?
        let model: String?
        switch selector {
        case .role(let role):
            entry = try resolve(role: role)
            model = entry?.effectiveModel
        case let .config(id, override):
            entry = try get(id).flatMap { $0.enabled ? $0 : nil }
            model = override.flatMap { $0.isEmpty ? nil : $0 } ?? entry?.effectiveModel
        }
        guard let entry else { return nil }
        return ResolvedModel(entry: entry, model: model, secrets: secretValues(of: entry))
    }

    // MARK: - Plugins

    /// The installed plugins, read from their descriptors (no code is loaded).
    public func plugins() async -> [PluginSummary] {
        await runtime.discover(searchPaths)
            .map(PluginSummary.init)
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    /// The models the entry's provider offers now: its live list when the
    /// provider has one and answers, else the template's static list.
    public func listModels(_ id: UUID) async throws -> [String] {
        guard let entry = try get(id) else { throw ModelRegistryError.notFound(id) }
        let descriptor = try await descriptor(for: entry)
        let config = entry.configuration
        guard let template = descriptor.template(id: config.templateId) else {
            throw ModelRegistryError.unknownTemplate(plugin: config.pluginIdentifier, template: config.templateId)
        }
        let apiKey = secretValues(of: entry)["apiKey"]
        let baseURL = entry.fields["baseURL"]
        // The managers are main-actor objects; only the source they pick is
        // needed, and loading it runs off the main actor.
        let source = await MainActor.run {
            ProviderModels.manager(
                pluginIdentifier: config.pluginIdentifier, template: template, baseURL: baseURL, apiKey: apiKey
            ).source
        }
        if let loaded = await source?.load() {
            return loaded.list.allIDs
        }
        return template.models
    }

    /// A one-line round trip to the entry's default model.
    public func test(_ id: UUID) async -> ModelTestResult {
        let clock = ContinuousClock()
        let start = clock.now
        func milliseconds() -> Int {
            let elapsed = start.duration(to: clock.now).components
            return Int(elapsed.seconds) * 1000 + Int(elapsed.attoseconds / 1_000_000_000_000_000)
        }
        do {
            guard let entry = try get(id) else { throw ModelRegistryError.notFound(id) }
            let resolved = ResolvedModel(entry: entry, model: entry.effectiveModel, secrets: secretValues(of: entry))
            let (plugin, descriptor) = try await runtime.load(entry.configuration.pluginIdentifier, searchPaths)
            let request = resolved.request(descriptor: descriptor)
            let context = AIChatContext(
                messages: [AIChatMessage(role: .user, content: "Reply with the single word OK.")],
                model: request.model,
                systemPrompt: nil,
                maxTokens: 64,
                config: request.config)
            let spec = try plugin.buildRequest(context)
            var reply = ""
            streamLoop: for try await event in runtime.run(spec, plugin) {
                switch event {
                case .textDelta(let text): reply += text
                case .end: break streamLoop
                case .thinkingDelta, .toolUse, .usage: continue
                }
            }
            let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return ModelTestResult(isOK: false, latencyMs: milliseconds(), message: "Empty reply from the model")
            }
            return ModelTestResult(isOK: true, latencyMs: milliseconds(), message: trimmed)
        } catch {
            return ModelTestResult(isOK: false, latencyMs: milliseconds(), message: error.localizedDescription)
        }
    }

    // MARK: - Changes

    /// Yields once for every write by any process, this one included. Each
    /// stream observes its own signal, released when the stream ends.
    public var changes: AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let observer = makeSignal()
        observer.observe { continuation.yield(()) }
        // Holding the observer in the termination handler keeps it alive for
        // exactly as long as the stream.
        continuation.onTermination = { _ in _ = observer }
        return stream
    }

    // MARK: - Loading a plugin

    /// The descriptor of the entry's plugin, from discovery (no code loaded).
    func descriptor(for entry: ModelEntry) async throws -> AIPluginDescriptor {
        let pluginId = entry.configuration.pluginIdentifier
        guard let descriptor = await runtime.discover(searchPaths).first(where: { $0.identifier == pluginId }) else {
            throw ModelRegistryError.pluginNotInstalled(pluginId)
        }
        return descriptor
    }

    // MARK: - Helpers

    private func secretValues(of entry: ModelEntry) -> [String: String] {
        var values: [String: String] = [:]
        for field in entry.secretFields {
            values[field] = secrets.value(for: entry.id, field: field)
        }
        return values
    }

    private static func validate(_ entry: ModelEntry) throws {
        let config = entry.configuration
        if config.name.trimmingCharacters(in: .whitespaces).isEmpty {
            throw ModelRegistryError.invalidEntry("A model entry needs a name")
        }
        if config.pluginIdentifier.isEmpty {
            throw ModelRegistryError.invalidEntry("A model entry needs a plugin identifier")
        }
        if config.templateId.isEmpty {
            throw ModelRegistryError.invalidEntry("A model entry needs a template id")
        }
    }

    private static func byName(_ lhs: ModelEntry, _ rhs: ModelEntry) -> Bool {
        switch lhs.configuration.name.localizedCaseInsensitiveCompare(rhs.configuration.name) {
        case .orderedAscending: return true
        case .orderedDescending: return false
        case .orderedSame: return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    static func migrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("models-v1") { conn in
            try conn.execute(sql: """
                CREATE TABLE model_entries (
                    id TEXT PRIMARY KEY NOT NULL,
                    json TEXT NOT NULL,
                    updated_at REAL
                )
                """)
        }
        return migrator
    }
}

extension ResolvedModel {

    /// The model id and value bag a request to this entry uses: the template's
    /// default values under the entry's fields, its secrets, then the model
    /// (the resolved one, else the template's default).
    public func request(descriptor: AIPluginDescriptor) -> (model: String, config: AIPluginConfig) {
        let templateId = entry.configuration.templateId
        let model = descriptor.effectiveModel(stored: model, templateId: templateId)
        var fields = descriptor.template(id: templateId)?.defaultValues ?? [:]
        fields.merge(entry.fields) { _, stored in stored }
        let values = descriptor.requestValues(templateId: templateId, fields: fields, secrets: secrets, model: model)
        return (model, AIPluginConfig(values))
    }
}
