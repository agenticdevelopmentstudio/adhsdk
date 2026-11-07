import Foundation
import Testing
import AgenticDeveloperHubSDKIntegrations
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
struct MailBrowserModelTests {
    private typealias BoxID = MailBrowserModel.MailboxID

    private static func service(messages: [MailMessage] = [], labels: [MailLabel]? = nil) -> ScriptedMailService {
        let service = ScriptedMailService(accounts: [.fixture()])
        service.setLabels(labels ?? [.fixture("INBOX", unread: 2), .fixture("SENT"), .fixture("UNREAD")])
        service.setMessages(messages)
        return service
    }

    private static func listRequests(_ service: ScriptedMailService) -> [MailMessageFilter] {
        service.requests.compactMap { if case .listMessages(let filter) = $0 { return filter } else { return nil } }
    }

    // MARK: - Loading

    @Test func reloadSelectsTheFirstAccountsInboxAndListsIt() async {
        let service = Self.service(messages: [.fixture(id: "m1"), .fixture(id: "m2", labels: ["SENT"])])
        let model = MailBrowserModel(client: service.client)
        await model.reload()
        #expect(model.selectedMailbox == BoxID(accountId: "a1", labelId: "INBOX"))
        #expect(model.messages.map(\.id) == ["m1"])
        #expect(model.hasMore == false)
    }

    @Test func withNoAccountsNothingIsSelected() async {
        let service = ScriptedMailService(accounts: [])
        let model = MailBrowserModel(client: service.client)
        await model.reload()
        #expect(model.selectedMailbox == nil)
        #expect(model.messages.isEmpty)
        #expect(model.errorMessage == nil)
    }

    @Test func allMailListsWithoutALabelFilter() async {
        let service = Self.service(messages: [.fixture(id: "m1"), .fixture(id: "m2", labels: ["SENT"])])
        let model = MailBrowserModel(client: service.client)
        await model.reload()
        await model.select(mailbox: BoxID(accountId: "a1", labelId: nil))
        #expect(model.messages.map(\.id) == ["m1", "m2"])
        #expect(Self.listRequests(service).last?.labels == [])
    }

    @Test func pagesAppendUntilTheLast() async {
        let messages = (1...5).map { MailMessage.fixture(id: "m\($0)") }
        let service = Self.service(messages: messages)
        let model = MailBrowserModel(client: service.client, pageSize: 2)
        await model.reload()
        #expect(model.messages.map(\.id) == ["m1", "m2"])
        #expect(model.hasMore)
        await model.loadMore()
        await model.loadMore()
        #expect(model.messages.map(\.id) == ["m1", "m2", "m3", "m4", "m5"])
        #expect(model.hasMore == false)
        await model.loadMore()
        #expect(Self.listRequests(service).count == 3)
    }

    @Test func switchingMailboxesReplacesTheListAndClosesTheMessage() async {
        let service = Self.service(messages: [.fixture(id: "m1"), .fixture(id: "m2", labels: ["SENT"])])
        let model = MailBrowserModel(client: service.client)
        await model.reload()
        await model.select(messageId: "m1")
        await model.select(mailbox: BoxID(accountId: "a1", labelId: "SENT"))
        #expect(model.messages.map(\.id) == ["m2"])
        #expect(model.selectedMessageId == nil)
        #expect(model.openedMessage == nil)
    }

    @Test func aPageForAnEarlierMailboxIsDropped() async {
        let service = Self.service(messages: [.fixture(id: "m1"), .fixture(id: "m2", labels: ["SENT"])])
        let model = MailBrowserModel(client: service.client)
        await model.reload()
        service.gate { if case .listMessages(let filter) = $0 { return filter.labels == [] } else { return false } }
        let slow = Task { await model.select(mailbox: BoxID(accountId: "a1", labelId: nil)) }
        await service.waitForRequests(service.requests.count + 1)
        service.gate { _ in false }
        await model.select(mailbox: BoxID(accountId: "a1", labelId: "SENT"))
        service.release()
        await slow.value
        #expect(model.selectedMailbox == BoxID(accountId: "a1", labelId: "SENT"))
        #expect(model.messages.map(\.id) == ["m2"])
    }

    @Test func aFailedListBecomesTheErrorMessage() async {
        let service = Self.service(messages: [.fixture(id: "m1")])
        service.fail(with: "store unavailable") { if case .listMessages = $0 { return true } else { return false } }
        let model = MailBrowserModel(client: service.client)
        await model.reload()
        #expect(model.errorMessage == "store unavailable")
        model.dismissError()
        #expect(model.errorMessage == nil)
    }

    // MARK: - Opening a message

    @Test func openingAMessageLoadsItsBody() async {
        let service = Self.service(messages: [.fixture(id: "m1")])
        let model = MailBrowserModel(client: service.client)
        await model.reload()
        #expect(model.messages.first?.bodyText == nil)
        await model.select(messageId: "m1")
        #expect(model.openedMessage?.bodyText == "body m1")
    }

    @Test func openingAnUnreadMessageMarksItReadAndLowersTheCount() async {
        let service = Self.service(messages: [.fixture(id: "m1", labels: ["INBOX", "UNREAD"])])
        let model = MailBrowserModel(client: service.client)
        await model.reload()
        await model.select(messageId: "m1")
        let markRead = MailRequest.modifyLabels(account: "a1", messageIds: ["m1"], add: [], remove: ["UNREAD"])
        #expect(service.requests.contains(markRead))
        #expect(model.messages.first.map(MailBrowserModel.isUnread) == false)
        #expect(model.openedMessage.map(MailBrowserModel.isUnread) == false)
        #expect(model.mailboxes["a1"]?.first { $0.labelId == "INBOX" }?.unread == 1)
    }

    @Test func openingAReadMessageChangesNoLabels() async {
        let service = Self.service(messages: [.fixture(id: "m1")])
        let model = MailBrowserModel(client: service.client)
        await model.reload()
        await model.select(messageId: "m1")
        #expect(!service.requests.contains { if case .modifyLabels = $0 { return true } else { return false } })
    }

    // MARK: - Refreshing after a sync

    @Test func aFinishedSyncReloadsTheList() async {
        let service = Self.service(messages: [.fixture(id: "m1")])
        let model = MailBrowserModel(client: service.client)
        await model.reload()
        service.setMessages([.fixture(id: "m0"), .fixture(id: "m1")])
        await model.refreshIfSynced()
        #expect(model.messages.map(\.id) == ["m1"])
        var synced = MailAccount.fixture()
        synced.lastSyncAt = "2026-11-07T12:00:00.000Z"
        service.setAccounts([synced])
        await model.refreshIfSynced()
        #expect(model.messages.map(\.id) == ["m0", "m1"])
    }

    @Test func aRefreshKeepsTheOpenMessage() async {
        let service = Self.service(messages: [.fixture(id: "m1")])
        let model = MailBrowserModel(client: service.client)
        await model.reload()
        await model.select(messageId: "m1")
        var synced = MailAccount.fixture()
        synced.lastSyncAt = "2026-11-07T12:00:00.000Z"
        service.setAccounts([synced])
        await model.refreshIfSynced()
        #expect(model.selectedMessageId == "m1")
        #expect(model.openedMessage?.id == "m1")
    }

    // MARK: - Display

    @Test func mailboxesFollowGmailsOrderAndSkipAttributeLabels() {
        let labels: [MailLabel] = [
            .fixture("TRASH"), .fixture("Label_2", name: "Work/Clients", type: "user"), .fixture("UNREAD"),
            .fixture("CATEGORY_UPDATES"), .fixture("SENT"), .fixture("INBOX", unread: 3),
            .fixture("Label_1", name: "Work", type: "user"), .fixture("SPAM")
        ]
        let boxes = MailBrowserModel.mailboxes(for: "a1", labels: labels)
        #expect(boxes.map(\.title) == ["Inbox", "Sent", "All Mail", "Work", "Clients", "Junk", "Trash"])
        #expect(boxes.map(\.depth) == [0, 0, 0, 0, 1, 0, 0])
        #expect(boxes.first?.unread == 3)
    }

    @Test(arguments: [
        ("PayPal <service@paypal.com>", "PayPal"),
        ("\"Doe, Jane\" <jane@example.com>", "Doe, Jane"),
        ("<only@example.com>", "only@example.com"),
        ("plain@example.com", "plain@example.com")
    ])
    func senderNameTakesTheDisplayName(from: String, expected: String) {
        #expect(MailBrowserModel.senderName(from) == expected)
    }

    @Test func listDateShowsTimeTodayAndDayOtherwise() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let locale = Locale(identifier: "en_US")
        let now = try Date.ISO8601FormatStyle().parse("2026-11-07T20:00:00Z")
        let today = MailBrowserModel.listDate("2026-11-07T18:59:24.000Z", now: now, calendar: calendar, locale: locale)
        let thisYear = MailBrowserModel.listDate("2026-03-02T10:00:00.000Z", now: now,
                                                calendar: calendar, locale: locale)
        let older = MailBrowserModel.listDate("2024-03-02T10:00:00.000Z", now: now, calendar: calendar, locale: locale)
        #expect(today.contains("6:59"))
        #expect(thisYear == "Mar 2")
        #expect(older.contains("2024"))
    }
}
