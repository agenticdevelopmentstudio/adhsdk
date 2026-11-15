// Tests/AgenticDeveloperHubSDKCoreTests/MCP/ReplyCountingTransportConformanceTests.swift
import XCTest
import Logging
import MCP
@testable import AgenticDeveloperHubSDKCore

/// A wrapped transport with a fixed inbound script that ends at once, a send
/// that can be made to throw, and a disconnect counter.
private actor StubInnerTransport: Transport {
    struct SendFailure: Error {}

    nonisolated let logger = Logger(label: "test.reply-counting.stub", factory: { _ in SwiftLogNoOpLogHandler() })
    private let script: [Data]
    private let failSends: Bool
    private(set) var sent: [Data] = []
    private(set) var disconnectCalls = 0

    init(script: [String], failSends: Bool = false) {
        self.script = script.map { Data($0.utf8) }
        self.failSends = failSends
    }

    func connect() async throws {}
    func disconnect() async { disconnectCalls += 1 }
    func send(_ data: Data) async throws {
        if failSends { throw SendFailure() }
        sent.append(data)
    }
    func receive() -> AsyncThrowingStream<Data, Swift.Error> {
        let script = script
        return AsyncThrowingStream { continuation in
            for message in script { continuation.yield(message) }
            continuation.finish()
        }
    }
}

/// Conformance vectors reply-counting-transport-004 ... 010. Vectors 001 to 003
/// are covered by `HostMCPServerDrainTests`.
final class ReplyCountingTransportConformanceTests: XCTestCase {

    /// Wraps `inner` and reads its whole script through the counting layer.
    private func receivedTransport(script: [String], failSends: Bool = false) async throws -> ReplyCountingTransport {
        let transport = ReplyCountingTransport(wrapping: StubInnerTransport(script: script, failSends: failSends))
        for try await _ in await transport.receive() {}
        return transport
    }

    func testV4_aBatchIsNotCounted() async throws {
        let transport = try await receivedTransport(script: [
            #"[{"jsonrpc":"2.0","id":1,"method":"ping"}]"#
        ])
        let owed = await transport.owedCount
        XCTAssertEqual(owed, 0)
    }

    func testV5_aNotificationIsNotCounted() async throws {
        let transport = try await receivedTransport(script: [
            #"{"jsonrpc":"2.0","method":"notifications/initialized"}"#
        ])
        let owed = await transport.owedCount
        XCTAssertEqual(owed, 0)
    }

    func testV6_aStringIdAndANumberIdAreDifferentIds() async throws {
        let transport = try await receivedTransport(script: [
            #"{"jsonrpc":"2.0","id":1,"method":"ping"}"#
        ])
        try await transport.send(Data(#"{"jsonrpc":"2.0","id":"1","result":{}}"#.utf8))
        let owed = await transport.owedCount
        XCTAssertEqual(owed, 1, "n:1 is still owed: the response answered s:1")
    }

    func testV7_aThrowingSendStillPaysTheDebt() async throws {
        let transport = try await receivedTransport(script: [
            #"{"jsonrpc":"2.0","id":3,"method":"ping"}"#
        ], failSends: true)
        let before = await transport.owedCount
        XCTAssertEqual(before, 1)

        do {
            try await transport.send(Data(#"{"jsonrpc":"2.0","id":3,"result":{}}"#.utf8))
            XCTFail("send should rethrow the wrapped transport's error")
        } catch is StubInnerTransport.SendFailure {
            // expected
        }
        let owed = await transport.owedCount
        XCTAssertEqual(owed, 0)
    }

    func testV8_cancellingAnUnknownIdChangesNothing() async throws {
        let transport = try await receivedTransport(script: [
            #"{"jsonrpc":"2.0","id":1,"method":"ping"}"#,
            #"{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":99}}"#
        ])
        let owed = await transport.owedCount
        XCTAssertEqual(owed, 1)
    }

    func testV9_disconnectReleasesASuspendedWaiter() async throws {
        let inner = StubInnerTransport(script: [#"{"jsonrpc":"2.0","id":1,"method":"ping"}"#])
        let transport = ReplyCountingTransport(wrapping: inner)
        for try await _ in await transport.receive() {}

        let clock = ContinuousClock()
        let start = clock.now
        let waiter = Task { await transport.waitUntilNothingOwed(deadline: .seconds(30)) }
        try await Task.sleep(for: .milliseconds(300))
        await transport.disconnect()
        let drained = await waiter.value

        XCTAssertFalse(drained, "something is still owed, so the released waiter reports false")
        XCTAssertLessThan(clock.now - start, .seconds(5), "disconnect releases the waiter well before its deadline")
        let disconnects = await inner.disconnectCalls
        XCTAssertEqual(disconnects, 1, "the wrapped transport is disconnected too")
    }

    func testV10_twoWaitersAreBothReleasedByOnePayment() async throws {
        let transport = try await receivedTransport(script: [
            #"{"jsonrpc":"2.0","id":1,"method":"ping"}"#
        ])
        let first = Task { await transport.waitUntilNothingOwed(deadline: .seconds(30)) }
        let second = Task { await transport.waitUntilNothingOwed(deadline: .seconds(30)) }
        try await Task.sleep(for: .milliseconds(300))

        try await transport.send(Data(#"{"jsonrpc":"2.0","id":1,"result":{}}"#.utf8))

        let firstResult = await first.value
        let secondResult = await second.value
        XCTAssertTrue(firstResult)
        XCTAssertTrue(secondResult)
    }
}
