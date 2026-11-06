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
    /// True while a browser sign-in (Add Account or Reconnect) is waiting for the user.
    @Published public private(set) var signingIn = false

    private let client: MailClient
    /// Calls in flight; `busy` is true while any is.
    private var inFlight = 0 {
        didSet { busy = inFlight > 0 }
    }
    /// Settings changed but not yet sent, per account. A stepper or toggle can change faster than
    /// the service answers; only the latest value is sent once the previous send finishes.
    private var pendingSettings: [String: MailSyncSettings] = [:]
    /// Accounts with a settings send in flight.
    private var sendingSettings: Set<String> = []
    /// The newest settings the user chose, per account, kept until its sends finish — so a
    /// reload landing mid-send shows that choice rather than the service's previous value.
    private var latestSettings: [String: MailSyncSettings] = [:]

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

    /// Reads the file inside the call, so a read failure becomes `errorMessage`.
    public func importClientJSON(from url: URL) async {
        await perform {
            let data = try Data(contentsOf: url)
            _ = try await self.client.send(.importOAuthClient(json: data))
        }
    }

    /// The OAuth client form's fields: the values from Google Cloud → Clients.
    @Published public var clientIdDraft = ""
    @Published public var clientSecretDraft = ""

    /// Whether the form has both values to save.
    public var canSaveClientDraft: Bool {
        !Self.trimmed(clientIdDraft).isEmpty && !Self.trimmed(clientSecretDraft).isEmpty
    }

    /// Imports the client typed into the form. The fields clear once the service accepts it
    /// and stay filled on failure, so a typo can be corrected.
    public func saveClientDraft() async {
        guard canSaveClientDraft else {
            errorMessage = "Enter both the client ID and the client secret."
            return
        }
        let config = GoogleOAuthClientConfig(
            clientId: Self.trimmed(clientIdDraft), clientSecret: Self.trimmed(clientSecretDraft))
        var saved = false
        await perform {
            _ = try await self.client.send(.importOAuthClient(json: try config.installedJSON()))
            saved = true
        }
        if saved {
            clientIdDraft = ""
            clientSecretDraft = ""
        }
    }

    private static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Clears the error message without making a call.
    public func dismissError() {
        errorMessage = nil
    }

    /// Also the "Reconnect" flow: the service matches the account by email and reuses it.
    public func addAccount() async {
        signingIn = true
        defer { signingIn = false }
        await perform { _ = try await self.client.send(.signIn) }
    }

    /// Ends a pending sign-in; the sign-in call then fails with "Sign-in was cancelled".
    public func cancelSignIn() async {
        do {
            _ = try await client.send(.cancelSignIn)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func remove(accountId: String) async {
        await perform { _ = try await self.client.send(.removeAccount(account: accountId)) }
    }

    /// Applies `settings` locally at once so the UI doesn't snap back, then sends them. While a
    /// send for the account is in flight, a new value only replaces the pending one; the running
    /// send delivers the latest when it finishes, so each change does not restart a sync.
    /// A failure drops what is pending and reloads, which restores the server's state.
    public func update(accountId: String, _ settings: MailSyncSettings) async {
        if let index = accounts.firstIndex(where: { $0.id == accountId }) {
            accounts[index].settings = settings
        }
        pendingSettings[accountId] = settings
        latestSettings[accountId] = settings
        guard sendingSettings.insert(accountId).inserted else { return }
        await perform {
            defer {
                self.sendingSettings.remove(accountId)
                self.latestSettings[accountId] = nil
            }
            do {
                while let next = self.pendingSettings.removeValue(forKey: accountId) {
                    _ = try await self.client.send(.updateSettings(account: accountId, settings: next))
                }
            } catch {
                self.pendingSettings[accountId] = nil
                throw error
            }
        }
    }

    public func syncNow(accountId: String) async {
        await perform { _ = try await self.client.send(.syncNow(account: accountId)) }
    }

    public func removeIntegration() async {
        await perform { _ = try await self.client.send(.removeProvider) }
    }

    // MARK: - Display text

    /// Whether a Google OAuth client has been imported; accounts can be added only then.
    public var isClientImported: Bool {
        provider?.configured == true
    }

    /// What the OAuth client section says about the imported client.
    public var oauthClientText: String {
        guard let provider else { return "Checking for an OAuth client…" }
        guard provider.configured else {
            return "Enter the client ID and secret of your Google Cloud Desktop app OAuth client, "
                + "or import its downloaded JSON. One client serves every Gmail account."
        }
        return "Gmail signs in with this OAuth client. To change it, enter new values below "
            + "or import a new JSON file."
    }

    /// The imported client id, shown in full.
    public var currentClientId: String? {
        guard isClientImported else { return nil }
        return provider?.clientId
    }

    /// The stored secret with all but its last five characters hidden. The daemon sends only
    /// those characters, and the mask is a fixed length so it does not reveal the secret's.
    public var maskedClientSecret: String? {
        guard isClientImported else { return nil }
        guard let suffix = provider?.clientSecretSuffix, !suffix.isEmpty else { return "Stored (hidden)" }
        return String(repeating: "•", count: 10) + suffix
    }

    public static func statusText(_ status: ConnectionStatus) -> String {
        switch status {
        case .active: return "Connected"
        case .error: return "Error"
        case .revoked: return "Reconnect needed"
        case .pending: return "Pending"
        }
    }

    public static func lastSyncedText(_ lastSyncAt: String?) -> String {
        lastSyncedText(lastSyncAt, now: Date(), locale: .current)
    }

    /// The clock and locale are fixed by tests.
    static func lastSyncedText(_ lastSyncAt: String?, now: Date, locale: Locale) -> String {
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
            var loaded = status.configured ? try await client.accounts() : []
            // A change made while reloading has not reached the service yet; keep showing it.
            for (id, settings) in latestSettings {
                if let index = loaded.firstIndex(where: { $0.id == id }) { loaded[index].settings = settings }
            }
            accounts = loaded
        } catch {
            if errorMessage == nil { errorMessage = error.localizedDescription }
        }
        if !accounts.contains(where: { $0.id == selectedAccountId }) {
            selectedAccountId = accounts.first?.id
        }
    }
}
