import Foundation
import AgenticDeveloperHubSDKDatabase
import AIPluginKit

/// Why the host refused a request.
public enum AgentHostError: Error, LocalizedError, Equatable {
    case agentNotFound(String)
    case agentDisabled(String)
    case sessionNotFound(UUID)
    /// The session already has a turn running.
    case turnInProgress(UUID)
    case invalidAgent(String)

    public var errorDescription: String? {
        switch self {
        case .agentNotFound(let id): return "No agent with id '\(id)'"
        case .agentDisabled(let id): return "The agent '\(id)' is disabled"
        case .sessionNotFound(let id): return "No session with id \(id.uuidString)"
        case .turnInProgress(let id): return "Session \(id.uuidString) already has a turn running"
        case .invalidAgent(let reason): return reason
        }
    }
}

/// Hosts a set of agents over one set of tools: stores their definitions and
/// sessions, runs their turns through the model registry's plugins, and
/// streams what happens as `AgentEnvelope`s.
public actor AgentHost {

    /// The caller name a tool sees when an agent's turn runs it.
    public static let agentCaller = "agent"

    public nonisolated let tools: [any AgentTool]

    private let store: AgentStore
    private let registry: ModelRegistry
    private let runtime: DaemonAIChat.PluginRuntime
    private let maxToolRounds: Int

    private var turns: [UUID: (token: UUID, task: Task<Void, Never>)] = [:]
    private var turnStreams: [UUID: AsyncStream<AgentEnvelope>.Continuation] = [:]
    private var tails: [UUID: [UUID: AsyncStream<AgentEnvelope>.Continuation]] = [:]
    private var nextSeq: [UUID: Int] = [:]

    /// - Parameters:
    ///   - database: where the host keeps its tables (roosterd passes `events.sqlite`).
    ///   - defaults: agents inserted when their id is absent; an edited one is kept.
    ///   - maxToolRounds: model round trips a turn may make before it fails;
    ///     a value below 1 is taken as 1.
    public init(
        database: BoundedDatabase,
        registry: ModelRegistry,
        tools: [any AgentTool],
        defaults: [AgentDefinition],
        runtime: DaemonAIChat.PluginRuntime = .live,
        maxToolRounds: Int = 16
    ) throws {
        self.store = try AgentStore(database: database)
        self.registry = registry
        self.tools = tools
        self.runtime = runtime
        self.maxToolRounds = max(1, maxToolRounds)
        try store.insertDefaults(defaults)
    }

    // MARK: - Agents

    public func agents() throws -> [AgentDefinition] { try store.agents() }

    public func agent(_ id: String) throws -> AgentDefinition? { try store.agent(id) }

    public func save(_ agent: AgentDefinition) throws {
        if agent.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AgentHostError.invalidAgent("An agent needs an id")
        }
        if agent.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AgentHostError.invalidAgent("An agent needs a name")
        }
        try store.save(agent)
    }

    // MARK: - Sessions

    public func createSession(agentId: String, title: String?) throws -> AgentSessionInfo {
        guard try store.agent(agentId) != nil else { throw AgentHostError.agentNotFound(agentId) }
        return try store.createSession(agentId: agentId, title: title)
    }

    public func sessions(agentId: String?) throws -> [AgentSessionInfo] {
        try store.sessions(agentId: agentId)
    }

    public func session(_ id: UUID) throws -> AgentSessionDetail? {
        guard let info = try store.session(id) else { return nil }
        return AgentSessionDetail(info: info, messages: try store.messages(id))
    }

    /// Deletes the session and its messages, stopping a running turn and
    /// ending every stream on it. The stopped turn emits and stores nothing more.
    public func deleteSession(_ id: UUID) throws {
        turns.removeValue(forKey: id)?.task.cancel()
        turnStreams.removeValue(forKey: id)?.finish()
        try store.deleteSession(id)
        for continuation in (tails.removeValue(forKey: id) ?? [:]).values {
            continuation.finish()
        }
        nextSeq[id] = nil
    }

    // MARK: - Turns

    /// Stores `text` as the user's message and runs one turn. The stream ends
    /// after its `turn_finished` or `turn_failed`; ending it early does not stop
    /// the turn (`interrupt` does).
    public func send(_ text: String, to session: UUID) throws -> AsyncStream<AgentEnvelope> {
        guard let info = try store.session(session) else { throw AgentHostError.sessionNotFound(session) }
        guard let agent = try store.agent(info.agentId) else { throw AgentHostError.agentNotFound(info.agentId) }
        guard agent.enabled else { throw AgentHostError.agentDisabled(agent.id) }
        guard turns[session] == nil else { throw AgentHostError.turnInProgress(session) }

        try store.append(AIChatMessage(role: .user, content: text), to: session)
        let (stream, continuation) = AsyncStream<AgentEnvelope>.makeStream()
        turnStreams[session] = continuation
        let token = UUID()
        turns[session] = (token, Task { await self.runTurn(session: session, agent: agent, token: token) })
        return stream
    }

    /// Every event on the session from now on, across turns, until the
    /// session is deleted or the caller stops listening.
    public func events(_ session: UUID) -> AsyncStream<AgentEnvelope> {
        let (stream, continuation) = AsyncStream<AgentEnvelope>.makeStream()
        let key = UUID()
        tails[session, default: [:]][key] = continuation
        continuation.onTermination = { _ in
            Task { await self.removeTail(session: session, key: key) }
        }
        return stream
    }

    /// Stops the session's running turn, which then ends with
    /// `turn_finished` and stop reason `interrupted`. Nothing running is not an error.
    public func interrupt(_ session: UUID) {
        turns[session]?.task.cancel()
    }

    // MARK: - Tools

    /// Runs one tool outside any turn — for a client of the host's handlers or
    /// its MCP bridge. A mutating tool run in a session (`context.sessionId`)
    /// reports its activity there.
    public func runTool(_ name: String, argumentsJSON: String, context: ToolCallContext) async throws -> ToolOutcome {
        guard let tool = tools.first(where: { $0.name == name }) else { throw AgentToolError.unknownTool(name) }
        let outcome = try await tool.run(argumentsJSON: argumentsJSON, context: context)
        if tool.isMutating, let sessionId = context.sessionId {
            emit(.activity(Self.activity(tool: name, argumentsJSON: argumentsJSON, outcome: outcome, context: context)),
                 session: sessionId)
        }
        return outcome
    }

    // MARK: - The loop

    private func runTurn(session: UUID, agent: AgentDefinition, token: UUID) async {
        let final: AgentEvent
        do {
            final = try await loop(session: session, agent: agent)
        } catch is CancellationError {
            final = .turnFinished(stopReason: Self.interruptedStopReason)
        } catch {
            final = Task.isCancelled
                ? .turnFinished(stopReason: Self.interruptedStopReason)
                : .turnFailed(message: error.localizedDescription)
        }
        // A turn whose session was deleted meanwhile no longer owns it.
        guard turns[session]?.token == token else { return }
        emit(final, session: session)
        turnStreams.removeValue(forKey: session)?.finish()
        turns[session] = nil
    }

    static let interruptedStopReason = "interrupted"

    /// Runs model round trips until the model answers without asking for a
    /// tool; returns the turn's last event.
    private func loop(session: UUID, agent: AgentDefinition) async throws -> AgentEvent {
        guard let resolved = try resolveModel(agent.model) else {
            return .turnFailed(message: "No model is available: add and enable one in the model registry")
        }
        let config = resolved.entry.configuration
        let (loaded, descriptor) = try await runtime.load(config.pluginIdentifier, registry.searchPaths)
        let request = resolved.request(descriptor: descriptor)
        let specs = tools.map {
            AIToolSpec(name: $0.name, description: $0.description, parametersJSONSchema: Data($0.inputSchemaJSON.utf8))
        }
        let toolContext = ToolCallContext(caller: Self.agentCaller, agentId: agent.id, sessionId: session)
        var plugin: (any AIPlugin)?

        for _ in 0..<maxToolRounds {
            try Task.checkCancellation()
            let history = try store.messages(session).compactMap(\.chatMessage)
            let context = AIChatContext(
                messages: history,
                model: request.model,
                systemPrompt: agent.prompt.isEmpty ? nil : agent.prompt,
                maxTokens: Self.maxTokens(thinking: agent.thinkingBudgetTokens),
                tools: specs,
                thinkingBudgetTokens: agent.thinkingBudgetTokens,
                config: request.config)
            let chosen = try plugin ?? Self.choosePlugin(
                loaded, descriptor: descriptor, model: request.model, templateId: config.templateId, context: context)
            plugin = chosen
            let spec = try chosen.buildRequest(context)

            var text = ""
            var uses: [(id: String, name: String, arguments: Data)] = []
            var usage: AIUsage?
            var stopReason: String?
            for try await event in runtime.run(spec, chosen) {
                try Task.checkCancellation()
                switch event {
                case .textDelta(let chunk):
                    text += chunk
                    emit(.textDelta(chunk), session: session)
                case .thinkingDelta(let chunk):
                    emit(.thinkingDelta(chunk), session: session)
                case let .toolUse(id, name, arguments):
                    uses.append((id, name, arguments))
                case .usage(let latest):
                    usage = latest
                case .end(let reason):
                    stopReason = reason
                }
            }
            try Task.checkCancellation()
            if !text.isEmpty {
                try store.append(AIChatMessage(role: .assistant, content: text), to: session)
            }
            if let usage { emit(.usage(usage), session: session) }
            if uses.isEmpty { return .turnFinished(stopReason: stopReason) }

            for use in uses {
                try await call(use, context: toolContext)
            }
        }
        return .turnFailed(message: "The agent used tools for \(maxToolRounds) rounds without answering")
    }

    /// Runs one tool the model asked for, storing the call and its result; a
    /// tool that throws (or does not exist) goes back to the model as an error result.
    private func call(_ use: (id: String, name: String, arguments: Data), context: ToolCallContext) async throws {
        guard let session = context.sessionId else { return }
        try Task.checkCancellation()
        let argumentsJSON = String(bytes: use.arguments, encoding: .utf8) ?? ""
        try store.append(
            AIChatMessage(role: .toolUse, content: "", toolUseId: use.id, toolName: use.name,
                          toolArgumentsJSON: use.arguments),
            to: session)
        emit(.toolStarted(callId: use.id, tool: use.name, argumentsJSON: argumentsJSON), session: session)

        let content: String
        let isError: Bool
        do {
            guard let tool = tools.first(where: { $0.name == use.name }) else {
                throw AgentToolError.unknownTool(use.name)
            }
            let outcome = try await tool.run(argumentsJSON: argumentsJSON, context: context)
            // Interrupted (or deleted) while the tool ran: leave the tool_use unanswered.
            try Task.checkCancellation()
            content = outcome.resultJSON
            isError = false
            emit(.toolFinished(callId: use.id, tool: use.name, summary: outcome.summary, error: nil), session: session)
            if tool.isMutating {
                emit(.activity(Self.activity(tool: use.name, argumentsJSON: argumentsJSON, outcome: outcome,
                                             context: context)),
                     session: session)
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            let message = error.localizedDescription
            content = Self.errorJSON(message)
            isError = true
            emit(.toolFinished(callId: use.id, tool: use.name, summary: "\(use.name) failed", error: message),
                 session: session)
        }
        try store.append(
            AIChatMessage(role: .toolResult, content: content, toolUseId: use.id, toolIsError: isError),
            to: session)
    }

    // MARK: - Model

    /// The agent's model. A role no enabled entry holds falls back to the
    /// first enabled entry, so an agent works as soon as any model is set up.
    private func resolveModel(_ selector: ModelSelector) throws -> ResolvedModel? {
        if let resolved = try registry.resolve(selector) { return resolved }
        guard case .role = selector, let first = try registry.list().first(where: \.enabled) else { return nil }
        return try registry.resolve(.config(id: first.id, model: nil))
    }

    /// The plugin the turn runs through: the loaded one when its template says
    /// the model takes tools natively and it speaks HTTP, else the loaded one
    /// wrapped so tools are described in the prompt. A subprocess provider
    /// (`claude -p`) never receives native tool definitions.
    static func choosePlugin(
        _ plugin: any AIPlugin, descriptor: AIPluginDescriptor, model: String, templateId: String,
        context: AIChatContext
    ) throws -> any AIPlugin {
        guard !context.tools.isEmpty else { return plugin }
        if descriptor.declaresNativeTools(model: model, templateId: templateId),
           case .http = try plugin.buildRequest(context).transport {
            return plugin
        }
        return PromptedToolCallingPlugin(wrapping: plugin)
    }

    /// Room for the answer on top of any thinking budget.
    static func maxTokens(thinking: Int?) -> Int {
        let answer = 4096
        return answer + (thinking ?? 0)
    }

    // MARK: - Events

    private func emit(_ event: AgentEvent, session: UUID) {
        let seq = nextSeq[session, default: 0]
        nextSeq[session] = seq + 1
        let envelope = AgentEnvelope(sessionId: session, seq: seq, event: event)
        turnStreams[session]?.yield(envelope)
        for continuation in (tails[session] ?? [:]).values {
            continuation.yield(envelope)
        }
    }

    private func removeTail(session: UUID, key: UUID) {
        tails[session]?[key] = nil
        if tails[session]?.isEmpty == true { tails[session] = nil }
    }

    // MARK: - Helpers

    static func activity(
        tool: String, argumentsJSON: String, outcome: ToolOutcome, context: ToolCallContext
    ) -> ActivityEntry {
        ActivityEntry(
            agentId: context.agentId ?? context.caller,
            sessionId: context.sessionId,
            tool: tool,
            argumentsJSON: argumentsJSON,
            reason: reason(in: argumentsJSON),
            summary: outcome.summary)
    }

    /// The `reason` string in a tool's JSON arguments, when there is one.
    static func reason(in argumentsJSON: String) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: Data(argumentsJSON.utf8)) as? [String: Any],
              let reason = object["reason"] as? String, !reason.isEmpty else { return nil }
        return reason
    }

    static func errorJSON(_ message: String) -> String {
        let data = try? JSONSerialization.data(withJSONObject: ["error": message], options: [.sortedKeys])
        return data.map { String(bytes: $0, encoding: .utf8) ?? "" } ?? #"{"error":"tool failed"}"#
    }
}
