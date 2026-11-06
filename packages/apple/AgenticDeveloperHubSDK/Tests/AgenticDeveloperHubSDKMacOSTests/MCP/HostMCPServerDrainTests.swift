// Tests/AgenticDeveloperHubSDKMacOSTests/MCP/HostMCPServerDrainTests.swift
import XCTest
import Logging
import MCP
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A transport whose input is a fixed script that ends at once. That is what
/// `printf '…' | olylo mcp` looks like: stdin hits EOF right after the last
/// request, before any reply is written. It records everything the server sends.
private actor ScriptedTransport: Transport {
    nonisolated let logger = Logger(label: "test.scripted", factory: { _ in SwiftLogNoOpLogHandler() })
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

    /// The numeric ids of the responses sent.
    func sentResponseIDs() -> [Int] {
        sent.compactMap { data in
            guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  object["method"] == nil else { return nil }
            return object["id"] as? Int
        }
    }
}

/// Advertises its tools only after `delay`, so a `tools/list` is still being
/// handled when the input has already closed.
private struct SlowSource: ChatToolSource {
    let delay: Duration
    func toolDefinitions() async -> [ToolDefinition] {
        try? await Task.sleep(for: delay)
        return [ToolDefinition(name: "slow", description: "slow",
                               parametersJSONSchema: ToolJSONSchema.object(properties: [:]))]
    }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        ("", false)
    }
}

final class HostMCPServerDrainTests: XCTestCase {
    private static let script = [
        #"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","#
            + #""capabilities":{},"clientInfo":{"name":"t","version":"0"}}}"#,
        #"{"jsonrpc":"2.0","method":"notifications/initialized"}"#,
        #"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#
    ]

    func testRequestsInFlightWhenInputClosesAreStillAnswered() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(SlowSource(delay: .milliseconds(300)))
        let transport = ScriptedTransport(script: Self.script)

        try await server.serveUntilDrained(over: transport)

        let ids = await transport.sentResponseIDs()
        XCTAssertEqual(ids.sorted(), [1, 2], "both the initialize and the tools/list replies are written")
    }

    func testACancelledRequestIsNoLongerOwedAReply() async throws {
        let transport = ReplyCountingTransport(wrapping: ScriptedTransport(script: [
            #"{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"slow"}}"#,
            #"{"jsonrpc":"2.0","id":"6","method":"tools/list"}"#,
            #"{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":5,"reason":"x"}}"#
        ]))
        for try await _ in await transport.receive() {}

        let owed = await transport.owedCount
        XCTAssertEqual(owed, 1, "only the request that was not cancelled is still owed")
        try await transport.send(Data(#"{"jsonrpc":"2.0","id":"6","result":{}}"#.utf8))
        let clock = ContinuousClock()
        let start = clock.now
        let drained = await transport.waitUntilNothingOwed(deadline: .seconds(30))
        XCTAssertTrue(drained)
        XCTAssertLessThan(clock.now - start, .seconds(5), "the cancelled request does not hold the drain open")
    }

    func testDrainGivesUpAtItsDeadline() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(SlowSource(delay: .seconds(60)))
        let transport = ScriptedTransport(script: Self.script)

        let clock = ContinuousClock()
        let start = clock.now
        try await server.serveUntilDrained(over: transport, deadline: .milliseconds(300))
        let elapsed = clock.now - start

        XCTAssertLessThan(elapsed, .seconds(10), "a reply that never comes does not hold the server open")
        let ids = await transport.sentResponseIDs()
        XCTAssertEqual(ids, [1], "the reply that did come was written; the hung one was abandoned")
    }
}
