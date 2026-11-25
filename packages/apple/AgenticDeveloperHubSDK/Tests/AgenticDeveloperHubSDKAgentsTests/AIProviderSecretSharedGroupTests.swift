import XCTest
import Combine
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKAgents

/// A Keychain location kept in memory, counting its reads.
final class FakeAIProviderSecretKeychain: AIProviderSecretKeychain, @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: String]
    private(set) var reads = 0

    init(items: [String: String] = [:]) {
        self.items = items
    }

    func item(_ account: String) -> String? {
        lock.withLock { items[account] }
    }

    func value(forAccount account: String) -> String? {
        lock.withLock {
            reads += 1
            return items[account]
        }
    }

    func set(_ value: String, forAccount account: String) -> Bool {
        lock.withLock { items[account] = value }
        return true
    }

    func delete(forAccount account: String) -> Bool {
        lock.withLock { _ = items.removeValue(forKey: account) }
        return true
    }

    func exists(forAccount account: String) -> Bool {
        lock.withLock { items[account] != nil }
    }
}

/// A signal fired by hand, standing in for another app's post.
final class FakeCrossProcessSignal: CrossProcessSignal, @unchecked Sendable {
    private let lock = NSLock()
    private var handler: (@Sendable () -> Void)?
    private var postCount = 0

    var posts: Int { lock.withLock { postCount } }

    func post() {
        let handler = lock.withLock { () -> (@Sendable () -> Void)? in
            postCount += 1
            return self.handler
        }
        handler?()
    }

    func observe(_ handler: @escaping @Sendable () -> Void) {
        lock.withLock { self.handler = handler }
    }
}

@MainActor
final class AIProviderSecretSharedGroupTests: XCTestCase {

    private let configID = UUID(uuidString: "6F1B1A7E-0000-4000-8000-000000000002")!
    private var apiKeyName: String { AIProviderConfigStore.fieldKey(config: configID, field: "apiKey") }
    private var apiKey: UserSetting<String> { UserSetting(apiKeyName, default: "", isSecure: true) }
    private let otherSecret = UserSetting<String>("hub.refresh_token", default: "", isSecure: true)

    func testTheSharedGroupIsReadFirst() {
        let shared = FakeAIProviderSecretKeychain(items: [apiKeyName: "sk-shared"])
        let fallback = InMemorySecureSettingsStorageProvider(initial: [apiKeyName: "sk-legacy"])
        let provider = AIProviderSharedSecretsProvider(sharedGroup: shared, fallback: fallback)

        XCTAssertEqual(provider.get(apiKey), "sk-shared")
    }

    func testAMissReadsTheBundleServiceAndCopiesForwardWithoutDeleting() {
        let shared = FakeAIProviderSecretKeychain()
        let fallback = InMemorySecureSettingsStorageProvider(initial: [apiKeyName: "sk-legacy"])
        let provider = AIProviderSharedSecretsProvider(sharedGroup: shared, fallback: fallback)

        XCTAssertEqual(provider.get(apiKey), "sk-legacy")
        XCTAssertEqual(shared.item(apiKeyName), "sk-legacy", "copied into the shared group")
        XCTAssertEqual(fallback.get(apiKey), "sk-legacy", "the app's own copy stays")
    }

    func testASecretInNeitherPlaceReadsEmpty() {
        let shared = FakeAIProviderSecretKeychain()
        let provider = AIProviderSharedSecretsProvider(
            sharedGroup: shared, fallback: InMemorySecureSettingsStorageProvider())

        XCTAssertEqual(provider.get(apiKey), "")
        XCTAssertFalse(provider.contains(apiKey))
        XCTAssertNil(shared.item(apiKeyName))
    }

    func testReadsAreMemoized() {
        let shared = FakeAIProviderSecretKeychain(items: [apiKeyName: "sk-shared"])
        let provider = AIProviderSharedSecretsProvider(
            sharedGroup: shared, fallback: InMemorySecureSettingsStorageProvider())

        _ = provider.get(apiKey)
        _ = provider.get(apiKey)
        XCTAssertEqual(shared.reads, 1)
    }

    func testAWriteGoesToTheSharedGroupOnly() {
        let shared = FakeAIProviderSecretKeychain()
        let fallback = InMemorySecureSettingsStorageProvider()
        let provider = AIProviderSharedSecretsProvider(sharedGroup: shared, fallback: fallback)

        provider.set("sk-new", for: apiKey)
        XCTAssertEqual(shared.item(apiKeyName), "sk-new")
        XCTAssertFalse(fallback.contains(apiKey))
        XCTAssertEqual(provider.get(apiKey), "sk-new")
    }

    func testARemoveClearsBothSoNothingIsCopiedForwardAgain() {
        let shared = FakeAIProviderSecretKeychain(items: [apiKeyName: "sk-shared"])
        let fallback = InMemorySecureSettingsStorageProvider(initial: [apiKeyName: "sk-legacy"])
        let provider = AIProviderSharedSecretsProvider(sharedGroup: shared, fallback: fallback)

        provider.remove(apiKey)
        XCTAssertNil(shared.item(apiKeyName))
        XCTAssertFalse(fallback.contains(apiKey))

        let fresh = AIProviderSharedSecretsProvider(sharedGroup: shared, fallback: fallback)
        XCTAssertEqual(fresh.get(apiKey), "")
    }

    func testAnotherSecureKeyStaysWithTheFallback() {
        let shared = FakeAIProviderSecretKeychain()
        let fallback = InMemorySecureSettingsStorageProvider()
        let provider = AIProviderSharedSecretsProvider(sharedGroup: shared, fallback: fallback)

        provider.set("token", for: otherSecret)
        XCTAssertEqual(fallback.get(otherSecret), "token")
        XCTAssertNil(shared.item(otherSecret.name))
    }

    func testAnotherAppsWriteIsReadAfterItsSignal() async {
        let shared = FakeAIProviderSecretKeychain(items: [apiKeyName: "sk-old"])
        let signal = FakeCrossProcessSignal()
        let provider = AIProviderSharedSecretsProvider(
            sharedGroup: shared, fallback: InMemorySecureSettingsStorageProvider(), changeSignal: signal)
        XCTAssertEqual(provider.get(apiKey), "sk-old")
        var announced: [String] = []
        let subscription = provider.changes.sink { announced.append($0) }

        // Another app rotates the key and posts.
        _ = shared.set("sk-new", forAccount: apiKeyName)
        signal.post()
        for _ in 0..<20 { await Task.yield() }

        XCTAssertEqual(provider.get(apiKey), "sk-new")
        XCTAssertEqual(announced, [apiKeyName])
        subscription.cancel()
    }

    func testItsOwnWritePostsTheSignalAndComesBackSilent() async {
        let signal = FakeCrossProcessSignal()
        let provider = AIProviderSharedSecretsProvider(
            sharedGroup: FakeAIProviderSecretKeychain(), fallback: InMemorySecureSettingsStorageProvider(),
            changeSignal: signal)
        var announced: [String] = []
        let subscription = provider.changes.sink { announced.append($0) }

        provider.set("sk-mine", for: apiKey)
        for _ in 0..<20 { await Task.yield() }

        XCTAssertEqual(signal.posts, 1)
        XCTAssertEqual(announced, [apiKeyName], "only the write's own announcement")
        subscription.cancel()
    }

    func testInstallingTwiceDoesNotStack() {
        let previous = UserSettings.shared
        UserSettings.shared = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        defer { UserSettings.shared = previous }

        XCTAssertFalse(AIProviderConfigStore.useSharedKeychainGroup(nil))
        XCTAssertFalse(UserSettings.shared.secureSettingsStorageProvider is AIProviderSharedSecretsProvider)

        XCTAssertTrue(AIProviderConfigStore.useSharedKeychainGroup("TEAM.com.agenticdevelopmentstudio.shared"))
        let installed = UserSettings.shared.secureSettingsStorageProvider
        XCTAssertTrue(installed is AIProviderSharedSecretsProvider)
        XCTAssertTrue(AIProviderConfigStore.useSharedKeychainGroup("TEAM.com.agenticdevelopmentstudio.shared"))
        XCTAssertTrue(UserSettings.shared.secureSettingsStorageProvider === installed)
    }
}
