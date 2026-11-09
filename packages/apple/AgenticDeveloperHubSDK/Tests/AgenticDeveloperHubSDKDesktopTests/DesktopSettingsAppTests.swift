import AppKit
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDesktop

@MainActor
final class DesktopSettingsAppTests: XCTestCase {
    private var settings: DesktopSettings!

    override func setUp() async throws {
        try await super.setUp()
        settings = DesktopSettings(store: UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        ))
    }

    private func makeController() -> DesktopSettingsAppViewController {
        let controller = DesktopSettingsAppViewController(settings: settings)
        _ = controller.view
        return controller
    }

    private func fire(_ control: NSControl) {
        _ = control.sendAction(control.action, to: control.target)
    }

    private func isShown(_ view: NSView, in controller: DesktopSettingsAppViewController) -> Bool {
        var current: NSView? = view
        while let candidate = current {
            if candidate === controller.view { return true }
            current = candidate.superview
        }
        return false
    }

    func test_descriptor() {
        let descriptor = DesktopSettingsApp(settings: settings).descriptor
        XCTAssertEqual(descriptor.identifier, "com.agenticdeveloperhub.desktop.settings")
        XCTAssertEqual(descriptor.displayName, "Settings")
        XCTAssertEqual(descriptor.icon, .symbol(name: "gearshape.fill", tint: "#8E8E93"))
        XCTAssertEqual(descriptor.defaultWindowSize, CGSize(width: 680, height: 460))
        XCTAssertEqual(descriptor.minimumWindowSize, CGSize(width: 560, height: 360))
    }

    func test_sidebar_listsAppearanceThenMenuBar_withAppearanceSelected() {
        let controller = makeController()
        XCTAssertEqual(controller.sidebar.numberOfRows, 2)
        XCTAssertEqual(DesktopSettingsAppViewController.Pane.allCases.map(\.title), ["Appearance", "Menu Bar"])
        XCTAssertEqual(controller.sidebar.selectedRow, 0)
        XCTAssertEqual(controller.selectedPane, .appearance)
        XCTAssertTrue(isShown(controller.appearance.colorWell, in: controller))
        XCTAssertTrue(isShown(controller.appearance.photoColumn, in: controller))
        XCTAssertFalse(isShown(controller.menuStyle.popUp, in: controller))
    }

    func test_selectingMenuBarRow_showsMenuStylePane() {
        let controller = makeController()
        controller.sidebar.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        XCTAssertEqual(controller.selectedPane, .menuBar)
        XCTAssertTrue(isShown(controller.menuStyle.popUp, in: controller))
        XCTAssertFalse(isShown(controller.appearance.colorWell, in: controller))
    }

    func test_menuStylePopUp_writesSetting() {
        let controller = makeController()
        controller.select(.menuBar)
        XCTAssertEqual(controller.menuStyle.popUp.titleOfSelectedItem, "macOS")
        controller.menuStyle.popUp.selectItem(withTitle: "Windows")
        fire(controller.menuStyle.popUp)
        XCTAssertEqual(settings.menuStyle, .windows)
    }

    func test_colorWell_writesDesktopColor() {
        let controller = makeController()
        controller.appearance.colorWell.color = NSColor(desktopHex: "#336699") ?? .black
        fire(controller.appearance.colorWell)
        XCTAssertEqual(settings.backgroundColorHex, "#336699")
    }

    func test_chosenPicture_writesPath_andRemoveClearsIt() {
        let controller = makeController()
        controller.appearance.applyChosenPhoto(url: URL(fileURLWithPath: "/tmp/olylo-none.png"))
        XCTAssertEqual(settings.backgroundImagePath, "/tmp/olylo-none.png")
        XCTAssertTrue(controller.appearance.removePhotoButton.isEnabled)
        fire(controller.appearance.removePhotoButton)
        XCTAssertNil(settings.backgroundImagePath)
    }

    func test_externalChange_updatesControls() {
        let controller = makeController()
        settings.menuStyle = .windows
        settings.backgroundColorHex = "#102030"
        XCTAssertEqual(controller.menuStyle.popUp.titleOfSelectedItem, "Windows")
        XCTAssertEqual(controller.appearance.colorWell.color.desktopHex, "#102030")
    }
}
