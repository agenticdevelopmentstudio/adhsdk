// Tests/AgenticDeveloperHubSDKCoreTests/MCP/HostMCPServerConformanceTests.swift
import XCTest
import Logging
import MCP
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors host-mcp-server-011 to -025 that `HostMCPServerTests`
/// does not reach. Vectors 001-010 are asserted there.

/// A source whose schema bytes are not JSON.
private struct BadSchemaSource: ChatToolSource {
    func toolDefinitions() async -> [ToolDefinition] {
        [ToolDefinition(name: "bad", description: "bad", parametersJSONSchema: Data("not json".utf8))]
    }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        ("", false)
    }
}

/// A source that answers every call with a fixed string and error flag.
private struct FixedSource: ChatToolSource {
    let names: [String]
    let content: String
    let isError: Bool
    func toolDefinitions() async -> [ToolDefinition] {
        names.map {
            ToolDefinition(name: $0, description: $0, parametersJSONSchema: ToolJSONSchema.object(properties: [:]))
        }
    }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        (content, isError)
    }
}

/// A source whose advertised names can change between requests.
private final class ChangingSource: ChatToolSource, @unchecked Sendable {
    var names: [String]
    init(names: [String]) { self.names = names }
    func toolDefinitions() async -> [ToolDefinition] {
        names.map {
            ToolDefinition(name: $0, description: $0, parametersJSONSchema: ToolJSONSchema.object(properties: [:]))
        }
    }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        ("", false)
    }
}

private struct ConnectFailure: Error, Equatable {}

/// A transport whose `connect()` throws.
private actor FailingConnectTransport: Transport {
    nonisolated let logger = Logger(label: "test.failing-connect", factory: { _ in SwiftLogNoOpLogHandler() })
    func connect() async throws { throw ConnectFailure() }
    func disconnect() async {}
    func send(_ data: Data) async throws {}
    func receive() -> AsyncThrowingStream<Data, Swift.Error> {
        AsyncThrowingStream { $0.finish() }
    }
}

/// A transport with a fixed input script that ends at once, and no initialize in it.
private actor ConformanceScriptedTransport: Transport {
    nonisolated let logger = Logger(label: "test.conformance-scripted", factory: { _ in SwiftLogNoOpLogHandler() })
    private let script: [Data]
    private(set) var sent: [Data] = []
    init(script: [String]) { self.script = script.map { Data($0.utf8) } }
    func connect() async throws {}
    func disconnect() async {}
    func send(_ data: Data) async throws { sent.append(data) }
    func receive() -> AsyncThrowingStream<Data, Swift.Error> {
        let script = script
        return AsyncThrowingStream { continuation in
            for message in script { continuation.yield(message) }
            continuation.finish()
        }
    }
    func sentData() -> [Data] { sent }
}

/// The scripted transport's replies (sent messages with no method), parsed outside the actor.
private func scriptedResponses(_ transport: ConformanceScriptedTransport) async -> [[String: Any]] {
    await transport.sentData()
        .compactMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
        .filter { $0["method"] == nil }
}

final class HostMCPServerConformanceTests: XCTestCase {

    private func connect(_ server: HostMCPServer) async throws -> (Client, Initialize.Result) {
        let pair = await InMemoryTransport.createConnectedPair()
        try await server.serve(over: pair.server)
        let client = Client(name: "test-client", version: "1")
        let initialized = try await client.connect(transport: pair.client)
        addTeardownBlock {
            await client.disconnect()
            await server.stop()
        }
        return (client, initialized)
    }

    private func text(_ result: (content: [MCP.Tool.Content], isError: Bool?)) -> String? {
        guard case .text(let text, _, _) = result.content.first else { return nil }
        return text
    }

    func testV011_callerHeaderName() {
        XCTAssertEqual(HostMCPServer.callerHeader, "X-ADHD-Pane")
        XCTAssertEqual(HostMCPServer.legacyCallerHeader, "X-ADKitchen-Pane")
        XCTAssertEqual(HostMCPServer.callerHeaders, ["X-ADHD-Pane", "X-ADKitchen-Pane"])
    }

    func testV012_undecodableSchemaFallsBackToEmptyObjectSchema() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(BadSchemaSource())
        let (client, _) = try await connect(server)
        let tools = try await client.listTools().tools
        XCTAssertEqual(tools.map(\.name), ["bad"])
        let schema = tools[0].inputSchema.objectValue
        XCTAssertEqual(schema?["type"], .string("object"))
        XCTAssertEqual(schema?["properties"]?.objectValue?.isEmpty, true)
    }

    func testV013_absentArgumentsReachTheSourceAsEmptyObject() async throws {
        let source = EchoSource(names: ["a"])
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(source)
        let (client, _) = try await connect(server)
        _ = try await client.callTool(name: "a")
        XCTAssertEqual(source.calls.first?.json, "{}")
    }

    func testV014_pngDataURLKeepsTheErrorFlag() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(
            FixedSource(names: ["shot"], content: "data:image/png;base64,iVBORw0KGgo=", isError: true))
        let (client, _) = try await connect(server)
        let result = try await client.callTool(name: "shot", arguments: [:])
        guard case .image(let data, let mime, _, _) = result.content.first else { return XCTFail("expected image") }
        XCTAssertEqual(data, "iVBORw0KGgo=")
        XCTAssertEqual(mime, "image/png")
        XCTAssertEqual(result.isError, true)
    }

    func testV015_duplicateNamesAreKeptAndCallGoesToTheFirst() async throws {
        let first = EchoSource(names: ["a"]), second = EchoSource(names: ["a"])
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(first)
        await server.register(second)
        let (client, _) = try await connect(server)
        let tools = try await client.listTools().tools
        XCTAssertEqual(tools.map(\.name), ["a", "a"])
        _ = try await client.callTool(name: "a", arguments: [:])
        XCTAssertEqual(first.calls.count, 1)
        XCTAssertTrue(second.calls.isEmpty)
    }

    func testV016_registrationsSurviveStop() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(EchoSource(names: ["a", "b"]))
        let first = await InMemoryTransport.createConnectedPair()
        try await server.serve(over: first.server)
        let firstClient = Client(name: "first", version: "1")
        _ = try await firstClient.connect(transport: first.client)
        await firstClient.disconnect()
        await server.stop()

        let (secondClient, _) = try await connect(server)
        let names = try await secondClient.listTools().tools.map(\.name)
        XCTAssertEqual(names, ["a", "b"])
    }

    func testV017_stopWithoutServingDoesNothing() async {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.stop()
        await server.stop()
    }

    func testV018_toolsCallWithoutInitializeIsAnswered() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(EchoSource(names: ["a"]))
        let transport = ConformanceScriptedTransport(script: [
            #"{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"a","arguments":{}}}"#
        ])
        try await server.serveUntilDrained(over: transport)
        let responses = await scriptedResponses(transport)
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual(responses.first?["id"] as? Int, 7)
        XCTAssertNil(responses.first?["error"], "the call is answered, not refused")
        let result = responses.first?["result"] as? [String: Any]
        let content = result?["content"] as? [[String: Any]]
        XCTAssertEqual(content?.first?["text"] as? String, "echo:a")
    }

    func testV019_sourcesWithNoPrefixAreListedInRegistrationOrder() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(EchoSource(names: ["x"]))
        await server.register(EchoSource(names: ["y"]))
        let (client, _) = try await connect(server)
        let names = try await client.listTools().tools.map(\.name)
        XCTAssertEqual(names, ["x", "y"])
    }

    func testV020_constructionParametersAreTheServerInfo() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        let (_, initialized) = try await connect(server)
        XCTAssertEqual(initialized.serverInfo.name, "Test")
        XCTAssertEqual(initialized.serverInfo.version, "1")
    }

    func testV021_serveThrowsWhenTransportFailsToStart() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(EchoSource(names: ["a"]))
        do {
            try await server.serve(over: FailingConnectTransport())
            XCTFail("serve should throw")
        } catch {
            XCTAssertTrue(error is ConnectFailure, "got \(error)")
        }
        await server.stop()
        // Nothing was recorded as current, so a later serve starts cleanly.
        let (client, _) = try await connect(server)
        let names = try await client.listTools().tools.map(\.name)
        XCTAssertEqual(names, ["a"])
    }

    func testV022_callLogLines() throws {
        throw XCTSkip(
            "The Logger is a private OSLog instance with no injection point; "
                + "entries cannot be captured reliably in a unit test.")
    }

    func testV023_listAsksTheSourcesLive() async throws {
        let source = ChangingSource(names: ["a"])
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(source)
        let (client, _) = try await connect(server)
        let before = try await client.listTools().tools.map(\.name)
        XCTAssertEqual(before, ["a"])
        source.names = ["a", "b"]
        let after = try await client.listTools().tools.map(\.name)
        XCTAssertEqual(after, ["a", "b"])
    }

    func testV024_plainResultIsOneTextItem() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(FixedSource(names: ["greet"], content: "hello", isError: false))
        let (client, _) = try await connect(server)
        let result = try await client.callTool(name: "greet", arguments: [:])
        XCTAssertEqual(result.content.count, 1)
        XCTAssertEqual(text(result), "hello")
        XCTAssertNotEqual(result.isError, true)
    }

    func testV025_serverGoneAnswersEmptyListAndServerGoneError() async throws {
        let pair = await InMemoryTransport.createConnectedPair()
        do {
            let server = HostMCPServer(appName: "Test", appVersion: "1")
            await server.register(EchoSource(names: ["a"]))
            try await server.serve(over: pair.server)
        }
        let client = Client(name: "test-client", version: "1")
        _ = try await client.connect(transport: pair.client)
        addTeardownBlock { await client.disconnect() }

        let tools = try await client.listTools().tools
        XCTAssertTrue(tools.isEmpty)
        let result = try await client.callTool(name: "a", arguments: [:])
        XCTAssertEqual(result.isError, true)
        XCTAssertEqual(text(result), "server is gone")

        // With no server, waiting for completion returns at once.
        let idle = HostMCPServer(appName: "Test", appVersion: "1")
        await idle.waitUntilServerCompleted()
    }
}
