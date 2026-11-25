import Foundation

/// A request to a mounted handler set, independent of any server: the method,
/// the path below the mount as segments, the query and the body.
public struct HandlerRequest: Sendable, Equatable {
    public var method: String
    /// Path segments below the mount: `/agent/sessions/<id>` mounted at
    /// `/agent` is `["sessions", "<id>"]`.
    public var path: [String]
    public var query: [String: String]
    public var body: Data

    public init(method: String, path: [String], query: [String: String] = [:], body: Data = Data()) {
        self.method = method.uppercased()
        self.path = path
        self.query = query
        self.body = body
    }

    /// The request for `path` written as a string (`"sessions/<id>"`; leading,
    /// trailing and doubled slashes ignored). Each segment is percent-decoded.
    public init(method: String, path: String, query: [String: String] = [:], body: Data = Data()) {
        self.init(method: method, path: Self.segments(path), query: query, body: body)
    }

    public static func segments(_ path: String) -> [String] {
        path.split(separator: "/", omittingEmptySubsequences: true)
            .map { String($0).removingPercentEncoding ?? String($0) }
    }
}

/// What a handler answers: JSON with a status, or a stream of agent events the
/// server relays (roosterd as SSE, with the event `type` as the SSE event name).
public enum HandlerResponse: Sendable {
    case json(status: Int, body: Data)
    case events(AsyncStream<AgentEnvelope>)

    /// The status a JSON reply carries; a stream is 200.
    public var status: Int {
        switch self {
        case .json(let status, _): return status
        case .events: return 200
        }
    }

    /// The error reply every handler uses: `{"error":"<code>","message":"…"}`.
    public static func error(_ status: Int, _ code: String, _ message: String) -> HandlerResponse {
        let body = (try? AgentsJSON.encode(HandlerError(error: code, message: message))) ?? Data()
        return .json(status: status, body: body)
    }

    /// `value` encoded with `AgentsJSON`, or a 500 when it cannot be.
    public static func encoded<T: Encodable>(_ value: T, status: Int = 200) -> HandlerResponse {
        do {
            return .json(status: status, body: try AgentsJSON.encode(value))
        } catch {
            return .error(500, HandlerError.internalCode, error.localizedDescription)
        }
    }

    /// A reply with no body (204, 202).
    public static func empty(_ status: Int) -> HandlerResponse {
        .json(status: status, body: Data())
    }
}

/// The error body: `{"error":"<code>","message":"…"}`.
public struct HandlerError: Codable, Sendable, Equatable {
    public var error: String
    public var message: String

    public init(error: String, message: String) {
        self.error = error
        self.message = message
    }

    public static let badRequestCode = "bad_request"
    public static let notFoundCode = "not_found"
    public static let conflictCode = "conflict"
    public static let unprocessableCode = "unprocessable"
    public static let internalCode = "internal"

    static func badRequest(_ message: String) -> HandlerResponse { .error(400, badRequestCode, message) }
    static func notFound(_ message: String) -> HandlerResponse { .error(404, notFoundCode, message) }
    static func conflict(_ message: String) -> HandlerResponse { .error(409, conflictCode, message) }
    static func unprocessable(_ message: String) -> HandlerResponse { .error(422, unprocessableCode, message) }
    static func failure(_ error: any Error) -> HandlerResponse {
        .error(500, internalCode, error.localizedDescription)
    }
    static let noRoute = notFound("No such route")
}

extension HandlerRequest {

    /// The body as a JSON object, or nil when it is not one (an empty body is `[:]`).
    func jsonObject() -> [String: Any]? {
        if body.isEmpty { return [:] }
        return (try? JSONSerialization.jsonObject(with: body)) as? [String: Any]
    }
}
