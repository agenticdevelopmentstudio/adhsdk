#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// Turns a hook event delivered over HTTP or the socket — not through the drop
/// directory — into a spool record (Design Ruling 2).
///
/// The record has no file name to borrow a key from, so the key is a fresh
/// `"cap-<UUID>"` stamped here, once, at capture: every delivery is its own record.
/// The payload is `ParsedEvent.envelopeJSON()` unchanged, the same envelope a drop
/// file carries.
public struct ClaudeCapture {
    public static func record(for event: ParsedEvent, now: Date) throws -> RawRecord {
        RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.legacyHookKind,
            dedupKey: "cap-\(UUID().uuidString)", receivedAt: now, payload: try event.envelopeJSON())
    }
}
#endif
