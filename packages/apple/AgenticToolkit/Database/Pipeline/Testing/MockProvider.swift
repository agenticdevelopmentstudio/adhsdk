import Foundation

/// A scripted provider for exercising the whole pipeline without a real agent.
/// Lives in the framework (no XCTest) so the daemon's and the app's test targets can use it.
public struct MockProvider: Normalizer {
    public let provider = "mock"

    public struct BadRecord: Error, CustomStringConvertible {
        public let key: String
        public var description: String { "MockProvider.BadRecord(\(key))" }
    }

    public init() {}

    /// Scripted record. Payload is JSON:
    /// `{"op":"event"|"session"|"turn"|"message"|"bad", "session":…, "t":<epoch>, "n":<int>,`
    /// `"pad":<int>, "blob":<pad bytes>}`
    public static func record(key: String, op operation: String, session: String = "s1", t epoch: Double,
                              n number: Int = 0, pad: Int = 0) -> RawRecord {
        let object: [String: Any] = [
            "op": operation, "session": session, "t": epoch, "n": number, "pad": pad,
            "blob": String(repeating: "x", count: max(0, pad))
        ]
        // Sorted keys so the same arguments always give the same bytes.
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return RawRecord(provider: "mock", sourceKind: "hook", dedupKey: key,
                         receivedAt: Date(timeIntervalSince1970: epoch), payload: data)
    }

    public func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch {
        let key = record.record.dedupKey
        guard let object = try JSONSerialization.jsonObject(with: record.record.payload) as? [String: Any],
              let operation = object["op"] as? String, operation != "bad" else {
            throw BadRecord(key: key)
        }
        let session = object["session"] as? String ?? "s1"
        let epoch = object["t"] as? Double ?? 0
        let count = object["n"] as? Int ?? 0
        let blob = object["blob"] as? String ?? ""
        let time = Date(timeIntervalSince1970: epoch)

        var batch = NormalizedBatch()
        // Every op observes the session, with varying as_of, fields and ties,
        // so the store's merge rules are exercised.
        let ended = count % 7 == 0
        batch.sessions = [SessionUpsert(
            sessionID: session, asOf: time, model: "m-\(count % 3)", title: "title-\(count)",
            status: ended ? "ended" : "active", startedAt: time, endedAt: ended ? time : nil,
            attrs: ["last": .number(Double(count)), "tag\(count % 4)": .string("v\(count)")])]

        switch operation {
        case "session":
            batch.events = [NormalizedEvent(
                dedupKey: "\(key)#0", sessionID: session, kind: .sessionStart, providerType: "SessionStart",
                time: time, summary: "session \(count)", rawRef: record.id)]
        case "turn":
            batch.turns = [TurnRow(
                dedupKey: "\(key)#turn", sessionID: session, time: time, model: "m-\(count % 3)",
                inputTokens: count, outputTokens: count * 2, cacheReadTokens: count % 5,
                cacheWriteTokens: count % 3, costUSD: Double(count) / 100, rawRef: record.id)]
        case "message":
            batch.messages = [MessageRow(
                uuid: "\(key)#msg", sessionID: session, role: count % 2 == 0 ? "user" : "assistant",
                time: time, text: "message \(count)" + blob, rawRef: record.id)]
        default:
            var attrs: [String: JSONValue] = ["n": .number(Double(count))]
            if !blob.isEmpty { attrs["blob"] = .string(blob) }
            batch.events = [NormalizedEvent(
                dedupKey: "\(key)#0", sessionID: session, kind: .toolCall, providerType: "PreToolUse",
                time: time, toolName: "Tool\(count % 3)", summary: "event \(count)", attrs: attrs,
                rawRef: record.id)]
        }
        return batch
    }
}
