import HTTPTypes
import OpenAPIRuntime

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public struct RawResponse: Sendable {
    public let status: Int
    public let headers: [String: String]
    public let body: Data

    public func decode<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = .adhDefault) throws -> T {
        try decoder.decode(type, from: body)
    }
}

public enum RawRequestError: Error, Sendable, Equatable {
    case invalidPath(String)
    case http(status: Int, body: Data)
}

extension JSONDecoder {
    /// The hub backend's two date encodings: the /v1 API's `created`/`updated`
    /// are unix timestamps in seconds; every other date is ISO-8601, with or
    /// without fractional seconds.
    public static let adhDefault: JSONDecoder = {
        let decoder = JSONDecoder()
        // Format styles, not ISO8601DateFormatter: the strategy closure is
        // @Sendable and only the value-type styles may be captured by it.
        let fractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        let plain = Date.ISO8601FormatStyle()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let seconds = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: seconds)
            }
            let text = try container.decode(String.self)
            if let date = (try? fractional.parse(text)) ?? (try? plain.parse(text)) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "not an ISO-8601 date: \(text)"))
        }
        return decoder
    }()
}

/// The one buffering cap for a whole-body read on the request path. Both the
/// request body `SessionRefreshMiddleware` buffers (so a retry can resend it)
/// and the response body `rawJSON` collects are governed by this single
/// contract: 16 MiB covers every JSON body the hub sends; uploads go through
/// storage presigned URLs, not this client.
enum ADHBodyLimit {
    static let maxBuffered = 16 * 1024 * 1024
}

/// Escape hatch for backend routes the OpenAPI document does not describe, or
/// describes stalely enough that the generated operation cannot express
/// the real request (see the design spec's endpoint inventory). Runs the exact
/// middleware chain the typed clients use, so bearer injection and
/// refresh-and-retry apply identically.
extension ADHClient {

    /// The `operationID` `rawJSON` reports to the middleware chain for a raw
    /// request. Middleware that keys off operation IDs (notably
    /// ``SessionRefreshMiddleware/exemptOperationIDs``) must derive its
    /// entries from this, never restate the format, so the two can never
    /// disagree about what a raw request is called.
    static func rawOperationID(method: HTTPRequest.Method, path: String) -> String {
        "raw \(method.rawValue) \(path)"
    }

    /// `POST /v1/auth/sessions/revoke` — a raw route the session layer itself
    /// sends (from ``signOut()``). Named here so `signOut` and the refresh
    /// middleware's exemption always describe the same request.
    static let revokeMethod: HTTPRequest.Method = .post
    static let revokePath = "/v1/auth/sessions/revoke"
    static let revokeRawOperationID = rawOperationID(method: revokeMethod, path: revokePath)

    /// `headers` is applied *after* the defaults below, so a caller can
    /// override `Accept`/`Content-Type` — and, more to the point, can set a
    /// header this client would never set for itself. The one real caller is
    /// ``exchangeOAuthCode(_:userAgent:)``, which has to present the
    /// *browser's* `User-Agent` because the backend binds an OAuth exchange
    /// code to it. A name the HTTP field grammar rejects is dropped rather
    /// than trapping: this is a transport detail, not a place to crash a
    /// sign-in.
    public func rawJSON(
        method: HTTPRequest.Method,
        path: String,
        query: [String: String] = [:],
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws -> RawResponse {
        guard path.hasPrefix("/") else { throw RawRequestError.invalidPath(path) }

        var fullPath = path
        if !query.isEmpty {
            let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+&=?#"))
            let encoded = query
                .sorted { $0.key < $1.key }
                .map { key, value in
                    let k = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
                    let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
                    return "\(k)=\(v)"
                }
                .joined(separator: "&")
            fullPath += (path.contains("?") ? "&" : "?") + encoded
        }

        var request = HTTPRequest(method: method, scheme: nil, authority: nil, path: fullPath)
        request.headerFields[.accept] = "application/json"
        if body != nil {
            request.headerFields[.contentType] = "application/json"
        }
        for (name, value) in headers.sorted(by: { $0.key < $1.key }) {
            guard let field = HTTPField.Name(name) else { continue }
            request.headerFields[field] = value
        }

        let operationID = Self.rawOperationID(method: method, path: path)
        let transport = self.transport
        var next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { request, body, baseURL in
            try await transport.transport.send(request, body: body, baseURL: baseURL, operationID: operationID)
        }
        for middleware in middlewares.reversed() {
            let tail = next
            next = { request, body, baseURL in
                try await middleware.intercept(request, body: body, baseURL: baseURL, operationID: operationID, next: tail)
            }
        }

        let (response, responseBody) = try await next(request, body.map { HTTPBody($0) }, transport.serverURL)
        let data: Data = if let responseBody {
            try await Data(collecting: responseBody, upTo: ADHBodyLimit.maxBuffered)
        } else {
            Data()
        }
        var headers: [String: String] = [:]
        for field in response.headerFields {
            headers[field.name.canonicalName] = field.value
        }
        guard response.status.code < 400 else {
            throw RawRequestError.http(status: response.status.code, body: data)
        }
        return RawResponse(status: response.status.code, headers: headers, body: data)
    }
}
