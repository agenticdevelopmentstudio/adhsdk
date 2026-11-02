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
    /// `{"op":"event"|"session"|"turn"|"usage"|"message"|"bad", "session":…, "t":<epoch>, "n":<int>,`
    /// `"pad":<int>, "blob":<pad bytes>[, "turn":<turn key>][, "uuid":<message uuid>]}`
    /// - `turn` and `usage` emit a turn keyed `turn` (default `<key>#turn`); several records naming
    ///   one turn key update that turn, merged per field by `as_of` (= `t`).
    /// - `message` emits a message with `uuid` (default `uuid-<key>`) and dedup key `<key>#msg`.
    public static func record(key: String, op operation: String, session: String = "s1", t epoch: Double,
                              n number: Int = 0, pad: Int = 0, turn: String? = nil,
                              uuid: String? = nil) -> RawRecord {
        RawRecord(provider: "mock", sourceKind: "hook", dedupKey: key,
                  receivedAt: Date(timeIntervalSince1970: epoch),
                  payload: payload(op: operation, session: session, t: epoch, n: number, pad: pad,
                                   turn: turn, uuid: uuid))
    }

    /// The payload bytes `record` would carry; one JSON object, no trailing newline.
    public static func payload(op operation: String, session: String = "s1", t epoch: Double, n number: Int = 0,
                               pad: Int = 0, turn: String? = nil, uuid: String? = nil) -> Data {
        var object: [String: Any] = [
            "op": operation, "session": session, "t": epoch, "n": number, "pad": pad,
            "blob": String(repeating: "x", count: max(0, pad))
        ]
        if let turn { object["turn"] = turn }
        if let uuid { object["uuid"] = uuid }
        // Sorted keys so the same arguments always give the same bytes.
        return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
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
                dedupKey: object["turn"] as? String ?? "\(key)#turn", sessionID: session, time: time,
                asOf: time, model: "m-\(count % 3)", inputTokens: count, outputTokens: count * 2,
                cacheReadTokens: count % 5, cacheWriteTokens: count % 3, costUSD: Double(count) / 100,
                attrs: ["kind": .string("turn"), "n\(count % 2)": .number(Double(count))], rawRef: record.id)]
        case "usage":
            // A later (or earlier) observation of a turn: different tokens and attrs, same key.
            batch.turns = [TurnRow(
                dedupKey: object["turn"] as? String ?? "\(key)#turn", sessionID: session, time: time,
                asOf: time, model: "m-\(count % 3)", account: "acct-\(count % 2)",
                inputTokens: count * 3, outputTokens: count, cacheReadTokens: count % 7,
                cacheWriteTokens: count % 2, costUSD: Double(count) / 50,
                attrs: ["kind": .string("usage"), "cache_creation_1h_tokens": .number(Double(count % 11))],
                rawRef: record.id)]
        case "message":
            batch.messages = [MessageRow(
                dedupKey: "\(key)#msg", uuid: object["uuid"] as? String ?? "uuid-\(key)", sessionID: session,
                role: count % 2 == 0 ? "user" : "assistant", time: time, text: "message \(count)" + blob,
                rawRef: record.id)]
        default:
            var attrs: [String: NormalizedValue] = ["n": .number(Double(count))]
            if !blob.isEmpty { attrs["blob"] = .string(blob) }
            batch.events = [NormalizedEvent(
                dedupKey: "\(key)#0", sessionID: session, kind: .toolCall, providerType: "PreToolUse",
                time: time, toolName: "Tool\(count % 3)", summary: "event \(count)", attrs: attrs,
                rawRef: record.id)]
        }
        return batch
    }
}
