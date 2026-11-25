import XCTest
import Combine
@testable import AgenticDeveloperHubSDKCore

/// A backend that keeps its values in memory and can be written "from another
/// app", announcing the change as adhd's feed would.
final class FakeSharedSettingsBackend: SharedSettingsBackend, @unchecked Sendable {

    struct LoadFailed: Error {}

    private let lock = NSLock()
    private var values: [String: Data]
    private var continuations: [AsyncStream<String>.Continuation] = []
    private var failsLoad: Bool
    private(set) var writes: [String] = []

    init(values: [String: Data] = [:], failsLoad: Bool = false) {
        self.values = values
        self.failsLoad = failsLoad
    }

    func stored(_ key: String) -> Data? {
        lock.withLock { values[key] }
    }

    /// A write made by another app: stored, then announced.
    func externalSet(_ value: Data, forKey key: String) {
        let listeners = lock.withLock { () -> [AsyncStream<String>.Continuation] in
            values[key] = value
            return continuations
        }
        listeners.forEach { $0.yield(key) }
    }

    func load() async throws -> [String: Data] {
        try lock.withLock {
            if failsLoad { throw LoadFailed() }
            return values
        }
    }

    func value(forKey key: String) async throws -> Data? {
        lock.withLock { values[key] }
    }

    func set(_ value: Data, forKey key: String) async throws {
        let listeners = lock.withLock { () -> [AsyncStream<String>.Continuation] in
            values[key] = value
            writes.append(key)
            return continuations
        }
        listeners.forEach { $0.yield(key) }
    }

    func remove(forKey key: String) async throws {
        let listeners = lock.withLock { () -> [AsyncStream<String>.Continuation] in
            values.removeValue(forKey: key)
            writes.append(key)
            return continuations
        }
        listeners.forEach { $0.yield(key) }
    }

    var changes: AsyncStream<String> {
        let (stream, continuation) = AsyncStream<String>.makeStream()
        lock.withLock { continuations.append(continuation) }
        return stream
    }
}

@MainActor
final class RoutedSettingsStorageProviderTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        // Writes UserSettings.shared, which suites in the other framework share.
        await ExclusiveAccess.Resource.userSettings.acquire()
    }

    override func tearDown() async throws {
        await ExclusiveAccess.Resource.userSettings.release()
        try await super.tearDown()
    }

    private let fontSize = UserSetting<Double>(SharedSettingKeys.terminalFontSize, default: 13)
    private let themeID = UserSetting<String>(SharedSettingKeys.activeThemeID, default: "default-theme")
    private let editorFont = UserSetting<Int>("editor.font_size", default: 12)
    private let configField = UserSetting<String>(
        "aiplugin.config.6F1B1A7E-0000-4000-8000-000000000001.field.baseURL", default: "")

    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    private func json(_ text: String) -> Data { Data(text.utf8) }

    // MARK: - Routing

    func testAnUnroutedKeyGoesToTheFallback() async throws {
        let fallback = InMemorySettingsStorageProvider()
        let backend = FakeSharedSettingsBackend()
        let provider = RoutedSettingsStorageProvider(backend: backend, fallback: fallback)
        try await provider.start()

        provider.set(16, for: editorFont)
        await provider.waitForPendingWrites()

        XCTAssertEqual(fallback.get(editorFont), 16)
        XCTAssertEqual(provider.get(editorFont), 16)
        XCTAssertTrue(backend.writes.isEmpty)
    }

    func testTheAIConfigPrefixIsRouted() {
        XCTAssertTrue(SharedSettingKeys.all.contains(configField.name))
        XCTAssertTrue(SharedSettingKeys.all.contains(SharedSettingKeys.aiProviderConfigurations))
        XCTAssertFalse(SharedSettingKeys.all.contains("aiplugin.selectedConfigurationId"))
        XCTAssertFalse(SharedSettingKeys.all.contains(editorFont.name))
    }

    func testARoutedWriteIsVisibleAtOnceAndReachesTheBackend() async throws {
        let fallback = InMemorySettingsStorageProvider()
        let backend = FakeSharedSettingsBackend()
        let provider = RoutedSettingsStorageProvider(backend: backend, fallback: fallback)
        try await provider.start()

        provider.set(18, for: fontSize)
        // Synchronously, before the backend has answered.
        XCTAssertEqual(provider.get(fontSize), 18)
        XCTAssertTrue(provider.contains(fontSize))

        await provider.waitForPendingWrites()
        XCTAssertEqual(backend.stored(fontSize.name), json("18"))
        XCTAssertFalse(fallback.contains(fontSize), "a routed write never lands in the fallback")
    }

    func testARoutedRemoveReadsTheDefaultAndReachesTheBackend() async throws {
        let backend = FakeSharedSettingsBackend(values: [fontSize.name: json("20")])
        let provider = RoutedSettingsStorageProvider(backend: backend, fallback: InMemorySettingsStorageProvider())
        try await provider.start()
        XCTAssertEqual(provider.get(fontSize), 20)

        provider.remove(fontSize)
        XCTAssertEqual(provider.get(fontSize), 13)
        await provider.waitForPendingWrites()
        XCTAssertNil(backend.stored(fontSize.name))
    }

    func testTheLoadedValuesAnswerRoutedReads() async throws {
        let fallback = InMemorySettingsStorageProvider()
        fallback.set(11, for: fontSize)
        let backend = FakeSharedSettingsBackend(values: [fontSize.name: json("17")])
        let provider = RoutedSettingsStorageProvider(backend: backend, fallback: fallback)

        XCTAssertEqual(provider.get(fontSize), 11, "before the load, the fallback answers")
        try await provider.start()
        XCTAssertEqual(provider.get(fontSize), 17)
        XCTAssertEqual(provider.get(themeID), "default-theme", "a key the backend lacks reads its default")
    }

    func testTheLoadAnnouncesAFallbackOnlyKeyThatNowReadsItsDefault() async throws {
        let fallback = InMemorySettingsStorageProvider()
        fallback.set("solarized-light", for: themeID)
        let provider = RoutedSettingsStorageProvider(backend: FakeSharedSettingsBackend(), fallback: fallback)
        XCTAssertEqual(provider.get(themeID), "solarized-light")

        var announced: [String] = []
        provider.changes.sink { announced.append($0) }.store(in: &cancellables)
        try await provider.start()

        XCTAssertEqual(provider.get(themeID), "default-theme")
        XCTAssertTrue(announced.contains(themeID.name), "a reader of the old value has to hear it changed")
    }

    // MARK: - Backend changes

    func testABackendChangeUpdatesTheCacheAndFiresUserSettingsChanges() async throws {
        let backend = FakeSharedSettingsBackend(values: [fontSize.name: json("13")])
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        let provider = RoutedSettingsStorageProvider(backend: backend, fallback: settings.settingsStorageProvider)
        settings.installSettingsProvider(provider)
        try await provider.start()

        let fired = expectation(description: "UserSettings.changes fires for the shared key")
        settings.changes
            .filter { $0 == SharedSettingKeys.terminalFontSize }
            .sink { _ in fired.fulfill() }
            .store(in: &cancellables)

        backend.externalSet(json("22"), forKey: fontSize.name)
        await fulfillment(of: [fired], timeout: 5)

        XCTAssertEqual(settings.get(fontSize), 22)
    }

    func testTheStaticInstallKeepsExistingSettingsListening() async throws {
        let previous = UserSettings.shared
        UserSettings.shared = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        defer { UserSettings.shared = previous }

        // Made before the install, so it subscribed to the store's changes then.
        let setting = UserSetting<Double>(SharedSettingKeys.terminalFontSize, default: 13)
        let backend = FakeSharedSettingsBackend(values: [setting.name: json("13")])
        let provider = RoutedSettingsStorageProvider(
            backend: backend, fallback: UserSettings.shared.settingsStorageProvider)
        UserSettings.install(routedProvider: provider)
        try await provider.start()

        let updated = expectation(description: "the existing setting sees the shared value")
        setting.$currentValue
            .filter { $0 == 30 }
            .first()
            .sink { _ in updated.fulfill() }
            .store(in: &cancellables)

        backend.externalSet(json("30"), forKey: setting.name)
        await fulfillment(of: [updated], timeout: 5)
    }

    func testTheEchoOfItsOwnWriteIsSilent() async throws {
        let backend = FakeSharedSettingsBackend()
        let provider = RoutedSettingsStorageProvider(backend: backend, fallback: InMemorySettingsStorageProvider())
        try await provider.start()

        var announced: [String] = []
        provider.changes.sink { announced.append($0) }.store(in: &cancellables)

        provider.set(19, for: fontSize)
        await provider.waitForPendingWrites()
        // Let the feed's echo arrive.
        for _ in 0..<20 { await Task.yield() }

        XCTAssertEqual(announced, [fontSize.name])
    }

    // MARK: - Load failure

    func testALoadFailureLeavesTheFallbacksValues() async {
        let fallback = InMemorySettingsStorageProvider()
        fallback.set(15, for: fontSize)
        fallback.set("solarized-light", for: themeID)
        let backend = FakeSharedSettingsBackend(values: [fontSize.name: json("40")], failsLoad: true)
        let provider = RoutedSettingsStorageProvider(backend: backend, fallback: fallback)

        do {
            try await provider.start()
            XCTFail("the load was meant to fail")
        } catch {
            XCTAssertTrue(error is FakeSharedSettingsBackend.LoadFailed)
        }

        XCTAssertFalse(provider.isLoaded)
        XCTAssertEqual(provider.get(fontSize), 15)
        XCTAssertEqual(provider.get(themeID), "solarized-light")
        XCTAssertTrue(provider.contains(themeID))
    }
}
