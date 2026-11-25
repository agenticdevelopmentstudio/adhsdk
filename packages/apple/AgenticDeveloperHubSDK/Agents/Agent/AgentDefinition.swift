import Foundation
import AIPluginKit

/// When an agent looks at something new arriving at its host: never, after the
/// host has handled it, or before (so it can act on it first).
public enum ArrivalMode: String, Codable, Sendable {
    case off, after, before
}

/// An agent: a prompt, a model and how it uses its host's tools.
public struct AgentDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var prompt: String
    public var model: ModelSelector
    /// Per-tool overrides of `AgentTool.permissionDefault`; stored now,
    /// enforced in phase 2.
    public var toolPermissions: [String: ToolPermission]
    public var arrival: ArrivalMode
    /// How long an arrival turn may take before the host stops waiting.
    public var deadlineSeconds: Double
    public var thinkingBudgetTokens: Int?
    public var enabled: Bool

    public static let defaultDeadlineSeconds: Double = 30

    public init(
        id: String,
        name: String,
        prompt: String,
        model: ModelSelector,
        toolPermissions: [String: ToolPermission] = [:],
        arrival: ArrivalMode = .off,
        deadlineSeconds: Double = AgentDefinition.defaultDeadlineSeconds,
        thinkingBudgetTokens: Int? = nil,
        enabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.model = model
        self.toolPermissions = toolPermissions
        self.arrival = arrival
        self.deadlineSeconds = deadlineSeconds
        self.thinkingBudgetTokens = thinkingBudgetTokens
        self.enabled = enabled
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, prompt, model, toolPermissions, arrival, deadlineSeconds, thinkingBudgetTokens, enabled
    }

    /// `id`, `name`, `prompt` and `model` are required; the rest take the
    /// memberwise init's defaults, so a client can PUT a minimal definition.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        prompt = try container.decode(String.self, forKey: .prompt)
        model = try container.decode(ModelSelector.self, forKey: .model)
        toolPermissions = try container.decodeIfPresent([String: ToolPermission].self, forKey: .toolPermissions) ?? [:]
        arrival = try container.decodeIfPresent(ArrivalMode.self, forKey: .arrival) ?? .off
        deadlineSeconds = try container.decodeIfPresent(Double.self, forKey: .deadlineSeconds)
            ?? Self.defaultDeadlineSeconds
        thinkingBudgetTokens = try container.decodeIfPresent(Int.self, forKey: .thinkingBudgetTokens)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
    }
}

/// A record of a mutating tool's run, for the host's activity feed. Emitted as
/// an `AgentEvent`, not persisted (phase 2 keeps a log).
public struct ActivityEntry: Codable, Sendable, Equatable {
    public var id: UUID
    /// When the tool ran (`at` on the event wire).
    public var occurredAt: Date
    public var agentId: String
    public var sessionId: UUID?
    public var tool: String
    public var argumentsJSON: String
    /// The `reason` argument the tool was given, when there was one.
    public var reason: String?
    public var summary: String

    public init(
        id: UUID = UUID(), occurredAt: Date = Date(), agentId: String, sessionId: UUID?,
        tool: String, argumentsJSON: String, reason: String?, summary: String
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.agentId = agentId
        self.sessionId = sessionId
        self.tool = tool
        self.argumentsJSON = argumentsJSON
        self.reason = reason
        self.summary = summary
    }
}

/// A conversation with one agent.
public struct AgentSessionInfo: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var agentId: String
    public var title: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID, agentId: String, title: String?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.agentId = agentId
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// A session and every message in it, oldest first.
public struct AgentSessionDetail: Codable, Sendable, Equatable {
    public var info: AgentSessionInfo
    public var messages: [AgentMessage]

    public init(info: AgentSessionInfo, messages: [AgentMessage]) {
        self.info = info
        self.messages = messages
    }
}

/// One stored message of a session: the Codable form of `AIChatMessage`
/// (which is not Codable, and carries tool arguments as `Data`).
public struct AgentMessage: Codable, Sendable, Equatable {
    /// Position in the session, from 0.
    public var seq: Int
    /// `system`, `user`, `assistant`, `tool_use` or `tool_result`.
    public var role: String
    public var content: String
    public var toolUseId: String?
    public var toolName: String?
    public var toolArgumentsJSON: String?
    public var toolIsError: Bool?
    public var createdAt: Date

    public init(seq: Int, message: AIChatMessage, createdAt: Date = Date()) {
        self.seq = seq
        self.role = message.role.rawValue
        self.content = message.content
        self.toolUseId = message.toolUseId
        self.toolName = message.toolName
        self.toolArgumentsJSON = message.toolArgumentsJSON.map { String(bytes: $0, encoding: .utf8) ?? "" }
        self.toolIsError = message.toolIsError
        self.createdAt = createdAt
    }

    /// The chat message, or nil for a role this build does not know.
    public var chatMessage: AIChatMessage? {
        guard let role = AIChatMessage.Role(rawValue: role) else { return nil }
        return AIChatMessage(
            role: role,
            content: content,
            toolUseId: toolUseId,
            toolName: toolName,
            toolArgumentsJSON: toolArgumentsJSON.map { Data($0.utf8) },
            toolIsError: toolIsError)
    }
}
