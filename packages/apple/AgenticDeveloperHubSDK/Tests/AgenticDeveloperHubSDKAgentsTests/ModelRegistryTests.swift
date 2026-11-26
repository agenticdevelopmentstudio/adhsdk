// Tests/AgenticDeveloperHubSDKAgentsTests/ModelRegistryTests.swift
import Testing
import Foundation
import AIPluginKit
import AgenticDeveloperHubSDKDatabase
@testable import AgenticDeveloperHubSDKAgents

@Suite("ModelRegistry")
struct ModelRegistryTests {

    @Test("lists entries by name, case-insensitively")
    func listsByName() throws {
        let registry = try makeRegistry()
        try registry.upsert(makeEntry(name: "zeta"), secrets: nil)
        try registry.upsert(makeEntry(name: "Alpha"), secrets: nil)
        try registry.upsert(makeEntry(name: "beta"), secrets: nil)
        #expect(try registry.list().map(\.configuration.name) == ["Alpha", "beta", "zeta"])
    }

    @Test("stores secrets in the secret store and only their names in the entry")
    func secretsStayOutOfTheEntry() throws {
        let secrets = FakeModelSecrets()
        let registry = try makeRegistry(secrets: secrets)
        let entry = makeEntry()
        try registry.upsert(entry, secrets: ["apiKey": "sk-test", "empty": ""])

        let stored = try #require(try registry.get(entry.id))
        #expect(stored.secretFields == ["apiKey"])
        #expect(secrets.value(for: entry.id, field: "apiKey") == "sk-test")
        let json = try AgentsJSON.encodeString(stored)
        #expect(!json.contains("sk-test"))
    }

    @Test("nil secrets keep the stored ones; a new set drops the stale ones")
    func secretUpdates() throws {
        let secrets = FakeModelSecrets()
        let registry = try makeRegistry(secrets: secrets)
        var entry = makeEntry()
        try registry.upsert(entry, secrets: ["apiKey": "one", "orgId": "org"])

        entry.configuration.name = "Renamed"
        try registry.upsert(entry, secrets: nil)
        #expect(try registry.get(entry.id)?.secretFields == ["apiKey", "orgId"])

        try registry.upsert(entry, secrets: ["apiKey": "two"])
        #expect(try registry.get(entry.id)?.secretFields == ["apiKey"])
        #expect(secrets.value(for: entry.id, field: "apiKey") == "two")
        #expect(secrets.value(for: entry.id, field: "orgId") == nil)
    }

    @Test("an update keeps createdAt and advances updatedAt")
    func keepsCreatedAt() throws {
        let registry = try makeRegistry()
        let created = Date(timeIntervalSince1970: 1_000)
        var entry = makeEntry()
        entry.createdAt = created
        try registry.upsert(entry, secrets: nil)
        entry.createdAt = Date()
        try registry.upsert(entry, secrets: nil)
        let stored = try #require(try registry.get(entry.id))
        #expect(stored.createdAt == created)
        #expect(stored.updatedAt > created)
    }

    @Test("remove deletes the entry and its secrets")
    func removeClearsSecrets() throws {
        let secrets = FakeModelSecrets()
        let registry = try makeRegistry(secrets: secrets)
        let entry = makeEntry()
        try registry.upsert(entry, secrets: ["apiKey": "sk"])
        try registry.remove(entry.id)
        #expect(try registry.get(entry.id) == nil)
        #expect(secrets.count == 0)
        try registry.remove(entry.id)
    }

    @Test("a secret that cannot be removed throws and stays listed")
    func secretRemovalFailure() throws {
        let secrets = FakeModelSecrets()
        let registry = try makeRegistry(secrets: secrets)
        let entry = makeEntry()
        try registry.upsert(entry, secrets: ["apiKey": "one", "orgId": "org"])
        secrets.failingRemovals = ["orgId"]

        #expect(throws: ModelSecretStoreError.removeFailed(field: "orgId")) {
            try registry.upsert(entry, secrets: ["apiKey": "two"])
        }
        #expect(try registry.get(entry.id)?.secretFields == ["apiKey", "orgId"])
        #expect(secrets.value(for: entry.id, field: "apiKey") == "two")

        #expect(throws: ModelSecretStoreError.removeFailed(field: "orgId")) {
            try registry.remove(entry.id)
        }
        #expect(try registry.get(entry.id) != nil)

        secrets.failingRemovals = []
        try registry.remove(entry.id)
        #expect(try registry.get(entry.id) == nil)
    }

    @Test("list skips a row that does not decode and returns the rest")
    func skipsCorruptRow() throws {
        let database = try BoundedDatabase(path: ":memory:")
        let registry = try makeRegistry(database: database)
        try registry.upsert(makeEntry(name: "good"), secrets: nil)
        try database.write { conn in
            try conn.execute(
                sql: "INSERT INTO model_entries (id, json, updated_at) VALUES (?, ?, ?)",
                arguments: [UUID().uuidString, "{not json", 0])
        }

        #expect(try registry.list().map(\.configuration.name) == ["good"])
    }

    @Test("an upsert whose secret write fails removes the secrets it added")
    func rollsBackNewSecrets() throws {
        let secrets = FakeModelSecrets()
        let registry = try makeRegistry(secrets: secrets)
        let entry = makeEntry()
        secrets.failingSets = ["orgId"]

        #expect(throws: ModelSecretStoreError.writeFailed(field: "orgId")) {
            try registry.upsert(entry, secrets: ["apiKey": "sk", "orgId": "org"])
        }
        #expect(secrets.count == 0)
        #expect(try registry.get(entry.id) == nil)
    }

    @Test("an upsert whose secret write fails restores the values it replaced")
    func rollsBackReplacedSecrets() throws {
        let secrets = FakeModelSecrets()
        let registry = try makeRegistry(secrets: secrets)
        let entry = makeEntry()
        try registry.upsert(entry, secrets: ["apiKey": "one"])
        secrets.failingSets = ["orgId"]

        #expect(throws: ModelSecretStoreError.writeFailed(field: "orgId")) {
            try registry.upsert(entry, secrets: ["apiKey": "two", "orgId": "org"])
        }
        #expect(secrets.value(for: entry.id, field: "apiKey") == "one")
        #expect(secrets.value(for: entry.id, field: "orgId") == nil)
        #expect(try registry.get(entry.id)?.secretFields == ["apiKey"])
    }

    @Test("create stores a new entry once; a second create of its id is a duplicate")
    func createsOnce() throws {
        let secrets = FakeModelSecrets()
        let registry = try makeRegistry(secrets: secrets)
        let entry = makeEntry()

        let stored = try registry.create(entry, secrets: ["apiKey": "one"])
        #expect(stored.secretFields == ["apiKey"])
        #expect(throws: ModelRegistryError.duplicate(entry.id)) {
            try registry.create(entry, secrets: ["apiKey": "two"])
        }
        #expect(secrets.value(for: entry.id, field: "apiKey") == "one")
        #expect(try registry.list().count == 1)
    }

    @Test("concurrent creates of one id store one entry")
    func concurrentCreates() async throws {
        let registry = try makeRegistry()
        let entry = makeEntry()

        let outcomes = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<8 {
                group.addTask { (try? registry.create(entry)) != nil }
            }
            return await group.reduce(into: [Bool]()) { $0.append($1) }
        }

        #expect(outcomes.filter { $0 }.count == 1)
        #expect(try registry.list().count == 1)
    }

    @Test("create validates like upsert and rolls back a failed secret write")
    func createValidates() throws {
        let secrets = FakeModelSecrets()
        let registry = try makeRegistry(secrets: secrets)
        #expect(throws: ModelRegistryError.self) { try registry.create(makeEntry(name: " ")) }

        let entry = makeEntry()
        secrets.failingSets = ["orgId"]
        #expect(throws: ModelSecretStoreError.writeFailed(field: "orgId")) {
            try registry.create(entry, secrets: ["apiKey": "sk", "orgId": "org"])
        }
        #expect(secrets.count == 0)
        #expect(try registry.get(entry.id) == nil)
    }

    @Test("rejects an entry without a name, plugin or template")
    func validates() throws {
        let registry = try makeRegistry()
        #expect(throws: ModelRegistryError.self) { try registry.upsert(makeEntry(name: "  "), secrets: nil) }
        let noPlugin = ModelEntry(configuration: AIProviderConfiguration(
            name: "x", pluginIdentifier: "", templateId: FakePluginConstants.templateId))
        #expect(throws: ModelRegistryError.self) { try registry.upsert(noPlugin, secrets: nil) }
        let noTemplate = ModelEntry(configuration: AIProviderConfiguration(
            name: "x", pluginIdentifier: FakePluginConstants.identifier, templateId: ""))
        #expect(throws: ModelRegistryError.self) { try registry.upsert(noTemplate, secrets: nil) }
    }

    @Test("a role resolves to the first enabled entry holding it")
    func resolvesRole() throws {
        let registry = try makeRegistry()
        try registry.upsert(makeEntry(name: "A", roles: ["fast"], enabled: false), secrets: nil)
        let second = makeEntry(name: "B", roles: ["fast", "cheap"])
        try registry.upsert(second, secrets: nil)
        #expect(try registry.resolve(role: "fast")?.id == second.id)
        #expect(try registry.resolve(role: "smart") == nil)
    }

    @Test("a selector resolves the model and the secrets")
    func resolvesSelector() throws {
        let registry = try makeRegistry()
        let entry = makeEntry(model: "fake-native", roles: ["smart"])
        try registry.upsert(entry, secrets: ["apiKey": "sk"])

        let byRole = try #require(try registry.resolve(.role("smart")))
        #expect(byRole.model == "fake-native")
        #expect(byRole.secrets == ["apiKey": "sk"])

        let byConfig = try #require(try registry.resolve(.config(id: entry.id, model: "fake-prompted")))
        #expect(byConfig.model == "fake-prompted")
        #expect(try registry.resolve(.config(id: entry.id, model: ""))?.model == "fake-native")
        #expect(try registry.resolve(.config(id: UUID(), model: nil)) == nil)
    }

    @Test("a disabled entry does not resolve by id")
    func disabledEntryDoesNotResolve() throws {
        let registry = try makeRegistry()
        let entry = makeEntry(enabled: false)
        try registry.upsert(entry, secrets: nil)
        #expect(try registry.resolve(.config(id: entry.id, model: nil)) == nil)
    }

    @Test("request merges template defaults under the entry's fields and adds secrets and model")
    func requestValues() throws {
        var entry = makeEntry()
        entry.fields = ["authMode": "key"]
        let resolved = ResolvedModel(entry: entry, model: nil, secrets: ["apiKey": "sk"])
        let request = resolved.request(descriptor: fakeDescriptor())
        #expect(request.model == FakePluginConstants.nativeModel)
        #expect(request.config.values["baseURL"] == "https://example.invalid")
        #expect(request.config.values["authMode"] == "key")
        #expect(request.config.values["apiKey"] == "sk")
        #expect(request.config.values["model"] == FakePluginConstants.nativeModel)
    }

    @Test("plugins lists the discovered descriptors")
    func listsPlugins() async throws {
        let registry = try makeRegistry()
        let plugins = await registry.plugins()
        #expect(plugins.map(\.identifier) == [FakePluginConstants.identifier])
        #expect(plugins.first?.templates.first?.models.count == 2)
    }

    @Test("plugins lists refused plugins with their load error, and using one is incompatible")
    func listsRefusedPlugins() async throws {
        var runtime = ScriptedRuntime().runtime
        let refusal = PluginLoadFailure(
            identifier: "com.test.stale", displayName: "Stale",
            message: "Plugin 'Stale' was built against AIPluginKit ABI 0, but this host has ABI 1; rebuild the plugin")
        runtime.refused = { _ in [refusal] }
        runtime.discover = { _ in [] }
        let registry = try makeRegistry(runtime: runtime)

        let plugins = await registry.plugins()
        #expect(plugins.map(\.identifier) == ["com.test.stale"])
        #expect(plugins.first?.loadError == refusal.message)
        #expect(plugins.first?.templates.isEmpty == true)

        let entry = ModelEntry(configuration: AIProviderConfiguration(
            name: "stale", pluginIdentifier: "com.test.stale", templateId: "t"))
        try registry.upsert(entry, secrets: nil)
        let incompatible = ModelRegistryError.pluginIncompatible(plugin: "com.test.stale", message: refusal.message)
        await #expect(throws: incompatible) {
            _ = try await registry.listModels(entry.id)
        }
    }

    @Test("test reports the model's reply")
    func testsAModel() async throws {
        let script = ScriptedRuntime(rounds: [[.textDelta(" OK\n"), .end(stopReason: "end_turn")]])
        let registry = try makeRegistry(runtime: script.runtime)
        let entry = makeEntry()
        try registry.upsert(entry, secrets: ["apiKey": "sk"])
        let result = await registry.test(entry.id)
        #expect(result.isOK)
        #expect(result.message == "OK")
        #expect(result.latencyMs >= 0)
        #expect(script.plugin.builtContexts.first?.maxTokens == 64)
    }

    @Test("test fails on an empty reply and on an unknown id")
    func testFailures() async throws {
        let script = ScriptedRuntime(rounds: [[.end(stopReason: "end_turn")]])
        let registry = try makeRegistry(runtime: script.runtime)
        let entry = makeEntry()
        try registry.upsert(entry, secrets: nil)
        #expect(await registry.test(entry.id).isOK == false)
        #expect(await registry.test(UUID()).isOK == false)
    }

    @Test("every write posts the change signal and wakes a changes stream")
    func postsChanges() async throws {
        let signal = FakeSignal()
        let registry = try makeRegistry(signal: signal)
        let changes = registry.changes
        let entry = makeEntry()
        try registry.upsert(entry, secrets: nil)
        try registry.remove(entry.id)
        #expect(signal.posts == 2)
        var iterator = changes.makeAsyncIterator()
        #expect(await iterator.next() != nil)
    }

    @Test("ModelTestResult carries `ok` on the wire")
    func testResultWire() throws {
        let json = try AgentsJSON.encodeString(ModelTestResult(isOK: true, latencyMs: 12, message: "OK"))
        #expect(json.contains(#""ok":true"#))
        let decoded = try AgentsJSON.decode(ModelTestResult.self, from: json)
        #expect(decoded.isOK)
    }

    @Test("ModelSelector round-trips its flat JSON form")
    func selectorWire() throws {
        let id = UUID()
        for selector in [ModelSelector.role("fast"), .config(id: id, model: "m"), .config(id: id, model: nil)] {
            let data = try AgentsJSON.encode(selector)
            #expect(try AgentsJSON.decode(ModelSelector.self, from: data) == selector)
        }
        let role = try AgentsJSON.decode(ModelSelector.self, from: #"{"type":"role","role":"smart"}"#)
        #expect(role == .role("smart"))
    }

    @Test("a minimal ModelEntry decodes with defaults")
    func minimalEntryDecodes() throws {
        let id = UUID()
        let json = """
            {"configuration":{"id":"\(id.uuidString)","name":"Min","pluginIdentifier":"p","templateId":"t"}}
            """
        let entry = try AgentsJSON.decode(ModelEntry.self, from: json)
        #expect(entry.id == id)
        #expect(entry.enabled)
        #expect(entry.roles.isEmpty)
        #expect(entry.secretFields.isEmpty)
    }
}
