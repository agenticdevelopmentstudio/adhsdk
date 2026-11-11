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

    func test_settingsApp_hasNoSettingsOfItsOwn() {
        XCTAssertFalse(DesktopSettingsApp(settings: settings).hasSettings)
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

    func test_appearanceRows_alignTheirControlsAtTheTrailingEdge() {
        let controller = makeController()
        controller.view.frame = NSRect(x: 0, y: 0, width: 680, height: 460)
        controller.view.layoutSubtreeIfNeeded()
        let colorWell = controller.appearance.colorWell
        let photo = controller.appearance.photoColumn
        let colorMaxX = colorWell.convert(colorWell.bounds, to: controller.view).maxX
        let photoMaxX = photo.convert(photo.bounds, to: controller.view).maxX
        XCTAssertEqual(photoMaxX, colorMaxX, accuracy: 0.5)
        // Pane inset 20, row inset 12, and the group box's 1pt border.
        XCTAssertEqual(colorMaxX, 680 - 20 - 12 - 1, accuracy: 0.5)
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
        controller.appearance.applyChosenPhoto(url: URL(fileURLWithPath: "/tmp/temporal-none.png"))
        XCTAssertEqual(settings.backgroundImagePath, "/tmp/temporal-none.png")
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
