// Tests/AgenticDeveloperHubSDKAgentsTests/AgentBridgeTests.swift
import Testing
import Foundation
@testable import AgenticDeveloperHubSDKAgents

@Suite("RemoteAgentTools")
struct RemoteAgentToolsTests {

    /// A client whose transport calls a host's handlers in-process.
    private func makeRemote(caller: String = "mcp") throws -> RemoteAgentTools {
        let handlers = AgentHandlers(host: try makeHost(script: ScriptedRuntime()))
        return RemoteAgentTools(caller: caller) { await handlers.handle($0) }
    }

    @Test("loads every host tool with its schema, permission and mutating flag")
    func loads() async throws {
        let tools = try await makeRemote().load()
        #expect(tools.map(\.name) == ["echo", "bump", "broken"])
        let bump = try #require(tools.first { $0.name == "bump" })
        #expect(bump.isMutating)
        #expect(bump.permissionDefault == .ask)
        let schema = try JSONSerialization.jsonObject(with: Data(bump.inputSchemaJSON.utf8)) as? [String: Any]
        #expect(schema?["required"] as? [String] == ["reason"])
    }

    @Test("runs a tool on the host, as its caller")
    func runs() async throws {
        let tools = try await makeRemote(caller: "bridge").load()
        let echo = try #require(tools.first { $0.name == "echo" })
        let outcome = try await echo.run(argumentsJSON: #"{"text":"x"}"#, context: ToolCallContext(caller: "ignored"))
        #expect(outcome.resultJSON.contains(#""caller":"bridge""#))
        #expect(outcome.resultJSON.contains(#""text":"x""#))
        #expect(outcome.summary == "Echoed")
    }

    @Test("a failing tool throws the host's 422 and message")
    func failure() async throws {
        let tools = try await makeRemote().load()
        let broken = try #require(tools.first { $0.name == "broken" })
        await #expect(throws: RemoteAgentToolError.failed(status: 422, message: "The tool broke")) {
            try await broken.run(argumentsJSON: "{}", context: ToolCallContext(caller: "x"))
        }
    }

    @Test("arguments that are not a JSON object are refused; empty ones are sent as {}")
    func malformedArguments() async throws {
        let tools = try await makeRemote().load()
        let echo = try #require(tools.first { $0.name == "echo" })
        for bad in ["not json", "[1, 2]", "\"text\""] {
            await #expect(throws: AgentToolError.invalidArguments(tool: "echo")) {
                try await echo.run(argumentsJSON: bad, context: ToolCallContext(caller: "x"))
            }
        }
        let outcome = try await echo.run(argumentsJSON: "  ", context: ToolCallContext(caller: "x"))
        #expect(outcome.summary == "Echoed")
    }

    @Test("an error reply from the list throws")
    func listFails() async {
        let remote = RemoteAgentTools { _ in .error(500, HandlerError.internalCode, "Down") }
        await #expect(throws: RemoteAgentToolError.failed(status: 500, message: "Down")) {
            try await remote.load()
        }
    }

    @Test("a reply that is not a tool list throws malformedReply")
    func malformed() async {
        let remote = RemoteAgentTools { _ in .json(status: 200, body: Data("{}".utf8)) }
        await #expect(throws: RemoteAgentToolError.self) {
            try await remote.load()
        }
    }
}

@Suite("AgentToolSource")
struct AgentToolSourceTests {

    private let source = AgentToolSource(tools: [EchoTool(), FailingTool()], caller: "mcp")

    @Test("defines one MCP tool per agent tool")
    func definitions() async {
        let definitions = await source.toolDefinitions()
        #expect(definitions.map(\.name) == ["echo", "broken"])
        #expect(definitions[0].parametersJSONSchema == Data(EchoTool().inputSchemaJSON.utf8))
    }

    @Test("a call returns the tool's result, run as the source's caller")
    func callSucceeds() async {
        let result = await source.callTool(name: "echo", argumentsJSON: Data(#"{"text":"x"}"#.utf8), caller: "other")
        #expect(!result.isError)
        #expect(result.content.contains(#""caller":"mcp""#))
        let empty = await source.callTool(name: "echo", argumentsJSON: Data(), caller: nil)
        #expect(empty.content.contains(#""echo":{}"#))
    }

    @Test("an unknown or failing tool answers isError")
    func callFails() async {
        let unknown = await source.callTool(name: "nope", argumentsJSON: Data(), caller: nil)
        #expect(unknown.isError)
        let broken = await source.callTool(name: "broken", argumentsJSON: Data(), caller: nil)
        #expect(broken.isError)
        #expect(broken.content == "The tool broke")
    }

    @Test("with no caller given, every tool runs as external")
    func defaultCaller() async {
        let source = AgentToolSource(tools: [EchoTool()])
        #expect(source.caller == "external")
        let result = await source.callTool(name: "echo", argumentsJSON: Data("{}".utf8), caller: "ignored")
        #expect(result.content.contains(#""caller":"external""#))
    }

    @Test("argument bytes that are not UTF-8 reach the tool as an empty string")
    func undecodableArguments() async {
        let result = await source.callTool(name: "echo", argumentsJSON: Data([0xFF, 0xFE, 0xFD]), caller: nil)
        #expect(!result.isError)
        #expect(result.content.hasPrefix(#"{"echo":,"#))
    }

    @Test("two tools with one name: the first runs")
    func firstNameMatch() async {
        let source = AgentToolSource(tools: [
            FixedTool(name: "echo", result: "first"), FixedTool(name: "echo", result: "second")
        ])
        let result = await source.callTool(name: "echo", argumentsJSON: Data(), caller: nil)
        #expect(result.content == "first")
    }

    @Test("a mutating tool runs with no policy check, and its resultJSON is the content")
    func mutatingToolRuns() async {
        let source = AgentToolSource(tools: [CounterTool()])
        let result = await source.callTool(name: "bump", argumentsJSON: Data(#"{"reason":"x"}"#.utf8), caller: nil)
        #expect(!result.isError)
        #expect(result.content == #"{"count":1}"#)
    }
}

/// A tool that answers one fixed result, to tell same-named tools apart.
private struct FixedTool: AgentTool {
    let name: String
    let result: String
    let description = "Answers a fixed result."
    let inputSchemaJSON = #"{"type":"object"}"#
    let permissionDefault = ToolPermission.auto
    let isMutating = false

    func run(argumentsJSON: String, context: ToolCallContext) async throws -> ToolOutcome {
        ToolOutcome(resultJSON: result, summary: result)
    }
}
