import Foundation
import AgenticDeveloperHubSDKMail
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKHubMail

/// Answers the mail RPC (`MailRequest` → `MailResponse`) from the hub mail
/// mirror, so the mail browser and the Email App read hub-synced mail through
/// the same `MailClient` they use for the direct Gmail path. Label changes go
/// to the hub's `modify_labels` action and are written into the mirror until
/// the next pull brings the hub's copy.
public final class HubMailBridge: Sendable {

    private let store: HubMailStore
    private let writeLabels: @Sendable (HubMailLabelWrite) async throws -> Void
    private let syncNow: @Sendable () async -> Void

    public init(
        store: HubMailStore,
        writeLabels: @escaping @Sendable (HubMailLabelWrite) async throws -> Void,
        syncNow: @escaping @Sendable () async -> Void
    ) {
        self.store = store
        self.writeLabels = writeLabels
        self.syncNow = syncNow
    }

    /// A label writer that posts through `sender` and treats an answer that
    /// is not ok as a failure carrying the hub's reason.
    public static func labelWriter(
        sender: HubMailSender
    ) -> @Sendable (HubMailLabelWrite) async throws -> Void {
        { write in
            let result = try await sender.modifyLabels(write)
            guard result.ok else { throw Failure(result.error ?? "the hub did not change the labels") }
        }
    }

    /// A `MailClient` answered by this bridge, coded as the daemon transport codes.
    public var client: MailClient {
        MailClient { [self] data in
            let request = try JSONDecoder().decode(MailRequest.self, from: data)
            return try JSONEncoder().encode(await respond(to: request))
        }
    }

    // MARK: - Requests

    public func respond(to request: MailRequest) async -> MailResponse {
        do {
            return try await answer(request)
        } catch let failure as Failure {
            return failure.notFound ? .notFound(failure.message) : .failure(failure.message)
        } catch let error as HubMailSendError {
            switch error {
            case .rejected(let status):
                return .failure("the hub refused the label change (status \(status))")
            }
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    private func answer(_ request: MailRequest) async throws -> MailResponse {
        switch request {
        case .providerStatus:
            return .providerStatus(MailProviderStatus(configured: true, clientId: nil))
        case .importOAuthClient, .removeProvider, .signIn, .cancelSignIn, .removeAccount, .updateSettings:
            return .failure("Gmail accounts read through the hub are managed on the hub")
        case .listAccounts:
            return .accounts(try accounts().map(\.account))
        case .syncNow:
            await syncNow()
            return .ok
        case .listLabels(let account):
            return .labels(try store.labels(connectionId: try owner(account).id).map(Self.label))
        case .listMessages(let filter):
            return .messages(try listMessages(filter))
        case .getMessage(let account, let id):
            let owner = try owner(account)
            let message = try message(id, owner: owner)
            return .message(mailMessage(message, owner: owner, names: try names(owner), includeBodies: true))
        case .getThread(let account, let id, let includeBodies):
            return .thread(try thread(owner: try owner(account), id: id, includeBodies: includeBodies))
        case .modifyLabels(let account, let messageIds, let add, let remove):
            let messages = try await modifyLabels(owner: try owner(account), ids: messageIds, add: add, remove: remove)
            return .messages(MailMessagePage(messages: messages, nextCursor: nil))
        case .moveMessages(let account, let messageIds, let destination, let from):
            return .moved(try await moveMessages(
                owner: try owner(account), ids: messageIds, destination: destination, from: from))
        }
    }

    // MARK: - Accounts

    /// One connection, with the address it sends from.
    struct Owner {
        let id: String
        let email: String

        var account: MailAccount {
            MailAccount(id: id, email: email, status: .active, lastSyncAt: nil, lastError: nil, settings: .default)
        }
    }

    private func accounts() throws -> [Owner] {
        try store.connections().map { id in
            let sent = try store.messages(HubMailQuery(connectionId: id, labelIds: ["SENT"], limit: 1))
            let email = sent.messages.first?.from.flatMap(Self.address) ?? id
            return Owner(id: id, email: email)
        }
    }

    private func owner(_ account: String) throws -> Owner {
        let owners = try accounts()
        if let byId = owners.first(where: { $0.id == account }) { return byId }
        if let byEmail = owners.first(where: { $0.email.caseInsensitiveCompare(account) == .orderedSame }) {
            return byEmail
        }
        throw Failure("unknown account: \(account)", notFound: true)
    }

    /// The address in a `from` header: the part inside `<…>` when there is
    /// one, else the whole value, trimmed and lowercased.
    static func address(_ from: String) -> String? {
        var text = Substring(from)
        if let open = text.lastIndex(of: "<"),
           let close = text[open...].firstIndex(of: ">") {
            text = text[text.index(after: open)..<close]
        }
        let address = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return address.isEmpty ? nil : address
    }

    // MARK: - Messages

    private func listMessages(_ filter: MailMessageFilter) throws -> MailMessagePage {
        let owner = try owner(filter.account)
        guard filter.searchQuery == nil else {
            throw Failure("search isn't available for mail read through the hub")
        }
        let cursor = try filter.cursor.map(Self.decodeCursor)
        let labels = try store.labels(connectionId: owner.id)
        let labelIds = try Self.resolve(filter.labels, in: labels)
        let anyLabelIds = try Self.resolve(filter.anyLabels, in: labels)
        let page = try store.messages(HubMailQuery(
            connectionId: owner.id, labelIds: labelIds, anyLabelIds: anyLabelIds,
            since: filter.since, until: filter.until, limit: filter.limit, before: cursor))
        let names = Self.names(labels)
        return MailMessagePage(
            messages: page.messages.map {
                mailMessage($0, owner: owner, names: names, includeBodies: filter.includeBodies)
            },
            nextCursor: try page.next.map(Self.encodeCursor),
            appliedAnyLabels: !anyLabelIds.isEmpty)
    }

    private func message(_ id: String, owner: Owner) throws -> HubEmailMessage {
        guard let message = try store.message(connectionId: owner.id, id: id) else {
            throw Failure("unknown message: \(id)", notFound: true)
        }
        return message
    }

    private func thread(owner: Owner, id: String, includeBodies: Bool) throws -> MailThread {
        var threadId = id
        var messages = try store.thread(connectionId: owner.id, threadId: id)
        if messages.isEmpty, let message = try store.message(connectionId: owner.id, id: id) {
            if let messageThread = message.threadId {
                threadId = messageThread
                messages = try store.thread(connectionId: owner.id, threadId: messageThread)
            } else {
                threadId = message.externalId
                messages = [message]
            }
        }
        guard !messages.isEmpty else { throw Failure("unknown thread: \(id)", notFound: true) }
        let names = try names(owner)
        return MailThread(id: threadId, messages: messages.map {
            mailMessage($0, owner: owner, names: names, includeBodies: includeBodies)
        })
    }

    // MARK: - Label writes

    private func modifyLabels(
        owner: Owner, ids: [String], add: [String], remove: [String]
    ) async throws -> [MailMessage] {
        let labels = try store.labels(connectionId: owner.id)
        let addIds = try Self.resolve(add, in: labels)
        let removeIds = try Self.resolve(remove, in: labels)
        let originals = try ids.map { try message($0, owner: owner) }
        let names = Self.names(labels)
        if !(addIds.isEmpty && removeIds.isEmpty) && !originals.isEmpty {
            try await write(originals, owner: owner, add: addIds, remove: removeIds)
        }
        return try originals.map {
            mailMessage(try message($0.id, owner: owner), owner: owner, names: names, includeBodies: false)
        }
    }

    private func moveMessages(
        owner: Owner, ids: [String], destination: String, from: [String]?
    ) async throws -> [MailMoveResult] {
        let labels = try store.labels(connectionId: owner.id)
        let destinationId = try Self.resolve([destination], in: labels)[0]
        let fromIds = try Self.resolve(from ?? (destinationId == "INBOX" ? [] : ["INBOX"]), in: labels)
        guard !fromIds.contains(destinationId) else {
            throw Failure("cannot move to \(destination): it is also a label to move from")
        }
        let originals = try ids.map { try message($0, owner: owner) }
        let changing = originals.filter {
            !$0.labelIds.contains(destinationId) || $0.labelIds.contains(where: fromIds.contains)
        }
        if !changing.isEmpty {
            try await write(changing, owner: owner, add: [destinationId], remove: fromIds)
        }
        let names = Self.names(labels)
        return try originals.map { old in
            let added = old.labelIds.contains(destinationId) ? [] : [destinationId]
            let removed = fromIds.filter(old.labelIds.contains)
            return MailMoveResult(
                message: mailMessage(try message(old.id, owner: owner), owner: owner, names: names,
                                     includeBodies: false),
                added: added.map { names[$0] ?? $0 }, removed: removed.map { names[$0] ?? $0 })
        }
    }

    /// Posts the change to the hub, then writes it into the mirror. A refusal
    /// throws before the mirror is touched.
    private func write(_ messages: [HubEmailMessage], owner: Owner, add: [String], remove: [String]) async throws {
        try await writeLabels(HubMailLabelWrite(
            connectionId: owner.id, messageIds: messages.map(\.externalId), add: add, remove: remove))
        try store.applyLabels(messageIds: messages.map(\.id), add: add, remove: remove)
    }

    // MARK: - Mapping

    private func names(_ owner: Owner) throws -> [String: String] {
        Self.names(try store.labels(connectionId: owner.id))
    }

    static func names(_ labels: [HubEmailLabel]) -> [String: String] {
        Dictionary(labels.map { ($0.externalId, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    /// Each value as a provider label id, without duplicates: an exact id,
    /// else an exact (case-sensitive) name.
    static func resolve(_ values: [String], in labels: [HubEmailLabel]) throws -> [String] {
        var seen = Set<String>()
        return try values.compactMap { value in
            guard let label = labels.first(where: { $0.externalId == value })
                    ?? labels.first(where: { $0.name == value }) else {
                throw Failure("unknown label: \(value)")
            }
            return seen.insert(label.externalId).inserted ? label.externalId : nil
        }
    }

    static func label(_ label: HubEmailLabel) -> MailLabel {
        MailLabel(
            id: label.externalId, name: label.name, type: label.type, parentName: label.parentName,
            messagesTotal: label.messagesTotal, messagesUnread: label.messagesUnread)
    }

    private func mailMessage(
        _ message: HubEmailMessage, owner: Owner, names: [String: String], includeBodies: Bool
    ) -> MailMessage {
        MailMessage(
            id: message.id, gmailId: message.externalId, threadId: message.threadId ?? "",
            account: owner.email, from: message.from ?? "", to: message.to, cc: message.cc,
            labels: message.labelIds, labelNames: message.labelIds.map { names[$0] ?? $0 },
            subject: message.subject ?? "", snippet: HTMLText.decodeEntities(message.snippet ?? ""),
            date: message.internalDate ?? "", mailClass: MailClassifier.classify(labelIds: message.labelIds),
            bodyText: includeBodies ? Self.bodyText(message) : nil,
            bodyHtml: includeBodies ? message.bodyHtml : nil,
            attachments: Self.attachments(message.attachmentsJSON))
    }

    /// The text body; for a message with none (or a blank one), its HTML read as text.
    static func bodyText(_ message: HubEmailMessage) -> String? {
        if let text = message.bodyText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        guard let html = message.bodyHtml else { return message.bodyText }
        let text = HTMLText.plainText(fromHTML: html)
        return text.isEmpty ? message.bodyText : text
    }

    static func attachments(_ json: String?) -> [EmailAttachmentRef] {
        guard let data = json?.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([EmailAttachmentRef].self, from: data)) ?? []
    }

    // MARK: - Cursor

    private struct Cursor: Codable {
        let date: String?
        let id: String
    }

    static func encodeCursor(_ cursor: HubMailPageCursor) throws -> String {
        try JSONEncoder().encode(Cursor(date: cursor.internalDate, id: cursor.id)).base64EncodedString()
    }

    static func decodeCursor(_ text: String) throws -> HubMailPageCursor {
        guard let data = Data(base64Encoded: text),
              let cursor = try? JSONDecoder().decode(Cursor.self, from: data) else {
            throw Failure("bad cursor")
        }
        return HubMailPageCursor(internalDate: cursor.date, id: cursor.id)
    }

    // MARK: - Failure

    struct Failure: Error, LocalizedError {
        let message: String
        let notFound: Bool

        init(_ message: String, notFound: Bool = false) {
            self.message = message
            self.notFound = notFound
        }

        var errorDescription: String? { message }
    }
}
