#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// Turns a hook event delivered over HTTP or the socket — not through the drop
/// directory — into a spool record (Design Ruling 2).
///
/// The record has no file name to borrow a key from, so the key is a fresh
/// `"cap-<UUID>"` stamped here, once, at capture: every delivery is its own record.
/// The payload is `ParsedEvent.envelopeJSON()`, the same envelope a drop file
/// carries, with the file fingerprint stamped in (`ClaudeFileFingerprint`).
public struct ClaudeCapture {
    public static func record(for event: ParsedEvent, now: Date) throws -> RawRecord {
        RawRecord(
            provider: ClaudeProvider.name, sourceKind: ClaudeProvider.legacyHookKind,
            dedupKey: "cap-\(UUID().uuidString)", receivedAt: now,
            payload: try ClaudeFileFingerprint.stamped(event).envelopeJSON())
    }
}

/// Stamps `file_size_bytes` and `file_sha256` (`FileFingerprintEnricher`) into
/// the hook data of a `ConfigChange` or `InstructionsLoaded` event, whose
/// `file_path` names a file whose *contents* matter — a settings or skill file,
/// a CLAUDE.md — before the event reaches the spool.
///
/// The fingerprint describes the file at event time, so only capture can
/// compute it: the normalizer is pure and never reads the disk, and a replay
/// from the raw archive must see the same bytes. Stamping here keeps both true.
/// A field the hook data already carries is kept, so an envelope stamped once
/// (a spill file re-read, a re-feed) keeps its first fingerprint.
public enum ClaudeFileFingerprint {
    /// The hooks whose `file_path` is fingerprinted.
    public static let eventTypes: Set<String> = [
        HookEventType.configChange.rawValue, HookEventType.instructionsLoaded.rawValue
    ]

    /// `hookData` with the fingerprint of its `file_path` added, for the
    /// fingerprinted hooks; otherwise (or with nothing to measure) unchanged.
    public static func stamped(_ hookData: [String: Any], eventType: String) -> [String: Any] {
        guard eventTypes.contains(eventType) else { return hookData }
        let fingerprint = FileFingerprintEnricher.enrich(hookData: hookData)
        guard !fingerprint.isEmpty else { return hookData }
        return hookData.merging(fingerprint) { existing, _ in existing }
    }

    /// `event` with its hook data stamped.
    public static func stamped(_ event: ParsedEvent) -> ParsedEvent {
        guard eventTypes.contains(event.eventType) else { return event }
        return ParsedEvent(
            eventType: event.eventType, timestamp: event.timestamp,
            hookData: stamped(event.hookData, eventType: event.eventType),
            context: event.context, accountEmail: event.accountEmail,
            oauthAccountEmail: event.oauthAccountEmail)
    }

    /// A drop file's envelope bytes with the hook data stamped. Bytes that are
    /// not a fingerprinted hook's envelope, or that gain nothing, come back
    /// verbatim — every other drop file is spooled exactly as written.
    public static func stamped(envelope data: Data) -> Data {
        guard eventTypes.contains(where: { data.range(of: Data($0.utf8)) != nil }),
              var envelope = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let eventType = envelope["event"] as? String,
              let hookData = envelope["hook_data"] as? [String: Any] else { return data }
        let stamped = stamped(hookData, eventType: eventType)
        guard stamped.count != hookData.count else { return data }
        envelope["hook_data"] = stamped
        guard JSONSerialization.isValidJSONObject(envelope),
              let out = try? JSONSerialization.data(withJSONObject: envelope) else { return data }
        return out
    }
}
#endif
