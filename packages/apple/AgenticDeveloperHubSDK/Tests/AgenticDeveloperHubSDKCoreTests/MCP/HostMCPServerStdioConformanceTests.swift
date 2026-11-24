// Tests/AgenticDeveloperHubSDKCoreTests/MCP/HostMCPServerStdioConformanceTests.swift
import XCTest
import Logging
import MCP
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors host-mcp-server-stdio-005 to -017 that
/// `HostMCPServerDrainTests` does not reach. Vectors 001-004 are asserted there.

private struct StdioTestError: Error, Equatable {}

/// Records that the stream handed out by `receive()` was terminated.
private actor TerminationFlag {
    private(set) var terminated = false
    func mark() { terminated = true }
}

/// A wrapped transport whose input, ending and failures the test controls.
private actor ScriptedInnerTransport: Transport {
    enum Ending { case finish, fail(StdioTestError), hang }

    nonisolated let logger = Logger(label: "test.scripted-inner", factory: { _ in SwiftLogNoOpLogHandler() })
    private let script: [Data]
    private let ending: Ending
    private let flag: TerminationFlag
    private(set) var sent: [Data] = []
    private(set) var disconnected = false

    init(script: [String] = [], ending: Ending = .finish, flag: TerminationFlag = TerminationFlag()) {
        self.script = script.map { Data($0.utf8) }
        self.ending = ending
        self.flag = flag
    }

    func connect() async throws {}
    func disconnect() async { disconnected = true }
    func send(_ data: Data) async throws { sent.append(data) }
    func receive() -> AsyncThrowingStream<Data, Swift.Error> {
        let script = script, ending = ending, flag = flag
        return AsyncThrowingStream { continuation in
            for message in script { continuation.yield(message) }
            switch ending {
            case .finish: continuation.finish()
            case .fail(let error): continuation.finish(throwing: error)
            case .hang:
                continuation.onTermination = { _ in Task { await flag.mark() } }
            }
        }
    }
}

/// A transport whose `connect()` throws.
private actor StdioFailingConnectTransport: Transport {
    nonisolated let logger = Logger(label: "test.stdio-failing-connect", factory: { _ in SwiftLogNoOpLogHandler() })
    func connect() async throws { throw StdioTestError() }
    func disconnect() async {}
    func send(_ data: Data) async throws {}
    func receive() -> AsyncThrowingStream<Data, Swift.Error> { AsyncThrowingStream { $0.finish() } }
}

final class HostMCPServerStdioConformanceTests: XCTestCase {

    /// Reads the wrapper's stream to its end and returns what it yielded.
    private func drain(_ transport: ReplyCountingTransport) async throws -> [Data] {
        var received: [Data] = []
        for try await data in await transport.receive() { received.append(data) }
        return received
    }

    func testV005_stringIdAndNumberIdAreDifferentIds() async throws {
        let transport = ReplyCountingTransport(wrapping: ScriptedInnerTransport(script: [
            #"{"jsonrpc":"2.0","id":1,"method":"tools/list"}"#
        ]))
        _ = try await drain(transport)
        try await transport.send(Data(#"{"jsonrpc":"2.0","id":"1","result":{}}"#.utf8))
        let owed = await transport.owedCount
        XCTAssertEqual(owed, 1)
    }

    func testV006_notificationsAreNotCounted() async throws {
        let transport = ReplyCountingTransport(wrapping: ScriptedInnerTransport(script: [
            #"{"jsonrpc":"2.0","method":"notifications/initialized"}"#
        ]))
        _ = try await drain(transport)
        let owed = await transport.owedCount
        XCTAssertEqual(owed, 0)
    }

    func testV007_batchesAreNotCounted() async throws {
        let transport = ReplyCountingTransport(wrapping: ScriptedInnerTransport(script: [
            #"[{"jsonrpc":"2.0","id":1,"method":"tools/list"},{"jsonrpc":"2.0","id":2,"method":"tools/list"}]"#
        ]))
        _ = try await drain(transport)
        let owed = await transport.owedCount
        XCTAssertEqual(owed, 0)
    }

    func testV008_waitWithNothingOwedReturnsTrueAtOnce() async {
        let transport = ReplyCountingTransport(wrapping: ScriptedInnerTransport())
        let clock = ContinuousClock()
        let start = clock.now
        let drained = await transport.waitUntilNothingOwed(deadline: .seconds(30))
        XCTAssertTrue(drained)
        XCTAssertLessThan(clock.now - start, .seconds(5))
    }

    func testV009_unparseableBytesAreNotCountedButStillYielded() async throws {
        let transport = ReplyCountingTransport(wrapping: ScriptedInnerTransport(script: ["not json"]))
        let received = try await drain(transport)
        XCTAssertEqual(received, [Data("not json".utf8)])
        let owed = await transport.owedCount
        XCTAssertEqual(owed, 0)
    }

    func testV010_drainDeadlineValue() {
        XCTAssertEqual(HostMCPServer.stdioDrainDeadline, .seconds(360))
    }

    func testV011_sendPassesBytesThrough() async throws {
        let inner = ScriptedInnerTransport()
        let transport = ReplyCountingTransport(wrapping: inner)
        let bytes = Data(#"{"jsonrpc":"2.0","method":"notifications/x"}"#.utf8)
        try await transport.send(bytes)
        let sent = await inner.sent
        XCTAssertEqual(sent, [bytes])
    }

    func testV012_disconnectReleasesWaiters() async throws {
        let inner = ScriptedInnerTransport(script: [#"{"jsonrpc":"2.0","id":1,"method":"tools/list"}"#])
        let transport = ReplyCountingTransport(wrapping: inner)
        _ = try await drain(transport)
        let clock = ContinuousClock()
        let start = clock.now
        let waiter = Task { await transport.waitUntilNothingOwed(deadline: .seconds(30)) }
        try await Task.sleep(for: .milliseconds(300))
        await transport.disconnect()
        let drained = await waiter.value
        XCTAssertFalse(drained)
        XCTAssertLessThan(clock.now - start, .seconds(10), "the waiter does not sit out its deadline")
        let disconnected = await inner.disconnected
        XCTAssertTrue(disconnected)
    }

    func testV013_wrappedStreamErrorEndsTheWrapperStreamWithThatError() async throws {
        let transport = ReplyCountingTransport(wrapping: ScriptedInnerTransport(ending: .fail(StdioTestError())))
        do {
            _ = try await drain(transport)
            XCTFail("the stream should end with an error")
        } catch {
            XCTAssertTrue(error is StdioTestError, "got \(error)")
        }
    }

    func testV014_serveUntilDrainedThrowsTheStartError() async {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        do {
            try await server.serveUntilDrained(over: StdioFailingConnectTransport())
            XCTFail("should throw")
        } catch {
            XCTAssertTrue(error is StdioTestError, "got \(error)")
        }
    }

    func testV015_unansweredRequestAtDeadlineLogsOneWarning() throws {
        throw XCTSkip(
            "The Logger is a private OSLog instance with no injection point; "
                + "entries cannot be captured reliably in a unit test.")
    }

    func testV016_serveStdioWritesReplyBeforeReturning() throws {
        throw XCTSkip(
            "serveStdio() reads the real process stdin and writes the real stdout; "
                + "a unit test cannot pipe them.")
    }

    func testV017_endingTheConsumerStreamCancelsTheReader() async throws {
        let flag = TerminationFlag()
        let transport = ReplyCountingTransport(wrapping: ScriptedInnerTransport(
            script: [#"{"jsonrpc":"2.0","id":1,"method":"tools/list"}"#], ending: .hang, flag: flag))
        for try await _ in await transport.receive() { break }

        var terminated = false
        for _ in 0..<40 {
            terminated = await flag.terminated
            if terminated { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertTrue(terminated, "the task reading the wrapped transport is cancelled")
        let owed = await transport.owedCount
        XCTAssertEqual(owed, 1)
    }
}
