import Foundation

/// The tools of an agent host in another process, reached through its
/// handlers: `GET tools` lists them, `POST tools/<name>` runs one with caller
/// `external`. The transport is the caller's — HTTP to a daemon, XPC, or an
/// `AgentHandlers` in the same process for a test.
public struct RemoteAgentTools: Sendable {

    /// Sends a request to the host's agent mount (paths are relative to it,
    /// e.g. `["tools"]`) and returns its reply.
    public typealias Transport = @Sendable (HandlerRequest) async throws -> HandlerResponse

    private let transport: Transport
    private let caller: String

    public init(caller: String = AgentHandlers.defaultToolCaller, transport: @escaping Transport) {
        self.caller = caller
        self.transport = transport
    }

    /// The host's tools, each running remotely when run.
    public func load() async throws -> [any AgentTool] {
        let body = try Self.success(try await transport(HandlerRequest(method: "GET", path: ["tools"])))
        guard let list = try JSONSerialization.jsonObject(with: body) as? [[String: Any]] else {
            throw RemoteAgentToolError.malformedReply("Expected a JSON array of tools")
        }
        return try list.map { info in
            guard let name = info["name"] as? String, !name.isEmpty else {
                throw RemoteAgentToolError.malformedReply("A tool has no name")
            }
            let schema = info["input_schema"] ?? [String: Any]()
            let schemaData = try JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys])
            return RemoteAgentTool(
                name: name,
                description: info["description"] as? String ?? "",
                inputSchemaJSON: String(bytes: schemaData, encoding: .utf8) ?? "{}",
                permissionDefault: (info["permission"] as? String).flatMap(ToolPermission.init) ?? .auto,
                isMutating: info["mutating"] as? Bool ?? false,
                caller: caller,
                transport: transport)
        }
    }

    /// The body of a 2xx JSON reply; anything else throws, with the host's message.
    static func success(_ response: HandlerResponse) throws -> Data {
        guard case let .json(status, body) = response else {
            throw RemoteAgentToolError.malformedReply("Expected JSON, got an event stream")
        }
        guard (200..<300).contains(status) else {
            let message = (try? AgentsJSON.decode(HandlerError.self, from: body))?.message
                ?? String(bytes: body, encoding: .utf8) ?? ""
            throw RemoteAgentToolError.failed(status: status, message: message)
        }
        return body
    }
}

/// Why a remote tool call failed.
public enum RemoteAgentToolError: Error, LocalizedError, Equatable {
    /// The host answered with an error status (404 unknown tool, 422 the tool threw, …).
    case failed(status: Int, message: String)
    case malformedReply(String)

    public var errorDescription: String? {
        switch self {
        case .failed(_, let message): return message
        case .malformedReply(let message): return message
        }
    }
}

/// One tool of a remote host.
struct RemoteAgentTool: AgentTool {
    let name: String
    let description: String
    let inputSchemaJSON: String
    let permissionDefault: ToolPermission
    let isMutating: Bool
    let caller: String
    let transport: RemoteAgentTools.Transport

    /// Posts `{arguments, caller}`; the context's caller is replaced by the
    /// remote set's, since the host sees this process as one caller. Empty
    /// arguments are sent as `{}`; anything else that is not a JSON object is
    /// refused with `invalidArguments` and never sent.
    func run(argumentsJSON: String, context _: ToolCallContext) async throws -> ToolOutcome {
        let arguments: [String: Any]
        if argumentsJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            arguments = [:]
        } else if let object = (try? JSONSerialization.jsonObject(with: Data(argumentsJSON.utf8))) as? [String: Any] {
            arguments = object
        } else {
            throw AgentToolError.invalidArguments(tool: name)
        }
        let body = try JSONSerialization.data(withJSONObject: ["arguments": arguments, "caller": caller])
        let reply = try await transport(HandlerRequest(method: "POST", path: ["tools", name], body: body))
        return try AgentsJSON.decode(ToolOutcome.self, from: RemoteAgentTools.success(reply))
    }
}
