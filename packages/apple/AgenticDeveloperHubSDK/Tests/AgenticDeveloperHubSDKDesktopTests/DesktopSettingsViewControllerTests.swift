import AppKit
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDesktop

@MainActor
final class DesktopSettingsViewControllerTests: XCTestCase {
    private var store: UserSettings!
    private var settings: DesktopSettings!

    override func setUp() async throws {
        try await super.setUp()
        store = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        settings = DesktopSettings(store: store)
    }

    private func makeController() -> DesktopSettingsViewController {
        let controller = DesktopSettingsViewController(settings: settings)
        _ = controller.view
        return controller
    }

    private func fire(_ control: NSControl) {
        _ = control.sendAction(control.action, to: control.target)
    }

    func test_controls_reflectCurrentSettings() {
        settings.backgroundColorHex = "#102030"
        settings.iconArrangement = .smallIcons
        settings.keepArranged = false
        settings.backgroundImagePath = "/tmp/olylo-none.png"
        let controller = makeController()
        XCTAssertEqual(controller.colorWell.color.desktopHex, "#102030")
        XCTAssertEqual(controller.arrangePopUp.titleOfSelectedItem, "Small Icons")
        XCTAssertEqual(controller.keepArrangedCheckbox.state, .off)
        XCTAssertTrue(controller.removePhotoButton.isEnabled)
        XCTAssertEqual(controller.arrangePopUp.itemTitles, ["Large Icons", "Small Icons", "List"])
    }

    func test_selectingList_disablesKeepArranged() {
        let controller = makeController()
        XCTAssertTrue(controller.keepArrangedCheckbox.isEnabled)
        controller.arrangePopUp.selectItem(withTitle: "List")
        fire(controller.arrangePopUp)
        XCTAssertFalse(controller.keepArrangedCheckbox.isEnabled)
    }

    func test_changingArrangement_writesSetting() {
        let controller = makeController()
        controller.arrangePopUp.selectItem(withTitle: "List")
        fire(controller.arrangePopUp)
        XCTAssertEqual(settings.iconArrangement, .list)
    }

    func test_keepArranged_writesSetting() {
        let controller = makeController()
        controller.keepArrangedCheckbox.performClick(nil)
        XCTAssertFalse(settings.keepArranged)
    }

    func test_applyChosenPhoto_storesPath_andEnablesRemove() {
        let controller = makeController()
        XCTAssertFalse(controller.removePhotoButton.isEnabled)
        controller.applyChosenPhoto(url: URL(fileURLWithPath: "/tmp/photo.png"))
        XCTAssertEqual(settings.backgroundImagePath, "/tmp/photo.png")
        XCTAssertTrue(controller.removePhotoButton.isEnabled)
    }

    func test_remove_clearsPath() {
        settings.backgroundImagePath = "/tmp/photo.png"
        let controller = makeController()
        controller.removePhotoButton.performClick(nil)
        XCTAssertNil(settings.backgroundImagePath)
        XCTAssertFalse(controller.removePhotoButton.isEnabled)
    }

    func test_colorWell_writesHex() {
        let controller = makeController()
        controller.colorWell.color = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        fire(controller.colorWell)
        XCTAssertEqual(settings.backgroundColorHex, "#FF0000")
    }

    func test_externalChange_updatesControls_withoutWriteBack() {
        let controller = makeController()
        var writes = 0
        let observer = store.changes.sink { _ in writes += 1 }
        defer { observer.cancel() }
        settings.iconArrangement = .list
        XCTAssertEqual(writes, 1)
        XCTAssertEqual(controller.arrangePopUp.titleOfSelectedItem, "List")
        XCTAssertFalse(controller.keepArrangedCheckbox.isEnabled)
        settings.backgroundColorHex = "#445566"
        XCTAssertEqual(controller.colorWell.color.desktopHex, "#445566")
        XCTAssertEqual(writes, 2)
    }

    func test_photo_reloadsOnlyWhenPathChanges() {
        settings.backgroundImagePath = "/tmp/olylo-a.png"
        let controller = makeController()
        XCTAssertEqual(controller.photoLoadCount, 1)
        settings.keepArranged = false
        settings.iconArrangement = .smallIcons
        settings.backgroundColorHex = "#010203"
        XCTAssertEqual(controller.photoLoadCount, 1)
        settings.backgroundImagePath = "/tmp/olylo-b.png"
        XCTAssertEqual(controller.photoLoadCount, 2)
    }
}
