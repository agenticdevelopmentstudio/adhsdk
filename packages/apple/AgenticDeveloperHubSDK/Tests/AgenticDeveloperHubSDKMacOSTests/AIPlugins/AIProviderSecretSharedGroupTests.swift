import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

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
