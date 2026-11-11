import Foundation

/// A request to the mail service. Account arguments take a connection id or an email address.
public enum MailRequest: Codable, Sendable, Equatable {
    case providerStatus
    case importOAuthClient(json: Data)
    case removeProvider
    case listAccounts
    /// Runs the browser flow in the service's process. Refused while another sign-in is pending.
    case signIn
    /// Ends a pending sign-in, which then answers "Sign-in was cancelled". Harmless when none is.
    case cancelSignIn
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

    /// True for the requests that read or label mail in accounts already signed in: everything
    /// `MailCommandLine` and `MailToolSource` send. False for the ones that administer the
    /// integration (the OAuth client, accounts, sign-in, sync settings), which a host keeps for
    /// its own UI. The switch is exhaustive so a new request has to be placed on one side.
    public var isMailboxAccess: Bool {
        switch self {
        case .listAccounts, .listLabels, .listMessages, .getMessage, .modifyLabels:
            return true
        case .providerStatus, .importOAuthClient, .removeProvider, .signIn, .cancelSignIn,
             .removeAccount, .updateSettings, .syncNow:
            return false
        }
    }
}

/// Which messages to list. `since`/`until` are inclusive ISO-8601 strings; labels are ids or
/// names: a message must carry every one of `labels` (AND) and, when `anyLabels` is not empty,
/// at least one of `anyLabels` (OR). `cursor` is the `nextCursor` of the previous page.
public struct MailMessageFilter: Codable, Sendable, Equatable {
    public static let limitRange = 1...500
    public static let defaultLimit = 50

    public var account: String
    public var since: String?
    public var until: String?
    public var labels: [String]
    public var anyLabels: [String]
    public var limit: Int {
        didSet { limit = Self.clamp(limit) }
    }
    public var cursor: String?
    public var includeBodies: Bool

    public init(
        account: String, since: String? = nil, until: String? = nil, labels: [String] = [],
        anyLabels: [String] = [], limit: Int = MailMessageFilter.defaultLimit, cursor: String? = nil,
        includeBodies: Bool = false
    ) {
        self.account = account
        self.since = since
        self.until = until
        self.labels = labels
        self.anyLabels = anyLabels
        self.limit = Self.clamp(limit)
        self.cursor = cursor
        self.includeBodies = includeBodies
    }

    private enum CodingKeys: String, CodingKey {
        case account, since, until, labels, anyLabels, limit, cursor, includeBodies
    }

    /// Lenient: only `account` is required; the rest take their defaults.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            account: try container.decode(String.self, forKey: .account),
            since: try container.decodeIfPresent(String.self, forKey: .since),
            until: try container.decodeIfPresent(String.self, forKey: .until),
            labels: try container.decodeIfPresent([String].self, forKey: .labels) ?? [],
            anyLabels: try container.decodeIfPresent([String].self, forKey: .anyLabels) ?? [],
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
    /// The imported OAuth client id. A desktop client id is not secret; it appears in every
    /// sign-in URL.
    public var clientId: String?
    /// The last `secretSuffixLength` characters of the client secret, so the user can tell
    /// which secret is stored. Nil when the secret is too short to show part of it safely.
    /// The whole secret never leaves the daemon.
    public var clientSecretSuffix: String?

    public static let secretSuffixLength = 5

    public init(configured: Bool, clientId: String?, clientSecretSuffix: String? = nil) {
        self.configured = configured
        self.clientId = clientId
        self.clientSecretSuffix = clientSecretSuffix
    }

    /// The part of `secret` that may be shown: its last `secretSuffixLength` characters, and
    /// only when at least twice that many characters stay hidden.
    public static func visibleSuffix(ofSecret secret: String) -> String? {
        guard secret.count >= secretSuffixLength * 3 else { return nil }
        return String(secret.suffix(secretSuffixLength))
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
    /// Gmail's preview text, with the HTML entities Gmail leaves in it decoded.
    public var snippet: String
    public var date: String
    public var mailClass: MailClass
    /// With bodies only: the `text/plain` part, or for a message without one, its HTML read as
    /// text (`MailHTMLText`).
    public var bodyText: String?
    /// With bodies only: the `text/html` part, as sent.
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
    /// A message id matched nothing. Its own case so a caller can tell it from other failures.
    case notFound(String)
}

/// A `.failure` reply from the service, or a reply of the wrong shape; `.notFound` for a
/// `.notFound` reply.
public enum MailClientError: Error, Equatable, LocalizedError {
    case remote(String)
    case notFound(String)

    public var errorDescription: String? {
        switch self {
        case .remote(let message), .notFound(let message): return message
        }
    }
}

/// Talks to a `MailIntegrationService` over any byte transport (XPC, a socket, or in-process).
public struct MailClient: Sendable {
    private let transport: @Sendable (Data) async throws -> Data

    public init(transport: @escaping @Sendable (Data) async throws -> Data) {
        self.transport = transport
    }

    /// `.failure(message)` throws `MailClientError.remote(message)`; `.notFound(message)` throws
    /// `MailClientError.notFound(message)`.
    public func send(_ request: MailRequest) async throws -> MailResponse {
        let reply = try await transport(try JSONEncoder().encode(request))
        let response = try JSONDecoder().decode(MailResponse.self, from: reply)
        if case .failure(let message) = response { throw MailClientError.remote(message) }
        if case .notFound(let message) = response { throw MailClientError.notFound(message) }
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
