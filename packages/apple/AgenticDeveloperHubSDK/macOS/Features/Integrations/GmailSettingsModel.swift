import Combine
import Foundation
import AgenticDeveloperHubSDKIntegrations

/// The state behind the Gmail settings view. Every action the view offers goes through
/// here, so this is the tested unit; the view only reads it and calls it.
@MainActor
public final class GmailSettingsModel: ObservableObject {
    @Published public private(set) var provider: MailProviderStatus?
    @Published public private(set) var accounts: [MailAccount] = []
    @Published public var selectedAccountId: String?
    @Published public private(set) var busy = false
    @Published public private(set) var errorMessage: String?

    private let client: MailClient
    /// Calls in flight; `busy` is true while any is.
    private var inFlight = 0 {
        didSet { busy = inFlight > 0 }
    }

    public init(client: MailClient) {
        self.client = client
    }

    /// The account the detail controls edit.
    public var selectedAccount: MailAccount? {
        accounts.first { $0.id == selectedAccountId }
    }

    public func reload() async {
        await perform { }
    }

    public func importClientJSON(_ data: Data) async {
        await perform { _ = try await self.client.send(.importOAuthClient(json: data)) }
    }

    /// Reads the file inside the call, so a read failure becomes `errorMessage`.
    public func importClientJSON(from url: URL) async {
        await perform {
            let data = try Data(contentsOf: url)
            _ = try await self.client.send(.importOAuthClient(json: data))
        }
    }

    /// Clears the error message without making a call.
    public func dismissError() {
        errorMessage = nil
    }

    /// Also the "Reconnect" flow: the service matches the account by email and reuses it.
    public func addAccount() async {
        await perform { _ = try await self.client.send(.signIn) }
    }

    public func remove(accountId: String) async {
        await perform { _ = try await self.client.send(.removeAccount(account: accountId)) }
    }

    /// Applies `settings` locally at once so the UI doesn't snap back, then sends them.
    /// A failure reloads, which restores the server's state.
    public func update(accountId: String, _ settings: MailSyncSettings) async {
        if let index = accounts.firstIndex(where: { $0.id == accountId }) {
            accounts[index].settings = settings
        }
        await perform {
            _ = try await self.client.send(.updateSettings(account: accountId, settings: settings))
        }
    }

    public func syncNow(accountId: String) async {
        await perform { _ = try await self.client.send(.syncNow(account: accountId)) }
    }

    public func removeIntegration() async {
        await perform { _ = try await self.client.send(.removeProvider) }
    }

    // MARK: - Display text

    public static func statusText(_ status: ConnectionStatus) -> String {
        switch status {
        case .active: return "Connected"
        case .error: return "Error"
        case .revoked: return "Reconnect needed"
        case .pending: return "Pending"
        }
    }

    public static func lastSyncedText(_ lastSyncAt: String?, now: Date = Date(), locale: Locale = .current) -> String {
        guard let lastSyncAt, let date = parse(lastSyncAt) else { return "Never synced" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = locale
        return "Last synced " + formatter.localizedString(for: date, relativeTo: now)
    }

    private static func parse(_ text: String) -> Date? {
        try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(text)
    }

    // MARK: - Calls

    /// Runs `action`, then reloads the provider and accounts. The error message is cleared
    /// when the call starts and set from the first failure; a reload always follows so the
    /// model shows the server's state.
    private func perform(_ action: () async throws -> Void) async {
        inFlight += 1
        errorMessage = nil
        defer { inFlight -= 1 }
        do {
            try await action()
        } catch {
            errorMessage = error.localizedDescription
        }
        do {
            let status = try await client.providerStatus()
            provider = status
            accounts = status.configured ? try await client.accounts() : []
        } catch {
            if errorMessage == nil { errorMessage = error.localizedDescription }
        }
        if !accounts.contains(where: { $0.id == selectedAccountId }) {
            selectedAccountId = accounts.first?.id
        }
    }
}
