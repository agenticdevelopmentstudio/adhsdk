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
        #expect(model.provider == MailProviderStatus(configured: true, clientId: "abc"))
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

    @Test func onlyTheModelThatStartedTheLatestSignInClaimsIt() async {
        let service = ScriptedMailService()
        let signIns = GmailSignInTracker()
        let desktop = GmailSettingsModel(client: service.client, signIns: signIns)
        let settings = GmailSettingsModel(client: service.client, signIns: signIns)
        #expect(desktop.startedLatestSignIn == false)
        #expect(settings.startedLatestSignIn == false)
        await desktop.addAccount()
        #expect(desktop.startedLatestSignIn)
        #expect(settings.startedLatestSignIn == false)
        await settings.addAccount()
        #expect(desktop.startedLatestSignIn == false)
        #expect(settings.startedLatestSignIn)
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

    @Test func statusText() {
        #expect(GmailSettingsModel.statusText(.active) == "Connected")
        #expect(GmailSettingsModel.statusText(.error) == "Error")
        #expect(GmailSettingsModel.statusText(.revoked) == "Reconnect needed")
        #expect(GmailSettingsModel.statusText(.pending) == "Pending")
    }

    @Test func lastSyncedTextIsExactForAFixedDate() throws {
        let now = try Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse("2026-01-02T05:04:05.000Z")
        let locale = Locale(identifier: "en_US")
        #expect(GmailSettingsModel.lastSyncedText(nil, now: now, locale: locale) == "Never synced")
        #expect(GmailSettingsModel.lastSyncedText("2026-01-02T03:04:05.000Z", now: now, locale: locale)
            == "Last synced 2 hours ago")
        #expect(GmailSettingsModel.lastSyncedText("garbage", now: now, locale: locale) == "Never synced")
    }

    @Test func removeSendsRemoveAccount() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        await model.remove(accountId: "a1")
        #expect(service.requests.contains(.removeAccount(account: "a1")))
    }

    @Test func syncNowSendsSyncNow() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        await model.syncNow(accountId: "a1")
        #expect(service.requests.contains(.syncNow(account: "a1")))
    }

    @Test func errorMessageClearsWhenTheNextCallStarts() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        service.fail(with: "boom") { $0 == .signIn }
        let model = GmailSettingsModel(client: service.client)
        await model.addAccount()
        #expect(model.errorMessage == "boom")
        service.gate { $0 == .syncNow(account: "a1") }
        let before = service.requests.count
        let call = Task { await model.syncNow(accountId: "a1") }
        await service.waitForRequests(before + 1)
        #expect(model.errorMessage == nil)
        service.release()
        await call.value
    }

    @Test func busyIsTrueDuringACall() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        service.gate { $0 == .signIn }
        let before = service.requests.count
        let call = Task { await model.addAccount() }
        await service.waitForRequests(before + 1)
        #expect(model.busy == true)
        service.release()
        await call.value
        #expect(model.busy == false)
    }

    @Test func busyStaysTrueUntilOverlappingCallsBothFinish() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        service.gate { $0 == .signIn || $0 == .syncNow(account: "a1") }
        let before = service.requests.count
        let first = Task { await model.addAccount() }
        let second = Task { await model.syncNow(accountId: "a1") }
        await service.waitForRequests(before + 2)
        service.release()
        await first.value
        await second.value
        #expect(model.busy == false)
    }

    @Test func busyIsNotClearedByTheFirstOfTwoOverlappingCalls() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        service.gate { $0 == .signIn }
        let before = service.requests.count
        let slow = Task { await model.addAccount() }
        await service.waitForRequests(before + 1)
        await model.syncNow(accountId: "a1")
        #expect(model.busy == true)
        service.release()
        await slow.value
        #expect(model.busy == false)
    }

    @Test func updateAppliesLocallyBeforeTheSend() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        var settings = MailSyncSettings.default
        settings.windowDays = 7
        service.gate {
            if case .updateSettings = $0 { return true }
            return false
        }
        let before = service.requests.count
        let call = Task { await model.update(accountId: "a1", settings) }
        await service.waitForRequests(before + 1)
        #expect(model.accounts.first?.settings == settings)
        #expect(model.busy == true)
        service.release()
        await call.value
    }

    @Test func rapidUpdatesCoalesceToTheLatestSettings() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        func window(_ days: Int) -> MailSyncSettings {
            var settings = MailSyncSettings.default
            settings.windowDays = days
            return settings
        }
        service.gate {
            if case .updateSettings = $0 { return true }
            return false
        }
        let before = service.requests.count
        let first = Task { await model.update(accountId: "a1", window(7)) }
        await service.waitForRequests(before + 1)
        // Sent while the first is in flight: only the last of these should reach the service.
        await model.update(accountId: "a1", window(14))
        await model.update(accountId: "a1", window(30))
        #expect(model.accounts.first?.settings == window(30), "applied locally at once")
        service.release()
        await first.value

        let sent = service.requests.compactMap { request -> Int? in
            if case .updateSettings(_, let settings) = request { return settings.windowDays }
            return nil
        }
        #expect(sent == [7, 30])
        #expect(model.accounts.first?.settings == window(30))
        #expect(model.busy == false)
    }

    @Test func aReloadDuringASettingsSendKeepsShowingTheChosenValue() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        var chosen = MailSyncSettings.default
        chosen.windowDays = 7
        service.gate {
            if case .updateSettings = $0 { return true }
            return false
        }
        let before = service.requests.count
        let update = Task { await model.update(accountId: "a1", chosen) }
        await service.waitForRequests(before + 1)
        // Another call's reload lands while the send is still in flight.
        await model.syncNow(accountId: "a1")
        #expect(model.accounts.first?.settings == chosen, "the reload must not flash the old value")
        service.release()
        await update.value
    }

    @Test func cancelSignInSendsCancelWhileSigningIn() async {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        #expect(model.signingIn == false)
        service.gate { $0 == .signIn }
        let before = service.requests.count
        let call = Task { await model.addAccount() }
        await service.waitForRequests(before + 1)
        #expect(model.signingIn == true)
        await model.cancelSignIn()
        #expect(service.requests.contains(.cancelSignIn))
        service.release()
        await call.value
        #expect(model.signingIn == false)
    }

    @Test func importFromURLSendsTheFileBytes() async throws {
        let service = ScriptedMailService(provider: MailProviderStatus(configured: false, clientId: nil))
        let model = GmailSettingsModel(client: service.client)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        let bytes = Data(#"{"installed":{"client_id":"x"}}"#.utf8)
        try bytes.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        await model.importClientJSON(from: url)
        #expect(service.requests.contains(.importOAuthClient(json: bytes)))
        #expect(model.errorMessage == nil)
        #expect(model.provider?.configured == true)
    }

    @Test func importFromMissingURLSetsErrorMessage() async {
        let service = ScriptedMailService(provider: MailProviderStatus(configured: false, clientId: nil))
        let model = GmailSettingsModel(client: service.client)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        await model.importClientJSON(from: url)
        #expect(model.errorMessage?.isEmpty == false)
        #expect(!service.requests.contains { if case .importOAuthClient = $0 { return true } else { return false } })
    }

    @Test func oauthClientTextBeforeTheFirstLoad() {
        let model = GmailSettingsModel(client: ScriptedMailService().client)
        #expect(model.isClientImported == false)
        #expect(model.oauthClientText == "Checking for an OAuth client…")
    }

    @Test func oauthClientTextWhenNoClientIsImported() async {
        let service = ScriptedMailService(provider: MailProviderStatus(configured: false, clientId: nil))
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        #expect(model.isClientImported == false)
        #expect(model.oauthClientText == "Enter the client ID and secret of your Google Cloud Desktop app "
            + "OAuth client, or import its downloaded JSON. One client serves every Gmail account.")
    }

    @Test func theImportedClientIsShownWithTheSecretMasked() async {
        let service = ScriptedMailService(provider: MailProviderStatus(
            configured: true, clientId: "id-9.apps.googleusercontent.com", clientSecretSuffix: "12345"))
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        #expect(model.isClientImported == true)
        #expect(model.oauthClientText == "Gmail signs in with this OAuth client. To change it, enter new "
            + "values below or import a new JSON file.")
        #expect(model.currentClientId == "id-9.apps.googleusercontent.com")
        #expect(model.maskedClientSecret == "••••••••••12345")
    }

    @Test func aSecretTooShortToPartlyShowIsFullyHidden() async {
        let service = ScriptedMailService(provider: MailProviderStatus(configured: true, clientId: "id"))
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        #expect(model.maskedClientSecret == "Stored (hidden)")
    }

    @Test func nothingIsShownWithoutAnImportedClient() async {
        let service = ScriptedMailService(provider: MailProviderStatus(configured: false, clientId: nil))
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        #expect(model.currentClientId == nil)
        #expect(model.maskedClientSecret == nil)
    }

    @Test func replacingTheClientSendsTheNewJSONAndKeepsAccounts() async throws {
        let service = ScriptedMailService(accounts: [.fixture()])
        let model = GmailSettingsModel(client: service.client)
        await model.reload()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        let bytes = Data(#"{"installed":{"client_id":"y"}}"#.utf8)
        try bytes.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        await model.importClientJSON(from: url)
        #expect(service.requests.contains(.importOAuthClient(json: bytes)))
        #expect(model.accounts == [.fixture()])
        #expect(model.errorMessage == nil)
    }

    @Test func savingTheClientFormSendsItAsInstalledJSONAndClearsTheFields() async throws {
        let service = ScriptedMailService(provider: MailProviderStatus(configured: false, clientId: nil))
        let model = GmailSettingsModel(client: service.client)
        model.clientIdDraft = "  id-1.apps.googleusercontent.com \n"
        model.clientSecretDraft = " GOCSPX-secret "
        #expect(model.canSaveClientDraft)
        await model.saveClientDraft()
        let sent = service.requests.compactMap { request -> Data? in
            if case .importOAuthClient(let json) = request { return json }
            return nil
        }
        #expect(sent.count == 1)
        let parsed = try GoogleOAuthClientConfig.parse(json: try #require(sent.first))
        #expect(parsed == GoogleOAuthClientConfig(
            clientId: "id-1.apps.googleusercontent.com", clientSecret: "GOCSPX-secret"))
        #expect(model.clientIdDraft.isEmpty)
        #expect(model.clientSecretDraft.isEmpty)
        #expect(model.errorMessage == nil)
        #expect(model.isClientImported)
    }

    @Test func aRejectedClientKeepsTheFormFilled() async {
        let service = ScriptedMailService(provider: MailProviderStatus(configured: false, clientId: nil))
        service.fail(with: "bad client") {
            if case .importOAuthClient = $0 { return true }
            return false
        }
        let model = GmailSettingsModel(client: service.client)
        model.clientIdDraft = "id"
        model.clientSecretDraft = "secret"
        await model.saveClientDraft()
        #expect(model.errorMessage == "bad client")
        #expect(model.clientIdDraft == "id")
        #expect(model.clientSecretDraft == "secret")
    }

    @Test func anIncompleteClientFormSendsNothing() async {
        let service = ScriptedMailService(provider: MailProviderStatus(configured: false, clientId: nil))
        let model = GmailSettingsModel(client: service.client)
        model.clientIdDraft = "id"
        model.clientSecretDraft = "   "
        #expect(!model.canSaveClientDraft)
        await model.saveClientDraft()
        #expect(model.errorMessage == "Enter both the client ID and the client secret.")
        #expect(!service.requests.contains { if case .importOAuthClient = $0 { return true } else { return false } })
    }

    @Test func dismissErrorClearsIt() async {
        let service = ScriptedMailService()
        service.fail(with: "boom") { $0 == .signIn }
        let model = GmailSettingsModel(client: service.client)
        await model.addAccount()
        model.dismissError()
        #expect(model.errorMessage == nil)
    }
}
