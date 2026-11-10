import Foundation

/// A JSON value with a stable Codable form: every number is a Double, so the same
/// value always encodes to the same text (with `.sortedKeys`).
///
/// Named `NormalizedValue`, not `JSONValue`: `AgenticDeveloperHubSDKSync` already exports a
/// top-level `JSONValue`, and `apple-sync` and `apple-database` are lateral
/// foundation tiers, so Database must not import Sync. A second top-level
/// `JSONValue` here made the name ambiguous in every module that imports both
/// (SyncGRDB, Markdown, the app). Same resolution as `ExtensionManifest.JSONValue`
/// (`Core/Extensions/ExtensionManifest.swift`).
public indirect enum NormalizedValue: Sendable, Equatable, Codable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([NormalizedValue])
    case object([String: NormalizedValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([NormalizedValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: NormalizedValue].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    /// False when this value holds NaN or an infinity anywhere. JSON cannot encode
    /// those, so `canonicalString()` throws on them and the store cannot write them;
    /// normalizers must never emit one (conformance check `nonFiniteNumber`).
    public var isFinite: Bool {
        switch self {
        case .null, .bool, .string: return true
        case .number(let value): return value.isFinite
        case .array(let values): return values.allSatisfy(\.isFinite)
        case .object(let values): return values.values.allSatisfy(\.isFinite)
        }
    }

    /// Sorted-keys JSON text; the canonical form used for storage and tie-breaks.
    public func canonicalString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        // Top-level fragments (a bare number or string) are valid for JSONEncoder.
        let data = try encoder.encode(self)
        guard let text = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(self, .init(codingPath: [], debugDescription: "not UTF-8"))
        }
        return text
    }
}

public enum EventKind: String, Sendable, CaseIterable {
    case sessionStart = "session_start"
    case sessionEnd = "session_end"
    case prompt
    case toolCall = "tool_call"
    case toolResult = "tool_result"
    case stop
    case compaction
    case subagentStart = "subagent_start"
    case subagentStop = "subagent_stop"
    case notification
    case permission
    case message
    case other
}

public struct NormalizedEvent: Sendable, Equatable {
    /// Unique per provider; usually "<record key>#<n>".
    public var dedupKey: String
    public var sessionID: String
    public var kind: EventKind
    /// The provider's own name for it, e.g. "PreToolUse".
    public var providerType: String
    public var time: Date
    public var cwd: String?
    public var toolName: String?
    public var summary: String?
    public var attrs: [String: NormalizedValue]
    /// The raw archive id this was derived from.
    public var rawRef: Int64

    public init(
        dedupKey: String, sessionID: String, kind: EventKind, providerType: String, time: Date,
        cwd: String? = nil, toolName: String? = nil, summary: String? = nil,
        attrs: [String: NormalizedValue] = [:], rawRef: Int64
    ) {
        self.dedupKey = dedupKey
        self.sessionID = sessionID
        self.kind = kind
        self.providerType = providerType
        self.time = time
        self.cwd = cwd
        self.toolName = toolName
        self.summary = summary
        self.attrs = attrs
        self.rawRef = rawRef
    }
}

public struct SessionUpsert: Sendable, Equatable {
    public var sessionID: String
    /// The event time this observation comes from.
    public var asOf: Date
    public var cwd: String?
    public var project: String?
    public var account: String?
    public var model: String?
    public var title: String?
    /// "active" or "ended".
    public var status: String?
    public var startedAt: Date?
    public var endedAt: Date?
    public var attrs: [String: NormalizedValue]

    public init(
        sessionID: String, asOf: Date, cwd: String? = nil, project: String? = nil,
        account: String? = nil, model: String? = nil, title: String? = nil, status: String? = nil,
        startedAt: Date? = nil, endedAt: Date? = nil, attrs: [String: NormalizedValue] = [:]
    ) {
        self.sessionID = sessionID
        self.asOf = asOf
        self.cwd = cwd
        self.project = project
        self.account = account
        self.model = model
        self.title = title
        self.status = status
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.attrs = attrs
    }
}

/// One model turn (usage). Several records may carry the same turn (for Claude,
/// every transcript line of one API message shares `message.id`), so turns merge
/// like sessions: each field, and each attrs key, keeps the value with the greatest
/// `as_of`; on an exact tie the lexically larger UTF-8 value wins. The result never
/// depends on the order the records arrive in.
public struct TurnRow: Sendable, Equatable {
    /// Unique per provider; records that describe the same turn emit the same key.
    public var dedupKey: String
    public var sessionID: String
    public var time: Date
    /// When this observation of the turn was made; `time` when nil.
    public var asOf: Date?
    public var model: String?
    public var account: String?
    public var agent: String?
    public var toolName: String?
    public var inputTokens: Int
    public var outputTokens: Int
    public var cacheReadTokens: Int
    public var cacheWriteTokens: Int
    public var costUSD: Double?
    /// Model- and provider-specific fields, e.g. `cache_creation_1h_tokens`, `is_subagent`.
    public var attrs: [String: NormalizedValue]
    public var rawRef: Int64

    public init(
        dedupKey: String, sessionID: String, time: Date, asOf: Date? = nil, model: String? = nil,
        account: String? = nil, agent: String? = nil, toolName: String? = nil, inputTokens: Int = 0,
        outputTokens: Int = 0, cacheReadTokens: Int = 0, cacheWriteTokens: Int = 0, costUSD: Double? = nil,
        attrs: [String: NormalizedValue] = [:], rawRef: Int64
    ) {
        self.dedupKey = dedupKey
        self.sessionID = sessionID
        self.time = time
        self.asOf = asOf
        self.model = model
        self.account = account
        self.agent = agent
        self.toolName = toolName
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheWriteTokens = cacheWriteTokens
        self.costUSD = costUSD
        self.attrs = attrs
        self.rawRef = rawRef
    }
}

/// A conversation message, keyed by `(provider, session_id, uuid)`: a transcript
/// uuid repeats across sessions when a session is resumed or forked, and each copy
/// is its own row. `dedupKey` ties the row to the record it came from.
public struct MessageRow: Sendable, Equatable {
    /// The record's dedup key, or that key plus `#<suffix>`.
    public var dedupKey: String
    public var uuid: String
    public var parentUUID: String?
    public var sessionID: String
    public var role: String
    public var time: Date
    public var isSidechain: Bool
    public var text: String
    public var attrs: [String: NormalizedValue]
    public var rawRef: Int64

    public init(
        dedupKey: String, uuid: String, parentUUID: String? = nil, sessionID: String, role: String, time: Date,
        isSidechain: Bool = false, text: String, attrs: [String: NormalizedValue] = [:], rawRef: Int64
    ) {
        self.dedupKey = dedupKey
        self.uuid = uuid
        self.parentUUID = parentUUID
        self.sessionID = sessionID
        self.role = role
        self.time = time
        self.isSidechain = isSidechain
        self.text = text
        self.attrs = attrs
        self.rawRef = rawRef
    }
}

public struct NormalizedBatch: Sendable, Equatable {
    public var events: [NormalizedEvent] = []
    public var sessions: [SessionUpsert] = []
    public var turns: [TurnRow] = []
    public var messages: [MessageRow] = []

    public init() {}

    public var isEmpty: Bool { events.isEmpty && sessions.isEmpty && turns.isEmpty && messages.isEmpty }

    /// Every place this batch holds NaN or an infinity (an attrs value, a cost or a
    /// date), as `<row key>.<field>`; empty when the batch is storable.
    public var nonFiniteFields: [String] {
        var found: [String] = []
        func attrs(_ owner: String, _ values: [String: NormalizedValue]) {
            for (key, value) in values.sorted(by: { $0.key < $1.key }) where !value.isFinite {
                found.append("\(owner).attrs.\(key)")
            }
        }
        func date(_ owner: String, _ field: String, _ value: Date?) {
            if let value, !value.timeIntervalSince1970.isFinite { found.append("\(owner).\(field)") }
        }
        for event in events {
            attrs(event.dedupKey, event.attrs)
            date(event.dedupKey, "time", event.time)
        }
        for session in sessions {
            attrs(session.sessionID, session.attrs)
            date(session.sessionID, "asOf", session.asOf)
            date(session.sessionID, "startedAt", session.startedAt)
            date(session.sessionID, "endedAt", session.endedAt)
        }
        for turn in turns {
            attrs(turn.dedupKey, turn.attrs)
            date(turn.dedupKey, "time", turn.time)
            date(turn.dedupKey, "asOf", turn.asOf)
            if let cost = turn.costUSD, !cost.isFinite { found.append("\(turn.dedupKey).costUSD") }
        }
        for message in messages {
            attrs(message.dedupKey, message.attrs)
            date(message.dedupKey, "time", message.time)
        }
        return found
    }

    public mutating func append(_ other: NormalizedBatch) {
        events += other.events
        sessions += other.sessions
        turns += other.turns
        messages += other.messages
    }
}
