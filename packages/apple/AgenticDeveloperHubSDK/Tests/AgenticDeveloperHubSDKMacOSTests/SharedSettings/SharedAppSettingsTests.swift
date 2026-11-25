import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// `SharedAppSettings`: building one routes the shared keys of
/// `UserSettings.shared` through the backend and leaves every other key in
/// the app's own store; `start` loads the backend's values, retrying a load
/// that fails.
@MainActor
final class SharedAppSettingsTests: XCTestCase {

    /// adhd's shared settings in memory; its first `failures` loads fail.
    private final class Backend: SharedSettingsBackend, @unchecked Sendable {
        struct Unreachable: Error {}

        private let lock = NSLock()
        private var values: [String: Data]
        private var failures: Int
        private(set) var loads = 0

        init(values: [String: Data] = [:], failures: Int = 0) {
            self.values = values
            self.failures = failures
        }

        func load() async throws -> [String: Data] {
            try lock.withLock {
                loads += 1
                if failures > 0 {
                    failures -= 1
                    throw Unreachable()
                }
                return values
            }
        }

        func value(forKey key: String) async throws -> Data? { lock.withLock { values[key] } }
        func set(_ value: Data, forKey key: String) async throws { lock.withLock { values[key] = value } }
        func remove(forKey key: String) async throws { _ = lock.withLock { values.removeValue(forKey: key) } }
        var changes: AsyncStream<String> { AsyncStream { _ in } }
    }

    private var previousSettings: UserSettings!
    private var ownProvider: InMemorySettingsStorageProvider!
    private let fontSize = UserSetting<Double>(SharedSettingKeys.terminalFontSize, default: 13)
    private let editorFont = UserSetting<Int>("editor.font_size", default: 12)

    override func setUp() async throws {
        try await super.setUp()
        await ExclusiveAccess.Resource.userSettings.acquire()
        previousSettings = UserSettings.shared
        ownProvider = InMemorySettingsStorageProvider()
        UserSettings.shared = UserSettings(
            with: ownProvider, secureSettingsProvider: InMemorySecureSettingsStorageProvider())
    }

    override func tearDown() async throws {
        UserSettings.shared = previousSettings
        await ExclusiveAccess.Resource.userSettings.release()
        try await super.tearDown()
    }

    func testBuildingOneInstallsTheRoutedProviderOverTheAppsOwnStore() {
        let shared = SharedAppSettings(backend: Backend())

        XCTAssertTrue(UserSettings.shared.settingsStorageProvider as? RoutedSettingsStorageProvider === shared.provider)
        XCTAssertTrue(shared.provider.fallback as? InMemorySettingsStorageProvider === ownProvider)
    }

    func testAnUnsharedKeyStaysInTheAppsOwnStore() {
        _ = SharedAppSettings(backend: Backend())

        editorFont.value = 15

        XCTAssertEqual(ownProvider.get(editorFont), 15)
    }

    func testStartRetriesAFailedLoadThenAnswersWithTheBackendsValues() async throws {
        let backend = Backend(values: [fontSize.name: Data("30".utf8)], failures: 2)
        let shared = SharedAppSettings(backend: backend)
        var failures = 0

        shared.start(every: .milliseconds(10)) { _ in failures += 1 }
        let deadline = Date().addingTimeInterval(5)
        while !shared.provider.isLoaded, Date() < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        shared.stop()

        XCTAssertTrue(shared.provider.isLoaded)
        XCTAssertEqual(failures, 2)
        XCTAssertEqual(backend.loads, 3)
        XCTAssertEqual(fontSize.value, 30)
    }
}
