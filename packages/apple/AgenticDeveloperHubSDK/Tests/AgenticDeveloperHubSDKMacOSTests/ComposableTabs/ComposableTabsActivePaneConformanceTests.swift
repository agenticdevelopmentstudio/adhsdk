import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKCoreMacOS
@testable import AgenticDeveloperHubSDKMacOS
@testable import AgenticDeveloperHubSDKUI

/// Conformance vectors for the `ui/layout/composable-tabs/active-pane` recipe.
///
/// Every test builds its own windows with fresh pane backdrops, because the
/// tracker is a process-wide singleton keyed by window. Pointer events go
/// through `NSApp.sendEvent`, which is the path the tracker's local monitor
/// listens on.
@MainActor
final class ComposableTabsActivePaneConformanceTests: XCTestCase {

    private typealias Pane = ComposableTabsPaneBackgroundView

    /// A view that can be told how to behave when the keyboard is offered.
    private final class FocusView: NSView {
        var accepts = true
        var declinesBecoming = false
        var refusesResign = false
        var becomeCount = 0
        var mouseDownCount = 0
        override var acceptsFirstResponder: Bool { accepts }
        override func becomeFirstResponder() -> Bool {
            becomeCount += 1
            return !declinesBecoming
        }
        override func resignFirstResponder() -> Bool { !refusesResign }
        override func mouseDown(with event: NSEvent) { mouseDownCount += 1 }
    }

    /// Records every change notification, with the window it was posted for.
    @MainActor private final class ChangeLog {
        var windows: [ObjectIdentifier] = []
        nonisolated(unsafe) var token: NSObjectProtocol?
        init() {
            token = NotificationCenter.default.addObserver(
                forName: ComposableTabsActivePane.didChangeNotification, object: nil, queue: nil
            ) { [weak self] note in
                let window = (note.object as? NSWindow).map(ObjectIdentifier.init)
                MainActor.assumeIsolated {
                    if let window { self?.windows.append(window) }
                }
            }
        }
        func count(for window: NSWindow) -> Int { windows.filter { $0 == ObjectIdentifier(window) }.count }
        deinit { token.map { NotificationCenter.default.removeObserver($0) } }
    }

    private struct Rig {
        let window: NSWindow
        let panes: [Pane]
        let focus: [FocusView]
    }

    private let tracker = ComposableTabsActivePane.shared
    private var windows: [NSWindow] = []
    private var savedFollows = false
    private var savedHighlight = true
    private var logs: [ChangeLog] = []

    override func setUp() async throws {
        await ExclusiveAccess.Resource.userSettings.acquire()
        savedFollows = UserSettings.activePaneFollowsMouse.currentValue
        savedHighlight = UserSettings.highlightActivePane.currentValue
        UserSettings.shared.set(false, for: UserSettings.activePaneFollowsMouse)
        UserSettings.shared.set(true, for: UserSettings.highlightActivePane)
        drain()
    }

    override func tearDown() async throws {
        for window in windows {
            ComposableTabsArrangeMode.shared.setEnabled(false, in: window)
            if let sheet = window.attachedSheet { window.endSheet(sheet) }
            window.close()
        }
        windows.removeAll()
        logs.removeAll()
        UserSettings.shared.set(savedFollows, for: UserSettings.activePaneFollowsMouse)
        UserSettings.shared.set(savedHighlight, for: UserSettings.highlightActivePane)
        drain()
        await ExclusiveAccess.Resource.userSettings.release()
    }

    // MARK: Helpers

    private func drain() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }

    /// Runs the run loop until `condition` holds or `timeout` passes. A
    /// setting change reaches the panes through a sink on the main queue, so
    /// it lands a turn after the write — on a loaded machine, later than one
    /// fixed `drain()` allows. Waiting on the outcome makes that wait exact.
    private func drain(until condition: () -> Bool, timeout: TimeInterval = 5) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
    }

    /// Runs the run loop in `.eventTracking` mode only, until `condition`
    /// holds or `timeout` passes — the mode a main-queue sink must still be
    /// served in during a drag. One `run(mode:before:)` call returns after the
    /// first source it handles, which on a cold or loaded run is often not the
    /// main queue's, so a single call cannot stand for "the queue drained".
    private func drainEventTracking(until condition: () -> Bool, timeout: TimeInterval = 5) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            RunLoop.current.run(mode: .eventTracking, before: Date().addingTimeInterval(0.01))
        }
    }

    private func setFollows(_ enabled: Bool) {
        UserSettings.shared.set(enabled, for: UserSettings.activePaneFollowsMouse)
        drain()
    }

    private func setHighlight(_ enabled: Bool) {
        UserSettings.shared.set(enabled, for: UserSettings.highlightActivePane)
        drain()
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        windows.append(window)
        return window
    }

    /// Adds one 300 by 400 pane at slot `index`, holding a focusable child at
    /// (20, 20) sized 100 by 100.
    private func addPane(to window: NSWindow, index: Int) -> (Pane, FocusView) {
        let pane = Pane(nodeID: UUID())
        pane.frame = NSRect(x: CGFloat(index) * 300, y: 0, width: 300, height: 400)
        let child = FocusView(frame: NSRect(x: 20, y: 20, width: 100, height: 100))
        window.contentView?.addSubview(pane)
        pane.addSubview(child)
        window.contentView?.layoutSubtreeIfNeeded()
        return (pane, child)
    }

    private func makeRig(panes count: Int = 2, in existing: NSWindow? = nil) -> Rig {
        let window = existing ?? makeWindow()
        var panes: [Pane] = []
        var focus: [FocusView] = []
        for index in 0..<count {
            let (pane, child) = addPane(to: window, index: index)
            panes.append(pane)
            focus.append(child)
        }
        return Rig(window: window, panes: panes, focus: focus)
    }

    private func observeChanges() -> ChangeLog {
        let log = ChangeLog()
        logs.append(log)
        return log
    }

    /// A point in pane `index` clear of its child view.
    private func emptyPoint(_ index: Int) -> NSPoint {
        NSPoint(x: CGFloat(index) * 300 + 200, y: 300)
    }

    /// A point on pane `index`'s child view.
    private func childPoint(_ index: Int) -> NSPoint {
        NSPoint(x: CGFloat(index) * 300 + 50, y: 50)
    }

    private func send(_ type: NSEvent.EventType, at point: NSPoint, in window: NSWindow?) throws {
        let event = try XCTUnwrap(NSEvent.mouseEvent(
            with: type,
            location: point,
            modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window?.windowNumber ?? 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        ))
        NSApp.sendEvent(event)
    }

    private func makeKey(_ window: NSWindow) throws {
        window.makeKeyAndOrderFront(nil)
        drain()
        try XCTSkipUnless(window.isKeyWindow, "This environment cannot make a window key")
    }

    /// `rig.window` is in front but not key, because `other` is key.
    private func makeNotKey(_ rig: Rig) throws {
        rig.window.orderFront(nil)
        let other = makeWindow()
        try makeKey(other)
        try XCTSkipIf(rig.window.isKeyWindow, "This environment cannot hold two windows apart")
    }

    private func rgba(_ color: CGColor?) throws -> [CGFloat] {
        let cgColor = try XCTUnwrap(color)
        let converted = try XCTUnwrap(NSColor(cgColor: cgColor)?.usingColorSpace(.sRGB))
        return [converted.redComponent, converted.greenComponent, converted.blueComponent, converted.alphaComponent]
    }

    private func srgb(_ color: RGBAColor) -> NSColor {
        NSColor(srgbRed: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
    }

    private func assertColor(_ actual: CGColor?, _ expected: RGBAColor, _ message: String = "") throws {
        let expectedColor = NSColor(srgbRed: expected.red, green: expected.green, blue: expected.blue,
                                    alpha: expected.alpha)
        let expectedComponents = try rgba(expectedColor.cgColor)
        let actualComponents = try rgba(actual)
        for (left, right) in zip(actualComponents, expectedComponents) {
            XCTAssertEqual(left, right, accuracy: 0.01, message)
        }
    }

    private func palette(of pane: Pane) -> SemanticPalette {
        pane.resolvedThemeScope.palette
    }

    // MARK: Active node bookkeeping

    func testCTA01_tracksActiveNodePerWindow() {
        let first = makeRig()
        let second = makeRig()
        tracker.activate(nodeID: first.panes[1].nodeID, in: first.window)
        XCTAssertEqual(tracker.activeNodeID(in: first.window), first.panes[1].nodeID)
        XCTAssertEqual(tracker.activeNodeID(in: second.window), second.panes[0].nodeID)
    }

    func testCTA02_unclaimedPaneCountsAsActive() {
        let rig = makeRig()
        rig.window.close()
        drain()
        XCTAssertNil(tracker.activeNodeID(in: rig.window))
        XCTAssertTrue(tracker.isInActivePane(rig.focus[0]))
        XCTAssertTrue(tracker.isInActivePane(rig.focus[1]))
    }

    func testCTA03_membershipDecidedByNodeIDMatch() {
        let rig = makeRig()
        XCTAssertTrue(tracker.isInActivePane(rig.focus[0]))
        XCTAssertFalse(tracker.isInActivePane(rig.focus[1]))
    }

    func testCTA04_viewOutsideAnyPaneCountsAsActive() {
        XCTAssertTrue(tracker.isInActivePane(NSView()))
        let window = makeWindow()
        let loose = NSView()
        window.contentView?.addSubview(loose)
        XCTAssertTrue(tracker.isInActivePane(loose))
    }

    func testCTA05_nilWindowHasNoActiveNode() {
        XCTAssertNil(tracker.activeNodeID(in: nil))
    }

    func testCTA06_arrivalClaimsActiveInAnUnclaimedWindow() {
        let rig = makeRig(panes: 1)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
    }

    func testCTA07_arrivalDoesNotStealActiveFromALivePane() {
        let rig = makeRig()
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
    }

    func testCTA08_arrivalEnablesMouseMovedTrackingWhenSettingOn() {
        setFollows(true)
        let window = makeWindow()
        _ = addPane(to: window, index: 0)
        window.acceptsMouseMovedEvents = false
        _ = addPane(to: window, index: 1)
        XCTAssertTrue(window.acceptsMouseMovedEvents)
    }

    func testCTA09_departureHandsOffToASurvivingPane() {
        let rig = makeRig()
        rig.panes[0].removeFromSuperview()
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[1].nodeID)
    }

    func testCTA10_departureClearsActiveIDWhenNoPaneSurvives() {
        let rig = makeRig(panes: 1)
        rig.panes[0].removeFromSuperview()
        XCTAssertNil(tracker.activeNodeID(in: rig.window))
    }

    func testCTA11_departureOfANonActivePaneIsInert() {
        let rig = makeRig()
        let log = observeChanges()
        rig.panes[1].removeFromSuperview()
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
        XCTAssertEqual(log.count(for: rig.window), 0)
    }

    func testCTA12_windowCloseClearsActiveIDSilently() {
        let rig = makeRig()
        let log = observeChanges()
        rig.window.close()
        drain()
        XCTAssertNil(tracker.activeNodeID(in: rig.window))
        XCTAssertEqual(log.count(for: rig.window), 0)
    }

    func testCTA13_activationIsIdempotent() {
        let rig = makeRig()
        let log = observeChanges()
        tracker.activate(nodeID: rig.panes[0].nodeID, in: rig.window)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
        XCTAssertEqual(log.count(for: rig.window), 0)
    }

    func testCTA14_activationPostsNotificationOnChange() {
        let rig = makeRig()
        let log = observeChanges()
        tracker.activate(nodeID: rig.panes[1].nodeID, in: rig.window)
        XCTAssertEqual(log.count(for: rig.window), 1)
    }

    // MARK: Pointer-move tracking

    func testCTA15_settingEnabledReachesAlreadyOpenWindows() {
        let first = makeRig()
        let second = makeRig()
        XCTAssertFalse(first.window.acceptsMouseMovedEvents)
        setFollows(true)
        XCTAssertTrue(first.window.acceptsMouseMovedEvents)
        XCTAssertTrue(second.window.acceptsMouseMovedEvents)
    }

    func testCTA16_acceptsMouseMovedIsNeverResetToFalse() {
        let rig = makeRig()
        setFollows(true)
        XCTAssertTrue(rig.window.acceptsMouseMovedEvents)
        setFollows(false)
        XCTAssertTrue(rig.window.acceptsMouseMovedEvents)
    }

    // MARK: Event routing

    func testCTA17_clicksAreEvaluatedRegardlessOfTheSetting() throws {
        let rig = makeRig()
        try send(.leftMouseDown, at: emptyPoint(1), in: rig.window)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[1].nodeID)
    }

    func testCTA18_mouseMovedIsGatedByTheSetting() throws {
        let rig = makeRig()
        try makeKey(rig.window)
        try send(.mouseMoved, at: emptyPoint(1), in: rig.window)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
    }

    func testCTA19_mouseMovedIsGatedByKeyWindow() throws {
        let rig = makeRig()
        setFollows(true)
        try makeNotKey(rig)
        try send(.mouseMoved, at: emptyPoint(1), in: rig.window)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
    }

    func testCTA20_mouseMovedIsGatedByAnAttachedSheet() throws {
        let rig = makeRig()
        setFollows(true)
        try makeKey(rig.window)
        let sheet = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        sheet.isReleasedWhenClosed = false
        rig.window.beginSheet(sheet)
        XCTAssertNotNil(rig.window.attachedSheet)
        try send(.mouseMoved, at: emptyPoint(1), in: rig.window)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
    }

    func testCTA21_mouseMovedIsGatedByArrangeMode() throws {
        let rig = makeRig()
        setFollows(true)
        try makeKey(rig.window)
        ComposableTabsArrangeMode.shared.setEnabled(true, in: rig.window)
        try send(.mouseMoved, at: emptyPoint(1), in: rig.window)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
    }

    func testCTA22_eventOutsideAnyPaneIsIgnored() throws {
        let rig = makeRig(panes: 1)
        let log = observeChanges()
        try send(.leftMouseDown, at: NSPoint(x: 500, y: 300), in: rig.window)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
        XCTAssertEqual(log.count(for: rig.window), 0)
    }

    func testCTA23_eventOnTheAlreadyActivePaneIsANoOp() throws {
        let rig = makeRig()
        setFollows(true)
        try makeKey(rig.window)
        let log = observeChanges()
        try send(.leftMouseDown, at: emptyPoint(0), in: rig.window)
        try send(.mouseMoved, at: emptyPoint(0), in: rig.window)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
        XCTAssertEqual(log.count(for: rig.window), 0)
    }

    func testCTA24_clickActivatesADifferentPaneDirectly() throws {
        let rig = makeRig()
        try send(.leftMouseDown, at: emptyPoint(1), in: rig.window)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[1].nodeID)
    }

    func testCTA25_mouseMovedTakesFocusBeforeActivating() throws {
        let rig = makeRig()
        setFollows(true)
        try makeKey(rig.window)
        try send(.mouseMoved, at: childPoint(1), in: rig.window)
        XCTAssertTrue(rig.window.firstResponder === rig.focus[1])
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[1].nodeID)
    }

    func testCTA26_focusRefusalBlocksMouseMovedActivation() throws {
        let rig = makeRig()
        setFollows(true)
        try makeKey(rig.window)
        XCTAssertTrue(rig.window.makeFirstResponder(rig.focus[0]))
        rig.focus[0].refusesResign = true
        try send(.mouseMoved, at: childPoint(1), in: rig.window)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
        XCTAssertTrue(rig.window.firstResponder === rig.focus[0])
    }

    func testCTA27_theEventMonitorNeverConsumesAnEvent() throws {
        let rig = makeRig()
        // AppKit hands a mouse-down to the view under it only in a window it
        // will route events to, so the window is made key first.
        try makeKey(rig.window)
        try send(.leftMouseDown, at: childPoint(1), in: rig.window)
        XCTAssertEqual(rig.focus[1].mouseDownCount, 1)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[1].nodeID)
    }

    func testCTA28_focusWalkProceedsInnermostToOutermost() throws {
        let rig = makeRig()
        setFollows(true)
        try makeKey(rig.window)
        let inner = FocusView(frame: NSRect(x: 10, y: 10, width: 50, height: 50))
        inner.accepts = false
        let outer = FocusView(frame: NSRect(x: 150, y: 150, width: 100, height: 100))
        outer.addSubview(inner)
        rig.panes[1].addSubview(outer)
        try send(.mouseMoved, at: NSPoint(x: 300 + 150 + 10 + 25, y: 150 + 10 + 25), in: rig.window)
        XCTAssertTrue(rig.window.firstResponder === outer)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[1].nodeID)
    }

    func testCTA29_focusWalkTreatsTheCurrentResponderAsAlreadyTaken() throws {
        let rig = makeRig()
        setFollows(true)
        try makeKey(rig.window)
        XCTAssertTrue(rig.window.makeFirstResponder(rig.focus[1]))
        rig.focus[1].becomeCount = 0
        try send(.mouseMoved, at: childPoint(1), in: rig.window)
        XCTAssertEqual(rig.focus[1].becomeCount, 0)
        XCTAssertTrue(rig.window.firstResponder === rig.focus[1])
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[1].nodeID)
    }

    func testCTA30_focusWalkStopsOnOutgoingRefusal() throws {
        let rig = makeRig()
        setFollows(true)
        try makeKey(rig.window)
        let grandchild = FocusView(frame: NSRect(x: 10, y: 10, width: 50, height: 50))
        rig.focus[1].addSubview(grandchild)
        XCTAssertTrue(rig.window.makeFirstResponder(rig.focus[0]))
        rig.focus[0].refusesResign = true
        try send(.mouseMoved, at: NSPoint(x: 300 + 20 + 10 + 25, y: 20 + 10 + 25), in: rig.window)
        XCTAssertEqual(grandchild.becomeCount, 0)
        XCTAssertEqual(rig.focus[1].becomeCount, 0)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
    }

    func testCTA31_focusWalkRestoresTheOriginalResponderOnExhaustion() throws {
        let rig = makeRig()
        setFollows(true)
        try makeKey(rig.window)
        XCTAssertTrue(rig.window.makeFirstResponder(rig.focus[0]))
        rig.focus[1].declinesBecoming = true
        try send(.mouseMoved, at: childPoint(1), in: rig.window)
        XCTAssertTrue(rig.window.firstResponder === rig.focus[0])
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[1].nodeID)
    }

    func testCTA32_focusWalkReportsRefusedWhenRestorationFails() throws {
        let rig = makeRig()
        setFollows(true)
        try makeKey(rig.window)
        XCTAssertTrue(rig.window.makeFirstResponder(rig.focus[0]))
        rig.focus[0].declinesBecoming = true
        rig.focus[1].declinesBecoming = true
        try send(.mouseMoved, at: childPoint(1), in: rig.window)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
    }

    // MARK: Drawing

    func testCTA33_everyPaneIsAlwaysOutlined() {
        let rig = makeRig()
        for pane in rig.panes {
            pane.applyTheme(palette(of: pane))
            XCTAssertEqual(pane.layer?.borderWidth, 2)
        }
    }

    func testCTA34_theBackdropIsAlwaysThePaneBackdropColor() throws {
        let rig = makeRig()
        for pane in rig.panes {
            pane.applyTheme(palette(of: pane))
            try assertColor(pane.layer?.backgroundColor, palette(of: pane).projectPaneBackdrop)
        }
    }

    func testCTA35_theActivePaneUsesTheAccentOutlineColor() throws {
        let rig = makeRig()
        try makeKey(rig.window)
        let paneColors = palette(of: rig.panes[0])
        XCTAssertNotEqual(
            try rgba(srgb(paneColors.projectActivePaneOutline).cgColor),
            try rgba(srgb(paneColors.projectPaneOutline).cgColor)
        )
        rig.panes[0].applyTheme(paneColors)
        try assertColor(rig.panes[0].layer?.borderColor, paneColors.projectActivePaneOutline)
    }

    func testCTA36_everyOtherPaneUsesTheHairlineOutlineColor() throws {
        let rig = makeRig()
        try makeKey(rig.window)
        let paneColors = palette(of: rig.panes[1])
        rig.panes[1].applyTheme(paneColors)
        try assertColor(rig.panes[1].layer?.borderColor, paneColors.projectPaneOutline)
        setHighlight(false)
        rig.panes[0].applyTheme(paneColors)
        try assertColor(rig.panes[0].layer?.borderColor, paneColors.projectPaneOutline)
    }

    func testCTA37_theAccentColorRequiresAFocusedWindow() throws {
        let rig = makeRig()
        try makeNotKey(rig)
        let paneColors = palette(of: rig.panes[0])
        rig.panes[0].applyTheme(paneColors)
        try assertColor(rig.panes[0].layer?.borderColor, paneColors.projectPaneOutline)
    }

    func testCTA38_anAttachedSheetCountsTheWindowAsFocused() throws {
        let rig = makeRig()
        try makeKey(rig.window)
        let sheet = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        sheet.isReleasedWhenClosed = false
        rig.window.beginSheet(sheet)
        sheet.makeKeyAndOrderFront(nil)
        drain()
        try XCTSkipUnless(sheet.isKeyWindow && !rig.window.isKeyWindow, "The sheet did not take key")
        let paneColors = palette(of: rig.panes[0])
        rig.panes[0].applyTheme(paneColors)
        try assertColor(rig.panes[0].layer?.borderColor, paneColors.projectActivePaneOutline)
    }

    func testCTA39_aThemeOverrideTakesPrecedenceOverTheUserSetting() throws {
        throw XCTSkip("No seam: the override lives on the active theme, which a test cannot swap per pane")
    }

    func testCTA40_theFillIsInsetFromTheBackdropEdges() throws {
        let rig = makeRig(panes: 1)
        let pane = rig.panes[0]
        pane.layoutSubtreeIfNeeded()
        let fill = try XCTUnwrap(pane.subviews.first)
        let inset = Pane.borderInset
        XCTAssertEqual(inset, 2)
        XCTAssertEqual(fill.frame, pane.bounds.insetBy(dx: inset, dy: inset))
    }

    func testCTA41_theFillIsTheFirstSubview() {
        let pane = Pane(nodeID: UUID())
        let first = pane.subviews.first
        XCTAssertNotNil(first)
        pane.addSubview(NSView())
        XCTAssertTrue(pane.subviews.first === first)
    }

    func testCTA42_aWindowChangeReportsDepartureBeforeArrival() {
        let source = makeRig(panes: 1)
        let target = makeWindow()
        let log = observeChanges()
        target.contentView?.addSubview(source.panes[0])
        let sourceID = ObjectIdentifier(source.window)
        let targetID = ObjectIdentifier(target)
        let order = log.windows.filter { $0 == sourceID || $0 == targetID }
        XCTAssertEqual(order, [sourceID, targetID])
    }

    func testCTA43_theBackdropRepaintsOnItsOwnWindowsActivationChange() {
        let rig = makeRig()
        let other = makeWindow()
        rig.panes[0].layer?.borderWidth = 7
        NotificationCenter.default.post(name: ComposableTabsActivePane.didChangeNotification, object: other)
        XCTAssertEqual(rig.panes[0].layer?.borderWidth, 7)
        NotificationCenter.default.post(name: ComposableTabsActivePane.didChangeNotification, object: rig.window)
        XCTAssertEqual(rig.panes[0].layer?.borderWidth, 2)
    }

    func testCTA44_theBackdropRepaintsOnAnyKeyWindowChange() {
        let rig = makeRig()
        let other = makeWindow()
        rig.panes[0].layer?.borderWidth = 7
        NotificationCenter.default.post(name: NSWindow.didBecomeKeyNotification, object: other)
        XCTAssertEqual(rig.panes[0].layer?.borderWidth, 2)
        rig.panes[0].layer?.borderWidth = 7
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: other)
        XCTAssertEqual(rig.panes[0].layer?.borderWidth, 2)
    }

    func testCTA45_theBackdropRepaintsOnAHighlightSettingChange() {
        let rig = makeRig()
        rig.panes[0].layer?.borderWidth = 7
        setHighlight(false)
        drain { rig.panes[0].layer?.borderWidth != 7 }
        XCTAssertEqual(rig.panes[0].layer?.borderWidth, 2)
    }

    func testCTA46_aHiddenPaneRemainsLive() {
        let rig = makeRig()
        rig.panes[1].isHidden = true
        rig.panes[0].removeFromSuperview()
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[1].nodeID)
    }

    func testCTA47_isInActivePaneIgnoresKeyWindow() throws {
        let rig = makeRig()
        try makeNotKey(rig)
        let whileBackground = tracker.isInActivePane(rig.focus[0])
        let whileBackgroundOther = tracker.isInActivePane(rig.focus[1])
        try makeKey(rig.window)
        XCTAssertTrue(whileBackground)
        XCTAssertFalse(whileBackgroundOther)
        XCTAssertTrue(tracker.isInActivePane(rig.focus[0]))
        XCTAssertFalse(tracker.isInActivePane(rig.focus[1]))
    }

    func testCTA48_anEventWithNoWindowIsIgnored() throws {
        let rig = makeRig()
        let log = observeChanges()
        try send(.leftMouseDown, at: emptyPoint(1), in: nil)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
        XCTAssertEqual(log.count(for: rig.window), 0)
    }

    func testCTA49_aNilContentViewMeansNoPane() throws {
        let rig = makeRig()
        let bare = makeWindow()
        bare.contentView = nil
        let log = observeChanges()
        try send(.leftMouseDown, at: emptyPoint(1), in: bare)
        XCTAssertNil(tracker.activeNodeID(in: bare))
        XCTAssertEqual(log.count(for: bare), 0)
        XCTAssertEqual(tracker.activeNodeID(in: rig.window), rig.panes[0].nodeID)
    }

    func testCTA50_eventMonitorIsLocalToTheAppsOwnWindows() throws {
        throw XCTSkip("A window belonging to another application cannot be created from inside this process")
    }

    func testCTA51_closeAndHighlightChangesDispatchThroughTheMainQueue() {
        let rig = makeRig()
        rig.window.close()
        drainEventTracking(until: { tracker.activeNodeID(in: rig.window) == nil })
        XCTAssertNil(tracker.activeNodeID(in: rig.window))

        let other = makeRig(panes: 1)
        other.panes[0].layer?.borderWidth = 7
        UserSettings.shared.set(false, for: UserSettings.highlightActivePane)
        drainEventTracking(until: { other.panes[0].layer?.borderWidth == 2 })
        XCTAssertEqual(other.panes[0].layer?.borderWidth, 2)
    }

    func testCTA52_anUnclaimedWindowDrawsNoAccentEvenThoughMembershipReportsTrue() throws {
        let rig = makeRig()
        rig.window.close()
        drain()
        XCTAssertNil(tracker.activeNodeID(in: rig.window))
        for (index, pane) in rig.panes.enumerated() {
            let paneColors = palette(of: pane)
            pane.applyTheme(paneColors)
            try assertColor(pane.layer?.borderColor, paneColors.projectPaneOutline)
            XCTAssertTrue(tracker.isInActivePane(rig.focus[index]))
        }
    }

    func testCTA53_contrastAppliesNoAdjustment() throws {
        let rig = makeRig()
        try makeKey(rig.window)
        let paneColors = palette(of: rig.panes[0])
        rig.panes[0].applyTheme(paneColors)
        try assertColor(rig.panes[0].layer?.borderColor, paneColors.projectActivePaneOutline)
    }

    func testCTA54_confinesToUiThread() throws {
        throw XCTSkip("Verified by inspection only: @MainActor isolation is enforced at build time")
    }
}
