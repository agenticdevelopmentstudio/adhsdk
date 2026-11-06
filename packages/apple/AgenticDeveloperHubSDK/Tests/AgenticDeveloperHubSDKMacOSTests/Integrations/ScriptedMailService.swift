import Foundation
import AgenticDeveloperHubSDKIntegrations

/// A scripted mail service for the settings-model tests: answers each request from
/// mutable state (or a scripted failure) and records every request.
final class ScriptedMailService: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [MailRequest] = []
    private var provider: MailProviderStatus
    private var accountList: [MailAccount]
    private var failure: String?
    private var failingRequest: ((MailRequest) -> Bool)?

    init(provider: MailProviderStatus = MailProviderStatus(configured: true, clientIdHint: "abc"),
         accounts: [MailAccount] = []) {
        self.provider = provider
        self.accountList = accounts
    }

    var requests: [MailRequest] { lock.withLock { recorded } }

    /// Makes requests matching `matches` answer `.failure(message)`.
    func fail(with message: String, when matches: @escaping @Sendable (MailRequest) -> Bool) {
        lock.withLock { failure = message; failingRequest = matches }
    }

    func setAccounts(_ accounts: [MailAccount]) { lock.withLock { accountList = accounts } }

    var client: MailClient {
        MailClient { data in
            let request = try JSONDecoder().decode(MailRequest.self, from: data)
            return try JSONEncoder().encode(self.answer(request))
        }
    }

    private func answer(_ request: MailRequest) -> MailResponse {
        lock.withLock {
            recorded.append(request)
            if let failure, failingRequest?(request) == true { return .failure(failure) }
            switch request {
            case .providerStatus: return .providerStatus(provider)
            case .listAccounts: return .accounts(accountList)
            case .removeProvider:
                provider = MailProviderStatus(configured: false, clientIdHint: nil)
                accountList = []
                return .ok
            case .importOAuthClient:
                provider = MailProviderStatus(configured: true, clientIdHint: "abc")
                return .ok
            case .updateSettings(let account, let settings):
                if let index = accountList.firstIndex(where: { $0.id == account }) {
                    accountList[index].settings = settings
                    return .account(accountList[index])
                }
                return .failure("no such account")
            default: return .ok
            }
        }
    }
}

extension MailAccount {
    static func fixture(id: String = "a1", email: String = "me@example.com",
                        status: ConnectionStatus = .active) -> MailAccount {
        MailAccount(id: id, email: email, status: status, lastSyncAt: nil, lastError: nil, settings: .default)
    }
}
