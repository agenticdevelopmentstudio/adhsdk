import AppKit
import SwiftUI
import UniformTypeIdentifiers
import AgenticDeveloperHubSDKIntegrations

/// The Gmail detail pane. It reads `GmailSettingsModel` and calls it; nothing else.
struct GmailSettingsView: View {
    @ObservedObject var model: GmailSettingsModel

    private static let pollChoices = [5, 15, 30, 60]
    /// Fixed windows rather than a stepper: each change re-syncs, so a day at a time is costly.
    private static let windowChoices = [7, 14, 30, 90, 180, 365]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            oauthClientSection
            Divider()
            accountsSection
            if let message = model.errorMessage {
                Text(message).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - OAuth client

    private var oauthClientSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OAuth Client").font(.headline)
            Text(model.oauthClientText).fixedSize(horizontal: false, vertical: true)
            if let clientId = model.currentClientId, let secret = model.maskedClientSecret {
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
                    GridRow {
                        Text("Current client ID").foregroundStyle(.secondary)
                        Text(clientId).textSelection(.enabled).monospaced()
                    }
                    GridRow {
                        Text("Current secret").foregroundStyle(.secondary)
                        Text(secret).monospaced()
                    }
                }
            }
            Form {
                TextField("Client ID", text: $model.clientIdDraft, prompt: Text("….apps.googleusercontent.com"))
                SecureField("Client secret", text: $model.clientSecretDraft)
            }
            .frame(maxWidth: 460)
            HStack {
                Button(model.isClientImported ? "Replace Client" : "Save Client") {
                    Task { await model.saveClientDraft() }
                }
                .disabled(model.busy || !model.canSaveClientDraft)
                Text("or").foregroundStyle(.secondary)
                Button(model.isClientImported ? "Replace from JSON…" : "Import Client JSON…") {
                    importClientJSON()
                }
                .disabled(model.busy)
            }
            if model.isClientImported && !model.accounts.isEmpty {
                Text("Accounts signed in with a replaced client need Reconnect.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func importClientJSON() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task { await model.importClientJSON(from: url) }
    }

    // MARK: - Accounts

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accounts").font(.headline)
            if !model.isClientImported {
                Text("Add the OAuth client above before adding an account.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            List(model.accounts, id: \.id, selection: $model.selectedAccountId) { account in
                accountRow(account)
            }
            .frame(minHeight: 120)
            HStack {
                Button("Add Account…") { Task { await model.addAccount() } }
                    .disabled(model.busy || !model.isClientImported)
                Button("Remove") {
                    if let account = model.selectedAccount { confirmRemove(account) }
                }
                .disabled(model.selectedAccount == nil || model.busy)
                if model.signingIn {
                    ProgressView().controlSize(.small)
                    Text("Waiting for Google sign-in in your browser…").font(.caption)
                    Button("Cancel") { Task { await model.cancelSignIn() } }
                }
            }
            if let account = model.selectedAccount {
                settings(for: account)
            }
        }
    }

    private func confirmRemove(_ account: MailAccount) {
        let alert = NSAlert()
        alert.messageText = "Remove \(account.email)?"
        alert.informativeText = "This signs the account out of Google, removes its stored sign-in "
            + "and deletes its mail from this Mac."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        alert.buttons.first?.hasDestructiveAction = true
        let remove = { Task { await model.remove(accountId: account.id) } }
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn { _ = remove() }
            }
        } else if alert.runModal() == .alertFirstButtonReturn {
            _ = remove()
        }
    }

    private func accountRow(_ account: MailAccount) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(account.email)
                Text(GmailSettingsModel.statusText(account.status))
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .background(.quaternary, in: Capsule())
            }
            if account.status == .error, let lastError = account.lastError {
                Text(lastError).font(.caption).foregroundStyle(.red)
            }
            Text(GmailSettingsModel.lastSyncedText(account.lastSyncAt))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func settings(for account: MailAccount) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if account.status == .revoked || account.status == .error {
                    Button("Reconnect") { Task { await model.addAccount() } }
                        .disabled(model.busy)
                }
                Button("Sync Now") { Task { await model.syncNow(accountId: account.id) } }
                    .disabled(model.busy)
            }
            Toggle("Sync archived mail", isOn: binding(account, \.includeArchived))
            Toggle("Sync junk mail", isOn: binding(account, \.includeSpam))
            Toggle("Sync deleted mail", isOn: binding(account, \.includeTrash))
            Picker("Fetch mail from the last", selection: binding(account, \.windowDays)) {
                ForEach(Self.choices(Self.windowChoices, including: account.settings.windowDays), id: \.self) { days in
                    Text("\(days) days").tag(days)
                }
            }
            .frame(maxWidth: 300)
            Picker("Check for mail every", selection: binding(account, \.pollIntervalMinutes)) {
                ForEach(Self.choices(Self.pollChoices, including: account.settings.pollIntervalMinutes),
                        id: \.self) { minutes in
                    Text("\(minutes) minutes").tag(minutes)
                }
            }
            .frame(maxWidth: 300)
        }
    }

    /// The fixed choices, plus the account's current value when it is a custom one.
    private static func choices(_ fixed: [Int], including current: Int) -> [Int] {
        fixed.contains(current) ? fixed : (fixed + [current]).sorted()
    }

    /// Reads one field of the account's settings; a write sends the whole settings at once.
    private func binding<Value>(
        _ account: MailAccount, _ keyPath: WritableKeyPath<MailSyncSettings, Value>
    ) -> Binding<Value> {
        Binding(
            get: { account.settings[keyPath: keyPath] },
            set: { value in
                var updated = account.settings
                updated[keyPath: keyPath] = value
                Task { await model.update(accountId: account.id, updated) }
            })
    }
}
