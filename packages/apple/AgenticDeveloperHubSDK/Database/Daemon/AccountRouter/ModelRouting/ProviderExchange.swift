#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import AIPluginKit
import Foundation

/// The provider side of one exchange: the request a `ProviderRoute` gets, and
/// the bytes the client gets back in place of the provider's. Never reads,
/// logs or returns a header value other than the ones it builds.
enum ProviderExchange {
    /// Sent when the client named none; the Messages API requires one.
    static let defaultAnthropicVersion = "2023-06-01"
    /// The subscription-token beta: meaningless, and possibly refused, with an API key.
    static let oauthBeta = "oauth-2025-04-20"
    /// A non-streamed provider reply larger than this is not translated.
    static let replyLimit = 32 * 1024 * 1024
    /// What a client streaming a translated reply gets when the provider's stream breaks.
    static let streamFailedEvent = Data(
        ("event: error\ndata: "
            + #"{"type":"error","error":{"type":"api_error","message":"provider stream failed"}}"#
            + "\n\n").utf8)

    /// The provider request: `body` is already in the route's wire format. The
    /// client's own credential never goes to a provider; only the route's key does.
    static func request(_ route: ProviderRoute, head: RouterRequestHead, body: Data, streams: Bool) -> URLRequest {
        UpstreamCall.request(url: route.endpoint, method: "POST", fields: fields(route, head: head, streams: streams),
                             body: body)
    }

    static func fields(_ route: ProviderRoute, head: RouterRequestHead, streams: Bool) -> [HTTPHeaderField] {
        var fields = [
            HTTPHeaderField(name: "content-type", value: "application/json"),
            HTTPHeaderField(name: "accept", value: streams ? "text/event-stream" : "application/json"),
            HTTPHeaderField(name: "accept-encoding", value: "identity")
        ]
        switch route.wire {
        case .chatCompletions:
            if let key = route.apiKey { fields.append(HTTPHeaderField(name: "authorization", value: "Bearer \(key)")) }
        case .anthropic:
            if let key = route.apiKey { fields.append(HTTPHeaderField(name: "x-api-key", value: key)) }
            let version = head.values("anthropic-version").first { !$0.isEmpty } ?? defaultAnthropicVersion
            fields.append(HTTPHeaderField(name: "anthropic-version", value: version))
            let kept = head.values("anthropic-beta")
                .flatMap { $0.split(separator: ",") }
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.lowercased() != oauthBeta }
            if !kept.isEmpty {
                fields.append(HTTPHeaderField(name: "anthropic-beta", value: kept.joined(separator: ",")))
            }
        }
        return fields
    }

    /// The head the client gets for a translated reply: no provider header
    /// passes through. With `length`, a sized body; else chunked when
    /// `chunked`, or delimited by the close.
    static func clientHead(streams: Bool, chunked: Bool, length: Int?) -> Data {
        var text = "HTTP/1.1 200 OK\r\n"
        text += "Content-Type: \(streams ? "text/event-stream" : "application/json")\r\n"
        text += "request-id: router-\(UUID().uuidString.lowercased())\r\n"
        if let length {
            text += "Content-Length: \(length)\r\n"
        } else if chunked {
            text += "Transfer-Encoding: chunked\r\n"
        }
        text += "Connection: close\r\n\r\n"
        return Data(text.utf8)
    }

    /// A non-streamed `chat.completion` as an Anthropic `message`; nil when it
    /// cannot be translated.
    static func message(fromChatCompletion data: Data, route: ProviderRoute) -> Data? {
        guard let message = try? AnthropicChatTranslation.anthropicMessage(
            fromChatCompletion: data, fallbackModel: route.model), !message.isEmpty else { return nil }
        return message
    }
}
#endif
