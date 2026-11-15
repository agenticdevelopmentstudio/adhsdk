import AgenticDeveloperHubSDKCore
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// View ▸ Tab Position: four checked items over `tabs.positions`.
@MainActor
final class TabPositionMenuTests: XCTestCase {

    private func makeSettings(_ positions: TabPositions) -> UserSettings {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        settings.set(positions, for: UserSettings.tabsPositions)
        return settings
    }

    func test_menuHasFourCheckedItemsInOrder() {
        let settings = makeSettings(TabPositions([.top, .right]))
        let items = TabPositionMenu.contributions(settings: settings)

        XCTAssertEqual(items.map(\.title), ["Top", "Left", "Right", "Bottom"])
        XCTAssertTrue(items.allSatisfy { $0.slot == .view })
        XCTAssertTrue(items.allSatisfy { $0.submenu == "Tab Position" })
        XCTAssertEqual(items.map { $0.isChecked?() }, [true, false, true, false])
    }

    func test_uncheckingLastEdgeIsRefused() {
        let settings = makeSettings(TabPositions([.left]))
        let left = TabPositionMenu.contributions(settings: settings)[1]

        left.action()

        XCTAssertEqual(settings.get(UserSettings.tabsPositions).edges, [.left])
        XCTAssertEqual(left.isChecked?(), true)
    }

    func test_menuTogglesEdge() {
        let settings = makeSettings(TabPositions([.top]))
        let bottom = TabPositionMenu.contributions(settings: settings)[3]

        bottom.action()
        XCTAssertEqual(settings.get(UserSettings.tabsPositions).edges, [.top, .bottom])
        XCTAssertEqual(bottom.isChecked?(), true)

        bottom.action()
        XCTAssertEqual(settings.get(UserSettings.tabsPositions).edges, [.top])
        XCTAssertEqual(bottom.isChecked?(), false)
    }
}
