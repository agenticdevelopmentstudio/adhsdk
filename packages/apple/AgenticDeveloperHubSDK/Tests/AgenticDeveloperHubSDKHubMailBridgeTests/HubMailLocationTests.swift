import XCTest
@testable import AgenticDeveloperHubSDKHubMailBridge

/// The mirror's file and the device id every hub mail app keeps.
final class HubMailLocationTests: XCTestCase {

    private var suite: String!
    private var defaults: UserDefaults!

    override func setUp() {
        suite = "hub-mail-location-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
    }

    func test_app_putsTheMirrorInItsOwnFile_underTheAppsSupportFolder() {
        let location = HubMailLocation.app("Temporal", defaults: defaults)
        XCTAssertEqual(location.databaseURL.lastPathComponent, "hub-mail.db")
        XCTAssertEqual(location.databaseURL.deletingLastPathComponent().lastPathComponent, "Temporal")
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        XCTAssertEqual(
            location.databaseURL.deletingLastPathComponent().deletingLastPathComponent().standardizedFileURL,
            support.standardizedFileURL)
    }

    func test_deviceId_isMadeOnce_andKept() {
        let first = HubMailLocation.deviceId(defaults: defaults)
        XCTAssertFalse(first.isEmpty)
        XCTAssertEqual(defaults.string(forKey: HubMailLocation.defaultDeviceIdKey), first)
        XCTAssertEqual(HubMailLocation.deviceId(defaults: defaults), first)
        XCTAssertEqual(HubMailLocation.app("Temporal", defaults: defaults).deviceId, first)
    }

    func test_deviceId_replacesAnEmptyStoredValue() {
        defaults.set("", forKey: "custom")
        let made = HubMailLocation.deviceId(defaults: defaults, key: "custom")
        XCTAssertFalse(made.isEmpty)
        XCTAssertEqual(defaults.string(forKey: "custom"), made)
    }
}
