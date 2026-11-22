#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// Header handling for both directions, and which requests are routing candidates.
enum RouterHeaders {
    /// RFC 9110 §7.6.1 connection-specific fields. Any `proxy-*` field and any
    /// field the `Connection` header names are treated the same way.
    static let hopByHop: Set<String> = [
        "connection", "keep-alive", "transfer-encoding", "te", "trailer", "upgrade",
        "proxy-authorization", "proxy-authenticate", "proxy-connection"
    ]
    /// `URLSession` sets these itself. `accept-encoding` is replaced with
    /// `identity`; `expect` was answered by the router.
    private static let dropFromRequest: Set<String> = ["host", "content-length", "accept-encoding", "expect"]
    /// The router re-frames the body as chunked. `URLSession` has already
    /// decoded any content coding, so the coding header would lie.
    private static let dropFromResponse: Set<String> = ["content-length", "content-encoding"]
    static let sessionHeader = "x-claude-code-session-id"
    private static let quotaPrefix = "anthropic-ratelimit-unified-"

    struct QuotaColumns: Equatable, Sendable {
        var fiveHour: Double?
        var sevenDay: Double?
        var fiveHourStatus: String?
        var sevenDayStatus: String?
        var organizationId: String?
    }

    static func connectionTokens(_ values: [String]) -> Set<String> {
        Set(values.flatMap { $0.split(separator: ",") }
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty })
    }

    private static func isHopByHop(_ lowered: String, listed: Set<String>) -> Bool {
        hopByHop.contains(lowered) || lowered.hasPrefix("proxy-") || listed.contains(lowered)
    }

    /// The fields sent upstream. With a `bearer`, the client's `Authorization`
    /// value is replaced and any `x-api-key` goes: a routed request carries one
    /// credential, the pool's. The returned array keeps the client's order, but
    /// header order is not preserved on the wire: URLSession reorders fields
    /// and adds its own defaults (accept, accept-language, user-agent,
    /// cache-control), so nothing may depend on order.
    static func upstreamFields(_ head: RouterRequestHead, bearer: String?) -> [HTTPHeaderField] {
        let listed = connectionTokens(head.values("connection"))
        var fields: [HTTPHeaderField] = []
        var swapped = false
        for field in head.fields {
            let lowered = field.name.lowercased()
            if isHopByHop(lowered, listed: listed) || dropFromRequest.contains(lowered) { continue }
            if bearer != nil, lowered == "x-api-key" { continue }
            if let bearer, lowered == "authorization" {
                if !swapped { fields.append(HTTPHeaderField(name: field.name, value: "Bearer \(bearer)")) }
                swapped = true
                continue
            }
            fields.append(field)
        }
        if let bearer, !swapped { fields.append(HTTPHeaderField(name: "authorization", value: "Bearer \(bearer)")) }
        fields.append(HTTPHeaderField(name: "accept-encoding", value: "identity"))
        return fields
    }

    /// Requests that spend subscription quota: POST to `/v1/messages…`, no
    /// `x-api-key`, and exactly one `Authorization: Bearer sk-ant-oat…`.
    /// Returns that token, which the fence must still accept.
    static func candidateToken(_ head: RouterRequestHead) -> String? {
        guard head.method == "POST", isRoutablePath(head.path), head.values("x-api-key").isEmpty else { return nil }
        let credentials = head.values("authorization")
        guard credentials.count == 1, let value = credentials.first,
              let space = value.firstIndex(of: " "), value[..<space].lowercased() == "bearer" else { return nil }
        let token = value[value.index(after: space)...].trimmingCharacters(in: .whitespaces)
        return token.hasPrefix("sk-ant-oat") ? token : nil
    }

    /// A path that could mean something other than what it says upstream
    /// (`..`, percent-encoding) is never routed.
    static func isRoutablePath(_ path: String) -> Bool {
        path.hasPrefix("/v1/messages") && !path.contains("..") && !path.contains("%")
    }

    /// Response fields for the client, sorted by name. `HTTPURLResponse` has
    /// already merged duplicates and lost their order.
    static func responseFields(_ headers: [String: String]) -> [HTTPHeaderField] {
        let listed = connectionTokens(headers["connection"].map { [$0] } ?? [])
        return headers.keys.sorted().compactMap { name in
            guard let value = headers[name], !isHopByHop(name, listed: listed), !dropFromResponse.contains(name),
                  isSafe(name), isSafe(value) else { return nil }
            return HTTPHeaderField(name: name, value: value)
        }
    }

    private static func isSafe(_ text: String) -> Bool {
        !text.unicodeScalars.contains { $0 == "\r" || $0 == "\n" || $0 == "\0" }
    }

    static func hasBody(method: String, status: Int) -> Bool {
        method != "HEAD" && status != 204 && status != 304 && !(100..<200).contains(status)
    }

    static func lowercased(_ response: HTTPURLResponse) -> [String: String] {
        var headers: [String: String] = [:]
        for (key, value) in response.allHeaderFields {
            guard let name = key as? String else { continue }
            headers[name.lowercased()] = "\(value)"
        }
        return headers
    }

    static func quotaColumns(_ headers: [String: String]) -> QuotaColumns {
        func fraction(_ key: String) -> Double? {
            guard let text = headers[quotaPrefix + key], let value = Double(text), value.isFinite else { return nil }
            return value
        }
        return QuotaColumns(
            fiveHour: fraction("5h-utilization"),
            sevenDay: fraction("7d-utilization"),
            fiveHourStatus: headers[quotaPrefix + "5h-status"],
            sevenDayStatus: headers[quotaPrefix + "7d-status"],
            organizationId: headers["anthropic-organization-id"])
    }

    static func reasonPhrase(_ status: Int) -> String {
        let phrases: [Int: String] = [
            100: "Continue", 200: "OK", 201: "Created", 202: "Accepted", 204: "No Content",
            301: "Moved Permanently", 302: "Found", 303: "See Other", 304: "Not Modified",
            307: "Temporary Redirect", 308: "Permanent Redirect", 400: "Bad Request", 401: "Unauthorized",
            403: "Forbidden", 404: "Not Found", 405: "Method Not Allowed", 408: "Request Timeout",
            409: "Conflict", 413: "Payload Too Large", 422: "Unprocessable Entity", 429: "Too Many Requests",
            431: "Request Header Fields Too Large", 500: "Internal Server Error", 501: "Not Implemented",
            502: "Bad Gateway", 503: "Service Unavailable", 504: "Gateway Timeout", 529: "Overloaded"
        ]
        return phrases[status] ?? "Unknown"
    }
}
#endif
