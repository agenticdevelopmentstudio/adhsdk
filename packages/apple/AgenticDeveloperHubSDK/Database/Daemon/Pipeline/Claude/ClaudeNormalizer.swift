#if canImport(AgenticDeveloperHubSDKCore)
import Foundation

public enum ClaudeNormalizerError: Error, Equatable {
    /// The record's source kind has no normalizer (yet). Carries the kind.
    case unsupportedSourceKind(String)
    /// The payload is not parseable for its source kind (a hook envelope, or a
    /// transcript payload whose line is a JSON object). Carries the record's dedup key.
    case unparseable(String)

    /// How an ``unparseable(_:)`` record's quarantine reason starts: the drainer
    /// records a normalizer error as `String(describing:)`, `unparseable("<key>")`.
    public static let unparseableReasonPrefix = String(String(describing: Self.unparseable("")).dropLast(2))

    /// Quarantine reasons that are final: the normalizer is pure, so a record it
    /// could not parse never will, and it can never become an `events.db` row. Its
    /// bytes are in the raw archive, and it stays listed (and retryable) under the
    /// ingestion errors; only a caller waiting for captures to reach `events.db`
    /// skips it (`ProviderSpool.quarantinedCount(excludingReasonPrefixes:)`).
    public static let permanentReasonPrefixes = [unparseableReasonPrefix]
}

/// The Claude provider's normalizer: dispatches each archived record to the
/// normalizer for its source kind. Hook envelopes, live or legacy, share one
/// normalizer; transcript lines have their own. Any other kind throws.
public struct ClaudeNormalizer: Normalizer {
    public let provider = ClaudeProvider.name

    private let hooks = ClaudeHookNormalizer()
    private let transcripts = ClaudeTranscriptNormalizer()

    public init() {}

    public func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch {
        switch record.record.sourceKind {
        case ClaudeProvider.hookKind, ClaudeProvider.legacyHookKind:
            return try hooks.normalize(record)
        case ClaudeProvider.transcriptKind:
            return try transcripts.normalize(record)
        case ClaudeProvider.quarantineKind:
            // Archive-only: kept for its bytes, never an event (a replay too).
            return NormalizedBatch()
        default:
            throw ClaudeNormalizerError.unsupportedSourceKind(record.record.sourceKind)
        }
    }

    /// Two transcript payloads under one key (same session, file stem, offset and
    /// line hash) are one occurrence when their line bytes match, whatever else
    /// differs: the same transcript seen under another project directory's path, or
    /// counted at another line number. Hook kinds, and transcript payloads that do
    /// not decode, keep the byte-equal default.
    public func isEquivalent(archived: RawRecord, incoming: RawRecord) -> Bool {
        if archived.payload == incoming.payload { return true }
        guard archived.sourceKind == ClaudeProvider.transcriptKind,
              incoming.sourceKind == ClaudeProvider.transcriptKind,
              let old = try? ClaudeTranscriptPayload.decode(archived.payload),
              let new = try? ClaudeTranscriptPayload.decode(incoming.payload)
        else { return false }
        return old.line == new.line && old.lineBytes == new.lineBytes
    }
}
#endif
