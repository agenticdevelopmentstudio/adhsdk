import AppKit
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDesktop

/// The macOS menu style: one menu bar across the top of the Desktop, led by the AI star.
@MainActor
final class DesktopTopMenuBarTests: XCTestCase {
    private var settings: DesktopSettings!
    private var registry: DesktopAppRegistry!
    private var app: StubApp!

    override func setUp() async throws {
        try await super.setUp()
        settings = DesktopSettings(store: UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        ))
        registry = DesktopAppRegistry()
        app = StubApp(identifier: "a", displayName: "Alpha")
        app.menus = [NSMenu(title: "File"), NSMenu(title: "Edit")]
        registry.register(app)
    }

    private func makeController(withSettingsApp: Bool = true) -> DesktopViewController {
        if withSettingsApp { registry.register(DesktopSettingsApp(settings: settings)) }
        let controller = DesktopViewController(registry: registry, settings: settings)
        controller.loadView()
        controller.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        controller.view.layoutSubtreeIfNeeded()
        return controller
    }

    private func titles(_ controller: DesktopViewController) -> [String] {
        controller.topMenuBar.menus.map(\.title)
    }

    private func desktopSettingsItem(_ menu: NSMenu) throws -> NSMenuItem {
        try XCTUnwrap(menu.items.first { $0.title == "Desktop Settings…" })
    }

    func test_macOSStyle_isTheDefault() {
        XCTAssertEqual(settings.menuStyle, .macOS)
    }

    func test_noWindows_showsStarThenDesktopMenu() {
        let controller = makeController()
        let bar = controller.topMenuBar
        XCTAssertFalse(bar.isHidden)
        XCTAssertEqual(titles(controller), ["AI", "Desktop"])
        XCTAssertTrue(bar.isSymbolTitle(at: 0))
        XCTAssertFalse(bar.isSymbolTitle(at: 1))
        XCTAssertEqual(bar.frame, CGRect(x: 0, y: 576, width: 800, height: DesktopMenuBarView.height))
    }

    func test_iconsAndWindows_sitBelowTheTopBar() {
        let controller = makeController()
        XCTAssertEqual(controller.windowLayer.frame, CGRect(x: 0, y: 0, width: 800, height: 576))
    }

    func test_starAndDesktopMenus_eachHoldDesktopSettings() throws {
        let controller = makeController()
        let star = controller.topMenuBar.menus[0]
        let desktop = controller.topMenuBar.menus[1]
        XCTAssertFalse(try desktopSettingsItem(star).isHidden)
        XCTAssertFalse(try desktopSettingsItem(desktop).isHidden)
    }

    func test_desktopSettingsItem_opensSettingsApp() throws {
        let controller = makeController()
        let item = try desktopSettingsItem(controller.topMenuBar.menus[0])
        _ = item.target?.perform(item.action, with: item)
        XCTAssertNotNil(controller.windowController(DesktopSettingsApp.identifier))
        XCTAssertEqual(controller.windowLayer.stack.frontID, DesktopSettingsApp.identifier)
    }

    func test_desktopSettingsItem_isHidden_withoutSettingsApp() throws {
        let controller = makeController(withSettingsApp: false)
        XCTAssertTrue(try desktopSettingsItem(controller.topMenuBar.menus[0]).isHidden)
    }

    func test_openApp_showsItsMenusInTopBar_andNoPerWindowBar() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        XCTAssertEqual(titles(controller), ["AI", "Alpha", "File", "Edit"])
        let chrome = try XCTUnwrap(controller.windowLayer.chrome(for: "a"))
        XCTAssertEqual(chrome.accessoryHeight, 0)
        XCTAssertNil(chrome.accessoryView)
    }

    func test_aboutWindowInFront_keepsOwningAppsMenus() {
        let controller = makeController()
        controller.openApp(identifier: "a")
        controller.showAbout(forApp: "a")
        XCTAssertEqual(controller.windowLayer.stack.frontID, "about:a")
        XCTAssertEqual(titles(controller), ["AI", "Alpha", "File", "Edit"])
    }

    func test_closingLastWindow_revertsToDesktopMenu() {
        let controller = makeController()
        controller.openApp(identifier: "a")
        controller.closeWindow(id: "a")
        XCTAssertEqual(titles(controller), ["AI", "Desktop"])
    }

    func test_switchingToWindowsStyle_restoresPerWindowBars_andHidesTopBar() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        settings.menuStyle = .windows
        let chrome = try XCTUnwrap(controller.windowLayer.chrome(for: "a"))
        XCTAssertEqual(chrome.accessoryHeight, DesktopMenuBarView.height)
        XCTAssertNotNil(chrome.accessoryView)
        XCTAssertTrue(controller.topMenuBar.isHidden)
        XCTAssertEqual(controller.windowLayer.frame, CGRect(x: 0, y: 0, width: 800, height: 600))
        settings.menuStyle = .macOS
        XCTAssertEqual(chrome.accessoryHeight, 0)
        XCTAssertFalse(controller.topMenuBar.isHidden)
        XCTAssertEqual(titles(controller), ["AI", "Alpha", "File", "Edit"])
    }

    func test_windowsStyle_atLaunch_opensWindowsWithTheirOwnBar() throws {
        settings.menuStyle = .windows
        let controller = makeController()
        controller.openApp(identifier: "a")
        XCTAssertTrue(controller.topMenuBar.isHidden)
        let chrome = try XCTUnwrap(controller.windowLayer.chrome(for: "a"))
        XCTAssertEqual(chrome.accessoryHeight, DesktopMenuBarView.height)
    }
}
