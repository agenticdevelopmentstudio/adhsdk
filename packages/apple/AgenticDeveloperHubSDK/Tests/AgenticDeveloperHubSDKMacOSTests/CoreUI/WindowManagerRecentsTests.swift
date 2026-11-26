import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class WindowManagerRecentsTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        // Writes UserSettings.shared, which suites in the other framework share.
        await ExclusiveAccess.Resource.userSettings.acquire()
    }

    override func tearDown() async throws {
        await ExclusiveAccess.Resource.userSettings.release()
        try await super.tearDown()
    }

    private static let limitKey = "NSRecentDocumentsLimit"

    /// A defaults suite of this test's own. `UserDefaults.standard` is one
    /// domain for every process of a parallel run: another worker's
    /// `WindowManager.shared` writing its own count there landed between this
    /// test's write and its read, and the test saw the default 10. The lock in
    /// `setUp` covers only this process.
    private var suiteName = ""
    private var defaults: UserDefaults!

    private func makeManager() -> WindowManager {
        suiteName = "WindowManagerRecentsTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        let provider = MockScreenProvider(screens: [])
        return WindowManager(
            screenProvider: provider,
            storage: MockStorage(),
            screenManager: ScreenManager(screenProvider: provider, storage: MockScreenSetStorage()),
            recentDocumentsDefaults: defaults
        )
    }

    private func removeSuite() {
        defaults?.removePersistentDomain(forName: suiteName)
    }

    func testApplyRecentDocumentCountFromSettingsWritesUserDefault() {
        let prior = UserSettings.recentWindowsCount.currentValue
        defer { UserSettings.recentWindowsCount.value = prior }
        let manager = makeManager()
        defer { removeSuite() }

        UserSettings.recentWindowsCount.value = 7
        manager.applyRecentDocumentCountFromSettings()
        XCTAssertEqual(defaults.integer(forKey: Self.limitKey), 7)

        UserSettings.recentWindowsCount.value = 3
        manager.applyRecentDocumentCountFromSettings()
        XCTAssertEqual(defaults.integer(forKey: Self.limitKey), 3)
    }

    func testSettingChangePropagatesViaCombineSink() {
        let prior = UserSettings.recentWindowsCount.currentValue
        defer { UserSettings.recentWindowsCount.value = prior }
        let manager = makeManager()
        defer { removeSuite() }

        UserSettings.recentWindowsCount.value = 12
        let expectation = expectation(description: "user default updated")
        DispatchQueue.main.async {
            XCTAssertEqual(self.defaults.integer(forKey: Self.limitKey), 12)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        withExtendedLifetime(manager) {}
    }
}
