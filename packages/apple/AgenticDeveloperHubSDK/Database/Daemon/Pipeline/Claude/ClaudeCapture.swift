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
        guard eventTypes.contains(eventType),
              hookData["file_size_bytes"] == nil || hookData["file_sha256"] == nil else { return hookData }
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
    ///
    /// The stamp is spliced in as text: the new fields go just before the
    /// `hook_data` object's closing brace, encoded with sorted keys, and every
    /// byte the hook wrote stays exactly as it was (a `1.0`, a large integer, an
    /// escaped `\/`, a duplicate key). The envelope is decoded only to read it.
    public static func stamped(envelope data: Data) -> Data {
        guard eventTypes.contains(where: { data.range(of: Data($0.utf8)) != nil }),
              let envelope = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let eventType = envelope["event"] as? String,
              let hookData = envelope["hook_data"] as? [String: Any] else { return data }
        let added = stamped(hookData, eventType: eventType).filter { hookData[$0.key] == nil }
        guard !added.isEmpty, JSONSerialization.isValidJSONObject(added),
              let encoded = try? JSONSerialization.data(withJSONObject: added, options: [.sortedKeys]),
              encoded.count > 2,
              let brace = EnvelopeText.hookDataClosingBrace(in: data) else { return data }
        var out = data
        // `{"a":1,"b":2}` minus its braces, after a comma when the object has members.
        var fragment = Data(encoded.dropFirst().dropLast())
        if brace.hasMembers { fragment.insert(UInt8(ascii: ","), at: fragment.startIndex) }
        out.insert(contentsOf: fragment, at: brace.index)
        return out
    }
}

/// A minimal reader of an envelope's JSON text: where the top-level
/// `hook_data` object ends, so a stamp can be spliced in without re-encoding.
enum EnvelopeText {
    struct Brace: Equatable {
        /// The offset of `hook_data`'s closing `}`.
        let index: Int
        /// Whether the object has at least one member.
        let hasMembers: Bool
    }

    /// The closing brace of the top-level `hook_data` object (the last one,
    /// should the key repeat), or nil when the text is not an object holding one.
    static func hookDataClosingBrace(in data: Data) -> Brace? {
        let bytes = [UInt8](data)
        var pos = skipSpace(bytes, 0)
        guard pos < bytes.count, bytes[pos] == UInt8(ascii: "{") else { return nil }
        pos += 1
        var found: Brace?
        while true {
            pos = skipSpace(bytes, pos)
            guard pos < bytes.count else { return nil }
            if bytes[pos] == UInt8(ascii: "}") { return found }
            if bytes[pos] == UInt8(ascii: ",") { pos += 1; continue }
            guard bytes[pos] == UInt8(ascii: "\""), let keyEnd = stringEnd(bytes, pos) else { return nil }
            let key = (try? JSONSerialization.jsonObject(
                with: Data(bytes[pos..<keyEnd]), options: .fragmentsAllowed)) as? String
            pos = skipSpace(bytes, keyEnd)
            guard pos < bytes.count, bytes[pos] == UInt8(ascii: ":") else { return nil }
            let valueStart = skipSpace(bytes, pos + 1)
            guard let valueEnd = valueEnd(bytes, valueStart) else { return nil }
            if key == "hook_data", bytes[valueStart] == UInt8(ascii: "{") {
                let inner = skipSpace(bytes, valueStart + 1)
                found = Brace(index: valueEnd - 1, hasMembers: inner < valueEnd - 1)
            }
            pos = valueEnd
        }
    }

    private static func skipSpace(_ bytes: [UInt8], _ start: Int) -> Int {
        var pos = start
        while pos < bytes.count, [0x20, 0x09, 0x0A, 0x0D].contains(bytes[pos]) { pos += 1 }
        return pos
    }

    /// One past the closing quote of the string starting at `start`.
    private static func stringEnd(_ bytes: [UInt8], _ start: Int) -> Int? {
        var pos = start + 1
        while pos < bytes.count {
            switch bytes[pos] {
            case UInt8(ascii: "\\"): pos += 2
            case UInt8(ascii: "\""): return pos + 1
            default: pos += 1
            }
        }
        return nil
    }

    /// One past the end of the value starting at `start`.
    private static func valueEnd(_ bytes: [UInt8], _ start: Int) -> Int? {
        guard start < bytes.count else { return nil }
        switch bytes[start] {
        case UInt8(ascii: "\""):
            return stringEnd(bytes, start)
        case UInt8(ascii: "{"), UInt8(ascii: "["):
            var depth = 0
            var pos = start
            while pos < bytes.count {
                switch bytes[pos] {
                case UInt8(ascii: "\""):
                    guard let end = stringEnd(bytes, pos) else { return nil }
                    pos = end
                    continue
                case UInt8(ascii: "{"), UInt8(ascii: "["):
                    depth += 1
                case UInt8(ascii: "}"), UInt8(ascii: "]"):
                    depth -= 1
                    if depth == 0 { return pos + 1 }
                default:
                    break
                }
                pos += 1
            }
            return nil
        default:
            var pos = start
            while pos < bytes.count, ![UInt8(ascii: ","), UInt8(ascii: "}"), UInt8(ascii: "]"),
                                     0x20, 0x09, 0x0A, 0x0D].contains(bytes[pos]) { pos += 1 }
            return pos
        }
    }
}
#endif
