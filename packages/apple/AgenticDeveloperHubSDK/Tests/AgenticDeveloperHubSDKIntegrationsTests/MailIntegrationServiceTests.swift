import Foundation
import Testing
import AIPluginKit
import AgenticDeveloperHubSDKDatabase
@testable import AgenticDeveloperHubSDKIntegrations

/// A clock tests move by hand.
private final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Date

    init(_ start: Date) { value = start }

    var now: Date { lock.withLock { value } }

    func advance(minutes: Double) { lock.withLock { value = value.addingTimeInterval(minutes * 60) } }
}

/// Returns a fixed credential, counting calls.
private final class FakeSignIn: GoogleSignInFlow, @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    private let credential: GoogleCredential

    init(credential: GoogleCredential) { self.credential = credential }

    var calls: Int { lock.withLock { count } }

    func signIn(config: GoogleOAuthClientConfig) async throws -> GoogleCredential {
        lock.withLock { count += 1 }
        return credential
    }
}

/// Never expected to be called: the tests' credentials do not expire.
private struct UnusedTokenEndpoint: GoogleTokenEndpoint {
    func refresh(refreshToken: String, config: GoogleOAuthClientConfig) async throws
        -> (accessToken: String, expiresIn: TimeInterval) {
        throw IntegrationError.signInFailed("unexpected refresh")
    }
}

/// An in-memory secret store whose credential writes fail; other keys (the client secret) work.
private final class CredentialRejectingSecretStore: SecretStoring, @unchecked Sendable {
    let inner = InMemorySecretStore()
    func get(forKey key: String) -> String? { inner.get(forKey: key) }
    func set(_ value: String, forKey key: String) -> Bool {
        key.hasSuffix(".credential") ? false : inner.set(value, forKey: key)
    }
    func delete(forKey key: String) -> Bool { inner.delete(forKey: key) }
    func deleteLegacy(forKey key: String) -> Bool { inner.deleteLegacy(forKey: key) }
}

private let start = Date(timeIntervalSince1970: 1_793_000_000)
private let clientJSON = Data("""
    {"installed":{"client_id":"1234567890-abcdefghijkl.apps.googleusercontent.com","client_secret":"shh"}}
    """.utf8)

private struct Harness {
    let service: MailIntegrationService
    let store: IntegrationsStore
    let secrets: any SecretStoring
    let api: FakeGmailAPI
    let clock: TestClock
    let signIn: FakeSignIn

    init(secrets: any SecretStoring = InMemorySecretStore()) throws {
        let store = try IntegrationsStore(database: BoundedDatabase(path: ":memory:"))
        let api = FakeGmailAPI()
        let clock = TestClock(start)
        let signIn = FakeSignIn(credential: GoogleCredential(
            accessToken: "tok", refreshToken: "refresh", expiresAt: start.addingTimeInterval(86_400 * 30)))
        self.store = store
        self.secrets = secrets
        self.api = api
        self.clock = clock
        self.signIn = signIn
        self.service = MailIntegrationService(
            store: store, secrets: secrets, signIn: signIn, tokenEndpoint: UnusedTokenEndpoint(),
            makeAPI: { _ in api }, now: { clock.now })
    }

    func dto(_ id: String, labels: [String], ageDays: Double = 1) -> GmailMessageDTO {
        let millis = Int((start.timeIntervalSince1970 - ageDays * 86_400) * 1000)
        return GmailMessageDTO(
            id: id, threadId: "t-\(id)", labelIds: labels, snippet: "snip \(id)", historyId: "1",
            internalDate: String(millis),
            payload: GmailPart(mimeType: "text/plain", headers: [
                GmailHeader(name: "Subject", value: "subject \(id)"),
                GmailHeader(name: "From", value: "sender@example.com")
            ], body: GmailBody(data: "aGVsbG8")))
    }

    /// Imports the client and signs in, then waits for the sign-in sync to finish.
    @discardableResult
    func connect() async throws -> MailAccount {
        guard case .providerStatus = await service.handle(.importOAuthClient(json: clientJSON)) else {
            Issue.record("import failed")
            throw IntegrationError.notConfigured
        }
        let response = await service.handle(.signIn)
        await service.waitForIdle()
        guard case .account(let account) = response else {
            Issue.record("sign-in returned \(response)")
            throw IntegrationError.signInFailed("test")
        }
        return account
    }

    func account(_ id: String) throws -> IntegrationConnection {
        try #require(try store.connection(idOrEmail: id))
    }

    func liveIds(_ connectionId: String) throws -> Set<String> {
        Set(try store.messages(MessageQuery(connectionId: connectionId, limit: 1000)).map(\.externalId))
    }
}

@Suite("MailIntegrationService")
struct MailIntegrationServiceTests {

    @Test func requestRoundTripsThroughData() async throws {
        let harness = try Harness()
        let request = try JSONEncoder().encode(MailRequest.listAccounts)
        let reply = await harness.service.handle(requestData: request)
        #expect(try JSONDecoder().decode(MailResponse.self, from: reply) == .accounts([]))
    }

    @Test func undecodableRequestIsBadRequest() async throws {
        let harness = try Harness()
        let reply = await harness.service.handle(requestData: Data("nope".utf8))
        #expect(try JSONDecoder().decode(MailResponse.self, from: reply) == .failure("bad request"))
    }

    @Test func signInWithoutProviderFails() async throws {
        let harness = try Harness()
        let response = await harness.service.handle(.signIn)
        guard case .failure(let message) = response else {
            Issue.record("expected failure, got \(response)")
            return
        }
        #expect(message.contains("not configured"))
        #expect(harness.signIn.calls == 0)
    }

    @Test func importReportsProviderStatus() async throws {
        let harness = try Harness()
        #expect(await harness.service.handle(.providerStatus)
            == .providerStatus(MailProviderStatus(configured: false, clientIdHint: nil)))
        let response = await harness.service.handle(.importOAuthClient(json: clientJSON))
        let expected = MailProviderStatus(configured: true, clientIdHint: "rcontent.com")
        #expect(response == .providerStatus(expected))
        #expect(harness.secrets.get(forKey: GoogleTokenProvider.clientSecretKey) == "shh")
        #expect(try harness.store.providerConfig(providerId: "gmail")?.clientId
            == "1234567890-abcdefghijkl.apps.googleusercontent.com")
    }

    @Test func importThenSignInCreatesAccountAndSyncs() async throws {
        let harness = try Harness()
        harness.api.emailAddress = "Me@Example.com"
        harness.api.historyId = "500"
        harness.api.setMessage(harness.dto("a", labels: ["INBOX"]))
        let account = try await harness.connect()

        #expect(account.email == "me@example.com")
        #expect(account.status == .active)
        #expect(account.settings == .default)
        let saved = try harness.account(account.id)
        #expect(saved.syncCursor == "500")
        #expect(saved.lastSyncAt == IntegrationClock.string(from: start))
        #expect(try harness.liveIds(account.id) == ["a"])
        #expect(harness.secrets.get(forKey: GoogleTokenProvider.key(connectionId: account.id)) != nil)
        #expect(await harness.service.handle(.listAccounts) == .accounts([
            MailAccount(id: account.id, email: "me@example.com", status: .active,
                        lastSyncAt: saved.lastSyncAt, lastError: nil, settings: .default)
        ]))
    }

    @Test func reSignInSameEmailReusesAccount() async throws {
        let harness = try Harness()
        let first = try await harness.connect()
        let custom = MailSyncSettings(includeArchived: true, windowDays: 60)
        _ = await harness.service.handle(.updateSettings(account: first.id, settings: custom))
        await harness.service.waitForIdle()
        let cursor = try harness.account(first.id).syncCursor

        let response = await harness.service.handle(.signIn)
        await harness.service.waitForIdle()

        guard case .account(let second) = response else {
            Issue.record("sign-in returned \(response)")
            return
        }
        #expect(second.id == first.id)
        #expect(second.settings == custom)
        #expect(try harness.account(first.id).syncCursor == cursor)
        #expect(try harness.store.connections(provider: "gmail").count == 1)
    }

    @Test func reSignInWithDifferentCaseReusesAccount() async throws {
        let harness = try Harness()
        harness.api.emailAddress = "me@example.com"
        let first = try await harness.connect()
        harness.api.emailAddress = "ME@EXAMPLE.COM"
        let response = await harness.service.handle(.signIn)
        await harness.service.waitForIdle()
        guard case .account(let second) = response else {
            Issue.record("sign-in returned \(response)")
            return
        }
        #expect(second.id == first.id)
        #expect(second.email == "me@example.com")
        #expect(try harness.store.connections(provider: "gmail").count == 1)
        // An email argument matches regardless of case.
        guard case .labels = await harness.service.handle(.listLabels(account: "Me@Example.COM")) else {
            Issue.record("mixed-case email did not resolve")
            return
        }
    }

    @Test func signInFailsWithoutLeavingAConnectionWhenCredentialCannotBeSaved() async throws {
        let harness = try Harness(secrets: CredentialRejectingSecretStore())
        _ = await harness.service.handle(.importOAuthClient(json: clientJSON))
        let response = await harness.service.handle(.signIn)
        await harness.service.waitForIdle()
        #expect(response == .failure("Sign-in failed: Could not save the Google credential to the Keychain"))
        #expect(try harness.store.connections(provider: "gmail").isEmpty)
    }

    @Test func runDueSyncsRespectsPollInterval() async throws {
        let harness = try Harness()
        let account = try await harness.connect()
        let calls = harness.api.labelsCalls
        #expect(calls == 1)

        harness.clock.advance(minutes: 14)
        await harness.service.runDueSyncs()
        #expect(harness.api.labelsCalls == calls)

        harness.clock.advance(minutes: 1)
        await harness.service.runDueSyncs()
        #expect(harness.api.labelsCalls == calls + 1)
        #expect(try harness.account(account.id).lastSyncAt
            == IntegrationClock.string(from: start.addingTimeInterval(15 * 60)))
    }

    @Test func revokedTokenMarksAccountRevokedAndStopsSyncing() async throws {
        let harness = try Harness()
        let account = try await harness.connect()
        harness.api.labelsError = IntegrationError.revoked
        harness.clock.advance(minutes: 15)
        await harness.service.runDueSyncs()

        let saved = try harness.account(account.id)
        #expect(saved.status == .revoked)
        #expect(saved.lastError == "Google access was revoked — sign in again")
        let calls = harness.api.labelsCalls

        harness.clock.advance(minutes: 60)
        await harness.service.runDueSyncs()
        #expect(harness.api.labelsCalls == calls)
    }

    @Test func otherSyncErrorMarksAccountErrorAndRetries() async throws {
        let harness = try Harness()
        let account = try await harness.connect()
        harness.api.listMessageIdsError = IntegrationError.gmail(status: 500, message: "boom")
        _ = await harness.service.handle(.updateSettings(
            account: account.id, settings: MailSyncSettings(includeArchived: true)))
        await harness.service.waitForIdle()
        let saved = try harness.account(account.id)
        #expect(saved.status == .error)
        #expect(saved.lastError == "Gmail returned 500: boom")

        harness.api.listMessageIdsError = nil
        harness.clock.advance(minutes: 15)
        await harness.service.runDueSyncs()
        #expect(try harness.account(account.id).status == .active)
        #expect(try harness.account(account.id).lastError == nil)
    }

    @Test func revokedProfileAtSignInFails() async throws {
        let harness = try Harness()
        _ = await harness.service.handle(.importOAuthClient(json: clientJSON))
        harness.api.profileError = IntegrationError.revoked
        #expect(await harness.service.handle(.signIn) == .failure("Google access was revoked — sign in again"))
        #expect(try harness.store.connections(provider: "gmail").isEmpty)
    }

    @Test func syncNowBypassesDueness() async throws {
        let harness = try Harness()
        let account = try await harness.connect()
        let calls = harness.api.labelsCalls
        let response = await harness.service.handle(.syncNow(account: nil))
        #expect(harness.api.labelsCalls == calls + 1)
        guard case .accounts(let accounts) = response else {
            Issue.record("syncNow returned \(response)")
            return
        }
        #expect(accounts.map(\.id) == [account.id])
    }

    @Test func disablingArchivedTombstonesArchivedRows() async throws {
        let harness = try Harness()
        harness.api.setMessage(harness.dto("filed", labels: ["INBOX"]))
        harness.api.setMessage(harness.dto("old", labels: ["CATEGORY_UPDATES"]))
        let account = try await harness.connect()
        _ = await harness.service.handle(.updateSettings(
            account: account.id, settings: MailSyncSettings(includeArchived: true)))
        await harness.service.waitForIdle()
        #expect(try harness.liveIds(account.id) == ["filed", "old"])
        let cursor = try harness.account(account.id).syncCursor

        // Stop the follow-up sync from re-adding anything, so the tombstone is what is observed.
        harness.api.historyPages = []
        _ = await harness.service.handle(.updateSettings(account: account.id, settings: .default))
        await harness.service.waitForIdle()

        #expect(try harness.liveIds(account.id) == ["filed"])
        // Narrowing alone keeps the cursor: the next sync is incremental.
        #expect(try harness.account(account.id).syncCursor == cursor)
        #expect(harness.api.historyCalls.last == cursor)
    }

    @Test func enablingSpamClearsCursor() async throws {
        let harness = try Harness()
        let account = try await harness.connect()
        harness.api.historyId = "777"
        let lists = harness.api.listCalls.count
        let response = await harness.service.handle(.updateSettings(
            account: account.id, settings: MailSyncSettings(includeSpam: true)))
        guard case .account(let updated) = response else {
            Issue.record("updateSettings returned \(response)")
            return
        }
        #expect(updated.settings.includeSpam)
        await harness.service.waitForIdle()
        // A cleared cursor means a full sync, which lists messages and takes the new baseline.
        #expect(harness.api.listCalls.count == lists + 1)
        #expect(harness.api.listCalls.last?.includeSpamTrash == true)
        #expect(try harness.account(account.id).syncCursor == "777")
    }

    @Test func wideningWindowClearsCursor() async throws {
        let harness = try Harness()
        let account = try await harness.connect()
        let lists = harness.api.listCalls.count
        _ = await harness.service.handle(.updateSettings(
            account: account.id, settings: MailSyncSettings(windowDays: 90)))
        await harness.service.waitForIdle()
        #expect(harness.api.listCalls.count == lists + 1)
    }

    @Test func invalidSettingsFail() async throws {
        let harness = try Harness()
        let account = try await harness.connect()
        let response = await harness.service.handle(.updateSettings(
            account: account.id, settings: MailSyncSettings(windowDays: 0)))
        #expect(response == .failure("Invalid sync settings: windowDays must be 1–3650, got 0"))
        #expect(try harness.account(account.id).syncSettings == .default)
    }

    private func labelled(_ harness: Harness) async throws -> MailAccount {
        harness.api.labels = [
            GmailLabelDTO(id: "INBOX", name: "INBOX", type: "system"),
            GmailLabelDTO(id: "STARRED", name: "STARRED", type: "system"),
            GmailLabelDTO(id: "Label_1", name: "Work", type: "user"),
            GmailLabelDTO(id: "Label_2", name: "Work/Projects", type: "user")
        ]
        harness.api.setMessage(harness.dto("m1", labels: ["INBOX"]))
        harness.api.setMessage(harness.dto("m2", labels: ["INBOX", "Label_1"]))
        return try await harness.connect()
    }

    @Test func modifyLabelsResolvesNamesAndRefreshesMessages() async throws {
        let harness = try Harness()
        let account = try await labelled(harness)
        let local = try #require(try harness.store.message(connectionId: account.id, idOrExternalId: "m1"))

        let response = await harness.service.handle(.modifyLabels(
            account: account.email, messageIds: [local.id, "m2"], add: ["Work/Projects", "STARRED"],
            remove: ["INBOX"]))

        #expect(harness.api.batchModifyCalls == [
            FakeGmailAPI.BatchModifyCall(ids: ["m1", "m2"], add: ["Label_2", "STARRED"], remove: ["INBOX"])
        ])
        guard case .messages(let page) = response else {
            Issue.record("modifyLabels returned \(response)")
            return
        }
        #expect(page.messages.map(\.gmailId) == ["m1", "m2"])
        #expect(page.messages[0].id == local.id)
        #expect(page.messages[0].labels == ["Label_2", "STARRED"])
        #expect(page.messages[0].labelNames == ["Work/Projects", "STARRED"])
        #expect(page.messages[1].labelNames == ["Work", "Work/Projects", "STARRED"])
        let stored = try #require(try harness.store.message(connectionId: account.id, idOrExternalId: "m2"))
        #expect(stored.labelIds == ["Label_1", "Label_2", "STARRED"])
    }

    @Test func modifyLabelsTombstonesMessagesThatAreNoLongerMirrored() async throws {
        let harness = try Harness()
        let account = try await labelled(harness)
        let response = await harness.service.handle(.modifyLabels(
            account: account.id, messageIds: ["m1"], add: [], remove: ["INBOX"]))
        guard case .messages(let page) = response else {
            Issue.record("modifyLabels returned \(response)")
            return
        }
        #expect(page.messages.first?.mailClass == .archived)
        #expect(try harness.liveIds(account.id) == ["m2"])
    }

    @Test func modifyLabelsRejectsUnknownLabelBeforeCallingGmail() async throws {
        let harness = try Harness()
        let account = try await labelled(harness)
        let response = await harness.service.handle(.modifyLabels(
            account: account.id, messageIds: ["m1"], add: ["work"], remove: []))
        #expect(response == .failure("unknown label: work"))
        #expect(harness.api.batchModifyCalls.isEmpty)
    }

    @Test func modifyLabelsRejectsUnknownMessageBeforeCallingGmail() async throws {
        let harness = try Harness()
        let account = try await labelled(harness)
        let response = await harness.service.handle(.modifyLabels(
            account: account.id, messageIds: ["nope"], add: ["Work"], remove: []))
        #expect(response == .failure("No message matches “nope”"))
        #expect(harness.api.batchModifyCalls.isEmpty)
    }

    @Test func modifyLabelsWithNoLabelsReturnsMessagesUnchanged() async throws {
        let harness = try Harness()
        let account = try await labelled(harness)
        let response = await harness.service.handle(.modifyLabels(
            account: account.id, messageIds: ["m1"], add: [], remove: []))
        guard case .messages(let page) = response else {
            Issue.record("modifyLabels returned \(response)")
            return
        }
        #expect(page.messages.map(\.gmailId) == ["m1"])
        #expect(page.messages.first?.labels == ["INBOX"])
        #expect(harness.api.batchModifyCalls.isEmpty)
    }

    @Test func modifyLabelsChunksBatchModifyAtOneThousand() async throws {
        let harness = try Harness()
        harness.api.labels = [GmailLabelDTO(id: "STARRED", name: "STARRED", type: "system")]
        let ids = (0..<2_500).map { String(format: "m%04d", $0) }
        for id in ids { harness.api.setMessage(harness.dto(id, labels: ["INBOX"])) }
        let account = try await harness.connect()

        let response = await harness.service.handle(.modifyLabels(
            account: account.id, messageIds: ids, add: ["STARRED"], remove: []))

        #expect(harness.api.batchModifyCalls.map(\.ids.count) == [1_000, 1_000, 500])
        #expect(harness.api.batchModifyCalls.flatMap(\.ids) == ids)
        guard case .messages(let page) = response else {
            Issue.record("modifyLabels returned \(response)")
            return
        }
        #expect(page.messages.count == 2_500)
    }

    @Test func modifyLabelsRevokedMarksAccountRevoked() async throws {
        let harness = try Harness()
        let account = try await labelled(harness)
        harness.api.batchModifyError = IntegrationError.revoked
        let response = await harness.service.handle(.modifyLabels(
            account: account.id, messageIds: ["m1"], add: ["Work"], remove: []))
        #expect(response == .failure("Google access was revoked — sign in again"))
        let saved = try harness.account(account.id)
        #expect(saved.status == .revoked)
        #expect(saved.lastError == "Google access was revoked — sign in again")
    }

    @Test func listLabelsMapsStoreRows() async throws {
        let harness = try Harness()
        let account = try await labelled(harness)
        let response = await harness.service.handle(.listLabels(account: account.id))
        guard case .labels(let labels) = response else {
            Issue.record("listLabels returned \(response)")
            return
        }
        #expect(labels.contains(MailLabel(id: "Label_2", name: "Work/Projects", type: "user",
                                          parentName: "Work", messagesTotal: nil, messagesUnread: nil)))
    }

    @Test func listMessagesFiltersAndPages() async throws {
        let harness = try Harness()
        harness.api.labels = [GmailLabelDTO(id: "Label_1", name: "Work", type: "user")]
        for day in 1...5 {
            harness.api.setMessage(harness.dto("w\(day)", labels: ["Label_1"], ageDays: Double(day)))
        }
        harness.api.setMessage(harness.dto("inbox", labels: ["INBOX"], ageDays: 1.5))
        let account = try await harness.connect()

        var filter = MailMessageFilter(account: account.email, labels: ["Work"], limit: 2)
        guard case .messages(let first) = await harness.service.handle(.listMessages(filter)) else {
            Issue.record("listMessages failed")
            return
        }
        #expect(first.messages.map(\.gmailId) == ["w1", "w2"])
        #expect(first.nextCursor == "2")
        #expect(first.messages.allSatisfy { $0.bodyText == nil && $0.bodyHtml == nil })
        #expect(first.messages.first?.labelNames == ["Work"])
        #expect(first.messages.first?.account == account.email)

        filter.cursor = first.nextCursor
        guard case .messages(let second) = await harness.service.handle(.listMessages(filter)) else {
            Issue.record("listMessages failed")
            return
        }
        #expect(second.messages.map(\.gmailId) == ["w3", "w4"])
        #expect(second.nextCursor == "4")

        filter.cursor = second.nextCursor
        guard case .messages(let third) = await harness.service.handle(.listMessages(filter)) else {
            Issue.record("listMessages failed")
            return
        }
        #expect(third.messages.map(\.gmailId) == ["w5"])
        #expect(third.nextCursor == nil)

        let since = IntegrationClock.string(from: start.addingTimeInterval(-2.5 * 86_400))
        let bounded = MailMessageFilter(account: account.id, since: since, includeBodies: true)
        guard case .messages(let recent) = await harness.service.handle(.listMessages(bounded)) else {
            Issue.record("listMessages failed")
            return
        }
        #expect(recent.messages.map(\.gmailId) == ["w1", "inbox", "w2"])
        #expect(recent.messages.first?.bodyText == "hello")
    }

    @Test func messageFilterClampsLimit() throws {
        #expect(MailMessageFilter(account: "a", limit: 0).limit == 1)
        #expect(MailMessageFilter(account: "a", limit: 9_999).limit == 500)
        let decoded = try JSONDecoder().decode(MailMessageFilter.self, from: Data(#"{"account":"a"}"#.utf8))
        #expect(decoded == MailMessageFilter(account: "a"))
        #expect(decoded.limit == 50)
        #expect(decoded.includeBodies == false)
    }

    @Test func getMessageByGmailId() async throws {
        let harness = try Harness()
        harness.api.setMessage(harness.dto("g1", labels: ["INBOX"]))
        let account = try await harness.connect()
        let response = await harness.service.handle(.getMessage(account: account.id, id: "g1"))
        guard case .message(let message) = response else {
            Issue.record("getMessage returned \(response)")
            return
        }
        #expect(message.gmailId == "g1")
        #expect(message.threadId == "t-g1")
        #expect(message.subject == "subject g1")
        #expect(message.from == "sender@example.com")
        #expect(message.bodyText == "hello")
        #expect(message.mailClass == .filed)
        #expect(await harness.service.handle(.getMessage(account: account.id, id: message.id)) == response)
        #expect(await harness.service.handle(.getMessage(account: account.id, id: "zz"))
            == .failure("No message matches “zz”"))
    }

    @Test func removeAccountForgetsCredentialAndDeletesConnection() async throws {
        let harness = try Harness()
        let account = try await harness.connect()
        #expect(await harness.service.handle(.removeAccount(account: account.email)) == .ok)
        #expect(harness.secrets.get(forKey: GoogleTokenProvider.key(connectionId: account.id)) == nil)
        #expect(await harness.service.handle(.listAccounts) == .accounts([]))
    }

    @Test func removeProviderClearsEverything() async throws {
        let harness = try Harness()
        let account = try await harness.connect()
        #expect(await harness.service.handle(.removeProvider) == .ok)
        #expect(await harness.service.handle(.listAccounts) == .accounts([]))
        #expect(harness.secrets.get(forKey: GoogleTokenProvider.clientSecretKey) == nil)
        #expect(harness.secrets.get(forKey: GoogleTokenProvider.key(connectionId: account.id)) == nil)
        #expect(try harness.store.providerConfig(providerId: "gmail") == nil)
        #expect(await harness.service.handle(.providerStatus)
            == .providerStatus(MailProviderStatus(configured: false, clientIdHint: nil)))
    }

    @Test func unknownAccountFails() async throws {
        let harness = try Harness()
        #expect(await harness.service.handle(.listLabels(account: "who"))
            == .failure("No connected account matches “who”"))
    }

    @Test func mailClientThrowsOnFailure() async throws {
        let harness = try Harness()
        let service = harness.service
        let client = MailClient { await service.handle(requestData: $0) }
        #expect(try await client.accounts() == [])
        #expect(try await client.providerStatus() == MailProviderStatus(configured: false, clientIdHint: nil))
        await #expect(throws: MailClientError.remote("No connected account matches “x”")) {
            try await client.labels(account: "x")
        }
        #expect(MailClientError.remote("boom").localizedDescription == "boom")
    }
}
