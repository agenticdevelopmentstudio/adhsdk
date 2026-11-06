import AppKit
import SwiftUI
import UniformTypeIdentifiers
import AgenticDeveloperHubSDKIntegrations

/// The Gmail detail pane. It reads `GmailSettingsModel` and calls it; nothing else.
struct GmailSettingsView: View {
    @ObservedObject var model: GmailSettingsModel

    private static let pollChoices = [5, 15, 30, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.provider?.configured == true {
                configured
            } else {
                notConfigured
            }
            if let message = model.errorMessage {
                Text(message).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Not configured

    private var notConfigured: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add the OAuth client JSON you downloaded from Google Cloud (Desktop app).")
            Button("Import Client JSON…") { importClientJSON() }
                .disabled(model.busy)
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

    // MARK: - Configured

    private var configured: some View {
        VStack(alignment: .leading, spacing: 12) {
            List(model.accounts, id: \.id, selection: $model.selectedAccountId) { account in
                accountRow(account)
            }
            .frame(minHeight: 120)
            HStack {
                Button("Add Account…") { Task { await model.addAccount() } }
                    .disabled(model.busy)
                Button("Remove") {
                    if let id = model.selectedAccountId { Task { await model.remove(accountId: id) } }
                }
                .disabled(model.selectedAccount == nil || model.busy)
            }
            if let account = model.selectedAccount {
                settings(for: account)
            }
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
                if account.status == .revoked {
                    Button("Reconnect") { Task { await model.addAccount() } }
                        .disabled(model.busy)
                }
                Button("Sync Now") { Task { await model.syncNow(accountId: account.id) } }
                    .disabled(model.busy)
            }
            Toggle("Sync archived mail", isOn: binding(account, \.includeArchived))
            Toggle("Sync junk mail", isOn: binding(account, \.includeSpam))
            Toggle("Sync deleted mail", isOn: binding(account, \.includeTrash))
            Stepper(
                "Fetch mail from the last \(account.settings.windowDays) days",
                value: binding(account, \.windowDays), in: MailSyncSettings.windowDaysRange)
            Picker("Check for mail every", selection: binding(account, \.pollIntervalMinutes)) {
                ForEach(pollChoices(including: account.settings.pollIntervalMinutes), id: \.self) { minutes in
                    Text("\(minutes) minutes").tag(minutes)
                }
            }
            .frame(maxWidth: 300)
        }
    }

    /// The fixed choices, plus the account's current value when it is a custom one.
    private func pollChoices(including current: Int) -> [Int] {
        Self.pollChoices.contains(current) ? Self.pollChoices : (Self.pollChoices + [current]).sorted()
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
