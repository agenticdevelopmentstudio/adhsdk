// The mail vocabulary's own names (to, cc, ok) are shorter than the
// identifier_name minimum; renaming them would read worse than the rule.
// swiftlint:disable identifier_name
import Foundation

/// The two hub resources Hub Mail mirrors.
public enum HubMailResource {
    public static let messages = "integration.integration_email_messages"
    public static let labels = "integration.integration_email_labels"
    public static let all: Set<String> = [messages, labels]
}

/// One mail message as the hub's Gmail worker stored it.
public struct HubEmailMessage: Sendable, Equatable, Identifiable {
    public let id: String
    public let connectionId: String
    public let provider: String
    public let externalId: String
    public let threadId: String?
    public let from: String?
    public let to: [String]
    public let cc: [String]
    public let subject: String?
    public let snippet: String?
    public let bodyText: String?
    public let bodyHtml: String?
    public let labelIds: [String]
    /// The hub's `internal_date`, as the ISO-8601 text it arrived in.
    public let internalDate: String?
    /// The `attachments` column as JSON text (attachment metadata).
    public let attachmentsJSON: String?

    public init(
        id: String, connectionId: String, provider: String, externalId: String,
        threadId: String? = nil, from: String? = nil, to: [String] = [], cc: [String] = [],
        subject: String? = nil, snippet: String? = nil, bodyText: String? = nil,
        bodyHtml: String? = nil, labelIds: [String] = [], internalDate: String? = nil,
        attachmentsJSON: String? = nil
    ) {
        self.id = id
        self.connectionId = connectionId
        self.provider = provider
        self.externalId = externalId
        self.threadId = threadId
        self.from = from
        self.to = to
        self.cc = cc
        self.subject = subject
        self.snippet = snippet
        self.bodyText = bodyText
        self.bodyHtml = bodyHtml
        self.labelIds = labelIds
        self.internalDate = internalDate
        self.attachmentsJSON = attachmentsJSON
    }
}

/// One mail label (Gmail's folders and tags).
public struct HubEmailLabel: Sendable, Equatable, Identifiable {
    public let id: String
    public let connectionId: String
    /// The provider's label id (`INBOX`, `Label_12`), which messages' `labelIds` name.
    public let externalId: String
    public let provider: String
    public let name: String
    public let parentName: String?
    /// `system` or `user`.
    public let type: String
    public let messagesTotal: Int?
    public let messagesUnread: Int?

    public var isSystem: Bool { type == "system" }

    public init(
        id: String, connectionId: String, externalId: String, provider: String, name: String,
        parentName: String? = nil, type: String, messagesTotal: Int? = nil, messagesUnread: Int? = nil
    ) {
        self.id = id
        self.connectionId = connectionId
        self.externalId = externalId
        self.provider = provider
        self.name = name
        self.parentName = parentName
        self.type = type
        self.messagesTotal = messagesTotal
        self.messagesUnread = messagesUnread
    }
}

/// Where the next page of messages starts: just after this message.
public struct HubMailPageCursor: Sendable, Equatable, Hashable {
    public let internalDate: String?
    public let id: String

    public init(internalDate: String?, id: String) {
        self.internalDate = internalDate
        self.id = id
    }
}

/// A page of messages, newest first, and where the next one starts.
public struct HubEmailMessagePage: Sendable, Equatable {
    public let messages: [HubEmailMessage]
    /// Non-nil exactly when more messages follow.
    public let next: HubMailPageCursor?

    public init(messages: [HubEmailMessage], next: HubMailPageCursor?) {
        self.messages = messages
        self.next = next
    }
}
// swiftlint:enable identifier_name
