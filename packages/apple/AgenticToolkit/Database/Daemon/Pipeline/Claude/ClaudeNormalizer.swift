#if canImport(AgenticToolkitCore)
import Foundation

public enum ClaudeNormalizerError: Error, Equatable {
    /// The record's source kind has no normalizer (yet). Carries the kind.
    case unsupportedSourceKind(String)
    /// The payload is not a parseable hook envelope. Carries the record's dedup key.
    case unparseable(String)
}

/// The Claude provider's normalizer: dispatches each archived record to the
/// normalizer for its source kind. Hook envelopes, live or legacy, share one
/// normalizer; transcripts are not normalized yet and throw.
public struct ClaudeNormalizer: Normalizer {
    public let provider = ClaudeProvider.name

    private let hooks = ClaudeHookNormalizer()

    public init() {}

    public func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch {
        switch record.record.sourceKind {
        case ClaudeProvider.hookKind, ClaudeProvider.legacyHookKind:
            return try hooks.normalize(record)
        default:
            throw ClaudeNormalizerError.unsupportedSourceKind(record.record.sourceKind)
        }
    }
}
#endif
