// macOS/Features/MCP/MCPHTTPEndpoint.swift
import Foundation
import AgenticDeveloperHubSDKCore
import FlyingFox
import FlyingSocks
import OSLog

/// Serves a `HostMCPServer` over MCP Streamable HTTP on 127.0.0.1.
///
/// FlyingFox owns the socket; `MCPStatelessHTTPHandler` owns everything MCP
/// (the SDK's stateless transport, the per-request JSON-RPC id, cancellation
/// and the collected body). This actor adds what is the socket's: the bearer
/// token, the single `POST /mcp` route, and a stop that waits for handlers
/// still running. FlyingFox's request timeout cancels the handler's task,
/// which the handler turns into a cancellation of the tool call.
public actor MCPHTTPEndpoint {

    public static let path = "/mcp"
    public static let preferredPort: UInt16 = 51477

    /// A navigation or wait can legitimately run for a while; FlyingFox wraps
    /// the whole handler in this timeout (its default is 15 s).
    public static let requestTimeout: TimeInterval = 120

    public enum StartError: Error {
        /// `start()` was called while another `start()` was still binding, or
        /// while a `stop()` was still tearing down.
        case alreadyStarting
        /// `stop()` arrived while `start()` was binding; everything was torn down.
        case stoppedWhileStarting
    }

    private enum Phase { case idle, starting, running, stopping }

    private struct ClosedEarly: Error {}

    private let server: HostMCPServer
    private let token: String
    private let preferred: UInt16
    private let requestTimeout: TimeInterval
    private let log: Logger
    private let handlers = ActiveHandlers()
    private var phase = Phase.idle
    private var stopRequested = false
    private var http: HTTPServer?
    private var runTask: Task<Void, Never>?
    private var handler: MCPStatelessHTTPHandler?
    public private(set) var port: UInt16?

    public init(server: HostMCPServer, token: String,
                preferredPort: UInt16 = MCPHTTPEndpoint.preferredPort,
                requestTimeout: TimeInterval = MCPHTTPEndpoint.requestTimeout, logger: Logger? = nil) {
        self.server = server
        self.token = token
        self.preferred = preferredPort
        self.requestTimeout = requestTimeout
        self.log = logger ?? Logger(subsystem: "AgenticDeveloperHubSDK", category: "automation")
    }

    /// Binds the preferred port, or an ephemeral one when it is taken, and
    /// returns the port actually listening. Already running: returns the
    /// port it is on. Called while another `start()` is binding: throws
    /// `StartError.alreadyStarting`.
    public func start() async throws -> UInt16 {
        switch phase {
        case .running:
            if let port { return port }
        case .starting, .stopping:
            throw StartError.alreadyStarting
        case .idle:
            break
        }
        phase = .starting
        stopRequested = false
        let bound: UInt16
        do {
            let handler = try await MCPStatelessHTTPHandler(server: server, path: Self.path)
            try checkNotStopped()
            self.handler = handler
            do {
                bound = try await listen(on: preferred, handler: handler)
            } catch where preferred != 0 && !stopRequested {
                log.info("automation: port \(self.preferred, privacy: .public) is taken; binding an ephemeral port")
                bound = try await listen(on: 0, handler: handler)
            }
            try checkNotStopped()
        } catch {
            await tearDown()
            phase = .idle
            stopRequested = false
            throw error
        }
        port = bound
        phase = .running
        log.notice("automation: listening on port \(bound, privacy: .public)")
        return bound
    }

    /// The longest `stop()` waits for requests still being handled.
    public static let defaultStopGrace: TimeInterval = 1

    /// How long a stop that waited on a handler leaves the response it just
    /// returned to be written, inside the grace.
    static let writeMargin: TimeInterval = 0.1

    /// Stops listening. Called while `start()` is binding, it records the
    /// request and `start()` tears down what it built and throws.
    ///
    /// `grace` is an upper bound, not a delay: the stop waits only for
    /// requests still being handled, and when it waited on one, a short
    /// `writeMargin` for the response it returned to be written. With nothing
    /// in flight it closes at once. (FlyingFox's own `stop(timeout:)` cannot
    /// be the wait: the server's run task never ends by itself, so it always
    /// sleeps out the whole timeout.) An app that is quitting passes `0`;
    /// nothing it could still send has a reader worth a second of the quit.
    public func stop(grace: TimeInterval = MCPHTTPEndpoint.defaultStopGrace) async {
        switch phase {
        case .starting:
            stopRequested = true
            return
        case .stopping:
            return
        case .idle, .running:
            break
        }
        // The phase flips and tearDown() moves everything out before its first
        // await, so a `start()` arriving meanwhile can neither see the closing
        // port nor bind a second server.
        phase = .stopping
        await tearDown(grace: grace)
        phase = .idle
    }

    private func checkNotStopped() throws {
        if stopRequested { throw StartError.stoppedWhileStarting }
    }

    private func tearDown(grace: TimeInterval = MCPHTTPEndpoint.defaultStopGrace) async {
        let closingHTTP = http
        let closingTask = runTask
        http = nil
        runTask = nil
        handler = nil
        port = nil
        let deadline = Date().addingTimeInterval(grace)
        let waited = closingHTTP != nil ? await handlers.waitUntilIdle(before: deadline) : false
        let margin = waited ? min(Self.writeMargin, max(0, deadline.timeIntervalSinceNow)) : 0
        await closingHTTP?.stop(timeout: margin)
        closingTask?.cancel()
        await server.stop()
    }

    // MARK: - Listening

    private func listen(on requested: UInt16, handler: MCPStatelessHTTPHandler) async throws -> UInt16 {
        let http = HTTPServer(address: try sockaddr_in.inet(ip4: "127.0.0.1", port: requested),
                              timeout: requestTimeout)
        let token = self.token
        let log = self.log
        let handlers = self.handlers
        await http.appendRoute(HTTPRoute("POST \(Self.path)")) { request in try await handlers.counting {
            guard Self.isAuthorized(request.headers[.authorization], token: token) else {
                log.info("automation: POST \(Self.path, privacy: .public) 401")
                var response = FlyingFox.HTTPResponse(statusCode: .unauthorized)
                response.headers[HTTPHeader("WWW-Authenticate")] = "Bearer"
                return response
            }
            let body = try await request.bodyData
            var headers: [String: String] = [:]
            for (name, value) in request.headers { headers[name.rawValue] = value }
            let answer = await handler.handle(method: "POST", headers: headers, body: body)
            log.info("automation: POST \(Self.path, privacy: .public) \(answer.status, privacy: .public)")
            var responseHeaders = HTTPHeaders()
            for (name, value) in answer.headers { responseHeaders[HTTPHeader(name)] = value }
            return FlyingFox.HTTPResponse(statusCode: Self.statusCode(answer.status),
                                          headers: responseHeaders, body: answer.body)
        } }
        // Anything else: the wrong path is 404, the right path with the
        // wrong method is 405.
        await http.appendRoute(HTTPRoute("*")) { request in
            if request.path == Self.path {
                var response = FlyingFox.HTTPResponse(statusCode: .methodNotAllowed)
                response.headers[HTTPHeader("Allow")] = "POST"
                return response
            }
            return FlyingFox.HTTPResponse(statusCode: .notFound)
        }
        // `run()` throws when the bind fails, and `waitUntilListening` would
        // only time out. The run task reports its end through a stream, which
        // (unlike `Task.value`) the race below can cancel.
        let (ended, endedContinuation) = AsyncThrowingStream<Void, Error>.makeStream()
        let task = Task {
            do {
                try await http.run()
                endedContinuation.finish()
            } catch {
                endedContinuation.finish(throwing: error)
            }
        }
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await http.waitUntilListening(timeout: 5) }
                group.addTask {
                    for try await _ in ended {}
                    // Cancelled because the other child won: not a failure.
                    if Task.isCancelled { return }
                    throw ClosedEarly()
                }
                try await group.next()
                group.cancelAll()
            }
        } catch {
            task.cancel()
            throw error
        }
        guard let address = await http.listeningAddress else {
            task.cancel()
            throw CocoaError(.fileNoSuchFile)
        }
        let bound: UInt16
        switch address {
        case .ip4(_, let port), .ip6(_, let port): bound = port
        default:
            task.cancel()
            throw CocoaError(.fileNoSuchFile)
        }
        self.http = http
        self.runTask = task
        return bound
    }

    /// `Bearer <token>` compared without an early exit on the first
    /// differing byte.
    private static func isAuthorized(_ header: String?, token: String) -> Bool {
        guard let header else { return false }
        let expected = Array("Bearer \(token)".utf8)
        let actual = Array(header.utf8)
        var difference = expected.count ^ actual.count
        for index in 0..<min(expected.count, actual.count) {
            difference |= Int(expected[index] ^ actual[index])
        }
        return difference == 0
    }

    // MARK: - Stopping

    /// How many POST handlers are running, so a stop waits for them and no
    /// longer.
    actor ActiveHandlers {
        private var count = 0

        /// Runs `body` counted as one handler.
        func counting<T: Sendable>(_ body: @Sendable () async throws -> T) async rethrows -> T {
            count += 1
            defer { count -= 1 }
            return try await body()
        }

        /// Waits until no handler is running or `deadline` passes; whether
        /// any was running when the wait began.
        func waitUntilIdle(before deadline: Date) async -> Bool {
            let busy = count > 0
            while count > 0, Date() < deadline {
                try? await Task.sleep(for: .milliseconds(10))
            }
            return busy
        }
    }

    // MARK: - Response mapping

    private static func statusCode(_ code: Int) -> HTTPStatusCode {
        switch code {
        case 200: return .ok
        case 202: return .accepted
        case 400: return .badRequest
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 405: return .methodNotAllowed
        case 406: return .notAcceptable
        case 421: return .misdirectedRequest
        case 500: return .internalServerError
        default: return HTTPStatusCode(code, phrase: "")
        }
    }
}
