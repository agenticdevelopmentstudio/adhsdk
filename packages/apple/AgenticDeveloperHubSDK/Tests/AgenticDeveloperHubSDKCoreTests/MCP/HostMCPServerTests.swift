// Tests/AgenticDeveloperHubSDKCoreTests/MCP/HostMCPServerTests.swift
import XCTest
import Logging
import MCP
@testable import AgenticDeveloperHubSDKCore

/// A source that records calls and answers with its name.
final class EchoSource: ChatToolSource, @unchecked Sendable {
    let names: [String]
    var calls: [(name: String, json: String, caller: String?)] = []
    init(names: [String]) { self.names = names }
    func toolDefinitions() async -> [ToolDefinition] {
        let schema = ToolJSONSchema.object(properties: ["x": ToolJSONSchema.string("x")])
        return names.map { ToolDefinition(name: $0, description: "echo \($0)", parametersJSONSchema: schema) }
    }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        calls.append((name, String(bytes: argumentsJSON, encoding: .utf8) ?? "", caller))
        if name == "fails" { return ("it failed", true) }
        if name == "image" { return ("data:image/png;base64,iVBORw0KGgo=", false) }
        return ("echo:\(name)", false)
    }
}

final class HostMCPServerTests: XCTestCase {

    /// Server + client joined by an in-memory transport pair.
    private func makePair(sources: [(any ChatToolSource, String?)]) async throws -> (HostMCPServer, Client) {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        for (source, prefix) in sources { await server.register(source, prefix: prefix) }
        // The pair is labelled (client:, server:) — destructure in that order.
        let (clientTransport, serverTransport) = await InMemoryTransport.createConnectedPair()
        try await server.serve(over: serverTransport)
        let client = Client(name: "test-client", version: "1")
        _ = try await client.connect(transport: clientTransport)
        addTeardownBlock {
            await client.disconnect()
            await server.stop()
        }
        return (server, client)
    }

    func testListToolsConcatenatesSourcesInRegistrationOrder() async throws {
        let (server, client) = try await makePair(sources: [
            (EchoSource(names: ["a", "b"]), nil), (EchoSource(names: ["c"]), nil)
        ])
        let tools = try await client.listTools().tools
        XCTAssertEqual(tools.map(\.name), ["a", "b", "c"])
        XCTAssertEqual(tools.first?.description, "echo a")
        await server.stop()
    }

    func testInputSchemaIsTheDefinitionsSchema() async throws {
        let (server, client) = try await makePair(sources: [(EchoSource(names: ["a"]), nil)])
        let tool = try await client.listTools().tools[0]
        let schema = tool.inputSchema.objectValue
        XCTAssertEqual(schema?["type"], .string("object"))
        XCTAssertNotNil(schema?["properties"]?.objectValue?["x"])
        await server.stop()
    }

    func testCallRoutesToTheSourceThatAdvertisesTheName() async throws {
        let first = EchoSource(names: ["a"]), second = EchoSource(names: ["b"])
        let (server, client) = try await makePair(sources: [(first, nil), (second, nil)])
        let result = try await client.callTool(name: "b", arguments: ["x": .string("1")])
        XCTAssertEqual(result.isError ?? false, false)
        guard case .text(let text, _, _) = result.content.first else { return XCTFail("expected text") }
        XCTAssertEqual(text, "echo:b")
        XCTAssertEqual(second.calls.count, 1)
        XCTAssertEqual(second.calls[0].json, #"{"x":"1"}"#)
        XCTAssertTrue(first.calls.isEmpty)
        await server.stop()
    }

    func testErrorResultIsErrorWithTheSentence() async throws {
        let (server, client) = try await makePair(sources: [(EchoSource(names: ["fails"]), nil)])
        let result = try await client.callTool(name: "fails", arguments: [:])
        XCTAssertEqual(result.isError, true)
        guard case .text(let text, _, _) = result.content.first else { return XCTFail("expected text") }
        XCTAssertEqual(text, "it failed")
        await server.stop()
    }

    func testUnknownToolIsAnErrorResultNotAProtocolError() async throws {
        let (server, client) = try await makePair(sources: [(EchoSource(names: ["a"]), nil)])
        let result = try await client.callTool(name: "nope", arguments: [:])
        XCTAssertEqual(result.isError, true)
        guard case .text(let text, _, _) = result.content.first else { return XCTFail("expected text") }
        XCTAssertEqual(text, "unknown tool nope")
        await server.stop()
    }

    func testPrefixIsAppliedToNamesAndStrippedOnCall() async throws {
        let source = EchoSource(names: ["info"])
        let (server, client) = try await makePair(sources: [(source, "host_")])
        let names = try await client.listTools().tools.map(\.name)
        XCTAssertEqual(names, ["host_info"])
        _ = try await client.callTool(name: "host_info", arguments: [:])
        XCTAssertEqual(source.calls.first?.name, "info")
        await server.stop()
    }

    func testPNGDataURLBecomesImageContent() async throws {
        let (server, client) = try await makePair(sources: [(EchoSource(names: ["image"]), nil)])
        let result = try await client.callTool(name: "image", arguments: [:])
        guard case .image(let data, let mime, _, _) = result.content.first else { return XCTFail("expected image") }
        XCTAssertEqual(mime, "image/png")
        XCTAssertEqual(data, "iVBORw0KGgo=")
        await server.stop()
    }

    func testSecondServeStopsTheFirst() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(EchoSource(names: ["a"]))
        addTeardownBlock { await server.stop() }

        let first = await InMemoryTransport.createConnectedPair()
        try await server.serve(over: first.server)
        let firstClient = Client(name: "first", version: "1")
        _ = try await firstClient.connect(transport: first.client)
        addTeardownBlock { await firstClient.disconnect() }

        let second = await InMemoryTransport.createConnectedPair()
        try await server.serve(over: second.server)
        let secondClient = Client(name: "second", version: "1")
        _ = try await secondClient.connect(transport: second.client)
        addTeardownBlock { await secondClient.disconnect() }

        let tools = try await secondClient.listTools().tools
        XCTAssertEqual(tools.map(\.name), ["a"])
        await server.stop()
    }

    func testCallerHeaderReachesTheSource() async throws {
        // `Server.HandlerContext` cannot be built outside the SDK, so the
        // header read (`caller(from:)`) and the call path are tested in turn.
        let request = HTTPRequest(method: "POST", headers: ["x-adhd-pane": "pane-7"])
        let caller = HostMCPServer.caller(from: request)
        XCTAssertEqual(caller, "pane-7")
        // The name the header had before adhd is still read, and the new one
        // wins when both are sent.
        XCTAssertEqual(HostMCPServer.caller(from: HTTPRequest(
            method: "POST", headers: ["X-ADKitchen-Pane": "pane-old"])), "pane-old")
        XCTAssertEqual(HostMCPServer.caller(from: HTTPRequest(
            method: "POST", headers: ["X-ADKitchen-Pane": "pane-old", "X-ADHD-Pane": "pane-new"])), "pane-new")
        XCTAssertNil(HostMCPServer.caller(from: nil))
        XCTAssertNil(HostMCPServer.caller(from: HTTPRequest(method: "POST")))

        let source = EchoSource(names: ["a"])
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(source)
        _ = await server.call(name: "a", arguments: [:], caller: caller)
        XCTAssertEqual(source.calls.first?.caller, "pane-7")
    }

    // MARK: - Serialized serve / stop

    func testOverlappingServesRunInCallOrder() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        let events = TransportEventLog()
        let first = GatedTransport(name: "A", gated: true, events: events)
        let second = GatedTransport(name: "B", gated: false, events: events)

        let serveFirst = Task { try await server.serve(over: first) }
        try await events.wait(for: "connect A")
        let serveSecond = Task { try await server.serve(over: second) }
        try await Task.sleep(for: .milliseconds(200))
        let beforeRelease = await events.all
        XCTAssertFalse(beforeRelease.contains("connect B"), "B started before A's serve returned: \(beforeRelease)")

        await first.release()
        try await serveFirst.value
        try await serveSecond.value
        await server.stop()

        let log = await events.all
        let order = ["connected A", "disconnect A", "connect B", "connected B", "disconnect B"]
        let indices = order.map { log.firstIndex(of: $0) }
        XCTAssertFalse(indices.contains(nil), "missing events in \(log)")
        XCTAssertEqual(indices.compactMap { $0 }, indices.compactMap { $0 }.sorted(), "out of order: \(log)")
    }

    func testFailedServeDoesNotBlockTheQueue() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(EchoSource(names: ["a"]))
        do {
            try await server.serve(over: ConnectFailingTransport())
            XCTFail("should throw")
        } catch {
            XCTAssertTrue(error is ConnectFailed, "got \(error)")
        }

        let (clientTransport, serverTransport) = await InMemoryTransport.createConnectedPair()
        try await server.serve(over: serverTransport)
        let client = Client(name: "test-client", version: "1")
        _ = try await client.connect(transport: clientTransport)
        let tools = try await client.listTools().tools
        XCTAssertEqual(tools.map(\.name), ["a"])
        await client.disconnect()
        await server.stop()
    }
}

/// Records transport calls, in order, across the transports of one test.
private actor TransportEventLog {
    private(set) var all: [String] = []

    func add(_ event: String) { all.append(event) }

    /// Waits up to two seconds for `event` to be recorded.
    func wait(for event: String) async throws {
        for _ in 0..<200 where !all.contains(event) {
            try await Task.sleep(for: .milliseconds(10))
        }
        if !all.contains(event) { XCTFail("timed out waiting for \(event): \(all)") }
    }
}

/// A transport whose `connect()` can be held until `release()`, and that
/// records each connect and disconnect. It never delivers a message.
private actor GatedTransport: Transport {
    nonisolated let logger = Logger(label: "test.gated", factory: { _ in SwiftLogNoOpLogHandler() })
    private let name: String
    private let events: TransportEventLog
    private var gated: Bool
    private var waiter: CheckedContinuation<Void, Never>?
    private let stream: AsyncThrowingStream<Data, Swift.Error>
    private let continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation

    init(name: String, gated: Bool, events: TransportEventLog) {
        self.name = name
        self.gated = gated
        self.events = events
        (stream, continuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
    }

    func connect() async throws {
        await events.add("connect \(name)")
        if gated { await withCheckedContinuation { waiter = $0 } }
        await events.add("connected \(name)")
    }

    func release() {
        gated = false
        waiter?.resume()
        waiter = nil
    }

    func disconnect() async {
        await events.add("disconnect \(name)")
        continuation.finish()
    }

    func send(_ data: Data) async throws {}

    func receive() -> AsyncThrowingStream<Data, Swift.Error> { stream }
}

private struct ConnectFailed: Error {}

private actor ConnectFailingTransport: Transport {
    nonisolated let logger = Logger(label: "test.connect-failing", factory: { _ in SwiftLogNoOpLogHandler() })
    func connect() async throws { throw ConnectFailed() }
    func disconnect() async {}
    func send(_ data: Data) async throws {}
    func receive() -> AsyncThrowingStream<Data, Swift.Error> { AsyncThrowingStream { $0.finish() } }
}
