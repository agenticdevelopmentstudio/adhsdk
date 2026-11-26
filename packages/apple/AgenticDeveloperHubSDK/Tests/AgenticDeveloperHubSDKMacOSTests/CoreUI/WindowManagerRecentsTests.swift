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

    /// Records the limit in memory. `UserDefaults.standard` is one domain for
    /// every process of a parallel run: another worker's
    /// `WindowManager.shared` writing its own count there landed between this
    /// test's write and its read, and the test saw the default 10. The lock in
    /// `setUp` covers only this process. A defaults suite of the test's own
    /// fixed that but left an empty plist in ~/Library/Preferences per run.
    private final class LimitRecorder: RecentDocumentsLimitWriting {
        var values: [String: Int] = [:]
        func set(_ value: Int, forKey defaultName: String) { values[defaultName] = value }
    }

    private var recorder = LimitRecorder()

    private func makeManager() -> WindowManager {
        recorder = LimitRecorder()
        let provider = MockScreenProvider(screens: [])
        return WindowManager(
            screenProvider: provider,
            storage: MockStorage(),
            screenManager: ScreenManager(screenProvider: provider, storage: MockScreenSetStorage()),
            recentDocumentsDefaults: recorder
        )
    }

    func testApplyRecentDocumentCountFromSettingsWritesUserDefault() {
        let prior = UserSettings.recentWindowsCount.currentValue
        defer { UserSettings.recentWindowsCount.value = prior }
        let manager = makeManager()

        UserSettings.recentWindowsCount.value = 7
        manager.applyRecentDocumentCountFromSettings()
        XCTAssertEqual(recorder.values[Self.limitKey], 7)

        UserSettings.recentWindowsCount.value = 3
        manager.applyRecentDocumentCountFromSettings()
        XCTAssertEqual(recorder.values[Self.limitKey], 3)
    }

    func testSettingChangePropagatesViaCombineSink() {
        let prior = UserSettings.recentWindowsCount.currentValue
        defer { UserSettings.recentWindowsCount.value = prior }
        let manager = makeManager()

        UserSettings.recentWindowsCount.value = 12
        let expectation = expectation(description: "user default updated")
        DispatchQueue.main.async {
            XCTAssertEqual(self.recorder.values[Self.limitKey], 12)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        withExtendedLifetime(manager) {}
    }
}
