import Foundation

/// Token usage for one request. Every count is cumulative for the request so
/// far; a count the provider does not report is zero.
public struct AIUsage: Sendable, Codable, Equatable {
    public var inputTokens: Int
    public var outputTokens: Int
    public var cacheReadTokens: Int
    public var cacheWriteTokens: Int

    public init(inputTokens: Int = 0, outputTokens: Int = 0, cacheReadTokens: Int = 0, cacheWriteTokens: Int = 0) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheWriteTokens = cacheWriteTokens
    }
}

/// One event in the assistant response stream. A plugin's decoder converts the
/// provider's raw byte stream into a sequence of these; the host renders them.
public enum AIStreamEvent: Sendable {

    /// A chunk of assistant text.
    case textDelta(String)

    /// A chunk of the model's reasoning ("thinking") text, kept apart from the
    /// answer so a consumer that only renders the answer can ignore it.
    case thinkingDelta(String)

    /// The model asked to call a tool. `argumentsJSON` is the raw JSON arguments.
    case toolUse(id: String, name: String, argumentsJSON: Data)

    /// Token usage for the request so far. A later `usage` event supersedes an
    /// earlier one: keep the last.
    case usage(AIUsage)

    /// The response finished. `stopReason` is the provider's reason, if any.
    case end(stopReason: String?)
}

/// Decodes a provider's streaming HTTP response body into `AIStreamEvent`s.
///
/// The host feeds raw bytes to `consume(_:)` as they arrive — possibly splitting
/// a single logical frame across calls — and the decoder buffers any partial
/// frame internally, returning only the events it can fully decode. When the
/// stream closes, the host calls `finish()` once to flush any trailing state.
///
/// A fresh decoder is created per request (see `AIPlugin.makeDecoder()`), so it
/// may hold mutable per-response parsing state.
public protocol AIStreamDecoder: AnyObject {

    /// Append newly received bytes and return whatever complete events can now
    /// be decoded. Buffer any partial trailing frame internally.
    func consume(_ data: Data) -> [AIStreamEvent]

    /// The stream closed; return any final events the decoder was holding.
    func finish() -> [AIStreamEvent]
}

extension AIStreamDecoder {
    public func finish() -> [AIStreamEvent] { [] }
}
