import Foundation

/// One message of a single session's conversation, oldest-first, as
/// `steno conversation fetch` hands it to a reader that follows along.
///
/// The per-session, cursor-paged twin of ``ConversationEntryDTO``: the feed
/// entry carries the attribution a merged, many-session timeline needs on every
/// row; a message belongs to one session, so it carries only what the message
/// itself says.
public struct ConversationMessageDTO: Codable, Sendable, Equatable {
    /// The same identity as ``ConversationEntryDTO/id`` — the transcript line's
    /// id times the block stride plus the block's index — so a message and its
    /// feed entry are the same row. It is a cursor, not a count: ids grow within
    /// one transcript entry but are not ordered across a resumed session's files.
    public let id: Int
    /// Who is talking: `user` (the human typed it), `model` (the agent said it),
    /// or `notice` (an interruption or other transcript event).
    public let type: String
    /// The extractor's finer kind — `prompt`, `reply`, `progress`, `thinking`,
    /// `notice` — for a reader that wants to tell a reply from work narration.
    public let kind: String
    public let content: String
    /// ISO-8601, as written in the transcript.
    public let time: String
    /// The subagent that said it, when it comes from one of the session's
    /// subagents' transcripts (read only with work output); nil for the
    /// session's own agent. Optional so a reader built before it still decodes.
    public let agentId: String?

    public init(id: Int, type: String, kind: String, content: String, time: String, agentId: String? = nil) {
        self.id = id
        self.type = type
        self.kind = kind
        self.content = content
        self.time = time
        self.agentId = agentId
    }

    /// A feed entry as a message: the one place the extractor's kinds fold into
    /// the user / model / notice split.
    public init(entry: ConversationEntryDTO) {
        self.init(
            id: entry.id, type: Self.type(forKind: entry.kind), kind: entry.kind,
            content: entry.text, time: entry.timestamp)
    }

    public static func type(forKind kind: String) -> String {
        switch kind {
        case "prompt": "user"
        case "notice": "notice"
        default: "model"
        }
    }
}

/// One page of ``ConversationMessageDTO``s, oldest first.
///
/// Paged by message id, not by time: the reader holds the last id it fetched
/// and asks for what comes after it, which is exact even where two transcript
/// entries share a timestamp.
public struct ConversationMessagesPageDTO: Codable, Sendable, Equatable {
    public let sessionId: String
    public let messages: [ConversationMessageDTO]
    /// The id to ask after for the next page: the last message's, or the
    /// cursor the page was asked with when it is empty. Nil when neither exists.
    public let nextAfterId: Int?
    /// True when the page reached the end of the range — the conversation's
    /// newest message, or the `through` id asked for.
    public let isComplete: Bool

    public init(sessionId: String, messages: [ConversationMessageDTO], nextAfterId: Int?, isComplete: Bool) {
        self.sessionId = sessionId
        self.messages = messages
        self.nextAfterId = nextAfterId
        self.isComplete = isComplete
    }
}

/// What a reader asks for: one session's messages after `afterId` (exclusive)
/// through `throughId` (inclusive), at most `limit` of them. Nil cursors open the
/// range at the conversation's first or newest message.
public struct ConversationMessagesQueryDTO: Codable, Sendable, Equatable {
    public let sessionId: String
    public let afterId: Int?
    public let throughId: Int?
    public let limit: Int
    public let includeWorkOutput: Bool

    public init(sessionId: String, afterId: Int?, throughId: Int?, limit: Int, includeWorkOutput: Bool) {
        self.sessionId = sessionId
        self.afterId = afterId
        self.throughId = throughId
        self.limit = limit
        self.includeWorkOutput = includeWorkOutput
    }
}

/// Why a message range could not be read.
public enum ConversationRangeError: Error, LocalizedError, Equatable {
    /// A cursor id that names no message of the session.
    case unknownMessageId(Int)
    /// The event store holding the messages is not open (the Claude pipeline
    /// is unavailable and retrying), so nothing can be said about the range.
    case eventStoreUnavailable

    public var errorDescription: String? {
        switch self {
        case .unknownMessageId(let id): "No message \(id) in this conversation."
        case .eventStoreUnavailable: "Conversation messages are unavailable until the Claude pipeline opens."
        }
    }
}
