import Foundation
import AgenticDeveloperHubSDKCore

/// Serves a set of `AgentTool`s as a `ChatToolSource`, so `HostMCPServer`
/// exposes them to any MCP client (`serveStdio()`), and a chat engine's tool
/// loop can run them.
///
/// ```swift
/// let server = HostMCPServer(appName: "rooster", appVersion: version)
/// await server.register(AgentToolSource(tools: try await RemoteAgentTools(transport: http).load()), prefix: nil)
/// try await server.serveStdio()
/// ```
public struct AgentToolSource: ChatToolSource {

    public let tools: [any AgentTool]
    /// The caller every tool sees (`external` for an MCP client).
    public let caller: String

    public init(tools: [any AgentTool], caller: String = AgentHandlers.defaultToolCaller) {
        self.tools = tools
        self.caller = caller
    }

    public func toolDefinitions() async -> [ToolDefinition] {
        tools.map { tool in
            ToolDefinition(
                name: tool.name, description: tool.description, parametersJSONSchema: Data(tool.inputSchemaJSON.utf8))
        }
    }

    /// Runs the tool, returning its `resultJSON`, or the error's message with
    /// `isError` set. The MCP caller id is not passed on: a tool sees `caller`.
    public func callTool(
        name: String, argumentsJSON: Data, caller _: String?
    ) async -> (content: String, isError: Bool) {
        guard let tool = tools.first(where: { $0.name == name }) else {
            return (AgentToolError.unknownTool(name).localizedDescription, true)
        }
        let arguments = argumentsJSON.isEmpty ? "{}" : (String(bytes: argumentsJSON, encoding: .utf8) ?? "")
        do {
            let outcome = try await tool.run(argumentsJSON: arguments, context: ToolCallContext(caller: caller))
            return (outcome.resultJSON, false)
        } catch {
            return (error.localizedDescription, true)
        }
    }
}
