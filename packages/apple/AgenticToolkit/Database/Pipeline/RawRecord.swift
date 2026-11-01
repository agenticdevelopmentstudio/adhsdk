import Foundation

/// One unit of captured input, exactly as it arrived. The payload is the verbatim
/// bytes; nothing downstream may alter what is stored in the raw archive.
public struct RawRecord: Sendable, Equatable {
    /// The agent the record came from, e.g. "claude", "mock", "codex".
    public let provider: String
    /// How it was captured, e.g. "hook", "transcript", "hook-legacy".
    public let sourceKind: String
    /// Unique within a provider; the same input always yields the same key.
    public let dedupKey: String
    public let receivedAt: Date
    /// The verbatim bytes.
    public let payload: Data

    public init(provider: String, sourceKind: String, dedupKey: String, receivedAt: Date, payload: Data) {
        self.provider = provider
        self.sourceKind = sourceKind
        self.dedupKey = dedupKey
        self.receivedAt = receivedAt
        self.payload = payload
    }
}
