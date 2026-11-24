import Foundation
import Testing
import AgenticDeveloperHubSDKIntegrations
@testable import AgenticDeveloperHubSDKMacOS

/// The account error alert: raised once per failure, never inline.
@MainActor
struct GmailSettingsAccountErrorTests {
    private static func failing(_ message: String, id: String = "a1",
                                email: String = "me@example.com") -> MailAccount {
        MailAccount(id: id, email: email, status: .error, lastSyncAt: nil, lastError: message, settings: .default)
    }

    private static func alert(_ message: String, id: String = "a1",
                              email: String = "me@example.com") -> GmailSettingsModel.AccountErrorAlert {
        GmailSettingsModel.AccountErrorAlert(accountId: id, email: email, message: message)
    }

    @Test func aFailingAccountIsAlertedOnce() async {
        let service = ScriptedMailService(accounts: [Self.failing("Quota exceeded")])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        #expect(model.accountError == Self.alert("Quota exceeded"))
        model.dismissAccountError()
        #expect(model.accountError == nil)
        await model.reload()
        #expect(model.accountError == nil)
    }

    @Test func aHealthyAccountRaisesNothing() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        #expect(model.accountError == nil)
    }

    @Test func aDifferentErrorIsAlertedAgain() async {
        let service = ScriptedMailService(accounts: [Self.failing("Quota exceeded")])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        model.dismissAccountError()
        service.setAccounts([Self.failing("Backend Error")])
        await model.reload()
        #expect(model.accountError == Self.alert("Backend Error"))
    }

    @Test func theSameErrorAfterARecoveryIsAlertedAgain() async {
        let service = ScriptedMailService(accounts: [Self.failing("Quota exceeded")])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        model.dismissAccountError()
        service.setAccounts([.fixture()])
        await model.reload()
        #expect(model.accountError == nil)
        service.setAccounts([Self.failing("Quota exceeded")])
        await model.reload()
        #expect(model.accountError == Self.alert("Quota exceeded"))
    }

    @Test func dismissingRaisesTheNextFailingAccount() async {
        let service = ScriptedMailService(accounts: [
            Self.failing("Quota exceeded"), Self.failing("Backend Error", id: "a2", email: "two@example.com")
        ])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        #expect(model.accountError == Self.alert("Quota exceeded"))
        model.dismissAccountError()
        #expect(model.accountError == Self.alert("Backend Error", id: "a2", email: "two@example.com"))
        model.dismissAccountError()
        #expect(model.accountError == nil)
    }

    @Test func showErrorReopensItWithoutRepeatingAfterwards() async {
        let service = ScriptedMailService(accounts: [Self.failing("Quota exceeded")])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        model.dismissAccountError()
        model.showError(accountId: "a1")
        #expect(model.accountError == Self.alert("Quota exceeded"))
        model.dismissAccountError()
        #expect(model.accountError == nil)
    }

    @Test func showErrorIgnoresAHealthyAccount() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        model.showError(accountId: "a1")
        #expect(model.accountError == nil)
    }
}
