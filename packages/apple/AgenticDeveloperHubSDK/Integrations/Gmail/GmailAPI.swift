import Foundation

/// The slice of the Gmail REST API the sync engine uses. Small so tests can fake it.
public protocol GmailAPI: Sendable {
    func profile() async throws -> GmailProfile
    func listMessageIds(query: String, includeSpamTrash: Bool, pageToken: String?) async throws -> GmailIdPage
    /// One page of a Gmail search, newest first: messages matching `query` (Gmail's search
    /// syntax) that carry every label in `labelIds`. Spam and Trash only when the query asks.
    func searchMessageIds(
        query: String, labelIds: [String], maxResults: Int, pageToken: String?
    ) async throws -> GmailIdPage
    /// A conversation and every message in it, oldest first (`threads.get`, format full).
    func thread(id: String) async throws -> GmailThreadDTO
    func message(id: String) async throws -> GmailMessageDTO
    func history(startHistoryId: String, pageToken: String?) async throws -> GmailHistoryPage
    func labels() async throws -> [GmailLabelDTO]
    func batchModify(ids: [String], add: [String], remove: [String]) async throws
}

/// The history cursor is older than Gmail keeps (HTTP 404 on `history`); a full sync is needed.
public struct GmailCursorExpired: Error, Equatable, Sendable {
    public init() {}
}

public struct GmailProfile: Decodable, Sendable {
    public let emailAddress: String
    public let historyId: String

    public init(emailAddress: String, historyId: String) {
        self.emailAddress = emailAddress
        self.historyId = historyId
    }
}

public struct GmailIdPage: Sendable {
    public let ids: [String]
    public let nextPageToken: String?

    public init(ids: [String], nextPageToken: String?) {
        self.ids = ids
        self.nextPageToken = nextPageToken
    }
}

public struct GmailThreadDTO: Decodable, Sendable {
    public let id: String
    public let messages: [GmailMessageDTO]

    public init(id: String, messages: [GmailMessageDTO]) {
        self.id = id
        self.messages = messages
    }

    private enum CodingKeys: String, CodingKey { case id, messages }

    /// Gmail leaves `messages` out of a thread with none it will show.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            messages: try container.decodeIfPresent([GmailMessageDTO].self, forKey: .messages) ?? [])
    }
}

public struct GmailHistoryPage: Sendable {
    public let changedIds: [String]
    public let deletedIds: [String]
    public let historyId: String
    public let nextPageToken: String?

    public init(changedIds: [String], deletedIds: [String], historyId: String, nextPageToken: String?) {
        self.changedIds = changedIds
        self.deletedIds = deletedIds
        self.historyId = historyId
        self.nextPageToken = nextPageToken
    }
}

public struct GmailHeader: Decodable, Sendable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

public struct GmailBody: Decodable, Sendable {
    public let attachmentId: String?
    public let size: Int?
    /// base64url.
    public let data: String?

    public init(attachmentId: String? = nil, size: Int? = nil, data: String? = nil) {
        self.attachmentId = attachmentId
        self.size = size
        self.data = data
    }
}

public struct GmailPart: Decodable, Sendable {
    public let partId: String?
    public let mimeType: String?
    public let filename: String?
    public let headers: [GmailHeader]?
    public let body: GmailBody?
    public let parts: [GmailPart]?

    public init(
        partId: String? = nil, mimeType: String? = nil, filename: String? = nil,
        headers: [GmailHeader]? = nil, body: GmailBody? = nil, parts: [GmailPart]? = nil
    ) {
        self.partId = partId
        self.mimeType = mimeType
        self.filename = filename
        self.headers = headers
        self.body = body
        self.parts = parts
    }
}

public struct GmailMessageDTO: Decodable, Sendable {
    public let id: String
    public let threadId: String
    public let labelIds: [String]?
    public let snippet: String?
    public let historyId: String?
    /// Epoch milliseconds, as a string.
    public let internalDate: String?
    public let payload: GmailPart?

    public init(
        id: String, threadId: String, labelIds: [String]? = nil, snippet: String? = nil,
        historyId: String? = nil, internalDate: String? = nil, payload: GmailPart? = nil
    ) {
        self.id = id
        self.threadId = threadId
        self.labelIds = labelIds
        self.snippet = snippet
        self.historyId = historyId
        self.internalDate = internalDate
        self.payload = payload
    }
}

public struct GmailLabelDTO: Decodable, Sendable {
    public let id: String
    public let name: String
    public let type: String
    public let messagesTotal: Int?
    public let messagesUnread: Int?
    public let color: LabelColor?

    public init(
        id: String, name: String, type: String, messagesTotal: Int? = nil,
        messagesUnread: Int? = nil, color: LabelColor? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.messagesTotal = messagesTotal
        self.messagesUnread = messagesUnread
        self.color = color
    }
}

/// Builds the `messages.list` query for a full sync. The query only narrows the fetch;
/// `MailClassifier` stays the authority on what is mirrored.
public enum GmailQuery {
    public static func fullSync(settings: MailSyncSettings, now: Date) -> (query: String, includeSpamTrash: Bool) {
        let after = Int(now.addingTimeInterval(-Double(settings.windowDays) * 86_400).timeIntervalSince1970)
        var query = "after:\(after)"
        if !settings.includeArchived {
            var classes = ["in:inbox", "in:sent", "in:drafts", "is:starred", "has:userlabels"]
            if settings.includeSpam { classes.append("in:spam") }
            if settings.includeTrash { classes.append("in:trash") }
            query += " {\(classes.joined(separator: " "))}"
        }
        return (query, settings.includeSpam || settings.includeTrash)
    }
}
