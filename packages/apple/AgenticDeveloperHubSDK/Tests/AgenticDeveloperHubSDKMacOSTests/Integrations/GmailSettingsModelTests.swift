import Foundation
import Testing
import AgenticDeveloperHubSDKIntegrations
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
struct GmailSettingsModelTests {
    @Test func reloadLoadsProviderAndAccounts() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        #expect(model.provider == MailProviderStatus(configured: true, clientIdHint: "abc"))
        #expect(model.accounts == [.fixture()])
        #expect(model.selectedAccountId == "a1")
        #expect(model.busy == false)
        #expect(model.errorMessage == nil)
    }

    @Test func addAccountSendsSignInThenReloads() async {
        let service = ScriptedMailService()
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        service.setAccounts([.fixture()])
        await model.addAccount()
        #expect(service.requests.contains(.signIn))
        #expect(service.requests.last == .listAccounts)
        #expect(model.accounts.count == 1)
    }

    @Test func updateSendsSettings() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        var settings = MailSyncSettings.default
        settings.includeSpam = true
        settings.windowDays = 90
        await model.update(accountId: "a1", settings)
        #expect(service.requests.contains(.updateSettings(account: "a1", settings: settings)))
        #expect(model.accounts.first?.settings == settings)
    }

    @Test func remoteFailureSetsErrorMessage() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        service.fail(with: "sign-in cancelled") { $0 == .signIn }
        let model = GmailSettingsModel(client: service.client)
        await model.addAccount()
        #expect(model.errorMessage == "sign-in cancelled")
        await model.reload()
        #expect(model.errorMessage == nil)
    }

    @Test func updateFailureRestoresServerStateAndSetsError() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        service.fail(with: "nope") {
            if case .updateSettings = $0 { return true }
            return false
        }
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        var settings = MailSyncSettings.default
        settings.includeTrash = true
        await model.update(accountId: "a1", settings)
        #expect(model.errorMessage == "nope")
        #expect(model.accounts.first?.settings == .default)
    }

    @Test func removeIntegrationClearsAccounts() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        await model.removeIntegration()
        #expect(service.requests.contains(.removeProvider))
        #expect(model.provider?.configured == false)
        #expect(model.accounts.isEmpty)
        #expect(model.selectedAccountId == nil)
    }

    @Test func statusTextAndLastSynced() {
        #expect(GmailSettingsModel.statusText(.active) == "Connected")
        #expect(GmailSettingsModel.statusText(.error) == "Error")
        #expect(GmailSettingsModel.statusText(.revoked) == "Reconnect needed")
        #expect(GmailSettingsModel.statusText(.pending) == "Pending")
        #expect(GmailSettingsModel.lastSyncedText(nil) == "Never synced")
        let recent = IntegrationClock.string(from: Date().addingTimeInterval(-3600))
        #expect(GmailSettingsModel.lastSyncedText(recent).hasPrefix("Last synced "))
    }
}
