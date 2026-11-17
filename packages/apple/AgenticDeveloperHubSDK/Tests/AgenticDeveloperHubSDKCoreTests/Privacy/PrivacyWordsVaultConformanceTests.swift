import Foundation
import LocalAuthentication
import Testing
@testable import AgenticDeveloperHubSDKCore

/// A scripted owner: answers every prompt with `result`, counting them.
/// Returns a fresh, unevaluated context on success — enough for an
/// ``InMemoryPrivacyWordStore`` standing in for an old-guarded item.
final class ScriptedOwnerAuthenticator: PrivacyOwnerAuthenticating, @unchecked Sendable {
    enum Result { case succeed, fail }

    private let lock = NSLock()
    private var prompts = 0
    var result: Result
    /// How long each prompt stays up, so tests can overlap two.
    let delay: UInt64

    init(_ result: Result = .succeed, delayNanoseconds: UInt64 = 0) {
        self.result = result
        self.delay = delayNanoseconds
    }

    var promptCount: Int { lock.withLock { prompts } }

    func authenticate(reason: String) async throws -> LAContext? {
        lock.withLock { prompts += 1 }
        if delay > 0 { try? await Task.sleep(nanoseconds: delay) }
        if lock.withLock({ result }) == .fail {
            throw PrivacyWordStore.StoreError.authenticationFailed("cancelled")
        }
        return LAContext()
    }
}

/// A store that fails on demand and counts its reads.
final class FaultyPrivacyWordStore: PrivacyWordStorage, @unchecked Sendable {
    let inner: InMemoryPrivacyWordStore
    private let lock = NSLock()
    private var loads = 0
    var failLoads = false
    var failSaves = false

    init(_ inner: InMemoryPrivacyWordStore = InMemoryPrivacyWordStore()) { self.inner = inner }

    var changeIdentity: String { inner.changeIdentity }
    var loadCount: Int { lock.withLock { loads } }

    func load(context: LAContext?) throws -> [PrivacyWord] {
        lock.withLock { loads += 1 }
        if lock.withLock({ failLoads }) { throw PrivacyWordStore.StoreError.unreadable }
        return try inner.load(context: context)
    }

    func save(_ words: [PrivacyWord]) throws {
        if lock.withLock({ failSaves }) { throw PrivacyWordStore.StoreError.keychain(errSecIO) }
        try inner.save(words)
    }
}

/// Records the change notifications posted for one store, from any process:
/// only what a test asserts on, which crosses isolation as plain values.
@MainActor
final class ChangeNotificationRecorder {
    struct Seen: Sendable {
        let object: String
        let hasUserInfo: Bool
    }

    private(set) var notes: [Seen] = []
    // Touched only on the main actor and in deinit, once nothing else holds it.
    private nonisolated(unsafe) var observer: NSObjectProtocol?

    init(for store: any PrivacyWordStorage) {
        observer = DistributedNotificationCenter.default().addObserver(
            forName: PrivacyWordsVault.changedNotification(for: store), object: nil, queue: .main
        ) { [weak self] note in
            let seen = Seen(object: "\(note.object ?? "")", hasUserInfo: note.userInfo?.isEmpty == false)
            MainActor.assumeIsolated { self?.notes.append(seen) }
        }
    }

    deinit { if let observer { DistributedNotificationCenter.default().removeObserver(observer) } }
}

/// Lets the distributed notification center deliver.
@MainActor
func settleNotifications(_ nanoseconds: UInt64 = 300_000_000) async {
    try? await Task.sleep(nanoseconds: nanoseconds)
}

@MainActor
@Suite("Privacy words vault conformance") struct PrivacyWordsVaultConformanceTests {
    private let secret = PrivacyWord(alias: "Sunflower", real: "Zorblax")
    private let siteWord = PrivacyWord(alias: "Tulip", real: "Quuxcorp", sites: ["example.com/*"])
    private let offWord = PrivacyWord(alias: "Daisy", real: "Hidden", isEnabled: false)

    private func vault(
        _ store: any PrivacyWordStorage = InMemoryPrivacyWordStore(),
        _ owner: ScriptedOwnerAuthenticator = ScriptedOwnerAuthenticator()
    ) -> PrivacyWordsVault {
        PrivacyWordsVault(store: store, authenticator: owner)
    }

    @Test("V1: a new vault has no filter")
    func testV1_newVaultNotLoaded() {
        let subject = vault()
        #expect(subject.filter == nil)
        #expect(subject.isLoaded == false)
    }

    @Test("V2: load over an empty store publishes an empty filter")
    func testV2_loadEmpty() throws {
        let subject = vault()
        #expect(try subject.load())
        #expect(subject.words == [])
        #expect(subject.filter?.pairs.isEmpty == true)
    }

    @Test("V3: load reads the store; the filter holds the enabled global words only")
    func testV3_loadReadsStore() throws {
        let subject = vault(InMemoryPrivacyWordStore(words: [secret, siteWord, offWord]))
        try subject.load()
        #expect(subject.words == [secret, siteWord, offWord])
        #expect(subject.filter?.pairs == [secret.pair])
        #expect(subject.filter(for: URL(string: "https://example.com/a"))?.pairs == [secret.pair, siteWord.pair])
        #expect(subject.everySiteFilter?.pairs == [secret.pair, siteWord.pair])
    }

    @Test("V4: load does not read again once loaded")
    func testV4_loadSilent() throws {
        let store = FaultyPrivacyWordStore(InMemoryPrivacyWordStore(words: [secret]))
        let subject = vault(store)
        try subject.load()
        try subject.load()
        #expect(store.loadCount == 1)
    }

    @Test("V5: load returns false for words under the old guard, without prompting")
    func testV5_loadNeedsAuth() throws {
        let owner = ScriptedOwnerAuthenticator()
        let subject = vault(InMemoryPrivacyWordStore(words: [secret], requiresAuthentication: true), owner)
        #expect(try subject.load() == false)
        #expect(subject.isLoaded == false)
        #expect(owner.promptCount == 0)
    }

    @Test("V6: load propagates an unreadable store")
    func testV6_loadOtherErrors() {
        let store = FaultyPrivacyWordStore()
        store.failLoads = true
        let subject = vault(store)
        #expect(throws: PrivacyWordStore.StoreError.unreadable) { try subject.load() }
        #expect(subject.isLoaded == false)
    }

    @Test("V7: authenticate upgrades words under the old guard, so later loads need no prompt")
    func testV7_authenticateUpgrades() async throws {
        let store = InMemoryPrivacyWordStore(words: [secret], requiresAuthentication: true)
        let subject = vault(store)
        try await subject.authenticate(reason: "test")
        #expect(subject.words == [secret])
        #expect(store.saveCount == 1)
        #expect(try store.load() == [secret])
    }

    @Test("V8: a failed authentication leaves the words unread and the store untouched")
    func testV8_authenticateErrors() async {
        let store = InMemoryPrivacyWordStore(words: [secret])
        let subject = vault(store, ScriptedOwnerAuthenticator(.fail))
        await #expect(throws: PrivacyWordStore.StoreError.self) { try await subject.authenticate(reason: "test") }
        #expect(subject.isLoaded == false)
        #expect(store.saveCount == 0)
    }

    @Test("V9: authenticate reads the words again even when loaded")
    func testV9_authenticateRereads() async throws {
        let store = InMemoryPrivacyWordStore(words: [secret])
        let subject = vault(store)
        try subject.load()
        store.replaceFromOutside([siteWord])
        try await subject.authenticate(reason: "test")
        #expect(subject.words == [siteWord])
    }

    @Test("V10: simultaneous upgrades share one prompt")
    func testV10_upgradeShared() async throws {
        let owner = ScriptedOwnerAuthenticator(delayNanoseconds: 200_000_000)
        let subject = vault(InMemoryPrivacyWordStore(words: [secret], requiresAuthentication: true), owner)
        async let first: Void = subject.loadUpgradingIfNeeded()
        async let second: Void = subject.loadUpgradingIfNeeded()
        _ = try await (first, second)
        #expect(owner.promptCount == 1)
        #expect(subject.words == [secret])
    }

    @Test("V11: every authenticate asks; success is never remembered")
    func testV11_authenticateAlwaysAsks() async throws {
        let owner = ScriptedOwnerAuthenticator()
        let subject = vault(InMemoryPrivacyWordStore(words: [secret]), owner)
        try await subject.authenticate(reason: "one")
        try await subject.authenticate(reason: "two")
        #expect(owner.promptCount == 2)
    }

    @Test("V12: save stores and applies the words and announces the change")
    func testV12_saveApplies() async throws {
        let store = InMemoryPrivacyWordStore()
        let subject = vault(store)
        let recorder = ChangeNotificationRecorder(for: store)
        try subject.save([secret])
        #expect(store.words == [secret])
        #expect(subject.filter?.pairs == [secret.pair])
        await settleNotifications()
        #expect(recorder.notes.count == 1)
    }

    @Test("V13: a vault does not reload from its own post")
    func testV13_ignoreOwnPosts() async throws {
        let store = FaultyPrivacyWordStore()
        let subject = vault(store)
        try subject.save([secret])
        let reads = store.loadCount
        await settleNotifications()
        #expect(store.loadCount == reads)
    }

    @Test("V14: a loaded vault reloads when another process announces a save")
    func testV14_reloadIfLoaded() async throws {
        let store = InMemoryPrivacyWordStore(words: [secret])
        let subject = vault(store)
        try subject.load()
        store.replaceFromOutside([siteWord])
        DistributedNotificationCenter.default().postNotificationName(
            PrivacyWordsVault.changedNotification(for: store),
            object: "not-this-process", userInfo: nil, deliverImmediately: true)
        await settleNotifications()
        #expect(subject.words == [siteWord])
    }

    @Test("V15: a vault that never loaded ignores another process's notification")
    func testV15_neverLoadedIgnoresNotification() async {
        let subject = vault()
        DistributedNotificationCenter.default().postNotificationName(
            PrivacyWordsVault.changedNotification(for: subject.store),
            object: "not-this-process", userInfo: nil, deliverImmediately: true)
        await settleNotifications(200_000_000)
        #expect(subject.filter == nil)
        #expect(subject.isLoaded == false)
    }

    @Test("V16: the keychain's notification name is service.account.changed")
    func testV16_notificationName() {
        let store = PrivacyWordStore(accessGroup: nil, service: "svc", account: "acct")
        #expect(PrivacyWordsVault.changedNotification(for: store).rawValue == "svc.acct.changed")
    }

    @Test("V17: save drops words with an empty alias or real")
    func testV17_saveNormalises() throws {
        let store = InMemoryPrivacyWordStore()
        let subject = vault(store)
        try subject.save([secret, PrivacyWord(alias: "", real: "x"), PrivacyWord(alias: "y", real: "")])
        #expect(store.words == [secret])
        #expect(subject.words == [secret])
    }

    @Test("V18: a cancelled upgrade clears, so the next call prompts again")
    func testV18_upgradeCleared() async throws {
        let owner = ScriptedOwnerAuthenticator(.fail)
        let subject = vault(InMemoryPrivacyWordStore(words: [secret], requiresAuthentication: true), owner)
        await #expect(throws: PrivacyWordStore.StoreError.self) { try await subject.loadUpgradingIfNeeded() }
        owner.result = .succeed
        try await subject.loadUpgradingIfNeeded()
        #expect(owner.promptCount == 2)
        #expect(subject.words == [secret])
    }

    @Test("V19: a store write failure propagates and leaves the words unchanged")
    func testV19_saveStoreError() throws {
        let store = FaultyPrivacyWordStore(InMemoryPrivacyWordStore(words: [secret]))
        let subject = vault(store)
        try subject.load()
        store.failSaves = true
        #expect(throws: PrivacyWordStore.StoreError.self) { try subject.save([siteWord]) }
        #expect(subject.words == [secret])
    }

    @Test("V20: loadUpgradingIfNeeded returns without a prompt when the words load")
    func testV20_loadUpgrading() async throws {
        let owner = ScriptedOwnerAuthenticator()
        let subject = vault(InMemoryPrivacyWordStore(words: [secret]), owner)
        try await subject.loadUpgradingIfNeeded()
        #expect(owner.promptCount == 0)
        #expect(subject.words == [secret])
    }

    @Test("V21: the notification carries no words")
    func testV21_notificationNoWords() async throws {
        let store = InMemoryPrivacyWordStore()
        let subject = vault(store)
        let recorder = ChangeNotificationRecorder(for: store)
        try subject.save([secret])
        await settleNotifications()
        let note = try #require(recorder.notes.first)
        #expect(!note.hasUserInfo)
        let object = note.object
        #expect(!object.contains(secret.real))
        #expect(!object.contains(secret.alias))
    }

    @Test("V22: a failing re-read inside authenticate propagates")
    func testV22_authenticateStoreError() async {
        let store = FaultyPrivacyWordStore()
        store.failLoads = true
        let subject = vault(store)
        await #expect(throws: PrivacyWordStore.StoreError.unreadable) {
            try await subject.authenticate(reason: "test")
        }
        #expect(subject.isLoaded == false)
    }

    // MARK: Replacing the store

    @Test("V23: replaceStore on a loaded vault shows the new store's words at once")
    func testV23_replaceLoaded() throws {
        let subject = vault(InMemoryPrivacyWordStore(words: [secret]))
        try subject.load()
        let owner = ScriptedOwnerAuthenticator()
        subject.replaceStore(InMemoryPrivacyWordStore(words: [siteWord]), authenticator: owner)
        #expect(subject.words == [siteWord])
        #expect(subject.authenticator as? ScriptedOwnerAuthenticator === owner)
    }

    @Test("V24: replaceStore on an unread vault leaves it unread")
    func testV24_replaceUnread() {
        let subject = vault()
        subject.replaceStore(InMemoryPrivacyWordStore(words: [secret]), authenticator: ScriptedOwnerAuthenticator())
        #expect(subject.isLoaded == false)
    }

    @Test("V25: replaceStore onto words that cannot be read silently drops the old ones")
    func testV25_replaceGuarded() throws {
        let subject = vault(InMemoryPrivacyWordStore(words: [secret]))
        try subject.load()
        subject.replaceStore(
            InMemoryPrivacyWordStore(words: [siteWord], requiresAuthentication: true),
            authenticator: ScriptedOwnerAuthenticator())
        #expect(subject.isLoaded == false)
        #expect(subject.filter == nil)
    }

    @Test("V26: after replaceStore the vault hears the new store's notifications, not the old")
    func testV26_replaceMovesObserver() async throws {
        let old = InMemoryPrivacyWordStore(words: [secret])
        let new = InMemoryPrivacyWordStore(words: [siteWord])
        let subject = vault(old)
        try subject.load()
        subject.replaceStore(new, authenticator: ScriptedOwnerAuthenticator())

        old.replaceFromOutside([offWord])
        DistributedNotificationCenter.default().postNotificationName(
            PrivacyWordsVault.changedNotification(for: old), object: "other", userInfo: nil, deliverImmediately: true)
        await settleNotifications()
        #expect(subject.words == [siteWord])

        new.replaceFromOutside([secret, siteWord])
        DistributedNotificationCenter.default().postNotificationName(
            PrivacyWordsVault.changedNotification(for: new), object: "other", userInfo: nil, deliverImmediately: true)
        await settleNotifications()
        #expect(subject.words == [secret, siteWord])
    }

    @Test("V27: save goes to the replacement store")
    func testV27_saveAfterReplace() throws {
        let old = InMemoryPrivacyWordStore()
        let new = InMemoryPrivacyWordStore()
        let subject = vault(old)
        subject.replaceStore(new, authenticator: ScriptedOwnerAuthenticator())
        try subject.save([secret])
        #expect(new.words == [secret])
        #expect(old.words == [])
    }

    @Test("V28: a store swapped while the prompt is up is not read by that authentication")
    func testV28_replaceDuringPrompt() async throws {
        let owner = ScriptedOwnerAuthenticator(delayNanoseconds: 200_000_000)
        let old = FaultyPrivacyWordStore(InMemoryPrivacyWordStore(words: [secret]))
        let subject = vault(old, owner)
        let pending = Task { try await subject.authenticate(reason: "test") }
        try? await Task.sleep(nanoseconds: 50_000_000)
        let new = FaultyPrivacyWordStore(InMemoryPrivacyWordStore(words: [siteWord]))
        subject.replaceStore(new, authenticator: owner)
        try await pending.value
        #expect(old.loadCount == 0)
        #expect(new.loadCount == 0)
        #expect(subject.isLoaded == false)
    }
}
