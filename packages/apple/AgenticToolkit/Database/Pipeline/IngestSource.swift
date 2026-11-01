import Foundation

/// Finds a provider's raw input and appends it to that provider's spool. Claude
/// has two: hooks and `.jsonl` transcripts.
///
/// Contract:
/// - **Owner of the dedup key.** The source derives every record's `dedupKey`, and
///   the same input must always yield the same key; different input must never
///   share one. The archive keeps the first bytes for a key and the drainer
///   quarantines a later record whose bytes differ (`ArchiveAppendOutcome.conflict`),
///   so a key collision costs a quarantine, never data, but it is a source bug.
/// - **Cursor and append are one transaction.** A source that tracks how far it
///   has read stores that cursor in the spool's `source_state` through
///   `ProviderSpool.append(_:settingSourceState:to:)`, so a crash leaves either
///   both (nothing to redo) or neither (the same bytes are read again). Nothing is
///   lost and nothing is spooled twice.
/// - **Waking.** The host calls `poll` on its own schedule (a file-system event, a
///   hook delivery, a timer), then wakes the provider's `PipelineDrainer`. A
///   source never drains.
public protocol IngestSource: Sendable {
    var provider: String { get }

    /// Appends whatever new input is available and returns how many records it
    /// appended (0 when there was nothing new). Safe to call at any time.
    func poll(into spool: ProviderSpool) throws -> Int
}

/// The points inside a source's `poll` where a test can inject a crash: before the
/// spool append (nothing written), and after it (append and cursor committed
/// together, so the cursor has advanced too).
public enum SourceStep: String, Sendable, CaseIterable {
    case beforeAppend, afterAppend
}
