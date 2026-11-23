// Core/MCP/MCPStatelessHTTPHandler.swift
import Foundation
import MCP

/// Answers MCP Streamable HTTP requests for a `HostMCPServer`, whatever owns
/// the socket: hand it a request's method, headers and body and it returns the
/// status, headers and body to send back. `MCPHTTPEndpoint` (FlyingFox) and
/// adhd's `/mcp` route both sit on it.
///
/// The SDK's `StatelessHTTPServerTransport` owns the protocol (Origin/Host,
/// Accept, Content-Type and protocol-version checks included). This handler
/// adds what the transport leaves to its host, none of which depends on the
/// socket:
///
/// - **A unique JSON-RPC id per request.** The stateless transport keys its
///   bookkeeping by id alone, so two callers who both send `"id": 1` would
///   otherwise collide. The caller's own id is put back into the answer.
/// - **Cancellation.** Because a request runs under an id its caller never
///   sent, a caller's `notifications/cancelled` is pointed at ours; and when
///   the task awaiting ``handle(method:headers:body:)`` is cancelled (an HTTP
///   timeout, a dropped connection), the same cancellation is sent into the
///   SDK, so the tool call stops when the client is told it did.
/// - **A collected body.** A `.stream` answer is read to its end; one that
///   fails midway becomes an empty 500 rather than a truncated 200.
///
/// Authentication and routing by path stay with the caller.
public actor MCPStatelessHTTPHandler {

    public typealias Response = (status: Int, headers: [String: String], body: Data)

    private let transport: StatelessHTTPServerTransport
    private let path: String
    private let inFlight = InFlightRequests()

    /// Starts `server` serving over a fresh stateless transport.
    ///
    /// - Parameter path: the path the requests are reported to the SDK under;
    ///   the SDK reads nothing from it.
    public init(server: HostMCPServer, path: String = "/mcp") async throws {
        let transport = StatelessHTTPServerTransport(logger: nil)
        try await server.serve(over: transport)
        self.transport = transport
        self.path = path
    }

    /// Answers one HTTP request. Only `POST` carries MCP over a stateless
    /// transport; any other method is a 405 naming `POST`.
    public func handle(method: String, headers: [String: String], body: Data) async -> Response {
        guard method.uppercased() == "POST" else {
            return (status: 405, headers: ["Allow": "POST"], body: Data())
        }
        let transport = self.transport
        let path = self.path
        let inFlight = self.inFlight
        let caller = Self.caller(in: headers)

        if let cancellation = Self.cancellation(in: body) {
            // The caller names the id it sent; the SDK knows the request by
            // ours. An id not in flight (already answered, or another
            // caller's) passes through and the SDK ignores it, as the spec
            // asks.
            let key = Self.inFlightKey(caller: caller, originalIDJSON: cancellation.originalIDJSON)
            let unique = await inFlight.uniqueID(for: key)
            let answer = await transport.handleRequest(MCP.HTTPRequest(
                method: "POST", headers: headers, body: unique.map(cancellation.naming) ?? body, path: path))
            if let unique { await Self.release(unique, on: transport, reason: "cancelled by the caller") }
            return await Self.collect(answer, restoring: IDRewrite(body: body, uniqueID: nil, originalIDJSON: nil))
        }

        let rewrite = Self.rewriteID(in: body)
        let key = rewrite.originalIDJSON.map { Self.inFlightKey(caller: caller, originalIDJSON: $0) }
        if let key, let unique = rewrite.uniqueID { await inFlight.begin(key, uniqueID: unique) }
        // Cancelling the awaiting task cancels nothing in the SDK on its own:
        // its handler task would run the tool call to its end, and the
        // transport's waiter for it would never be released. The
        // cancellation is forwarded into the SDK instead, the same way a
        // caller's own would be.
        let answer = await withTaskCancellationHandler {
            await transport.handleRequest(
                MCP.HTTPRequest(method: "POST", headers: headers, body: rewrite.body, path: path))
        } onCancel: {
            guard let unique = rewrite.uniqueID else { return }
            Task {
                await Self.cancel(unique, on: transport, headers: headers, path: path,
                                  reason: "the HTTP request was cancelled")
            }
        }
        if let key, let unique = rewrite.uniqueID { await inFlight.end(key, uniqueID: unique) }
        return await Self.collect(answer, restoring: rewrite)
    }

    /// The pane id a request names, under `HostMCPServer.callerHeader` or the
    /// legacy name, matched without regard to case.
    static func caller(in headers: [String: String]) -> String? {
        for name in HostMCPServer.callerHeaders {
            if let value = headers.first(where: { $0.key.caseInsensitiveCompare(name) == .orderedSame })?.value {
                return value
            }
        }
        return nil
    }

    // MARK: - JSON-RPC id rewriting

    /// A request body with its `id` replaced by a unique string, plus what is
    /// needed to put the caller's own id back into the answer.
    struct IDRewrite: Sendable {
        let body: Data
        let uniqueID: String?
        /// The original id, JSON-encoded as the sole element of an array.
        let originalIDJSON: Data?
    }

    /// A body that is a single JSON object with an `id` gets a fresh id; any
    /// other body (array, no id, unparseable) passes through unchanged.
    static func rewriteID(in body: Data) -> IDRewrite {
        guard var object = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
              let original = object["id"], isRewritable(original),
              let originalJSON = try? JSONSerialization.data(withJSONObject: [original]) else {
            return IDRewrite(body: body, uniqueID: nil, originalIDJSON: nil)
        }
        let unique = UUID().uuidString
        object["id"] = unique
        guard let rewritten = try? JSONSerialization.data(withJSONObject: object) else {
            return IDRewrite(body: body, uniqueID: nil, originalIDJSON: nil)
        }
        return IDRewrite(body: rewritten, uniqueID: unique, originalIDJSON: originalJSON)
    }

    /// Only a string or an integer is a JSON-RPC id the SDK tracks; null (which
    /// the SDK reads as "no id", a notification), booleans and fractions pass
    /// through untouched.
    private static func isRewritable(_ id: Any) -> Bool {
        if id is String { return true }
        guard let number = id as? NSNumber, CFGetTypeID(number) == CFNumberGetTypeID() else { return false }
        return !CFNumberIsFloatType(number)
    }

    /// Puts the caller's id back into a response body that carries ours.
    static func restoreID(in body: Data, using rewrite: IDRewrite) -> Data {
        guard let unique = rewrite.uniqueID, let originalJSON = rewrite.originalIDJSON,
              var object = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
              object["id"] as? String == unique,
              let original = (try? JSONSerialization.jsonObject(with: originalJSON)) as? [Any],
              let first = original.first,
              object.updateValue(first, forKey: "id") != nil,
              let restored = try? JSONSerialization.data(withJSONObject: object) else {
            return body
        }
        return restored
    }

    // MARK: - Cancellation

    /// The requests in flight, keyed by caller and the id the caller sent, so
    /// a `notifications/cancelled` naming that id finds the id the SDK knows
    /// the request by. Two requests can share a key: callers that name no
    /// pane (a session outside one) share the empty caller, so two sessions
    /// that both send `"id": 3` land on one key. Each is kept, and a
    /// cancellation that could mean either cancels neither: cancelling the
    /// wrong session's tool call is worse than letting one run to its end.
    actor InFlightRequests {
        private var uniqueIDs: [String: [String]] = [:]

        func begin(_ key: String, uniqueID: String) { uniqueIDs[key, default: []].append(uniqueID) }

        /// Forgets this request's entry only, so another request under the
        /// same key stays findable.
        func end(_ key: String, uniqueID: String) {
            guard var ids = uniqueIDs[key] else { return }
            ids.removeAll { $0 == uniqueID }
            uniqueIDs[key] = ids.isEmpty ? nil : ids
        }

        /// The one request in flight under `key`; nil when there is none or
        /// more than one.
        func uniqueID(for key: String) -> String? {
            guard let ids = uniqueIDs[key], ids.count == 1 else { return nil }
            return ids[0]
        }
    }

    static func inFlightKey(caller: String?, originalIDJSON: Data) -> String {
        (caller ?? "") + "\u{1F}" + (String(bytes: originalIDJSON, encoding: .utf8) ?? "")
    }

    /// A `notifications/cancelled` body whose `params.requestId` is an id the
    /// handler may have rewritten.
    struct Cancellation: Sendable {
        let body: Data
        /// The named id, JSON-encoded as the sole element of an array.
        let originalIDJSON: Data

        /// The same notification naming `uniqueID` instead.
        func naming(_ uniqueID: String) -> Data {
            guard var object = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
                  var params = object["params"] as? [String: Any] else { return body }
            params["requestId"] = uniqueID
            object["params"] = params
            return (try? JSONSerialization.data(withJSONObject: object)) ?? body
        }
    }

    /// Recognises a cancellation notification: no (rewritable) id of its own,
    /// the cancellation method, and a string or integer `requestId`.
    static func cancellation(in body: Data) -> Cancellation? {
        guard let object = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
              !(object["id"].map(isRewritable) ?? false),
              object["method"] as? String == CancelledNotification.name,
              let params = object["params"] as? [String: Any],
              let requestID = params["requestId"], isRewritable(requestID),
              let json = try? JSONSerialization.data(withJSONObject: [requestID]) else { return nil }
        return Cancellation(body: body, originalIDJSON: json)
    }

    /// Cancels the request the SDK knows as `uniqueID`: a cancellation
    /// notification into the transport, which the SDK answers by cancelling
    /// its handler task, then `release`.
    static func cancel(_ uniqueID: String, on transport: StatelessHTTPServerTransport,
                       headers: [String: String], path: String, reason: String) async {
        let notification: [String: Any] = [
            "jsonrpc": "2.0", "method": CancelledNotification.name,
            "params": ["requestId": uniqueID, "reason": reason]
        ]
        if let body = try? JSONSerialization.data(withJSONObject: notification) {
            _ = await transport.handleRequest(MCP.HTTPRequest(method: "POST", headers: headers, body: body, path: path))
        }
        await release(uniqueID, on: transport, reason: reason)
    }

    /// Answers the HTTP call waiting on `uniqueID` with an error. The SDK sends
    /// no response for a cancelled request, as the spec says, but over
    /// stateless HTTP a request with no response is a connection held open to
    /// the host's timeout and a transport waiter never released. Arriving
    /// after a real response, this finds no waiter and the transport drops it.
    static func release(_ uniqueID: String, on transport: StatelessHTTPServerTransport, reason: String) async {
        let response: [String: Any] = [
            "jsonrpc": "2.0", "id": uniqueID,
            // -32800 is the code the LSP gives a cancelled request; JSON-RPC
            // reserves none and MCP defines none.
            "error": ["code": -32800, "message": "request cancelled: \(reason)"]
        ]
        if let body = try? JSONSerialization.data(withJSONObject: response) {
            try? await transport.send(body)
        }
    }

    // MARK: - Response

    /// The SDK's answer as status, headers and a whole body, with the
    /// caller's id put back. A `.stream` is collected, which is fine for a
    /// stateless transport that never opens one for `tools/*`.
    private static func collect(_ answer: MCP.HTTPResponse, restoring rewrite: IDRewrite) async -> Response {
        var body = Data()
        switch answer {
        case .stream(let stream, _):
            do {
                for try await chunk in stream { body.append(chunk) }
            } catch {
                return (status: 500, headers: [:], body: Data())
            }
        default:
            body = answer.bodyData ?? Data()
        }
        return (status: answer.statusCode, headers: answer.headers, body: restoreID(in: body, using: rewrite))
    }
}
