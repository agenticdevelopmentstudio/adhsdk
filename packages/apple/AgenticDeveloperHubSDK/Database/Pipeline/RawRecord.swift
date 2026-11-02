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

/// Shared limits for the pipeline.
public enum PipelineLimits {
    /// The default byte budget for one spool batch or one replay chunk (32 MiB of
    /// payload). A batch always holds at least one record, however large.
    public static let defaultMaxBatchBytes = 32 * 1024 * 1024

    /// The longest prefix of `sizes` whose total stays within `maxBytes`, and never
    /// fewer than one element when `sizes` is not empty.
    public static func prefixWithinBudget(_ sizes: [Int], maxBytes: Int) -> Int {
        var total = 0
        for (index, size) in sizes.enumerated() {
            if index > 0 && total + size > maxBytes { return index }
            total += size
        }
        return sizes.count
    }
}
