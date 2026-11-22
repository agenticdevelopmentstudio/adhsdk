import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase
import Foundation
import Network
import os

/// What a planner was told about one upstream response head.
struct PlannerObservation: Equatable, Sendable {
    let account: String?
    let status: Int
}

/// A planner that returns fixed plans. `replan` adds the retry suffix the way
/// `AccountRoutingPlanner` does, so rows look like production rows.
final class ScriptedPlanner: ExchangePlanning, @unchecked Sendable {
    private let lock = NSLock()
    private let first: ExchangePlan
    private let retry: ExchangePlan
    private let retries: Bool
    private var seen: [PlannerObservation] = []

    init(first: ExchangePlan, retry: ExchangePlan = .verbatim, allowsRetry: Bool = true) {
        self.first = first
        self.retry = retry
        self.retries = allowsRetry
    }

    var observed: [PlannerObservation] { lock.withLock { seen } }

    func plan(_ head: RouterRequestHead) -> ExchangePlan { first }

    func allowsRetry() -> Bool { retries }

    func replan(_ head: RouterRequestHead, after account: String, status: Int) -> ExchangePlan {
        let note = "(retry after \(account) \(status))"
        let rule = retry.rule.map { "\($0) \(note)" } ?? note
        return ExchangePlan(account: retry.account, bearer: retry.bearer, rule: rule)
    }

    func observe(_ plan: ExchangePlan, head: UpstreamHead) {
        lock.withLock { seen.append(PlannerObservation(account: plan.account, status: head.status)) }
    }
}

/// Rows a `RouterConnection` recorded, for tests that run without a database.
final class RecordedExchanges: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [AccountRouterExchange] = []

    var rows: [AccountRouterExchange] { lock.withLock { stored } }

    func append(_ row: AccountRouterExchange) { lock.withLock { stored.append(row) } }

    /// Waits until `count` rows exist; returns the last, or nil on timeout.
    func waitForRow(count: Int = 1, timeout: TimeInterval = 5) async -> AccountRouterExchange? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let current = rows
            if current.count >= count { return current.last }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return nil
    }
}

/// A scripted HTTP/1.1 upstream on loopback. It parses each request with the
/// router's own parser and answers with a chunked body and `Connection: close`.
final class FakeUpstream: @unchecked Sendable {
    struct Received: Sendable {
        let head: RouterRequestHead
        let body: Data
    }

    struct Reply: Sendable {
        enum Ending: Sendable {
            /// Send every chunk, then the terminator.
            case complete
            /// Send the first chunk, then wait for `release()` (or the peer to close).
            case holdAfterFirstChunk
            /// Send the first chunk, then drop the connection.
            case dropAfterFirstChunk
        }

        var status = 200
        var headers: [HTTPHeaderField] = []
        var chunks: [Data] = []
        var ending = Ending.complete
    }

    private let lock = NSLock()
    private let queue = DispatchQueue(label: "FakeUpstream")
    private let reply: @Sendable (Received, Int) -> Reply
    private var server: AccountRouterListener?
    private var requests: [Received] = []
    private var released = false
    private var peerClosedFlag = false

    init(reply: @escaping @Sendable (Received, Int) -> Reply) {
        self.reply = reply
    }

    var received: [Received] { lock.withLock { requests } }
    /// The request bodies, in arrival order.
    var bodies: [Data] { received.map(\.body) }
    var peerClosed: Bool { lock.withLock { peerClosedFlag } }

    func start() async throws -> URL {
        let server = AccountRouterListener(port: 0) { [weak self] connection in self?.handle(connection) }
        lock.withLock { self.server = server }
        let port = try await server.start(timeout: 5)
        guard let url = URL(string: "http://127.0.0.1:\(port)") else { throw URLError(.badURL) }
        return url
    }

    func stop() { lock.withLock { server }?.stop() }

    func release() { lock.withLock { released = true } }

    func waitForPeerClose(timeout: TimeInterval = 5) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if peerClosed { return true }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return peerClosed
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        Task { await self.serve(connection) }
    }

    private func serve(_ connection: NWConnection) async {
        var parser = RouterRequestParser()
        var request: Received?
        while request == nil {
            let (data, isComplete, error) = await RawClient.receive(connection)
            for event in (try? parser.feed(data ?? Data())) ?? [] {
                if case let .complete(head, body) = event { request = Received(head: head, body: body) }
            }
            if request == nil && (isComplete || error != nil) {
                connection.cancel()
                return
            }
        }
        guard let request else { return }
        let index = lock.withLock { () -> Int in
            requests.append(request)
            return requests.count - 1
        }
        let answer = reply(request, index)
        let bodyless = request.head.method == "HEAD" || answer.status == 204 || answer.status == 304
        var text = "HTTP/1.1 \(answer.status) \(RouterHeaders.reasonPhrase(answer.status))\r\n"
        for field in answer.headers { text += "\(field.name): \(field.value)\r\n" }
        text += bodyless ? "Connection: close\r\n\r\n" : "Transfer-Encoding: chunked\r\nConnection: close\r\n\r\n"
        _ = await RawClient.send(Data(text.utf8), on: connection)
        if bodyless {
            connection.cancel()
            return
        }
        for (position, chunk) in answer.chunks.enumerated() {
            if position == 1 && answer.ending == .holdAfterFirstChunk {
                guard await holdUntilReleased(connection) else { return }
            }
            _ = await RawClient.send(Self.frame(chunk), on: connection)
            if position == 0 && answer.ending == .dropAfterFirstChunk {
                // Let the chunk reach the peer before the RST discards anything still buffered.
                try? await Task.sleep(for: .milliseconds(300))
                connection.forceCancel()
                return
            }
        }
        if answer.ending == .holdAfterFirstChunk && answer.chunks.count < 2 {
            guard await holdUntilReleased(connection) else { return }
        }
        _ = await RawClient.send(Data("0\r\n\r\n".utf8), on: connection)
        connection.cancel()
    }

    /// true once released; false (connection cancelled) if the peer closed first.
    private func holdUntilReleased(_ connection: NWConnection) async -> Bool {
        // This connection's own close ends its hold; `peerClosed` reports any.
        let closed = OSAllocatedUnfairLock(initialState: false)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] _, _, isComplete, error in
            guard isComplete || error != nil else { return }
            closed.withLock { $0 = true }
            self?.lock.withLock { self?.peerClosedFlag = true }
        }
        let deadline = Date().addingTimeInterval(30)
        while Date() < deadline {
            if lock.withLock({ released }) { return true }
            if closed.withLock({ $0 }) {
                connection.cancel()
                return false
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        connection.cancel()
        return false
    }

    static func frame(_ chunk: Data) -> Data {
        var framed = Data((String(chunk.count, radix: 16) + "\r\n").utf8)
        framed.append(chunk)
        framed.append(Data("\r\n".utf8))
        return framed
    }
}

/// A parsed response as the client saw it.
struct RawResponse: Sendable {
    let status: Int
    /// Lowercased names; a repeated name keeps the last value.
    let headers: [String: String]
    /// Every header line's lowercased name, in order, repeats included.
    let headerNames: [String]
    let body: Data
    /// A chunked body ended with the zero-size chunk.
    let terminated: Bool

    /// Parses the final response in `raw`, skipping any 1xx interim heads.
    static func parse(_ raw: Data) -> RawResponse? {
        var rest = raw
        while true {
            guard let end = rest.range(of: Data("\r\n\r\n".utf8)) else { return nil }
            let headText = String(bytes: rest[rest.startIndex..<end.lowerBound], encoding: .utf8) ?? ""
            let lines = headText.components(separatedBy: "\r\n")
            let parts = lines.first?.split(separator: " ") ?? []
            guard parts.count >= 2, let status = Int(parts[1]) else { return nil }
            rest = Data(rest[end.upperBound...])
            if (100..<200).contains(status) { continue }
            var headers: [String: String] = [:]
            var names: [String] = []
            for line in lines.dropFirst() {
                guard let colon = line.firstIndex(of: ":") else { continue }
                let name = line[..<colon].lowercased()
                names.append(name)
                headers[name] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            }
            guard headers["transfer-encoding"] == "chunked" else {
                return RawResponse(status: status, headers: headers, headerNames: names, body: rest, terminated: false)
            }
            let (body, terminated) = dechunk(rest)
            return RawResponse(status: status, headers: headers, headerNames: names, body: body, terminated: terminated)
        }
    }

    private static func dechunk(_ data: Data) -> (Data, Bool) {
        var body = Data()
        var rest = data
        while let lineEnd = rest.range(of: Data("\r\n".utf8)) {
            let sizeText = String(bytes: rest[rest.startIndex..<lineEnd.lowerBound], encoding: .utf8) ?? ""
            guard let size = Int(sizeText, radix: 16) else { break }
            if size == 0 { return (body, true) }
            let start = lineEnd.upperBound
            guard rest.distance(from: start, to: rest.endIndex) >= size + 2 else {
                body.append(rest[start...])
                break
            }
            let stop = rest.index(start, offsetBy: size)
            body.append(rest[start..<stop])
            rest = Data(rest[rest.index(stop, offsetBy: 2)...])
        }
        return (body, false)
    }
}

/// A byte-level HTTP client: the request goes out exactly as written.
final class RawClient: @unchecked Sendable {
    private let connection: NWConnection
    private let queue = DispatchQueue(label: "RawClient")
    private let lock = NSLock()
    private var buffer = Data()

    private init(_ connection: NWConnection) { self.connection = connection }

    static func connect(port: UInt16) async throws -> RawClient {
        let connection = NWConnection(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port) ?? .any, using: .tcp)
        let client = RawClient(connection)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let once = NSLock()
            nonisolated(unsafe) var resumed = false
            connection.stateUpdateHandler = { state in
                let result: Result<Void, Error>?
                switch state {
                case .ready: result = .success(())
                case .failed(let error), .waiting(let error): result = .failure(error)
                default: result = nil
                }
                guard let result else { return }
                let first = once.withLock { () -> Bool in
                    defer { resumed = true }
                    return !resumed
                }
                if first { continuation.resume(with: result) }
            }
            connection.start(queue: client.queue)
        }
        return client
    }

    /// One whole exchange: connect, send `request` in `piece`-sized writes, read to EOF.
    static func roundTrip(port: UInt16, request: Data, piece: Int = 256 * 1024,
                          timeout: TimeInterval = 30) async throws -> (RawResponse?, Data) {
        let client = try await connect(port: port)
        try await client.send(request, piece: piece)
        let raw = await client.readToEnd(timeout: timeout)
        return (RawResponse.parse(raw), raw)
    }

    func send(_ data: Data, piece: Int = .max) async throws {
        var offset = 0
        while offset < data.count {
            let end = min(data.count, offset + min(piece, data.count - offset))
            guard await Self.send(data.subdata(in: offset..<end), on: connection) else {
                throw URLError(.networkConnectionLost)
            }
            offset = end
        }
    }

    /// Reads until the bytes so far contain `marker`; returns them all.
    func readUntil(_ marker: Data, timeout: TimeInterval = 10) async -> Data {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let current = lock.withLock { buffer }
            if current.range(of: marker) != nil { return current }
            let (data, isComplete, error) = await Self.receive(connection)
            if let data { lock.withLock { buffer.append(data) } }
            if isComplete || error != nil { break }
        }
        return lock.withLock { buffer }
    }

    /// Reads until the server closes (or `timeout`, which cancels); returns every byte read.
    func readToEnd(timeout: TimeInterval = 30) async -> Data {
        queue.asyncAfter(deadline: .now() + timeout) { [connection] in connection.cancel() }
        while true {
            let (data, isComplete, error) = await Self.receive(connection)
            if let data { lock.withLock { buffer.append(data) } }
            if isComplete || error != nil { break }
        }
        connection.cancel()
        return lock.withLock { buffer }
    }

    func cancel() { connection.cancel() }

    static func receive(_ connection: NWConnection) async -> (Data?, Bool, NWError?) {
        await withCheckedContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 1 << 20) { data, _, isComplete, error in
                continuation.resume(returning: (data, isComplete, error))
            }
        }
    }

    static func send(_ data: Data, on connection: NWConnection) async -> Bool {
        await withCheckedContinuation { continuation in
            connection.send(content: data, completion: .contentProcessed { error in
                continuation.resume(returning: error == nil)
            })
        }
    }
}

/// A listener wired to `RouterConnection` with an injected planner, a fake
/// upstream and an in-memory recorder: the relay without the façade.
final class RelayHarness: @unchecked Sendable {
    let upstream: FakeUpstream
    /// The rows the connections recorded.
    let rows: RecordedExchanges
    let port: UInt16
    /// The allowances every connection draws on, to watch the limits work.
    let admission: RouterAdmission
    private let server: AccountRouterListener

    private init(upstream: FakeUpstream, rows: RecordedExchanges, server: AccountRouterListener, port: UInt16,
                 admission: RouterAdmission) {
        self.upstream = upstream
        self.rows = rows
        self.server = server
        self.port = port
        self.admission = admission
    }

    /// `upstreamOverride` points the router somewhere else (an unreachable port).
    static func start(
        planner: any ExchangePlanning = VerbatimPlanner(),
        modelPlanner: any ModelPlanning = PassModelPlanner(),
        upstreamOverride: URL? = nil,
        limits: RouterLimits = .standard,
        reply: @escaping @Sendable (FakeUpstream.Received, Int) -> FakeUpstream.Reply
    ) async throws -> RelayHarness {
        let upstream = FakeUpstream(reply: reply)
        let upstreamURL = try await upstream.start()
        let recorded = RecordedExchanges()
        let context = RouterContext(
            planner: planner, modelPlanner: modelPlanner, session: UpstreamCall.makeSession(),
            upstream: upstreamOverride ?? upstreamURL,
            limits: limits, record: { recorded.append($0) })
        let server = AccountRouterListener(port: 0, acceptLimit: limits.acceptLimit) { connection, ended in
            RouterConnection(connection: connection, context: context, ended: ended).start()
        }
        let port = try await server.start(timeout: 5)
        return RelayHarness(upstream: upstream, rows: recorded, server: server, port: port,
                            admission: context.admission)
    }

    func stop() {
        server.stop()
        upstream.stop()
    }
}
