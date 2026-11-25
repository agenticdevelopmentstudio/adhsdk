import XCTest
@testable import AgenticDeveloperHubSDKCore

/// A `UserSetting` mirrors whichever store is `UserSettings.shared`, including
/// one installed after the setting was made.
///
/// A static setting is made the first time anything touches it. When that was
/// while a test had replaced `shared`, the setting used to stay subscribed to
/// the replaced store, so its `currentValue` never saw another write for the
/// rest of the process, and whichever suite happened to run first decided.
@MainActor
final class UserSettingFollowsSharedTests: XCTestCase {

    private var original: UserSettings!

    override func setUp() async throws {
        try await super.setUp()
        await ExclusiveAccess.Resource.userSettings.acquire()
        original = UserSettings.shared
    }

    override func tearDown() async throws {
        UserSettings.shared = original
        await ExclusiveAccess.Resource.userSettings.release()
        try await super.tearDown()
    }

    func testASettingMadeUnderAReplacedStoreSeesWritesToTheNextOne() {
        UserSettings.shared = UserSettings(with: InMemorySettingsStorageProvider())
        let setting = UserSetting<String>("test.follows-shared.\(UUID().uuidString)", default: "")

        UserSettings.shared = UserSettings(with: InMemorySettingsStorageProvider())
        setting.value = "written later"

        XCTAssertEqual(setting.currentValue, "written later")
    }

    func testReplacingSharedRereadsTheValueTheNewStoreHolds() {
        let name = "test.follows-shared.\(UUID().uuidString)"
        let first = UserSettings(with: InMemorySettingsStorageProvider())
        UserSettings.shared = first
        let setting = UserSetting<String>(name, default: "")
        setting.value = "in the first store"

        let second = UserSettings(with: InMemorySettingsStorageProvider())
        second.set("in the second store", for: setting)
        UserSettings.shared = second

        XCTAssertEqual(setting.currentValue, "in the second store")
    }
}
