import Foundation

/// A JSON value with a stable Codable form: every number is a Double, so the same
/// value always encodes to the same text (with `.sortedKeys`).
public indirect enum JSONValue: Sendable, Equatable, Codable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

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
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
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
    public var attrs: [String: JSONValue]
    /// The raw archive id this was derived from.
    public var rawRef: Int64

    public init(
        dedupKey: String, sessionID: String, kind: EventKind, providerType: String, time: Date,
        cwd: String? = nil, toolName: String? = nil, summary: String? = nil,
        attrs: [String: JSONValue] = [:], rawRef: Int64
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
    public var attrs: [String: JSONValue]

    public init(
        sessionID: String, asOf: Date, cwd: String? = nil, project: String? = nil,
        account: String? = nil, model: String? = nil, title: String? = nil, status: String? = nil,
        startedAt: Date? = nil, endedAt: Date? = nil, attrs: [String: JSONValue] = [:]
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

public struct TurnRow: Sendable, Equatable {
    public var dedupKey: String
    public var sessionID: String
    public var time: Date
    public var model: String?
    public var account: String?
    public var agent: String?
    public var toolName: String?
    public var inputTokens: Int
    public var outputTokens: Int
    public var cacheReadTokens: Int
    public var cacheWriteTokens: Int
    public var costUSD: Double?
    public var rawRef: Int64

    public init(
        dedupKey: String, sessionID: String, time: Date, model: String? = nil, account: String? = nil,
        agent: String? = nil, toolName: String? = nil, inputTokens: Int = 0, outputTokens: Int = 0,
        cacheReadTokens: Int = 0, cacheWriteTokens: Int = 0, costUSD: Double? = nil, rawRef: Int64
    ) {
        self.dedupKey = dedupKey
        self.sessionID = sessionID
        self.time = time
        self.model = model
        self.account = account
        self.agent = agent
        self.toolName = toolName
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheWriteTokens = cacheWriteTokens
        self.costUSD = costUSD
        self.rawRef = rawRef
    }
}

public struct MessageRow: Sendable, Equatable {
    public var uuid: String
    public var parentUUID: String?
    public var sessionID: String
    public var role: String
    public var time: Date
    public var isSidechain: Bool
    public var text: String
    public var attrs: [String: JSONValue]
    public var rawRef: Int64

    public init(
        uuid: String, parentUUID: String? = nil, sessionID: String, role: String, time: Date,
        isSidechain: Bool = false, text: String, attrs: [String: JSONValue] = [:], rawRef: Int64
    ) {
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

    public mutating func append(_ other: NormalizedBatch) {
        events += other.events
        sessions += other.sessions
        turns += other.turns
        messages += other.messages
    }
}
