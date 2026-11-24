import XCTest
import Combine
@preconcurrency import Foundation
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors of the settings-storage recipe that the per-provider test files
/// (`InMemorySettingsStoreTests`, `UserDefaultsSettingsStoreTests`, `SqliteStorageProviderTests`,
/// `KeychainSecureSettingsStorageProviderTests`, `SettingsKeyTests`) do not already exercise.
/// Each test name carries its vector id (`testV002` is settings-storage-002).
@MainActor
final class SettingsStorageConformanceTests: XCTestCase {

    // MARK: - Test doubles

    private struct TestKey<Value: Codable & Sendable>: StorableSetting {
        let name: String
        let isSecure: Bool
        let defaultValue: Value
    }

    /// A value whose encoding always fails.
    private struct Unencodable: Codable, Sendable, Equatable {
        struct Failure: Error {}
        init() {}
        init(from decoder: Decoder) throws { self.init() }
        func encode(to encoder: Encoder) throws { throw Failure() }
    }

    /// An in-process stand-in for the iCloud key-value store that records how it was written to.
    private final class FakeUbiquitousStore: NSUbiquitousKeyValueStore {
        var storage: [String: Any] = [:]
        var int64Writes = 0
        var synchronizeCalls = 0

        override func object(forKey aKey: String) -> Any? { storage[aKey] }
        override func data(forKey aKey: String) -> Data? { storage[aKey] as? Data }
        override func set(_ anObject: Any?, forKey aKey: String) { storage[aKey] = anObject }
        override func set(_ value: Int64, forKey aKey: String) {
            int64Writes += 1
            storage[aKey] = value
        }
        override func removeObject(forKey aKey: String) { storage.removeValue(forKey: aKey) }
        override func synchronize() -> Bool {
            synchronizeCalls += 1
            return true
        }
        override var dictionaryRepresentation: [String: Any] { storage }
    }

    // MARK: - Fixtures

    private var originalShared: UserSettings!
    private var originalService: String!
    private var originalAccessGroup: String?
    private var cancellables: Set<AnyCancellable> = []
    private var tempDirectories: [URL] = []

    override func setUp() async throws {
        try await super.setUp()
        originalShared = UserSettings.shared
        originalService = KeychainHelper.service
        originalAccessGroup = KeychainHelper.accessGroup
        UserSettings.shared = makeMemoryUserSettings()
    }

    override func tearDown() async throws {
        cancellables = []
        UserSettings.shared = originalShared
        KeychainHelper.service = originalService
        KeychainHelper.accessGroup = originalAccessGroup
        for directory in tempDirectories { try? FileManager.default.removeItem(at: directory) }
        tempDirectories = []
        originalShared = nil
        originalService = nil
        originalAccessGroup = nil
        try await super.tearDown()
    }

    private func makeMemoryUserSettings() -> UserSettings {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    private func uniqueName(_ prefix: String) -> String {
        "\(prefix)-\(UUID().uuidString)"
    }

    // MARK: - Routing

    func testV002_keysRouteByIsSecure() {
        let plain = InMemorySettingsStorageProvider()
        let secure = InMemorySecureSettingsStorageProvider()
        let store = SettingsStore(with: plain, secureSettingsProvider: secure)
        let plainKey = TestKey<Int>(name: "t.plain", isSecure: false, defaultValue: 0)
        let secureKey = TestKey<String>(name: "t.secret", isSecure: true, defaultValue: "")

        store.set(5, for: plainKey)
        store.set("token", for: secureKey)

        XCTAssertEqual(plain.get(plainKey), 5)
        XCTAssertFalse(secure.contains(TestKey<Int>(name: "t.plain", isSecure: false, defaultValue: 0)))
        XCTAssertEqual(secure.get(secureKey), "token")
        XCTAssertFalse(plain.contains(TestKey<String>(name: "t.secret", isSecure: true, defaultValue: "")))
    }

    func testV030_storeChangesMergeBothProviders() {
        let store = SettingsStore(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        var observed: [String] = []
        store.changes.sink { observed.append($0) }.store(in: &cancellables)

        store.set(1, for: TestKey<Int>(name: "t.merged.plain", isSecure: false, defaultValue: 0))
        store.set("s", for: TestKey<String>(name: "t.merged.secure", isSecure: true, defaultValue: ""))

        XCTAssertEqual(observed, ["t.merged.plain", "t.merged.secure"])
    }

    func testV031_defaultProvidersAreStandardDefaultsAndKeychain() throws {
        throw XCTSkip("""
            The no-argument initialiser binds UserDefaults.standard and the real Keychain, which a unit \
            test must not write to; the routing itself is covered by V002 with injected providers
            """)
    }

    // MARK: - In-memory providers

    func testV009_inMemoryConcurrentAccess() throws {
        throw XCTSkip("""
            InMemorySettingsStorageProvider conforms to a main-actor protocol in its declaration, so its \
            calls are main-actor isolated and a test cannot reach it from concurrent threads
            """)
    }

    func testV011_inMemorySecureDelegatesToInMemory() {
        let secure = InMemorySecureSettingsStorageProvider()
        let key = TestKey<Int>(name: "t.delegate", isSecure: true, defaultValue: 3)
        var changed: [String] = []
        secure.changes.sink { changed.append($0) }.store(in: &cancellables)

        XCTAssertTrue(secure.isSecure)
        XCTAssertEqual(secure.get(key), 3)
        XCTAssertFalse(secure.contains(key))

        secure.set(8, for: key)
        XCTAssertEqual(secure.get(key), 8)
        XCTAssertTrue(secure.contains(key))

        secure.remove(key)
        XCTAssertEqual(secure.get(key), 3)
        XCTAssertFalse(secure.contains(key))
        XCTAssertEqual(changed, ["t.delegate", "t.delegate"])
        XCTAssertTrue(secure.keys(withPrefix: "t.").isEmpty)
    }

    // MARK: - Keychain provider

    func testV017_keychainEncodeFailureDoesNotNotify() {
        KeychainHelper.service = uniqueName("SettingsConformance")
        let provider = KeychainSecureSettingsStorageProvider(service: KeychainHelper.service)
        let key = TestKey<Unencodable>(name: uniqueName("t.unencodable"), isSecure: true, defaultValue: Unencodable())
        var changed: [String] = []
        provider.changes.sink { changed.append($0) }.store(in: &cancellables)

        provider.set(Unencodable(), for: key)

        XCTAssertTrue(changed.isEmpty)
    }

    func testV018_keychainRemoveFailureInvalidatesMemo() throws {
        throw XCTSkip("""
            A secure-store delete failure cannot be forced: KeychainHelper.delete is a static call into \
            the real Keychain with no seam to inject a failing status
            """)
    }

    func testV021_keychainContainsBypassesMemo() {
        let service = uniqueName("SettingsConformance")
        let provider = KeychainSecureSettingsStorageProvider(service: service)
        let name = uniqueName("t.contains")
        let key = TestKey<String>(name: name, isSecure: true, defaultValue: "none")

        XCTAssertEqual(provider.get(key), "none")
        XCTAssertFalse(provider.contains(key))

        KeychainHelper.set("behind", forKey: name)
        defer { KeychainHelper.delete(forKey: name) }

        XCTAssertEqual(provider.get(key), "none")
        XCTAssertTrue(provider.contains(key))
    }

    func testV022_keychainServiceOverrideIsProcessWide() {
        let serviceA = uniqueName("SettingsConformanceA")
        let serviceB = uniqueName("SettingsConformanceB")

        _ = KeychainSecureSettingsStorageProvider(service: serviceA)
        XCTAssertEqual(KeychainHelper.service, serviceA)

        _ = KeychainSecureSettingsStorageProvider(service: serviceB)
        XCTAssertEqual(KeychainHelper.service, serviceB)
    }

    // MARK: - SQLite provider

    func testV025_sqliteTransientBinding() throws {
        throw XCTSkip("""
            Whether a bound string is copied or borrowed is a memory-lifetime property; a round trip \
            passes either way, so a unit test cannot tell the two apart
            """)
    }

    func testV026_sqliteEncodeFailureDoesNotNotifyOrStore() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("SettingsConformance-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        tempDirectories.append(directory)
        let provider = try SqliteStorageProvider(path: directory.appendingPathComponent("s.sqlite").path)
        let key = TestKey<Unencodable>(name: "t.unencodable", isSecure: false, defaultValue: Unencodable())
        var changed: [String] = []
        provider.changes.sink { changed.append($0) }.store(in: &cancellables)

        provider.set(Unencodable(), for: key)

        XCTAssertTrue(changed.isEmpty)
        XCTAssertFalse(provider.contains(key))
    }

    // MARK: - iCloud provider

    func testV027_cloudProviderPromotesIntToInt64() {
        let fake = FakeUbiquitousStore()
        let provider = iCloudSettingsStorageProvider(store: fake)
        let key = TestKey<Int>(name: "t.cloud.int", isSecure: false, defaultValue: 0)

        provider.set(5, for: key)

        XCTAssertEqual(fake.int64Writes, 1)
        XCTAssertTrue(fake.storage["t.cloud.int"] is Int64)
        XCTAssertEqual(provider.get(key), 5)
    }

    func testV028_cloudProviderSynchronizesAndNotifies() {
        let fake = FakeUbiquitousStore()
        let provider = iCloudSettingsStorageProvider(store: fake)
        let key = TestKey<String>(name: "t.cloud.string", isSecure: false, defaultValue: "")
        var changed: [String] = []
        provider.changes.sink { changed.append($0) }.store(in: &cancellables)
        let before = fake.synchronizeCalls

        provider.set("v", for: key)

        XCTAssertEqual(fake.synchronizeCalls, before + 1)
        XCTAssertEqual(changed, ["t.cloud.string"])
    }

    func testV029_cloudProviderForwardsExternalChanges() {
        let fake = FakeUbiquitousStore()
        let provider = iCloudSettingsStorageProvider(store: fake)
        let forwarded = expectation(description: "external change forwarded")
        var changed: [String] = []
        provider.changes.sink { name in
            changed.append(name)
            forwarded.fulfill()
        }.store(in: &cancellables)

        NotificationCenter.default.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: fake,
            userInfo: [NSUbiquitousKeyValueStoreChangedKeysKey: ["someKey"]]
        )

        wait(for: [forwarded], timeout: 2.0)
        XCTAssertEqual(changed, ["someKey"])
    }

    // MARK: - UserSetting

    func testV032_settingReadsThroughOnConstruction() {
        let first = UserSetting<Int>("t.reads", default: 0)
        first.value = 7

        let second = UserSetting<Int>("t.reads", default: 0)

        XCTAssertEqual(second.currentValue, 7)
        XCTAssertEqual(first.currentValue, 7)
    }

    func testV033_settingWritesThrough() {
        let setting = UserSetting<Int>("t.writes", default: 0)
        XCTAssertFalse(setting.existsInStore())

        setting.value = 9

        XCTAssertEqual(UserSettings.shared.get(setting), 9)
        XCTAssertEqual(setting.value, 9)
        XCTAssertTrue(setting.existsInStore())
    }

    func testV034_observerCallbackIsDeferred() {
        let setting = UserSetting<Int>("t.observer", default: 0)
        let fired = expectation(description: "callback fired")
        var received: Int?
        let observer = UserSettingObserver(setting) { newValue in
            received = newValue
            fired.fulfill()
        }

        setting.value = 5

        XCTAssertNil(received, "the callback must not run synchronously inside the write")
        wait(for: [fired], timeout: 2.0)
        XCTAssertEqual(received, 5)
        withExtendedLifetime(observer) {}
    }

    func testV035_observedSettingWrapsObserver() {
        let setting = UserSetting<Int>("t.wrapped", default: 1)
        let wrapper = ObservedSetting(setting) { _ in }

        XCTAssertEqual(wrapper.wrappedValue, 1)
        wrapper.wrappedValue = 4
        XCTAssertEqual(wrapper.wrappedValue, 4)
        XCTAssertEqual(setting.value, 4)
        XCTAssertTrue(wrapper.projectedValue === setting)
    }

    func testV035_colorSettingIsAnObservableSetting() {
        let blue = RGBAColor(red: 0, green: 0, blue: 1, alpha: 1)
        let black = RGBAColor(red: 0, green: 0, blue: 0, alpha: 1)
        let setting: UserSetting<RGBAColor> = ColorSetting("t.color", default: black)

        setting.value = blue

        XCTAssertEqual(setting.currentValue, blue)
        XCTAssertEqual(UserSettings.shared.get(setting), blue)
    }

    func testV036_replacedSharedStoreIsUsedByLaterSettings() {
        let old = UserSettings.shared
        let replacement = makeMemoryUserSettings()
        UserSettings.shared = replacement

        let setting = UserSetting<Int>("t.replaced", default: 0)
        setting.value = 3

        XCTAssertEqual(replacement.get(setting), 3)
        XCTAssertTrue(replacement.contains(setting))
        XCTAssertFalse(old.contains(setting))
        replacement.set(4, for: setting)
        XCTAssertEqual(setting.currentValue, 4)
    }

    // MARK: - Threading

    func testV037_confinedToUIThread() throws {
        throw XCTSkip("""
            The confinement is a compile-time @MainActor guarantee: a use from another thread does not \
            build, and there is no runtime check a test can provoke
            """)
    }
}
