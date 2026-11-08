import AppKit
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDesktop

@MainActor
final class DesktopAppWindowTests: XCTestCase {
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
    }

    private func makeController(extra: [DesktopApp] = []) -> DesktopViewController {
        registry.register(app)
        extra.forEach { registry.register($0) }
        let controller = DesktopViewController(registry: registry, settings: settings)
        controller.loadView()
        controller.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        controller.view.layoutSubtreeIfNeeded()
        return controller
    }

    private func chrome(_ controller: DesktopViewController, _ id: String) throws -> DesktopWindowChromeView {
        try XCTUnwrap(controller.windowLayer.chrome(for: id))
    }

    private func keyEvent(_ key: String, flags: NSEvent.ModifierFlags = .command) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0, context: nil,
            characters: key, charactersIgnoringModifiers: key, isARepeat: false, keyCode: 0
        )!
    }

    /// Real mouse handlers on the chrome, with points in the chrome's coordinates.
    private func drag(
        _ chrome: DesktopWindowChromeView, from start: CGPoint, to end: CGPoint, clickCount: Int = 1
    ) throws {
        let layer = try XCTUnwrap(chrome.superview)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled], backing: .buffered, defer: true
        )
        window.contentView = layer.superview
        // Window coordinates are fixed up front: the chrome moves while it is dragged.
        let startWindow = chrome.convert(start, to: nil)
        let endWindow = chrome.convert(end, to: nil)
        func event(_ type: NSEvent.EventType, _ location: CGPoint) -> NSEvent {
            NSEvent.mouseEvent(
                with: type, location: location, modifierFlags: [], timestamp: 0,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: clickCount, pressure: 1
            )!
        }
        chrome.mouseDown(with: event(.leftMouseDown, startWindow))
        if end != start { chrome.mouseDragged(with: event(.leftMouseDragged, endWindow)) }
        chrome.mouseUp(with: event(.leftMouseUp, endWindow))
    }

    private final class Recorder: NSObject {
        private(set) var hits = 0
        @objc func hit(_ sender: Any?) { hits += 1 }
    }

    private func hostWindow(for controller: DesktopViewController) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled], backing: .buffered, defer: true
        )
        window.contentView = controller.view
        window.orderBack(nil)
        return window
    }

    func test_openApp_twice_keepsOneWindow_andFrontsIt() {
        let other = StubApp(identifier: "b", displayName: "Bravo")
        let controller = makeController(extra: [other])
        controller.openApp(identifier: "a")
        controller.openApp(identifier: "b")
        XCTAssertEqual(controller.openWindowIdentifiers, ["a", "b"])
        controller.openApp(identifier: "a")
        XCTAssertEqual(controller.openWindowIdentifiers, ["b", "a"])
        XCTAssertEqual(app.contentViewControllers.count, 1)
    }

    func test_closeApp_callsAppWillClose_andRemovesChildViewController() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        let content = try XCTUnwrap(app.contentViewControllers.first)
        XCTAssertTrue(controller.children.contains(content))
        controller.closeApp(identifier: "a")
        XCTAssertEqual(app.willCloseCount, 1)
        XCTAssertFalse(controller.children.contains(content))
        XCTAssertNil(content.view.superview)
        XCTAssertEqual(controller.openWindowIdentifiers, [])
    }

    func test_standardAppMenu_hasExactItems() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try XCTUnwrap(controller.windowController("a"))
        let menu = try XCTUnwrap(window.menus.first)
        XCTAssertEqual(menu.title, "Alpha")
        XCTAssertEqual(menu.items.map(\.title), ["About Alpha", "Settings…", "", "Close Alpha"])
        XCTAssertEqual(menu.items.map(\.keyEquivalent), ["", ",", "", "w"])
        XCTAssertTrue(menu.items[2].isSeparatorItem)
        XCTAssertEqual(menu.items[1].keyEquivalentModifierMask, .command)
        XCTAssertEqual(menu.items[3].keyEquivalentModifierMask, .command)
    }

    func test_appMenus_followStandardMenu_inOrder() throws {
        app.menus = [NSMenu(title: "File"), NSMenu(title: "View")]
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try XCTUnwrap(controller.windowController("a"))
        XCTAssertEqual(window.menus.map(\.title), ["Alpha", "File", "View"])
    }

    func test_showSettings_usesGeneratedForm_whenAppReturnsNil() throws {
        let controller = makeController()
        controller.showSettings(forApp: "a")
        let window = try XCTUnwrap(controller.windowController("settings:a"))
        XCTAssertTrue(window.contentViewController is DesktopSettingsFormViewController)
        XCTAssertEqual(try chrome(controller, "settings:a").title, "Alpha Settings")
    }

    func test_showSettings_usesAppController_whenProvided() throws {
        let custom = NSViewController()
        custom.view = NSView()
        app.settingsViewController = custom
        let controller = makeController()
        controller.showSettings(forApp: "a")
        let window = try XCTUnwrap(controller.windowController("settings:a"))
        XCTAssertTrue(window.contentViewController === custom)
    }

    func test_isShowingSettings_reflectsOpenSettingsWindow() {
        let controller = makeController()
        XCTAssertFalse(controller.isShowingSettings(forApp: "a"))
        controller.showSettings(forApp: "a")
        XCTAssertTrue(controller.isShowingSettings(forApp: "a"))
        controller.showSettings(forApp: "a")
        XCTAssertEqual(controller.openWindowIdentifiers, ["settings:a"])
        controller.closeWindow(id: "settings:a")
        XCTAssertFalse(controller.isShowingSettings(forApp: "a"))
    }

    func test_showAbout_opensAboutWindow() {
        let controller = makeController()
        controller.showAbout(forApp: "a")
        XCTAssertEqual(controller.openWindowIdentifiers, ["about:a"])
    }

    func test_savedFrame_isRestored_andClamped() throws {
        settings.windowFrames = ["a": CGRect(x: 5000, y: 5000, width: 400, height: 300)]
        let controller = makeController()
        controller.openApp(identifier: "a")
        let frame = try chrome(controller, "a").frame
        XCTAssertEqual(frame, CGRect(x: 760, y: 572, width: 400, height: 300))
    }

    func test_savedFrame_insideDesktop_isRestoredAsIs() throws {
        settings.windowFrames = ["a": CGRect(x: 50, y: 60, width: 400, height: 300)]
        let controller = makeController()
        controller.openApp(identifier: "a")
        XCTAssertEqual(try chrome(controller, "a").frame, CGRect(x: 50, y: 60, width: 400, height: 300))
    }

    func test_savedFrameForUnknownApp_isIgnored() throws {
        settings.windowFrames = ["ghost": CGRect(x: 1, y: 1, width: 100, height: 100)]
        let controller = makeController()
        controller.openApp(identifier: "a")
        XCTAssertEqual(try chrome(controller, "a").frame, CGRect(x: 195, y: 121.5, width: 410, height: 357))
        XCTAssertEqual(controller.openWindowIdentifiers, ["a"])
    }

    func test_defaultFrame_cascadesPerOpenWindow() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        controller.showAbout(forApp: "a")
        XCTAssertEqual(try chrome(controller, "about:a").frame.origin, CGPoint(x: 215 + 24, y: 68.5 + 24))
    }

    func test_cmdW_closesFrontAppWindow() {
        let controller = makeController()
        controller.openApp(identifier: "a")
        XCTAssertTrue(controller.view.performKeyEquivalent(with: keyEvent("w")))
        XCTAssertEqual(controller.openWindowIdentifiers, [])
        XCTAssertEqual(app.willCloseCount, 1)
    }

    func test_cmdW_closesAboutWindowOnly() {
        let controller = makeController()
        controller.openApp(identifier: "a")
        controller.showAbout(forApp: "a")
        XCTAssertTrue(controller.view.performKeyEquivalent(with: keyEvent("w")))
        XCTAssertEqual(controller.openWindowIdentifiers, ["a"])
        XCTAssertEqual(app.willCloseCount, 0)
    }

    func test_cmdComma_opensSettings() {
        let controller = makeController()
        controller.openApp(identifier: "a")
        XCTAssertTrue(controller.view.performKeyEquivalent(with: keyEvent(",")))
        XCTAssertTrue(controller.isShowingSettings(forApp: "a"))
    }

    func test_cmdW_withNoAppWindow_isNotHandled() {
        let controller = makeController()
        XCTAssertFalse(controller.view.performKeyEquivalent(with: keyEvent("w")))
    }

    func test_moveEnd_savesFrame_onceAndOnlyWhenChanged() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        let before = window.frame
        // A click on the title bar with no movement writes nothing.
        try drag(window, from: CGPoint(x: 200, y: 14), to: CGPoint(x: 200, y: 14))
        XCTAssertEqual(settings.windowFrames, [:])
        try drag(window, from: CGPoint(x: 200, y: 14), to: CGPoint(x: 250, y: 44))
        XCTAssertEqual(window.frame.origin, CGPoint(x: before.minX + 50, y: before.minY + 30))
        XCTAssertEqual(settings.windowFrames["a"], window.frame)
    }

    func test_resizeEnd_respectsMinimum_andSavesFrame() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        // Bottom-right corner, dragged far inward.
        try drag(window, from: CGPoint(x: 407, y: 354), to: CGPoint(x: 10, y: 10))
        XCTAssertEqual(window.frame.size, CGSize(width: 210, height: 207))
        XCTAssertEqual(settings.windowFrames["a"], window.frame)
    }

    func test_aboutAndSettingsFrames_areNotSaved() throws {
        let controller = makeController()
        controller.showAbout(forApp: "a")
        let window = try chrome(controller, "about:a")
        try drag(window, from: CGPoint(x: 200, y: 14), to: CGPoint(x: 250, y: 44))
        XCTAssertEqual(settings.windowFrames, [:])
    }

    func test_dragAboveDesktop_keepsTitleBarInside() {
        let clamped = DesktopWindowChromeView.clamped(
            CGRect(x: -1000, y: -500, width: 400, height: 300), in: CGSize(width: 800, height: 600),
            minimum: CGSize(width: 200, height: 150)
        )
        XCTAssertEqual(clamped.origin, CGPoint(x: -360, y: 0))
    }

    func test_closeButton_closesWindow() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        try drag(window, from: CGPoint(x: 14, y: 14), to: CGPoint(x: 14, y: 14))
        XCTAssertEqual(controller.openWindowIdentifiers, [])
        XCTAssertEqual(app.willCloseCount, 1)
    }

    func test_menuTitleClick_popsUpMenuBarWithMenus() throws {
        app.menus = [NSMenu(title: "File")]
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        let bar = try XCTUnwrap(window.subviews.compactMap { $0 as? DesktopMenuBarView }.first)
        XCTAssertEqual(bar.menus.map(\.title), ["Alpha", "File"])
        var shown: [String] = []
        bar.popUp = { menu, _, _ in shown.append(menu.title) }
        let title = try XCTUnwrap(bar.titleView(at: 1))
        let press = try XCTUnwrap(NSEvent.mouseEvent(
            with: .leftMouseDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
        ))
        // The menu opens on press, before any release.
        title.mouseDown(with: press)
        XCTAssertEqual(shown, ["File"])
    }

    func test_menuTitles_keepTheirFramesAcrossRepeatedLayout() throws {
        app.menus = [NSMenu(title: "File"), NSMenu(title: "Edit")]
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        let bar = try XCTUnwrap(window.subviews.compactMap { $0 as? DesktopMenuBarView }.first)
        bar.layout()
        let first = (0..<3).compactMap { bar.titleView(at: $0)?.frame }
        bar.layout()
        bar.layout()
        XCTAssertEqual((0..<3).compactMap { bar.titleView(at: $0)?.frame }, first)
        XCTAssertEqual(first.count, 3)
    }

    func test_menuBar_sitsBetweenTheSideResizeBands() throws {
        app.menus = [NSMenu(title: "File")]
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        window.layout()
        let bar = try XCTUnwrap(window.subviews.compactMap { $0 as? DesktopMenuBarView }.first)
        let band: CGFloat = 5 // the chrome's resize band
        XCTAssertEqual(bar.frame.minX, band)
        XCTAssertEqual(bar.frame.maxX, window.bounds.width - band)
    }

    func test_menuTitle_isAnAccessibleMenuBarItem_thatPressesOpen() throws {
        app.menus = [NSMenu(title: "File")]
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        let bar = try XCTUnwrap(window.subviews.compactMap { $0 as? DesktopMenuBarView }.first)
        var shown: [String] = []
        bar.popUp = { menu, _, _ in shown.append(menu.title) }
        let title = try XCTUnwrap(bar.titleView(at: 1))
        XCTAssertEqual(title.accessibilityRole(), .menuBarItem)
        XCTAssertEqual(title.accessibilityLabel(), "File")
        XCTAssertTrue(title.accessibilityPerformPress())
        XCTAssertEqual(shown, ["File"])
    }

    func test_savedFrameBelowMinimum_isRaisedToWholeWindowMinimum() throws {
        settings.windowFrames = ["a": CGRect(x: 100, y: 100, width: 50, height: 50)]
        let controller = makeController()
        controller.openApp(identifier: "a")
        XCTAssertEqual(try chrome(controller, "a").frame, CGRect(x: 100, y: 100, width: 210, height: 207))
    }

    func test_defaultWindow_contentHeightEqualsDefaultWindowSize() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        window.layoutSubtreeIfNeeded()
        XCTAssertEqual(window.contentContainer.frame.size, CGSize(width: 400, height: 300))
        XCTAssertEqual(
            window.frame.height, 300 + DesktopWindowChromeView.titleBarHeight + DesktopMenuBarView.height + 5
        )
    }

    func test_panelsUseOwnMinimum_notTheApps() throws {
        let controller = makeController()
        controller.showAbout(forApp: "a")
        controller.showSettings(forApp: "a")
        XCTAssertEqual(try chrome(controller, "about:a").minimumContentSize, CGSize(width: 300, height: 340))
        XCTAssertEqual(try chrome(controller, "settings:a").minimumContentSize, CGSize(width: 320, height: 200))
    }

    func test_mouseDownOnContent_frontsWindow() throws {
        settings.windowFrames = [
            "a": CGRect(x: 20, y: 20, width: 300, height: 300),
            "b": CGRect(x: 400, y: 20, width: 300, height: 300)
        ]
        let controller = makeController(extra: [StubApp(identifier: "b", displayName: "Bravo")])
        controller.openApp(identifier: "a")
        controller.openApp(identifier: "b")
        XCTAssertEqual(controller.openWindowIdentifiers, ["a", "b"])
        let window = hostWindow(for: controller)
        controller.view.layoutSubtreeIfNeeded()
        let target = controller.windowLayer.convert(CGPoint(x: 170, y: 200), to: nil)
        let event = try XCTUnwrap(NSEvent.mouseEvent(
            with: .leftMouseDown, location: target, modifierFlags: [], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
        ))
        // Through the application queue, so `NSApp.currentEvent` is the click while it dispatches.
        XCTAssertGreaterThan(window.windowNumber, 0)
        NSApp.postEvent(event, atStart: true)
        let next = try XCTUnwrap(NSApp.nextEvent(matching: .any, until: .distantPast, inMode: .default, dequeue: true))
        NSApp.sendEvent(next)
        XCTAssertEqual(controller.openWindowIdentifiers, ["b", "a"])
    }

    func test_closeWindow_releasesControllerAndContent_evenWhenAppKeepsContext() {
        let controller = makeController()
        weak var weakWindowController: DesktopAppWindowController?
        weak var weakContent: NSViewController?
        autoreleasepool {
            controller.openApp(identifier: "a")
            weakWindowController = controller.windowController("a")
            weakContent = app.contentViewControllers.first
            XCTAssertNotNil(weakWindowController)
            XCTAssertNotNil(weakContent)
            controller.closeApp(identifier: "a")
        }
        XCTAssertNil(weakWindowController)
        XCTAssertNil(weakContent)
    }

    func test_cmdW_closesFrontSettingsWindow() {
        let controller = makeController()
        controller.showSettings(forApp: "a")
        XCTAssertTrue(controller.view.performKeyEquivalent(with: keyEvent("w")))
        XCTAssertFalse(controller.isShowingSettings(forApp: "a"))
    }

    func test_appMenu_claimsKey_beforeStandardMenu() {
        let recorder = Recorder()
        let menu = NSMenu(title: "File")
        let item = NSMenuItem(title: "Custom", action: #selector(Recorder.hit(_:)), keyEquivalent: "w")
        item.target = recorder
        menu.addItem(item)
        app.menus = [menu]
        let controller = makeController()
        controller.openApp(identifier: "a")
        XCTAssertTrue(controller.view.performKeyEquivalent(with: keyEvent("w")))
        XCTAssertEqual(recorder.hits, 1)
        XCTAssertEqual(controller.openWindowIdentifiers, ["a"])
    }

    func test_closeApp_ignoresAboutAndSettingsIdentifiers() {
        let controller = makeController()
        controller.showAbout(forApp: "a")
        controller.showSettings(forApp: "a")
        controller.closeApp(identifier: "about:a")
        controller.closeApp(identifier: "settings:a")
        XCTAssertEqual(controller.openWindowIdentifiers, ["about:a", "settings:a"])
    }

    func test_topEdgeResize_atDesktopTop_shrinksHeight_keepingBottomEdge() throws {
        settings.windowFrames = ["a": CGRect(x: 100, y: 50, width: 400, height: 352)]
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        try drag(window, from: CGPoint(x: 200, y: 2), to: CGPoint(x: 200, y: -98))
        XCTAssertEqual(window.frame.minY, 0)
        XCTAssertEqual(window.frame.maxY, 402)
    }

    func test_moveAfterZoom_discardsRestoreFrame() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        window.toggleZoom()
        try drag(window, from: CGPoint(x: 200, y: 14), to: CGPoint(x: 150, y: 44))
        window.toggleZoom()
        XCTAssertEqual(window.frame, controller.windowLayer.bounds)
    }

    // MARK: Final review fixes

    func test_settingsWindow_usesControllersPreferredSize_whenNonZero() throws {
        let custom = NSViewController()
        custom.view = NSView()
        custom.preferredContentSize = CGSize(width: 720, height: 480)
        app.settingsViewController = custom
        let controller = makeController()
        controller.showSettings(forApp: "a")
        let window = try XCTUnwrap(controller.windowController("settings:a"))
        XCTAssertEqual(window.defaultContentSize, CGSize(width: 720, height: 480))
        let chrome = try chrome(controller, "settings:a")
        chrome.layoutSubtreeIfNeeded()
        XCTAssertEqual(chrome.contentContainer.frame.size, CGSize(width: 720, height: 480))
    }

    func test_settingsWindow_fallsBackTo440x300_whenPreferredSizeIsZero() throws {
        let custom = NSViewController()
        custom.view = NSView()
        app.settingsViewController = custom
        let controller = makeController()
        controller.showSettings(forApp: "a")
        let window = try XCTUnwrap(controller.windowController("settings:a"))
        XCTAssertEqual(window.defaultContentSize, CGSize(width: 440, height: 300))
        controller.showAbout(forApp: "a")
        XCTAssertEqual(try XCTUnwrap(controller.windowController("about:a")).defaultContentSize,
                       CGSize(width: 360, height: 430))
    }

    func test_doubleClickOnTitleBar_togglesZoom() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        let original = window.frame
        try drag(window, from: CGPoint(x: 200, y: 14), to: CGPoint(x: 200, y: 14), clickCount: 2)
        XCTAssertEqual(window.frame, controller.windowLayer.bounds)
        XCTAssertEqual(settings.windowFrames["a"], controller.windowLayer.bounds)
        try drag(window, from: CGPoint(x: 200, y: 14), to: CGPoint(x: 200, y: 14), clickCount: 2)
        XCTAssertEqual(window.frame, original)
    }

    func test_noOpTitleBarClick_keepsRestoreFrame() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        let original = window.frame
        window.toggleZoom()
        XCTAssertEqual(window.frame, controller.windowLayer.bounds)
        // A click with no movement must not forget the frame the zoom will restore.
        try drag(window, from: CGPoint(x: 200, y: 14), to: CGPoint(x: 200, y: 14))
        window.toggleZoom()
        XCTAssertEqual(window.frame, original)
    }

    func test_resizeBand_doesNotCoverContent() throws {
        let controller = makeController()
        controller.openApp(identifier: "a")
        let window = try chrome(controller, "a")
        window.layoutSubtreeIfNeeded()
        let band: CGFloat = 5
        XCTAssertEqual(window.contentContainer.frame.minX, band)
        XCTAssertEqual(window.contentContainer.frame.maxX, window.bounds.width - band)
        XCTAssertEqual(window.contentContainer.frame.maxY, window.bounds.height - band)
        func hit(_ local: CGPoint) -> NSView? {
            window.hitTest(CGPoint(x: window.frame.minX + local.x, y: window.frame.minY + local.y))
        }
        // In the band: the chrome. Just inside the content's corner: the content, not the chrome.
        XCTAssertTrue(hit(CGPoint(x: 2, y: 200)) === window)
        XCTAssertTrue(hit(CGPoint(x: window.bounds.width - 2, y: 200)) === window)
        XCTAssertTrue(hit(CGPoint(x: 200, y: window.bounds.height - 2)) === window)
        let inside = try XCTUnwrap(hit(CGPoint(x: band + 1, y: window.bounds.height - band - 1)))
        XCTAssertFalse(inside === window)
        XCTAssertTrue(inside.isDescendant(of: window.contentContainer))
    }

    func test_shrinkingDesktop_reclampsWindows_withoutWritingFrames() throws {
        let saved = CGRect(x: 700, y: 500, width: 400, height: 300)
        settings.windowFrames = ["a": saved]
        let controller = makeController()
        controller.openApp(identifier: "a")
        XCTAssertEqual(try chrome(controller, "a").frame.origin, CGPoint(x: 700, y: 500))
        controller.view.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        controller.view.layoutSubtreeIfNeeded()
        controller.windowLayer.layoutSubtreeIfNeeded()
        let frame = try chrome(controller, "a").frame
        XCTAssertEqual(frame.origin, CGPoint(x: 460, y: 372))
        XCTAssertEqual(settings.windowFrames["a"], saved)
    }

    func test_closingSettingsWindow_savesTextTypedButNotCommitted() throws {
        let schema = DesktopAppSettingsSchema(fields: [
            .init(key: "name", label: "Name", kind: .text(default: "x", placeholder: nil))
        ])
        let textApp = StubApp(identifier: "t", schema: schema, displayName: "Text")
        let controller = makeController(extra: [textApp])
        let host = hostWindow(for: controller)
        controller.showSettings(forApp: "t")
        let window = try XCTUnwrap(controller.windowController("settings:t"))
        let field = try XCTUnwrap(Self.descendants(of: window.chrome).compactMap { $0 as? NSTextField }
            .first { $0.identifier?.rawValue == "name" })
        XCTAssertTrue(host.makeFirstResponder(field))
        let editor = try XCTUnwrap(field.currentEditor())
        // Set without any action or change notification: only closing the window can commit it.
        editor.string = "typed"
        controller.closeWindow(id: "settings:t")
        XCTAssertEqual(settings.appSettings(for: textApp).string("name"), "typed")
    }

    func test_typingInSettingsField_commitsOnEveryChange() throws {
        let schema = DesktopAppSettingsSchema(fields: [
            .init(key: "name", label: "Name", kind: .text(default: "x", placeholder: nil))
        ])
        let textApp = StubApp(identifier: "t", schema: schema, displayName: "Text")
        let controller = makeController(extra: [textApp])
        controller.showSettings(forApp: "t")
        let window = try XCTUnwrap(controller.windowController("settings:t"))
        let form = try XCTUnwrap(window.contentViewController as? DesktopSettingsFormViewController)
        let field = try XCTUnwrap(Self.descendants(of: window.chrome).compactMap { $0 as? NSTextField }
            .first { $0.identifier?.rawValue == "name" })
        field.stringValue = "partial"
        form.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
        XCTAssertEqual(settings.appSettings(for: textApp).string("name"), "partial")
    }

    private static func descendants(of view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { descendants(of: $0) }
    }
}
