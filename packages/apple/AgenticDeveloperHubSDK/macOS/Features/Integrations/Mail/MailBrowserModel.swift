import Combine
import Foundation
import AgenticDeveloperHubSDKIntegrations

/// The state behind the mail window: accounts and their mailboxes, the selected mailbox's
/// messages a page at a time, and the open message. Every action the window offers goes
/// through here, so this is the tested unit; the view controllers only read it and call it.
@MainActor
public final class MailBrowserModel: ObservableObject {
    /// One row under an account in the sidebar: a Gmail label, or All Mail (`labelId == nil`).
    public struct Mailbox: Equatable, Hashable, Sendable {
        public let accountId: String
        public let labelId: String?
        /// The row's text: the last part of a nested label's name.
        public let title: String
        /// How deep a nested user label sits ("Work/Clients" is 1).
        public let depth: Int
        public let unread: Int?
    }

    /// The selected mailbox, by identity only, so a reload that changes counts keeps it.
    public struct MailboxID: Equatable, Hashable, Sendable {
        public let accountId: String
        public let labelId: String?
    }

    @Published public private(set) var accounts: [MailAccount] = []
    /// Each account's mailboxes, in sidebar order, keyed by account id.
    @Published public private(set) var mailboxes: [String: [Mailbox]] = [:]
    @Published public private(set) var selectedMailbox: MailboxID?
    @Published public private(set) var messages: [MailMessage] = []
    @Published public private(set) var hasMore = false
    @Published public private(set) var selectedMessageId: String?
    /// The selected message with its bodies; `nil` until it loads.
    @Published public private(set) var openedMessage: MailMessage?
    @Published public private(set) var loading = false
    @Published public private(set) var errorMessage: String?

    private let client: MailClient
    private let pageSize: Int
    private var nextCursor: String?
    /// Bumped whenever the list is replaced, so a page answering an older selection is dropped.
    private var listGeneration = 0
    /// Bumped whenever the selected message changes, for the same reason.
    private var messageGeneration = 0
    private var loadingMore = false
    /// Each account's `lastSyncAt` when last seen, so a poll can tell a sync has finished.
    private var seenSyncs: [String: String?] = [:]

    public init(client: MailClient, pageSize: Int = MailMessageFilter.defaultLimit) {
        self.client = client
        self.pageSize = pageSize
    }

    /// The selected mailbox's account.
    public var selectedAccount: MailAccount? {
        accounts.first { $0.id == selectedMailbox?.accountId }
    }

    public func dismissError() {
        errorMessage = nil
    }

    // MARK: - Loading

    /// Loads the accounts and their mailboxes, then the selected mailbox's first page. With
    /// nothing selected yet (or the selection gone), the first account's Inbox is selected.
    public func reload() async {
        loading = true
        defer { loading = false }
        do {
            let status = try await client.providerStatus()
            accounts = status.configured ? try await client.accounts() : []
            seenSyncs = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0.lastSyncAt) })
            var loaded: [String: [Mailbox]] = [:]
            for account in accounts {
                loaded[account.id] = Self.mailboxes(
                    for: account.id, labels: try await client.labels(account: account.id))
            }
            mailboxes = loaded
        } catch {
            errorMessage = error.localizedDescription
        }
        if let selectedMailbox, mailbox(selectedMailbox) != nil {
            await loadFirstPage(keepingSelection: true)
        } else if let first = accounts.first {
            let inbox = mailboxes[first.id]?.first { $0.labelId == "INBOX" } ?? mailboxes[first.id]?.first
            await select(mailbox: MailboxID(accountId: first.id, labelId: inbox?.labelId))
        } else {
            selectedMailbox = nil
            clearList()
        }
    }

    /// Shows `id`'s first page and closes the open message.
    public func select(mailbox id: MailboxID) async {
        guard id != selectedMailbox || messages.isEmpty else { return }
        selectedMailbox = id
        await loadFirstPage(keepingSelection: false)
    }

    /// Appends the next page; a no-op on the last page or while a page is loading.
    public func loadMore() async {
        guard hasMore, !loadingMore, let id = selectedMailbox, let cursor = nextCursor,
              let account = account(id.accountId) else { return }
        loadingMore = true
        defer { loadingMore = false }
        let generation = listGeneration
        do {
            let page = try await client.messages(filter(account: account, labelId: id.labelId, cursor: cursor))
            guard generation == listGeneration else { return }
            let known = Set(messages.map(\.id))
            messages += page.messages.filter { !known.contains($0.id) }
            nextCursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            guard generation == listGeneration else { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Opens a message: loads its bodies and, when it is unread, marks it read.
    public func select(messageId: String?) async {
        guard messageId != selectedMessageId else { return }
        messageGeneration += 1
        let generation = messageGeneration
        selectedMessageId = messageId
        openedMessage = nil
        guard let messageId, let listed = messages.first(where: { $0.id == messageId }),
              let account = account(forEmail: listed.account) else { return }
        do {
            let full = try await client.message(account: account.id, id: messageId)
            guard generation == messageGeneration else { return }
            openedMessage = full
            if full.labels.contains("UNREAD") { await markRead(full, account: account) }
        } catch {
            guard generation == messageGeneration else { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Reloads when an account's `lastSyncAt` moved since the last look, so mail a sync
    /// fetched appears without the user asking. Reads only the local store, never Gmail.
    public func refreshIfSynced() async {
        guard let latest = try? await client.accounts() else { return }
        let syncs = Dictionary(uniqueKeysWithValues: latest.map { ($0.id, $0.lastSyncAt) })
        guard syncs != seenSyncs else { return }
        await reload()
    }

    // MARK: - Display text

    /// The sender's name, or the bare address when the header has no name.
    public static func senderName(_ from: String) -> String {
        let trimmed = from.trimmingCharacters(in: .whitespaces)
        guard let open = trimmed.lastIndex(of: "<") else { return trimmed }
        let name = trimmed[..<open].trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        if !name.isEmpty { return name }
        return trimmed[trimmed.index(after: open)...].trimmingCharacters(in: CharacterSet(charactersIn: "> "))
    }

    /// The list's date column: the time today, the day this year, the full date before.
    public static func listDate(_ iso: String) -> String {
        listDate(iso, now: Date(), calendar: .current, locale: .current)
    }

    static func listDate(_ iso: String, now: Date, calendar: Calendar, locale: Locale) -> String {
        guard let date = parse(iso) else { return iso }
        var style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
        if calendar.isDate(date, inSameDayAs: now) {
            style = style.hour().minute()
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            style = style.month(.abbreviated).day()
        } else {
            style = style.year().month(.abbreviated).day()
        }
        return date.formatted(style)
    }

    /// The reader's date line.
    public static func fullDate(_ iso: String) -> String {
        guard let date = parse(iso) else { return iso }
        return date.formatted(date: .complete, time: .shortened)
    }

    public static func isUnread(_ message: MailMessage) -> Bool {
        message.labels.contains("UNREAD")
    }

    /// The sidebar's mailboxes for one account: the system mailboxes people look in, in
    /// Gmail's order, then All Mail, then user labels sorted by name. Attribute labels
    /// (`UNREAD`, `CATEGORY_*`, `CHAT`, …) are not mailboxes and are left out.
    static func mailboxes(for accountId: String, labels: [MailLabel]) -> [Mailbox] {
        let byId = Dictionary(labels.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        func system(_ id: String) -> Mailbox? {
            guard let label = byId[id], let title = systemTitles[id] else { return nil }
            return Mailbox(accountId: accountId, labelId: id, title: title, depth: 0, unread: label.messagesUnread)
        }
        let leading = ["INBOX", "STARRED", "IMPORTANT", "SENT", "DRAFT"].compactMap(system)
        let allMail = Mailbox(accountId: accountId, labelId: nil, title: "All Mail", depth: 0, unread: nil)
        let user = labels.filter { $0.type == "user" }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { label -> Mailbox in
                let parts = label.name.split(separator: "/", omittingEmptySubsequences: false)
                return Mailbox(accountId: accountId, labelId: label.id, title: String(parts.last ?? ""),
                               depth: parts.count - 1, unread: label.messagesUnread)
            }
        let trailing = ["SPAM", "TRASH"].compactMap(system)
        return leading + [allMail] + user + trailing
    }

    private static let systemTitles = [
        "INBOX": "Inbox", "STARRED": "Starred", "IMPORTANT": "Important", "SENT": "Sent",
        "DRAFT": "Drafts", "SPAM": "Spam", "TRASH": "Trash"
    ]

    // MARK: - Private

    private func loadFirstPage(keepingSelection: Bool) async {
        guard let id = selectedMailbox, let account = account(id.accountId) else {
            clearList()
            return
        }
        listGeneration += 1
        let generation = listGeneration
        if !keepingSelection {
            messages = []
            hasMore = false
            nextCursor = nil
            await select(messageId: nil)
        }
        do {
            // A refresh keeps as many rows as were showing, so the list does not shrink under the user.
            let limit = keepingSelection ? max(pageSize, messages.count) : pageSize
            let page = try await client.messages(filter(account: account, labelId: id.labelId, limit: limit))
            guard generation == listGeneration else { return }
            messages = page.messages
            nextCursor = page.nextCursor
            hasMore = page.nextCursor != nil
            if let selectedMessageId, !messages.contains(where: { $0.id == selectedMessageId }) {
                await select(messageId: nil)
            }
        } catch {
            guard generation == listGeneration else { return }
            errorMessage = error.localizedDescription
        }
    }

    private func markRead(_ message: MailMessage, account: MailAccount) async {
        do {
            let updated = try await client.modifyLabels(
                account: account.id, messageIds: [message.id], add: [], remove: ["UNREAD"])
            for changed in updated {
                if let index = messages.firstIndex(where: { $0.id == changed.id }) {
                    messages[index].labels = changed.labels
                    messages[index].labelNames = changed.labelNames
                }
                if openedMessage?.id == changed.id {
                    openedMessage?.labels = changed.labels
                    openedMessage?.labelNames = changed.labelNames
                }
            }
            adjustUnread(accountId: account.id, labels: message.labels, by: -1)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Keeps the sidebar's unread counts in step with a read made here, until the next sync
    /// brings Gmail's own counts.
    private func adjustUnread(accountId: String, labels: [String], by delta: Int) {
        guard var list = mailboxes[accountId] else { return }
        for index in list.indices {
            guard let labelId = list[index].labelId, labels.contains(labelId),
                  let unread = list[index].unread else { continue }
            let old = list[index]
            list[index] = Mailbox(accountId: old.accountId, labelId: old.labelId, title: old.title,
                                  depth: old.depth, unread: max(unread + delta, 0))
        }
        mailboxes[accountId] = list
    }

    private func clearList() {
        listGeneration += 1
        messages = []
        hasMore = false
        nextCursor = nil
        messageGeneration += 1
        selectedMessageId = nil
        openedMessage = nil
    }

    private func filter(
        account: MailAccount, labelId: String?, cursor: String? = nil, limit: Int? = nil
    ) -> MailMessageFilter {
        MailMessageFilter(account: account.id, labels: labelId.map { [$0] } ?? [],
                          limit: limit ?? pageSize, cursor: cursor)
    }

    private func mailbox(_ id: MailboxID) -> Mailbox? {
        mailboxes[id.accountId]?.first { $0.labelId == id.labelId }
    }

    private func account(_ id: String) -> MailAccount? {
        accounts.first { $0.id == id }
    }

    /// Listed messages name their account by email address.
    private func account(forEmail email: String) -> MailAccount? {
        accounts.first { $0.email == email } ?? selectedAccount
    }

    private static func parse(_ text: String) -> Date? {
        (try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(text))
            ?? (try? Date.ISO8601FormatStyle().parse(text))
    }
}
