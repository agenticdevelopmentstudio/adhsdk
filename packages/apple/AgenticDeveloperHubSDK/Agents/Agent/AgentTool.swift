import Foundation

/// Whether an agent may run a tool without asking. Stored per agent now;
/// enforced in phase 2.
public enum ToolPermission: String, Codable, Sendable {
    case auto, ask, never
}

/// One capability a host offers its agents (and, through the MCP bridge, other
/// clients): a JSON-in, JSON-out function with a schema.
public protocol AgentTool: Sendable {
    var name: String { get }
    var description: String { get }
    /// The JSON Schema of the arguments. A mutating tool requires a `reason`
    /// string, which the host records in its activity entry.
    var inputSchemaJSON: String { get }
    var permissionDefault: ToolPermission { get }
    /// Whether running it changes state; a mutating tool's run is reported as
    /// an `ActivityEntry` and returns its undo as `ToolOutcome.inverse`.
    var isMutating: Bool { get }
    func run(argumentsJSON: String, context: ToolCallContext) async throws -> ToolOutcome
}

/// Who is running a tool: the caller (`agent`, `external`, a CLI, …) and, from
/// an agent's turn, which agent and session.
public struct ToolCallContext: Sendable, Equatable {
    public var caller: String
    public var agentId: String?
    public var sessionId: UUID?

    public init(caller: String, agentId: String? = nil, sessionId: UUID? = nil) {
        self.caller = caller
        self.agentId = agentId
        self.sessionId = sessionId
    }
}

/// A tool call as data: which tool, with which arguments.
public struct ToolInvocation: Codable, Sendable, Equatable {
    public var tool: String
    public var argumentsJSON: String

    public init(tool: String, argumentsJSON: String) {
        self.tool = tool
        self.argumentsJSON = argumentsJSON
    }
}

/// What a tool returns.
public struct ToolOutcome: Codable, Sendable, Equatable {
    /// What the model sees.
    public var resultJSON: String
    /// One human line, for narration.
    public var summary: String
    /// A mutating tool's undo, as data (persisted in phase 2).
    public var inverse: ToolInvocation?

    public init(resultJSON: String, summary: String, inverse: ToolInvocation? = nil) {
        self.resultJSON = resultJSON
        self.summary = summary
        self.inverse = inverse
    }
}

/// Why a tool call could not be run at all, as distinct from a tool that ran
/// and threw.
public enum AgentToolError: Error, LocalizedError, Equatable {
    case unknownTool(String)
    /// The arguments were not a JSON object.
    case invalidArguments(tool: String)

    public var errorDescription: String? {
        switch self {
        case .unknownTool(let name): return "Unknown tool '\(name)'"
        case .invalidArguments(let tool): return "The arguments for '\(tool)' are not a JSON object"
        }
    }
}
