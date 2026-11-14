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
    /// The whole conversation, read from Gmail, oldest message first. `id` is a Gmail thread id,
    /// or a message id (ours or Gmail's) that stands for the thread it is in.
    case getThread(account: String, id: String, includeBodies: Bool)
    /// Messages by our id or Gmail's; labels by Gmail label id or exact name.
    case modifyLabels(account: String, messageIds: [String], add: [String], remove: [String])
    /// Adds `destination` and removes every label in `from`. A `nil` `from` means INBOX, or
    /// nothing when `destination` is INBOX; an empty one removes nothing. Ids and labels as for
    /// `modifyLabels`.
    case moveMessages(account: String, messageIds: [String], destination: String, from: [String]?)

    /// True for the requests that read or label mail in accounts already signed in: everything
    /// `MailCommandLine` and `MailToolSource` send. False for the ones that administer the
    /// integration (the OAuth client, accounts, sign-in, sync settings), which a host keeps for
    /// its own UI. The switch is exhaustive so a new request has to be placed on one side.
    public var isMailboxAccess: Bool {
        switch self {
        case .listAccounts, .listLabels, .listMessages, .getMessage, .getThread, .modifyLabels, .moveMessages:
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
///
/// With a `query`, the messages come from a Gmail search instead of the synced copy, so they
/// reach past the sync window and the synced classes. The query is Gmail's search syntax
/// (`from:greenhouse`); `since`, `until` and `labels` narrow it, and `anyLabels` is refused (write
/// `{label:a label:b}` in the query instead).
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
    public var query: String?

    public init(
        account: String, since: String? = nil, until: String? = nil, labels: [String] = [],
        anyLabels: [String] = [], limit: Int = MailMessageFilter.defaultLimit, cursor: String? = nil,
        includeBodies: Bool = false, query: String? = nil
    ) {
        self.account = account
        self.since = since
        self.until = until
        self.labels = labels
        self.anyLabels = anyLabels
        self.limit = Self.clamp(limit)
        self.cursor = cursor
        self.includeBodies = includeBodies
        self.query = query
    }

    private enum CodingKeys: String, CodingKey {
        case account, since, until, labels, anyLabels, limit, cursor, includeBodies, query
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
            includeBodies: try container.decodeIfPresent(Bool.self, forKey: .includeBodies) ?? false,
            query: try container.decodeIfPresent(String.self, forKey: .query))
    }

    /// The query with its surrounding whitespace trimmed; `nil` when there is none to run.
    public var searchQuery: String? {
        guard let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
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
    /// text (`HTMLText`).
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
    /// Opaque; pass it back as the filter's `cursor` for the next page. `nil` on the last page.
    public var nextCursor: String?
    /// True when the service applied the filter's `anyLabels`. A service built before that
    /// field decodes the filter without it and lists everything, and its reply leaves this out
    /// (so it decodes as false), which lets `MailClient.messages` refuse the page.
    public var appliedAnyLabels: Bool
    /// True when the page is the result of the filter's `query`, searched in Gmail. A service
    /// built before queries ignores one and lists the synced copy; this then decodes as false
    /// and `MailClient.messages` refuses the page.
    public var appliedQuery: Bool

    public init(
        messages: [MailMessage], nextCursor: String?, appliedAnyLabels: Bool = false, appliedQuery: Bool = false
    ) {
        self.messages = messages
        self.nextCursor = nextCursor
        self.appliedAnyLabels = appliedAnyLabels
        self.appliedQuery = appliedQuery
    }

    private enum CodingKeys: String, CodingKey {
        case messages, nextCursor, appliedAnyLabels, appliedQuery
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            messages: try container.decode([MailMessage].self, forKey: .messages),
            nextCursor: try container.decodeIfPresent(String.self, forKey: .nextCursor),
            appliedAnyLabels: try container.decodeIfPresent(Bool.self, forKey: .appliedAnyLabels) ?? false,
            appliedQuery: try container.decodeIfPresent(Bool.self, forKey: .appliedQuery) ?? false)
    }
}

/// A conversation as Gmail holds it now, oldest message first. A message carrying `SENT` is one
/// the account wrote.
public struct MailThread: Codable, Sendable, Equatable {
    /// Gmail's thread id.
    public var id: String
    public var messages: [MailMessage]

    public init(id: String, messages: [MailMessage]) {
        self.id = id
        self.messages = messages
    }
}

/// One message a move touched: its refreshed copy and the names of the labels it gained and
/// lost, measured against Gmail just before the write. `added` is empty when the message
/// already carried the destination.
public struct MailMoveResult: Codable, Sendable, Equatable {
    public var message: MailMessage
    public var added: [String]
    public var removed: [String]

    public init(message: MailMessage, added: [String], removed: [String]) {
        self.message = message
        self.added = added
        self.removed = removed
    }
}

public enum MailResponse: Codable, Sendable, Equatable {
    case providerStatus(MailProviderStatus)
    case accounts([MailAccount])
    case account(MailAccount)
    case labels([MailLabel])
    case messages(MailMessagePage)
    case message(MailMessage)
    case thread(MailThread)
    case moved([MailMoveResult])
    // swiftlint:disable:next identifier_name
    case ok
    /// `notFound` is true when a message id matched nothing, so a caller can tell that from
    /// other failures. It rides inside `.failure`, not in a case of its own, so a client built
    /// before it still decodes the reply and shows the message.
    case failure(String, notFound: Bool? = nil)

    /// A message id matched nothing.
    public static func notFound(_ message: String) -> MailResponse { .failure(message, notFound: true) }
}

/// A `.failure` reply from the service, or a reply of the wrong shape; `.notFound` for a
/// failure that says a message id matched nothing.
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

    /// `.failure(message)` throws `MailClientError.remote(message)`, or
    /// `MailClientError.notFound(message)` when the failure says a message id matched nothing.
    public func send(_ request: MailRequest) async throws -> MailResponse {
        let reply = try await transport(try JSONEncoder().encode(request))
        let response = try JSONDecoder().decode(MailResponse.self, from: reply)
        if case .failure(let message, let notFound) = response {
            throw notFound == true ? MailClientError.notFound(message) : MailClientError.remote(message)
        }
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

    /// Throws rather than return a page the service didn't filter by `anyLabels` or `query`.
    public func messages(_ filter: MailMessageFilter) async throws -> MailMessagePage {
        guard case .messages(let page) = try await send(.listMessages(filter)) else { throw Self.unexpected }
        if filter.searchQuery != nil && !page.appliedQuery { throw Self.queryIgnored }
        if !filter.anyLabels.isEmpty && !page.appliedAnyLabels { throw Self.anyLabelsIgnored }
        return page
    }

    /// A service built before threads can't decode the request and answers "bad request"; that
    /// is reported as a service too old to show threads.
    public func thread(account: String, id: String, includeBodies: Bool = false) async throws -> MailThread {
        let response: MailResponse
        do {
            response = try await send(.getThread(account: account, id: id, includeBodies: includeBodies))
        } catch MailClientError.remote(Self.badRequest) {
            throw Self.threadsUnsupported
        }
        guard case .thread(let thread) = response else { throw Self.unexpected }
        return thread
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

    public func moveMessages(
        account: String, messageIds: [String], destination: String, from: [String]? = nil
    ) async throws -> [MailMoveResult] {
        let request = MailRequest.moveMessages(
            account: account, messageIds: messageIds, destination: destination, from: from)
        guard case .moved(let results) = try await send(request) else { throw Self.unexpected }
        return results
    }

    private static let unexpected = MailClientError.remote("unexpected response from the mail service")
    static let anyLabelsIgnored = MailClientError.remote(
        "The mail service is too old to filter by any of several labels; restart it and try again.")
    static let queryIgnored = MailClientError.remote(
        "The mail service is too old to search Gmail; restart it and try again.")
    static let threadsUnsupported = MailClientError.remote(
        "The mail service is too old to show threads; restart it and try again.")
    /// What `MailIntegrationService` answers to a request it can't decode.
    static let badRequest = "bad request"
}

/// Where mail is read from: the Gmail integration this app runs itself, or
/// the copy the Agentic Developer Hub mirrors for the signed-in user.
public enum MailSource: String, Codable, Sendable, CaseIterable {
    case direct
    case hub
}

extension MailClient {
    /// A client that asks `pick` which client to use for each request, so a
    /// setting can switch the source while windows keep the client they were
    /// given. The request's bytes pass through untouched, so a failure keeps
    /// its `notFound` flag.
    public static func routed(_ pick: @escaping @Sendable () async -> MailClient) -> MailClient {
        MailClient { data in
            try await pick().transport(data)
        }
    }
}
