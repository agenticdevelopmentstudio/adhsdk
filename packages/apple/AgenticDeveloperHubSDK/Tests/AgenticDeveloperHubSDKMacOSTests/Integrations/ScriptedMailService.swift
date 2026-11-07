import Foundation
import Testing
import AgenticDeveloperHubSDKIntegrations

/// A scripted mail service for the settings-model tests: answers each request from
/// mutable state (or a scripted failure) and records every request.
final class ScriptedMailService: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [MailRequest] = []
    private var provider: MailProviderStatus
    private var accountList: [MailAccount]
    fileprivate var labelList: [MailLabel] = []
    fileprivate var messageList: [MailMessage] = []
    private var failure: String?
    private var failingRequest: ((MailRequest) -> Bool)?
    private var gateMatches: (@Sendable (MailRequest) -> Bool)?
    private var waiting: [CheckedContinuation<Void, Never>] = []

    init(provider: MailProviderStatus = MailProviderStatus(configured: true, clientId: "abc"),
         accounts: [MailAccount] = []) {
        self.provider = provider
        self.accountList = accounts
    }

    var requests: [MailRequest] { lock.withLock { recorded } }

    /// Makes requests matching `matches` answer `.failure(message)`.
    func fail(with message: String, when matches: @escaping @Sendable (MailRequest) -> Bool) {
        lock.withLock { failure = message; failingRequest = matches }
    }

    /// Holds requests matching `matches` inside the transport (after recording them) until `release()`.
    func gate(when matches: @escaping @Sendable (MailRequest) -> Bool) {
        lock.withLock { gateMatches = matches }
    }

    func release() {
        let held = lock.withLock { () -> [CheckedContinuation<Void, Never>] in
            gateMatches = nil
            defer { waiting = [] }
            return waiting
        }
        held.forEach { $0.resume() }
    }

    /// Suspends until at least `count` requests have reached the transport, or records an
    /// issue and returns false once `timeout` passes, so a missing request fails the test
    /// rather than hanging it.
    @discardableResult
    func waitForRequests(_ count: Int, timeout: Duration = .seconds(5)) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while requests.count < count {
            if ContinuousClock.now >= deadline {
                Issue.record("timed out waiting for \(count) requests; saw \(requests.count)")
                return false
            }
            try? await Task.sleep(for: .milliseconds(1))
        }
        return true
    }

    private func holdIfGated(_ request: MailRequest) async {
        let gated = lock.withLock { gateMatches?(request) == true }
        guard gated else { return }
        await withCheckedContinuation { continuation in
            let resumeNow = lock.withLock { () -> Bool in
                if gateMatches == nil { return true }
                waiting.append(continuation)
                return false
            }
            if resumeNow { continuation.resume() }
        }
    }

    func setAccounts(_ accounts: [MailAccount]) { lock.withLock { accountList = accounts } }
    func setLabels(_ labels: [MailLabel]) { lock.withLock { labelList = labels } }
    /// Newest first, as the service lists them; bodies are returned only by `getMessage`.
    func setMessages(_ messages: [MailMessage]) { lock.withLock { messageList = messages } }

    var client: MailClient {
        MailClient { data in
            let request = try JSONDecoder().decode(MailRequest.self, from: data)
            self.lock.withLock { self.recorded.append(request) }
            await self.holdIfGated(request)
            return try JSONEncoder().encode(self.answer(request))
        }
    }

    private func answer(_ request: MailRequest) -> MailResponse {
        lock.withLock {
            if let failure, failingRequest?(request) == true { return .failure(failure) }
            switch request {
            case .providerStatus: return .providerStatus(provider)
            case .listAccounts: return .accounts(accountList)
            case .removeProvider:
                provider = MailProviderStatus(configured: false, clientId: nil)
                accountList = []
                return .ok
            case .importOAuthClient:
                provider = MailProviderStatus(configured: true, clientId: "abc")
                return .ok
            case .updateSettings(let account, let settings):
                if let index = accountList.firstIndex(where: { $0.id == account }) {
                    accountList[index].settings = settings
                    return .account(accountList[index])
                }
                return .failure("no such account")
            case .listLabels: return .labels(labelList)
            case .listMessages(let filter): return .messages(page(filter))
            case .getMessage(_, let id):
                guard let message = messageList.first(where: { $0.id == id }) else {
                    return .failure("no such message")
                }
                return .message(message)
            case .modifyLabels(_, let ids, let add, let remove):
                var changed: [MailMessage] = []
                for index in messageList.indices where ids.contains(messageList[index].id) {
                    messageList[index].labels.removeAll { remove.contains($0) }
                    messageList[index].labels += add.filter { !messageList[index].labels.contains($0) }
                    changed.append(messageList[index])
                }
                return .messages(MailMessagePage(messages: changed, nextCursor: nil))
            default: return .ok
            }
        }
    }
}

extension ScriptedMailService {
    /// Called with the lock held.
    fileprivate func page(_ filter: MailMessageFilter) -> MailMessagePage {
        let matching = messageList.filter { message in filter.labels.allSatisfy(message.labels.contains) }
        let offset = filter.cursor.flatMap { Int($0) } ?? 0
        let listed = matching.dropFirst(offset).prefix(filter.limit).map { message -> MailMessage in
            var listed = message
            listed.bodyText = nil
            listed.bodyHtml = nil
            return listed
        }
        let next = offset + filter.limit < matching.count ? String(offset + filter.limit) : nil
        return MailMessagePage(messages: Array(listed), nextCursor: next)
    }
}

extension MailAccount {
    static func fixture(id: String = "a1", email: String = "me@example.com",
                        status: ConnectionStatus = .active) -> MailAccount {
        MailAccount(id: id, email: email, status: status, lastSyncAt: nil, lastError: nil, settings: .default)
    }
}

extension MailMessage {
    static func fixture(id: String, account: String = "me@example.com", labels: [String] = ["INBOX"],
                        subject: String = "Hello", date: String = "2026-11-07T10:00:00.000Z") -> MailMessage {
        MailMessage(id: id, gmailId: "g-" + id, threadId: "t-" + id, account: account,
                    from: "Ann Example <ann@example.com>", to: [account], cc: [], labels: labels,
                    labelNames: labels, subject: subject, snippet: "snippet " + id, date: date,
                    mailClass: .filed, bodyText: "body " + id, bodyHtml: nil, attachments: [])
    }
}

extension MailLabel {
    static func fixture(_ id: String, name: String? = nil, type: String = "system", unread: Int? = nil) -> MailLabel {
        MailLabel(id: id, name: name ?? id, type: type, parentName: nil, messagesTotal: nil, messagesUnread: unread)
    }
}
