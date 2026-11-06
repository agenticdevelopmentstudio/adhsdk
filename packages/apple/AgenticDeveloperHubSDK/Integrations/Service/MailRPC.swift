import Foundation

/// A request to the mail service. Account arguments take a connection id or an email address.
public enum MailRequest: Codable, Sendable, Equatable {
    case providerStatus
    case importOAuthClient(json: Data)
    case removeProvider
    case listAccounts
    /// Runs the browser flow in the service's process.
    case signIn
    case removeAccount(account: String)
    case updateSettings(account: String, settings: MailSyncSettings)
    /// `nil` syncs every account.
    case syncNow(account: String?)
    case listLabels(account: String)
    case listMessages(MailMessageFilter)
    /// `id` is our id or Gmail's.
    case getMessage(account: String, id: String)
    /// Messages by our id or Gmail's; labels by Gmail label id or exact name.
    case modifyLabels(account: String, messageIds: [String], add: [String], remove: [String])
}

/// Which messages to list. `since`/`until` are inclusive ISO-8601 strings; `labels` (ids or
/// names) must all be present; `cursor` is the `nextCursor` of the previous page.
public struct MailMessageFilter: Codable, Sendable, Equatable {
    public static let limitRange = 1...500
    public static let defaultLimit = 50

    public var account: String
    public var since: String?
    public var until: String?
    public var labels: [String]
    public var limit: Int {
        didSet { limit = Self.clamp(limit) }
    }
    public var cursor: String?
    public var includeBodies: Bool

    public init(
        account: String, since: String? = nil, until: String? = nil, labels: [String] = [],
        limit: Int = MailMessageFilter.defaultLimit, cursor: String? = nil, includeBodies: Bool = false
    ) {
        self.account = account
        self.since = since
        self.until = until
        self.labels = labels
        self.limit = Self.clamp(limit)
        self.cursor = cursor
        self.includeBodies = includeBodies
    }

    private enum CodingKeys: String, CodingKey {
        case account, since, until, labels, limit, cursor, includeBodies
    }

    /// Lenient: only `account` is required; the rest take their defaults.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            account: try container.decode(String.self, forKey: .account),
            since: try container.decodeIfPresent(String.self, forKey: .since),
            until: try container.decodeIfPresent(String.self, forKey: .until),
            labels: try container.decodeIfPresent([String].self, forKey: .labels) ?? [],
            limit: try container.decodeIfPresent(Int.self, forKey: .limit) ?? Self.defaultLimit,
            cursor: try container.decodeIfPresent(String.self, forKey: .cursor),
            includeBodies: try container.decodeIfPresent(Bool.self, forKey: .includeBodies) ?? false)
    }

    static func clamp(_ limit: Int) -> Int {
        min(max(limit, limitRange.lowerBound), limitRange.upperBound)
    }
}

public struct MailAccount: Codable, Sendable, Equatable {
    public var id: String
    public var email: String
    public var status: ConnectionStatus
    public var lastSyncAt: String?
    public var lastError: String?
    public var settings: MailSyncSettings

    public init(
        id: String, email: String, status: ConnectionStatus, lastSyncAt: String?, lastError: String?,
        settings: MailSyncSettings
    ) {
        self.id = id
        self.email = email
        self.status = status
        self.lastSyncAt = lastSyncAt
        self.lastError = lastError
        self.settings = settings
    }
}

public struct MailProviderStatus: Codable, Sendable, Equatable {
    public var configured: Bool
    /// The last 12 characters of the OAuth client id.
    public var clientIdHint: String?

    public init(configured: Bool, clientIdHint: String?) {
        self.configured = configured
        self.clientIdHint = clientIdHint
    }
}

public struct MailLabel: Codable, Sendable, Equatable {
    /// Gmail's label id.
    public var id: String
    public var name: String
    /// "system" or "user".
    public var type: String
    public var parentName: String?
    public var messagesTotal: Int?
    public var messagesUnread: Int?

    public init(
        id: String, name: String, type: String, parentName: String?, messagesTotal: Int?, messagesUnread: Int?
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.parentName = parentName
        self.messagesTotal = messagesTotal
        self.messagesUnread = messagesUnread
    }
}

public struct MailMessage: Codable, Sendable, Equatable {
    /// Our id.
    public var id: String
    public var gmailId: String
    public var threadId: String
    /// The account's email address.
    public var account: String
    public var from: String
    // swiftlint:disable identifier_name
    // `to`/`cc` are the wire names the RPC contract fixes.
    public var to: [String]
    public var cc: [String]
    // swiftlint:enable identifier_name
    /// Gmail label ids.
    public var labels: [String]
    /// `labels` mapped to names, falling back to the id.
    public var labelNames: [String]
    public var subject: String
    public var snippet: String
    public var date: String
    public var mailClass: MailClass
    public var bodyText: String?
    public var bodyHtml: String?
    public var attachments: [EmailAttachmentRef]

    // swiftlint:disable identifier_name
    public init(
        id: String, gmailId: String, threadId: String, account: String, from: String, to: [String],
        cc: [String], labels: [String], labelNames: [String], subject: String, snippet: String,
        date: String, mailClass: MailClass, bodyText: String?, bodyHtml: String?,
        attachments: [EmailAttachmentRef]
    ) {
    // swiftlint:enable identifier_name
        self.id = id
        self.gmailId = gmailId
        self.threadId = threadId
        self.account = account
        self.from = from
        self.to = to
        self.cc = cc
        self.labels = labels
        self.labelNames = labelNames
        self.subject = subject
        self.snippet = snippet
        self.date = date
        self.mailClass = mailClass
        self.bodyText = bodyText
        self.bodyHtml = bodyHtml
        self.attachments = attachments
    }
}

public struct MailMessagePage: Codable, Sendable, Equatable {
    public var messages: [MailMessage]
    /// The next offset as a decimal string; `nil` on the last page.
    public var nextCursor: String?

    public init(messages: [MailMessage], nextCursor: String?) {
        self.messages = messages
        self.nextCursor = nextCursor
    }
}

public enum MailResponse: Codable, Sendable, Equatable {
    case providerStatus(MailProviderStatus)
    case accounts([MailAccount])
    case account(MailAccount)
    case labels([MailLabel])
    case messages(MailMessagePage)
    case message(MailMessage)
    // swiftlint:disable:next identifier_name
    case ok
    case failure(String)
}

/// A `.failure` reply from the service, or a reply of the wrong shape.
public enum MailClientError: Error, Equatable, LocalizedError {
    case remote(String)

    public var errorDescription: String? {
        switch self {
        case .remote(let message): return message
        }
    }
}

/// Talks to a `MailIntegrationService` over any byte transport (XPC, a socket, or in-process).
public struct MailClient: Sendable {
    private let transport: @Sendable (Data) async throws -> Data

    public init(transport: @escaping @Sendable (Data) async throws -> Data) {
        self.transport = transport
    }

    /// `.failure(message)` throws `MailClientError.remote(message)`.
    public func send(_ request: MailRequest) async throws -> MailResponse {
        let reply = try await transport(try JSONEncoder().encode(request))
        let response = try JSONDecoder().decode(MailResponse.self, from: reply)
        if case .failure(let message) = response { throw MailClientError.remote(message) }
        return response
    }

    public func providerStatus() async throws -> MailProviderStatus {
        guard case .providerStatus(let status) = try await send(.providerStatus) else { throw Self.unexpected }
        return status
    }

    public func accounts() async throws -> [MailAccount] {
        guard case .accounts(let accounts) = try await send(.listAccounts) else { throw Self.unexpected }
        return accounts
    }

    public func labels(account: String) async throws -> [MailLabel] {
        guard case .labels(let labels) = try await send(.listLabels(account: account)) else { throw Self.unexpected }
        return labels
    }

    public func messages(_ filter: MailMessageFilter) async throws -> MailMessagePage {
        guard case .messages(let page) = try await send(.listMessages(filter)) else { throw Self.unexpected }
        return page
    }

    public func message(account: String, id: String) async throws -> MailMessage {
        guard case .message(let message) = try await send(.getMessage(account: account, id: id)) else {
            throw Self.unexpected
        }
        return message
    }

    public func modifyLabels(
        account: String, messageIds: [String], add: [String], remove: [String]
    ) async throws -> [MailMessage] {
        let request = MailRequest.modifyLabels(account: account, messageIds: messageIds, add: add, remove: remove)
        guard case .messages(let page) = try await send(request) else { throw Self.unexpected }
        return page.messages
    }

    private static let unexpected = MailClientError.remote("unexpected response from the mail service")
}
