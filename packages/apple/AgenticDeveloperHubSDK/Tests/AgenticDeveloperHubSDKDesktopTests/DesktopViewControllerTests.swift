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

    func test_dragEnd_inFreeMode_savesPosition() throws {
        settings.keepArranged = false
        let controller = makeController(names: [("a", "Alpha")])
        let grid = try XCTUnwrap(gridView(of: controller))
        drag(grid, from: CGPoint(x: 20, y: 20), to: CGPoint(x: 320, y: 220))
        XCTAssertEqual(settings.iconPositions["a"], CGPoint(x: 308, y: 208))
    }

    func test_drag_whenKeepArranged_writesNothing() throws {
        let controller = makeController(names: [("a", "Alpha")])
        let grid = try XCTUnwrap(gridView(of: controller))
        drag(grid, from: CGPoint(x: 20, y: 20), to: CGPoint(x: 320, y: 220))
        XCTAssertEqual(settings.iconPositions, [:])
        XCTAssertEqual(controller.iconOrigins["a"], CGPoint(x: 8, y: 8))
    }

    func test_click_withoutMovement_writesNoPosition() throws {
        settings.keepArranged = false
        let controller = makeController(names: [("a", "Alpha")])
        settings.iconPositions = [:]
        let grid = try XCTUnwrap(gridView(of: controller))
        drag(grid, from: CGPoint(x: 20, y: 20), to: nil)
        XCTAssertEqual(settings.iconPositions, [:])
        XCTAssertEqual(controller.selectedAppIdentifier, "a")
    }

    func test_turningKeepArrangedOff_inListMode_savesOnePositionPerApp() {
        settings.iconArrangement = .list
        let controller = makeController(names: [("b", "Bravo"), ("a", "Alpha")])
        settings.keepArranged = false
        withExtendedLifetime(controller) {}
        XCTAssertEqual(Set(settings.iconPositions.keys), ["a", "b"])
        XCTAssertEqual(settings.iconPositions["a"], CGPoint(x: 8, y: 8))
        XCTAssertEqual(settings.iconPositions["b"], CGPoint(x: 8, y: 104))
    }

    private func gridView(of controller: DesktopViewController) -> DesktopIconGridView? {
        allSubviews(of: controller.view).compactMap { $0 as? DesktopIconGridView }.first
    }

    /// Real mouse handlers, driven by synthesized events. Points are in grid coordinates (top-left origin).
    private func drag(_ grid: DesktopIconGridView, from start: CGPoint, to end: CGPoint?) {
        let window = grid.window ?? NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled], backing: .buffered, defer: true
        )
        if grid.window == nil, let root = grid.superview {
            window.contentView = root
        }
        func event(_ type: NSEvent.EventType, _ point: CGPoint) -> NSEvent {
            let location = grid.convert(point, to: nil)
            return NSEvent.mouseEvent(
                with: type, location: location, modifierFlags: [], timestamp: 0,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
            )!
        }
        grid.mouseDown(with: event(.leftMouseDown, start))
        if let end { grid.mouseDragged(with: event(.leftMouseDragged, end)) }
        grid.mouseUp(with: event(.leftMouseUp, end ?? start))
    }

    private func allSubviews(of view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { allSubviews(of: $0) }
    }
}
