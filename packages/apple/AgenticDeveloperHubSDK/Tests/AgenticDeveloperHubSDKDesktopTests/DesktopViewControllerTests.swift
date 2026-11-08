import AppKit
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDesktop

@MainActor
final class DesktopViewControllerTests: XCTestCase {
    private var settings: DesktopSettings!
    private var registry: DesktopAppRegistry!

    override func setUp() async throws {
        try await super.setUp()
        settings = DesktopSettings(store: UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        ))
        registry = DesktopAppRegistry()
    }

    private func makeController(names: [(String, String)] = []) -> DesktopViewController {
        for (id, name) in names { registry.register(StubApp(identifier: id, displayName: name)) }
        let controller = DesktopViewController(registry: registry, settings: settings)
        controller.loadView()
        controller.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        controller.view.layoutSubtreeIfNeeded()
        return controller
    }

    func test_background_missingPhotoPath_fallsBackToColor_noImage() {
        settings.backgroundImagePath = "/nonexistent/x.png"
        let controller = makeController()
        XCTAssertNil(controller.currentBackgroundImage)
    }

    func test_arranged_iconOriginsSortedByName() {
        let controller = makeController(names: [("c", "Charlie"), ("a", "alpha"), ("b", "Bravo")])
        let origins = controller.iconOrigins
        let ordered = ["a", "b", "c"].compactMap { origins[$0] }
        XCTAssertEqual(ordered.count, 3)
        XCTAssertEqual(ordered[0], CGPoint(x: 8, y: 8))
        XCTAssertEqual(ordered[1], CGPoint(x: 8, y: 104))
        XCTAssertEqual(ordered[2], CGPoint(x: 8, y: 200))
    }

    func test_turningKeepArrangedOff_savesCurrentOrigins() {
        let controller = makeController(names: [("b", "Bravo"), ("a", "Alpha")])
        let before = controller.iconOrigins
        settings.keepArranged = false
        controller.view.layoutSubtreeIfNeeded()
        XCTAssertEqual(settings.iconPositions, before)
        XCTAssertEqual(controller.iconOrigins, before)
    }

    func test_listMode_showsTable_withAllApps() {
        settings.iconArrangement = .list
        let controller = makeController(names: [("b", "Bravo"), ("a", "Alpha")])
        let tables = allSubviews(of: controller.view).compactMap { $0 as? NSTableView }
        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables.first?.numberOfRows, 2)
        XCTAssertEqual(tables.first?.tableColumns.map(\.title), ["Name", "Version", "Kind"])
        XCTAssertFalse(tables.first?.enclosingScrollView?.isHidden ?? true)
    }

    func test_dragEnd_inFreeMode_savesPosition() {
        settings.keepArranged = false
        let controller = makeController(names: [("a", "Alpha")])
        let grid = allSubviews(of: controller.view).compactMap { $0 as? DesktopIconGridView }.first
        grid?.simulateDrag(of: "a", to: CGPoint(x: 300, y: 200))
        XCTAssertEqual(settings.iconPositions["a"], CGPoint(x: 300, y: 200))
    }

    private func allSubviews(of view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { allSubviews(of: $0) }
    }
}
