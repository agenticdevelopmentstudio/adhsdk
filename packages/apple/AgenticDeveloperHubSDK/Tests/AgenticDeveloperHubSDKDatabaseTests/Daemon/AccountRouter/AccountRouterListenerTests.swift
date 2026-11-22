import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase
import Network

/// The listener binds loopback only, hands every connection over, refuses a
/// second start, and reports a port it cannot bind as an error.
final class AccountRouterListenerTests: XCTestCase {

    func testStartOnPortZeroBindsLoopbackAndHandsOverConnections() async throws {
        let accepted = expectation(description: "connection handed over")
        let server = AccountRouterListener(port: 0) { connection in
            connection.cancel()
            accepted.fulfill()
        }
        let port = try await server.start(timeout: 5)
        XCTAssertGreaterThan(port, 0)
        XCTAssertTrue(server.isListening)

        let client = NWConnection(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port) ?? .any, using: .tcp)
        client.start(queue: .global())
        await fulfillment(of: [accepted], timeout: 5)
        client.cancel()
        server.stop()
        XCTAssertFalse(server.isListening)
        server.stop()
    }

    func testSecondStartIsRefused() async throws {
        let server = AccountRouterListener(port: 0) { $0.cancel() }
        _ = try await server.start(timeout: 5)
        defer { server.stop() }
        do {
            _ = try await server.start(timeout: 1)
            XCTFail("a second start must throw")
        } catch {
            XCTAssertEqual(error as? AccountRouterListenerError, .alreadyStarted)
        }
    }

    func testABusyPortThrowsInsteadOfHanging() async throws {
        let first = AccountRouterListener(port: 0) { $0.cancel() }
        let port = try await first.start(timeout: 5)
        defer { first.stop() }
        let second = AccountRouterListener(port: port) { $0.cancel() }
        do {
            _ = try await second.start(timeout: 1)
            XCTFail("binding a busy port must throw")
        } catch {
            XCTAssertFalse(second.isListening)
        }
    }

    /// Review fix: a stale `.cancelled` or timer from an earlier start must
    /// never fail or tear down a later start.
    func testRestartRightAfterStopAlwaysSucceedsAndStaysListening() async throws {
        let server = AccountRouterListener(port: 0) { $0.cancel() }
        defer { server.stop() }
        for round in 0..<50 {
            let port = try await server.start(timeout: 5)
            XCTAssertGreaterThan(port, 0, "round \(round)")
            server.stop()
        }
        _ = try await server.start(timeout: 5)
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertTrue(server.isListening)
    }

    func testAStartThatNeverBecomesReadyTimesOut() async {
        let server = AccountRouterListener(port: 0, beginListening: { _, _ in }, onConnection: { $0.cancel() })
        do {
            _ = try await server.start(timeout: 0.2)
            XCTFail("a listener that never starts must time out")
        } catch {
            XCTAssertEqual(error as? AccountRouterListenerError, .timedOut)
            XCTAssertFalse(server.isListening)
        }
    }

    /// Parked fix (a): a start whose task is already cancelled stops waiting
    /// at once instead of sitting out its timeout.
    func testACancelledStartStopsWaitingAtOnce() async {
        let server = AccountRouterListener(port: 0, beginListening: { _, _ in }, onConnection: { $0.cancel() })
        let began = Date()
        let task = Task { () -> Error? in
            while !Task.isCancelled { await Task.yield() }
            do {
                _ = try await server.start(timeout: 30)
                return nil
            } catch {
                return error
            }
        }
        task.cancel()
        let error = await task.value
        XCTAssertTrue(error is CancellationError, "got \(String(describing: error))")
        XCTAssertLessThan(Date().timeIntervalSince(began), 5)
        XCTAssertFalse(server.isListening)
    }

    /// Parked fix (a), the other order: cancelled while already waiting.
    func testAStartCancelledWhileWaitingStopsWaitingAtOnce() async throws {
        let server = AccountRouterListener(port: 0, beginListening: { _, _ in }, onConnection: { $0.cancel() })
        let began = Date()
        let task = Task { () -> Error? in
            do {
                _ = try await server.start(timeout: 30)
                return nil
            } catch {
                return error
            }
        }
        try await Task.sleep(for: .milliseconds(200))
        task.cancel()
        let error = await task.value
        XCTAssertTrue(error is CancellationError, "got \(String(describing: error))")
        XCTAssertLessThan(Date().timeIntervalSince(began), 5)
        XCTAssertFalse(server.isListening)
    }

    /// Final review M11: dialling 127.0.0.1 would succeed with a wildcard bind
    /// too, so dial this host's own non-loopback address and expect a refusal.
    func testTheListenerRefusesANonLoopbackAddress() async throws {
        guard let external = Self.nonLoopbackIPv4() else {
            throw XCTSkip("no non-loopback IPv4 interface on this machine")
        }
        let handedOver = LocalHostBox()
        let server = AccountRouterListener(port: 0) { connection in
            handedOver.set("yes")
            connection.cancel()
        }
        let port = try await server.start(timeout: 5)
        defer { server.stop() }
        let outcome = LocalHostBox()
        let settled = expectation(description: "the dial settled")
        let client = NWConnection(host: NWEndpoint.Host(external), port: NWEndpoint.Port(rawValue: port) ?? .any,
                                  using: .tcp)
        client.stateUpdateHandler = { state in
            switch state {
            case .ready: outcome.set("ready")
            case .waiting, .failed: outcome.set("refused")
            default: return
            }
            client.stateUpdateHandler = nil
            settled.fulfill()
        }
        client.start(queue: .global())
        await fulfillment(of: [settled], timeout: 10)
        client.cancel()
        XCTAssertEqual(outcome.value, "refused", "\(external):\(port) must not reach a loopback-only listener")
        XCTAssertEqual(handedOver.value, "", "no connection from \(external) is handed over")
    }

    /// The first up, non-loopback IPv4 address of this host, if any.
    private static func nonLoopbackIPv4() -> String? {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return nil }
        defer { freeifaddrs(head) }
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let entry = cursor {
            defer { cursor = entry.pointee.ifa_next }
            let flags = Int32(entry.pointee.ifa_flags)
            guard let addr = entry.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET),
                  flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count),
                              nil, 0, NI_NUMERICHOST) == 0 else { continue }
            let bytes = host.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
            guard let text = String(bytes: bytes, encoding: .utf8) else { continue }
            return text
        }
        return nil
    }

    func testAcceptedConnectionsAreOnTheLoopbackInterface() async throws {
        let local = LocalHostBox()
        let seen = expectation(description: "local endpoint seen")
        let server = AccountRouterListener(port: 0) { connection in
            connection.stateUpdateHandler = { state in
                guard case .ready = state else { return }
                if case let .hostPort(host, _)? = connection.currentPath?.localEndpoint {
                    local.set("\(host)")
                }
                connection.cancel()
                seen.fulfill()
            }
            connection.start(queue: .global())
        }
        let port = try await server.start(timeout: 5)
        defer { server.stop() }
        let client = NWConnection(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port) ?? .any, using: .tcp)
        client.start(queue: .global())
        await fulfillment(of: [seen], timeout: 5)
        client.cancel()
        XCTAssertTrue(["127.0.0.1", "::1"].contains(local.value), "bound to \(local.value)")
    }

    /// Retry off: a routed 429 reaches the client as is, after one upstream call.
    func testWithRetryOffARouted429IsRelayedAfterOneCall() async throws {
        let planner = ScriptedPlanner(
            first: ExchangePlan(account: "oauth:a@x.com", bearer: "sk-ant-oat01-aaa", rule: "ranked"),
            retry: ExchangePlan(account: "oauth:b@x.com", bearer: "sk-ant-oat01-bbb", rule: "ranked"),
            allowsRetry: false)
        let relay = try await RelayHarness.start(planner: planner) { _, _ in
            FakeUpstream.Reply(status: 429, chunks: [Data("limited".utf8)])
        }
        defer { relay.stop() }
        let body = Data("{}".utf8)
        let request = Data(("POST /v1/messages HTTP/1.1\r\nHost: 127.0.0.1\r\n"
            + "Authorization: Bearer sk-ant-oat01-client\r\nContent-Length: \(body.count)\r\n\r\n").utf8) + body
        let (response, _) = try await RawClient.roundTrip(port: relay.port, request: request)
        XCTAssertEqual(response?.status, 429)
        XCTAssertEqual(response?.body, Data("limited".utf8))
        XCTAssertEqual(relay.upstream.received.count, 1)
        let recorded = await relay.rows.waitForRow()
        XCTAssertEqual(recorded?.routingRule, "ranked")
        XCTAssertEqual(planner.observed, [PlannerObservation(account: "oauth:a@x.com", status: 429)])
    }
}

private final class LocalHostBox: @unchecked Sendable {
    private let lock = NSLock()
    private var text = ""
    var value: String { lock.withLock { text } }
    func set(_ new: String) { lock.withLock { text = new } }
}
