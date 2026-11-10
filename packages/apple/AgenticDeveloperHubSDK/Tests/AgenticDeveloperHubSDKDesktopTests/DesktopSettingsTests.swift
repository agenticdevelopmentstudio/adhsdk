import Combine
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDesktop

@MainActor
final class DesktopSettingsTests: XCTestCase {
    private var store: UserSettings!

    override func setUp() async throws {
        try await super.setUp()
        store = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    func test_desktopSettings_defaults() {
        let settings = DesktopSettings(store: store)
        XCTAssertEqual(settings.backgroundColorHex, "#3A6EA5")
        XCTAssertNil(settings.backgroundImagePath)
        XCTAssertEqual(settings.iconArrangement, .largeIcons)
        XCTAssertTrue(settings.keepArranged)
        XCTAssertEqual(settings.iconPositions, [:])
        XCTAssertEqual(settings.windowFrames, [:])
        XCTAssertEqual(settings.menuStyle, .macOS)
    }

    func test_menuStyle_roundTrips_andPublishesChange() {
        let settings = DesktopSettings(store: store)
        var fired = 0
        let subscription = settings.changes.sink { fired += 1 }
        settings.menuStyle = .windows
        XCTAssertEqual(settings.menuStyle, .windows)
        XCTAssertEqual(DesktopSettings(store: store).menuStyle, .windows)
        XCTAssertEqual(fired, 1)
        withExtendedLifetime(subscription) {}
    }

    func test_desktopSettings_scalarsRoundTrip() {
        let settings = DesktopSettings(store: store)
        settings.backgroundColorHex = "#000000"
        settings.backgroundImagePath = "/tmp/x.png"
        settings.iconArrangement = .list
        settings.keepArranged = false
        XCTAssertEqual(settings.backgroundColorHex, "#000000")
        XCTAssertEqual(settings.backgroundImagePath, "/tmp/x.png")
        XCTAssertEqual(settings.iconArrangement, .list)
        XCTAssertFalse(settings.keepArranged)
        settings.backgroundImagePath = nil
        XCTAssertNil(settings.backgroundImagePath)
    }

    func test_desktopSettings_positionsAndFrames_roundTrip() {
        let settings = DesktopSettings(store: store)
        settings.iconPositions = ["a": CGPoint(x: 10, y: 20)]
        settings.windowFrames = ["a": CGRect(x: 1, y: 2, width: 300, height: 400)]
        XCTAssertEqual(settings.iconPositions["a"], CGPoint(x: 10, y: 20))
        XCTAssertEqual(settings.windowFrames["a"], CGRect(x: 1, y: 2, width: 300, height: 400))
    }

    func test_turningKeepArrangedOff_withNoDesktopOnScreen_dropsStalePositions() {
        let settings = DesktopSettings(store: store)
        settings.keepArranged = false
        settings.iconPositions = ["a": CGPoint(x: 300, y: 200)]
        settings.keepArranged = true
        XCTAssertEqual(settings.iconPositions["a"], CGPoint(x: 300, y: 200))
        settings.keepArranged = false
        XCTAssertEqual(settings.iconPositions, [:])
        // Writing false again keeps positions placed while free.
        settings.iconPositions = ["a": CGPoint(x: 40, y: 50)]
        settings.keepArranged = false
        XCTAssertEqual(settings.iconPositions["a"], CGPoint(x: 40, y: 50))
    }

    func test_desktopSettings_changes_emitsOnWrite() {
        let settings = DesktopSettings(store: store)
        var count = 0
        let sub = settings.changes.sink { count += 1 }
        settings.keepArranged = false
        XCTAssertEqual(count, 1)
        sub.cancel()
    }

    func test_clearingBackgroundImagePath_removesTheKey() {
        let settings = DesktopSettings(store: store)
        settings.backgroundImagePath = "/tmp/x.png"
        XCTAssertEqual(store.keys(withPrefix: "desktop.backgroundImagePath"), ["desktop.backgroundImagePath"])
        settings.backgroundImagePath = nil
        XCTAssertEqual(store.keys(withPrefix: "desktop.backgroundImagePath"), [])
        XCTAssertNil(settings.backgroundImagePath)
    }
}
