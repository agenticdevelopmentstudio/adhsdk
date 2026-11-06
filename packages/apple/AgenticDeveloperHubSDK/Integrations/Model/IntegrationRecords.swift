import Foundation
import GRDB

/// ISO-8601 UTC timestamps with fractional seconds, the format every integration column uses.
public enum IntegrationClock {
    public static func now() -> String {
        Date().formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }
}

public enum ConnectionStatus: String, Codable, Sendable { case active, error, revoked, pending }

/// Gmail's label color shape.
public struct LabelColor: Codable, Sendable, Equatable {
    public var textColor: String?
    public var backgroundColor: String?

    public init(textColor: String? = nil, backgroundColor: String? = nil) {
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }
}

public struct EmailAttachmentRef: Codable, Sendable, Equatable {
    public var attachmentId: String
    public var filename: String
    public var mimeType: String
    public var size: Int

    public init(attachmentId: String, filename: String, mimeType: String, size: Int) {
        self.attachmentId = attachmentId
        self.filename = filename
        self.mimeType = mimeType
        self.size = size
    }
}

/// Shared persistence rules: snake_case columns. GRDB stores a Codable property that is not a
/// plain column value (`[String]`, `MailSyncSettings`, `[EmailAttachmentRef]`, `LabelColor`)
/// as JSON TEXT, so those need no per-record code.
public protocol IntegrationRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Equatable {}

public extension IntegrationRecord {
    static var databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy { .convertFromSnakeCase }
    static var databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy { .convertToSnakeCase }
}

public struct IntegrationConnection: IntegrationRecord {
    public static let databaseTableName = "integration_connections"

    public var id: String
    public var provider: String
    public var serviceType: String
    public var externalAccountId: String
    public var displayName: String
    public var status: ConnectionStatus
    public var lastSyncAt: String?
    public var lastError: String?
    public var syncCursor: String?
    public var syncSettings: MailSyncSettings
    public var scopes: String
    public var createdAt: String
    public var updatedAt: String
    public var deletedAt: String?

    public init(
        id: String, provider: String = "gmail", serviceType: String = "messages",
        externalAccountId: String, displayName: String, status: ConnectionStatus = .pending,
        lastSyncAt: String? = nil, lastError: String? = nil, syncCursor: String? = nil,
        syncSettings: MailSyncSettings = .default, scopes: String,
        createdAt: String = IntegrationClock.now(), updatedAt: String = IntegrationClock.now(),
        deletedAt: String? = nil
    ) {
        self.id = id
        self.provider = provider
        self.serviceType = serviceType
        self.externalAccountId = externalAccountId
        self.displayName = displayName
        self.status = status
        self.lastSyncAt = lastSyncAt
        self.lastError = lastError
        self.syncCursor = syncCursor
        self.syncSettings = syncSettings
        self.scopes = scopes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

public struct ProviderConfig: IntegrationRecord {
    public static let databaseTableName = "integration_provider_configs"

    public var id: String
    public var providerId: String
    public var name: String
    public var clientId: String
    public var enabled: Bool
    public var createdAt: String
    public var updatedAt: String
    public var deletedAt: String?

    public init(
        id: String, providerId: String = "gmail", name: String, clientId: String, enabled: Bool = true,
        createdAt: String = IntegrationClock.now(), updatedAt: String = IntegrationClock.now(),
        deletedAt: String? = nil
    ) {
        self.id = id
        self.providerId = providerId
        self.name = name
        self.clientId = clientId
        self.enabled = enabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

public struct EmailMessage: IntegrationRecord {
    public static let databaseTableName = "integration_email_messages"

    public var id: String
    public var connectionId: String
    public var provider: String
    public var externalId: String
    public var threadId: String
    public var fromAddress: String
    public var toAddresses: [String]
    public var ccAddresses: [String]
    public var subject: String
    public var snippet: String
    public var bodyText: String?
    public var bodyHtml: String?
    public var labelIds: [String]
    public var internalDate: String
    public var historyId: String?
    public var attachments: [EmailAttachmentRef]
    /// Cached so queries and tombstoning need not re-derive it from `labelIds`.
    public var mailClass: MailClass
    public var isDeleted: Bool
    public var createdAt: String
    public var updatedAt: String
    public var deletedAt: String?

    public init(
        id: String, connectionId: String, provider: String = "gmail", externalId: String, threadId: String,
        fromAddress: String, toAddresses: [String] = [], ccAddresses: [String] = [],
        subject: String, snippet: String, bodyText: String? = nil, bodyHtml: String? = nil,
        labelIds: [String] = [], internalDate: String, historyId: String? = nil,
        attachments: [EmailAttachmentRef] = [], mailClass: MailClass? = nil, isDeleted: Bool = false,
        createdAt: String = IntegrationClock.now(), updatedAt: String = IntegrationClock.now(),
        deletedAt: String? = nil
    ) {
        self.id = id
        self.connectionId = connectionId
        self.provider = provider
        self.externalId = externalId
        self.threadId = threadId
        self.fromAddress = fromAddress
        self.toAddresses = toAddresses
        self.ccAddresses = ccAddresses
        self.subject = subject
        self.snippet = snippet
        self.bodyText = bodyText
        self.bodyHtml = bodyHtml
        self.labelIds = labelIds
        self.internalDate = internalDate
        self.historyId = historyId
        self.attachments = attachments
        self.mailClass = mailClass ?? MailClassifier.classify(labelIds: labelIds)
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

public struct EmailLabel: IntegrationRecord {
    public static let databaseTableName = "integration_email_labels"

    public var id: String
    public var connectionId: String
    public var externalId: String
    public var sourceProvider: String
    public var name: String
    public var parentName: String?
    /// "system" or "user".
    public var type: String
    public var color: LabelColor?
    public var messagesTotal: Int?
    public var messagesUnread: Int?
    public var isDeleted: Bool
    public var createdAt: String
    public var updatedAt: String
    public var deletedAt: String?

    public init(
        id: String, connectionId: String, externalId: String, sourceProvider: String = "gmail",
        name: String, parentName: String? = nil, type: String = "user", color: LabelColor? = nil,
        messagesTotal: Int? = nil, messagesUnread: Int? = nil, isDeleted: Bool = false,
        createdAt: String = IntegrationClock.now(), updatedAt: String = IntegrationClock.now(),
        deletedAt: String? = nil
    ) {
        self.id = id
        self.connectionId = connectionId
        self.externalId = externalId
        self.sourceProvider = sourceProvider
        self.name = name
        self.parentName = parentName
        self.type = type
        self.color = color
        self.messagesTotal = messagesTotal
        self.messagesUnread = messagesUnread
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

public struct ActionLog: IntegrationRecord {
    public static let databaseTableName = "integration_action_logs"

    public var id: String
    public var connectionId: String
    public var provider: String
    public var actionType: String
    public var idempotencyKey: String?
    /// JSON text.
    public var requestPayload: String
    /// "pending", "ok" or "error".
    public var status: String
    public var result: String?
    public var error: String?
    public var createdAt: String
    public var updatedAt: String

    public init(
        id: String, connectionId: String, provider: String = "gmail", actionType: String,
        idempotencyKey: String? = nil, requestPayload: String, status: String = "pending",
        result: String? = nil, error: String? = nil,
        createdAt: String = IntegrationClock.now(), updatedAt: String = IntegrationClock.now()
    ) {
        self.id = id
        self.connectionId = connectionId
        self.provider = provider
        self.actionType = actionType
        self.idempotencyKey = idempotencyKey
        self.requestPayload = requestPayload
        self.status = status
        self.result = result
        self.error = error
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
