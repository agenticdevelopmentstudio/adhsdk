// Tests/AgenticDeveloperHubSDKAgentsTests/AgentsTestSupport.swift
//
// Fakes shared by the model registry, agent host, handler and bridge suites:
// an in-memory secret store, a silent cross-process signal, a plugin runtime
// that plays back scripted model rounds, and a handful of tools.
import Foundation
import AIPluginKit
import AgenticDeveloperHubSDKDatabase
@testable import AgenticDeveloperHubSDKAgents

// MARK: - Secrets and signal

/// Secret values in a dictionary, keyed `<entry>/<field>`.
final class FakeModelSecrets: ModelSecretStore, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: String] = [:]

    func value(for entry: UUID, field: String) -> String? {
        lock.withLock { values["\(entry.uuidString)/\(field)"] }
    }

    func set(_ value: String, for entry: UUID, field: String) throws {
        lock.withLock { values["\(entry.uuidString)/\(field)"] = value }
    }

    /// Fields whose removal fails, to exercise `removeFailed`.
    var failingRemovals: Set<String> {
        get { lock.withLock { failing } }
        set { lock.withLock { failing = newValue } }
    }
    private var failing: Set<String> = []

    func remove(for entry: UUID, field: String) throws {
        try lock.withLock {
            if failing.contains(field) { throw ModelSecretStoreError.removeFailed(field: field) }
            values["\(entry.uuidString)/\(field)"] = nil
        }
    }

    var count: Int { lock.withLock { values.count } }
}

/// A signal that only reaches observers in this process, counting its posts.
final class FakeSignal: CrossProcessSignal, @unchecked Sendable {
    private let lock = NSLock()
    private var handler: (@Sendable () -> Void)?
    private(set) var posts = 0

    func post() {
        let current = lock.withLock { () -> (@Sendable () -> Void)? in
            posts += 1
            return handler
        }
        current?()
    }

    func observe(_ handler: @escaping @Sendable () -> Void) {
        lock.withLock { self.handler = handler }
    }
}

// MARK: - Plugin

enum FakePluginConstants {
    static let identifier = "test.fake-plugin"
    static let templateId = "default"
    static let nativeModel = "fake-native"
    static let promptedModel = "fake-prompted"
}

/// A plugin that describes an HTTP request (or, when `useCommand`, a
/// subprocess) and records every context it is asked to build.
final class FakePlugin: AIPlugin, @unchecked Sendable {
    private let lock = NSLock()
    private var contexts: [AIChatContext] = []
    var useCommand = false

    init() {}

    func buildRequest(_ context: AIChatContext) throws -> AIRequestSpec {
        lock.withLock { contexts.append(context) }
        if useCommand {
            return AIRequestSpec(transport: .command(
                executableURL: URL(fileURLWithPath: "/usr/bin/true"), arguments: [], stdin: nil, environment: [:]))
        }
        return AIRequestSpec(transport: .http(
            method: .post, url: URL(string: "https://example.invalid/v1")!, headers: [:], body: nil))
    }

    func makeDecoder() -> any AIStreamDecoder { FakeDecoder() }

    var builtContexts: [AIChatContext] { lock.withLock { contexts } }
}

final class FakeDecoder: AIStreamDecoder {
    func consume(_ data: Data) -> [AIStreamEvent] { [] }
}

/// The fake plugin's descriptor: one template with a secret `apiKey`, a
/// `baseURL` default, one model that takes tools natively and one that does not.
func fakeDescriptor() -> AIPluginDescriptor {
    AIPluginDescriptor(
        identifier: FakePluginConstants.identifier,
        displayName: "Fake",
        version: "1.0",
        templates: [
            AIPluginDescriptor.ProviderTemplate(
                id: FakePluginConstants.templateId,
                displayName: "Fake default",
                defaultValues: ["baseURL": "https://example.invalid"],
                models: [FakePluginConstants.nativeModel, FakePluginConstants.promptedModel],
                defaultModel: FakePluginConstants.nativeModel,
                fields: [AIPluginDescriptor.Field(key: "apiKey", label: "API key", kind: .secret)],
                modelDetails: [
                    AIPluginDescriptor.ModelDetail(id: FakePluginConstants.nativeModel, tools: true),
                    AIPluginDescriptor.ModelDetail(id: FakePluginConstants.promptedModel, tools: false)
                ])
        ])
}

/// Plays back one scripted list of stream events per model round. A round
/// past the script answers "done". `hang` makes every round wait forever
/// (until the turn is cancelled).
final class ScriptedRuntime: @unchecked Sendable {
    private let lock = NSLock()
    private var rounds: [[AIStreamEvent]]
    private var started = 0
    private var held: [AsyncThrowingStream<AIStreamEvent, Error>.Continuation] = []
    let plugin = FakePlugin()
    let hang: Bool

    init(rounds: [[AIStreamEvent]] = [], hang: Bool = false) {
        self.rounds = rounds
        self.hang = hang
    }

    var roundsStarted: Int { lock.withLock { started } }

    private func nextRound() -> [AIStreamEvent] {
        lock.withLock {
            started += 1
            return rounds.isEmpty ? [.textDelta("done"), .end(stopReason: "end_turn")] : rounds.removeFirst()
        }
    }

    var runtime: DaemonAIChat.PluginRuntime {
        DaemonAIChat.PluginRuntime(
            load: { [plugin] identifier, _ in
                guard identifier == FakePluginConstants.identifier else {
                    throw ModelRegistryError.pluginNotInstalled(identifier)
                }
                return (plugin, fakeDescriptor())
            },
            run: { [self] _, _ in
                if hang {
                    // Kept open (the continuation is held) until the turn is cancelled.
                    let (stream, continuation) = AsyncThrowingStream<AIStreamEvent, Error>.makeStream()
                    lock.withLock {
                        started += 1
                        held.append(continuation)
                    }
                    return stream
                }
                let events = nextRound()
                return AsyncThrowingStream { continuation in
                    for event in events { continuation.yield(event) }
                    continuation.finish()
                }
            },
            discover: { _ in [fakeDescriptor()] })
    }
}

// MARK: - Registry and host

func makeEntry(
    name: String = "Fake", id: UUID = UUID(), model: String? = nil, roles: [String] = [], enabled: Bool = true
) -> ModelEntry {
    ModelEntry(
        configuration: AIProviderConfiguration(
            id: id, name: name, pluginIdentifier: FakePluginConstants.identifier,
            templateId: FakePluginConstants.templateId),
        model: model,
        roles: roles,
        enabled: enabled)
}

func makeRegistry(
    runtime: DaemonAIChat.PluginRuntime = ScriptedRuntime().runtime,
    secrets: any ModelSecretStore = FakeModelSecrets(),
    signal: FakeSignal = FakeSignal()
) throws -> ModelRegistry {
    try ModelRegistry(
        database: try BoundedDatabase(path: ":memory:"),
        secrets: secrets,
        runtime: runtime,
        searchPaths: [],
        makeSignal: { signal })
}

func makeAgent(
    id: String = "helper", model: ModelSelector = .role("smart"), thinking: Int? = nil, enabled: Bool = true
) -> AgentDefinition {
    AgentDefinition(
        id: id, name: "Helper", prompt: "You help.", model: model,
        thinkingBudgetTokens: thinking, enabled: enabled)
}

/// A host on in-memory databases with one enabled model entry holding `smart`.
func makeHost(
    script: ScriptedRuntime,
    tools: [any AgentTool] = [EchoTool(), CounterTool(), FailingTool()],
    agents: [AgentDefinition] = [makeAgent()],
    model: String? = nil,
    maxToolRounds: Int = 16
) throws -> AgentHost {
    let registry = try makeRegistry(runtime: script.runtime)
    try registry.upsert(makeEntry(model: model, roles: ["smart"]), secrets: ["apiKey": "test-key"])
    return try AgentHost(
        database: try BoundedDatabase(path: ":memory:"),
        registry: registry,
        tools: tools,
        defaults: agents,
        runtime: script.runtime,
        maxToolRounds: maxToolRounds)
}

/// Every event of a stream, in order, until it ends.
func collect(_ stream: AsyncStream<AgentEnvelope>) async -> [AgentEnvelope] {
    var envelopes: [AgentEnvelope] = []
    for await envelope in stream { envelopes.append(envelope) }
    return envelopes
}

// MARK: - Tools

/// Read-only: returns its arguments under `echo`.
struct EchoTool: AgentTool {
    let name = "echo"
    let description = "Echoes its arguments."
    let inputSchemaJSON = #"{"type":"object","properties":{"text":{"type":"string"}}}"#
    let permissionDefault = ToolPermission.auto
    let isMutating = false

    func run(argumentsJSON: String, context: ToolCallContext) async throws -> ToolOutcome {
        ToolOutcome(resultJSON: #"{"echo":\#(argumentsJSON),"caller":"\#(context.caller)"}"#, summary: "Echoed")
    }
}

/// Mutating: records each call and returns its inverse.
struct CounterTool: AgentTool {
    let name = "bump"
    let description = "Bumps a counter."
    let inputSchemaJSON = #"{"type":"object","properties":{"reason":{"type":"string"}},"required":["reason"]}"#
    let permissionDefault = ToolPermission.ask
    let isMutating = true

    func run(argumentsJSON: String, context: ToolCallContext) async throws -> ToolOutcome {
        ToolOutcome(
            resultJSON: #"{"count":1}"#,
            summary: "Bumped the counter",
            inverse: ToolInvocation(tool: "unbump", argumentsJSON: "{}"))
    }
}

struct FakeToolFailure: Error, LocalizedError {
    var errorDescription: String? { "The tool broke" }
}

/// Always throws `FakeToolFailure`.
struct FailingTool: AgentTool {
    let name = "broken"
    let description = "Always fails."
    let inputSchemaJSON = "{}"
    let permissionDefault = ToolPermission.never
    let isMutating = false

    func run(argumentsJSON: String, context: ToolCallContext) async throws -> ToolOutcome {
        throw FakeToolFailure()
    }
}
