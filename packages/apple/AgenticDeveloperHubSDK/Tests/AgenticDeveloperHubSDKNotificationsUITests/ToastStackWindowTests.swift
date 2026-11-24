import AppKit
import XCTest
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

@MainActor
final class ToastStackWindowTests: XCTestCase {

    private let visible = CGRect(x: 0, y: 0, width: 1400, height: 900)
    private var suiteName = ""
    private var store = SettingsStore()
    private var rules = NoticeRoutingRules.defaults
    /// Far from every window, unless a test moves it.
    private var pointer = NSPoint(x: -5000, y: -5000)

    override func setUp() async throws {
        try await super.setUp()
        _ = NSApplication.shared
        suiteName = "ToastStackWindowTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        store = SettingsStore(
            with: UserDefaultsSettingsStorageProvider(defaults: defaults),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
    }

    override func tearDown() async throws {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        try await super.tearDown()
    }

    private func card(_ id: String) -> NoticeCardView {
        NoticeCardView(notice: Notice(id: id, source: "ci", title: id), actions: .inert, style: .toast)
    }

    private func window(_ position: NoticeProfile.Position = .bottomRight) -> ToastStackWindow {
        let window = ToastStackWindow(position: position, layer: .floating, hideFromSharing: false, store: store)
        window.mouseLocation = { [unowned self] in pointer }
        return window
    }

    private var offsets: [String: NoticeStackOffset] { store.get(NoticeSettings.toastStackOffsets) }

    func testChromeHiddenUntilHoverAndCardsDoNotMove() {
        let window = window()
        let cards = [card("a"), card("b")]
        window.arrange(views: cards, visible: visible)
        XCTAssertFalse(window.isChromeVisible)
        let frame = window.frame
        let before = cards.map(\.frame)
        XCTAssertGreaterThan(before[0].height, 0)

        window.setChromeVisible(true, animated: false)
        XCTAssertTrue(window.isChromeVisible)
        XCTAssertEqual(cards.map(\.frame), before)
        XCTAssertEqual(window.frame, frame)
    }

    func testDragEndPersistsOffsetPerPosition() {
        let window = window(.bottomRight)
        window.arrange(views: [card("a")], visible: visible)
        let anchored = window.frame
        window.setFrameOrigin(NSPoint(x: anchored.minX - 120, y: anchored.minY + 60))
        window.finishDrag()
        XCTAssertEqual(offsets["bottomRight"], NoticeStackOffset(dx: -120, dy: 60))
        XCTAssertNil(offsets["topLeft"])

        // A new window for the position, on any screen, starts there.
        let other = self.window(.bottomRight)
        other.arrange(views: [card("b")], visible: visible)
        XCTAssertEqual(other.frame.minX, anchored.minX - 120)
        XCTAssertEqual(other.frame.minY, anchored.minY + 60)

        let elsewhere = self.window(.topLeft)
        elsewhere.arrange(views: [card("c")], visible: visible)
        XCTAssertEqual(
            ToastStackGeometry.offset(
                of: elsewhere.frame,
                from: ToastStackGeometry.windowFrame(
                    stackSize: CGSize(width: elsewhere.frame.width - 16, height: elsewhere.frame.height - 38),
                    position: .topLeft, visible: visible, offset: .zero)),
            .zero)
    }

    func testResetClearsOffsetAndHidesButton() {
        let window = window()
        window.arrange(views: [card("a")], visible: visible)
        XCTAssertTrue(window.chrome.resetButton.isHidden)
        let anchored = window.frame
        window.setFrameOrigin(NSPoint(x: anchored.minX - 50, y: anchored.minY))
        window.finishDrag()
        XCTAssertFalse(window.chrome.resetButton.isHidden)

        window.resetOffset()
        XCTAssertNil(offsets["bottomRight"])
        XCTAssertTrue(window.chrome.resetButton.isHidden)
        XCTAssertEqual(window.frame, anchored)
    }

    func testHoveringTheWindowPausesEveryCountdown() {
        let window = window()
        let cards = [card("a"), card("b")]
        for card in cards { card.startAutoDismiss(after: 30) }
        window.arrange(views: cards, visible: visible)
        XCTAssertTrue(cards.allSatisfy(\.isCountdownRunning))

        window.setHovered(true)
        XCTAssertTrue(cards.allSatisfy { !$0.isCountdownRunning }, "one hover holds every card")
        XCTAssertTrue(window.isChromeVisible)

        window.setHovered(false)
        XCTAssertTrue(cards.allSatisfy(\.isCountdownRunning))
        cards.forEach { $0.stop() }
    }

    func testOneWindowPerStackForToastsButAlertsKeepPanels() {
        let toasts = ToastPresenter(rules: { [unowned self] in rules }, showHistory: {}, store: store)
        toasts.displays = { _ in [1] }
        toasts.show(Notice(id: "a", source: "ci", title: "a"), profiles: [toast(.bottomRight)], actions: .inert)
        toasts.show(Notice(id: "b", source: "ci", title: "b"), profiles: [toast(.bottomRight)], actions: .inert)
        toasts.show(Notice(id: "c", source: "ci", title: "c"), profiles: [toast(.topLeft)], actions: .inert)
        XCTAssertTrue(toasts.panels(of: "a")[0] === toasts.panels(of: "b")[0])
        XCTAssertTrue(toasts.panels(of: "a")[0] is ToastStackWindow)
        XCTAssertFalse(toasts.panels(of: "a")[0] === toasts.panels(of: "c")[0])
        ["a", "b", "c"].forEach { toasts.remove(id: $0) }

        let alerts = AlertPresenter(rules: { [unowned self] in rules })
        alerts.displays = { _ in [1] }
        for id in ["a", "b"] {
            alerts.show(
                Notice(id: id, source: "ci", title: id),
                profiles: [NoticeProfile(style: .alert, position: .center)], actions: .inert)
        }
        XCTAssertFalse(alerts.panels(of: "a")[0] === alerts.panels(of: "b")[0])
        XCTAssertFalse(alerts.panels(of: "a")[0] is ToastStackWindow)
        ["a", "b"].forEach { alerts.remove(id: $0) }
    }

    // MARK: Real pointer paths

    private func mouse(_ type: NSEvent.EventType, in window: NSWindow, atScreen point: NSPoint) -> NSEvent {
        guard let event = NSEvent.mouseEvent(
            with: type, location: window.convertPoint(fromScreen: point), modifierFlags: [], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
        else { fatalError("could not make a mouse event") }
        return event
    }

    private func barCenter(of window: ToastStackWindow) -> NSPoint {
        let bar = window.chrome.bar
        let local = NSPoint(x: bar.bounds.midX, y: bar.bounds.midY)
        return window.convertPoint(toScreen: bar.convert(local, to: nil))
    }

    func testBarDragThroughRealEventsMovesAndPersists() {
        let window = window(.bottomRight)
        window.arrange(views: [card("a")], visible: visible)
        window.setChromeVisible(true, animated: false)
        let anchored = window.frame
        let start = barCenter(of: window)
        let bar = window.chrome.bar

        bar.mouseDown(with: mouse(.leftMouseDown, in: window, atScreen: start))
        bar.mouseDragged(with: mouse(.leftMouseDragged, in: window,
                                          atScreen: NSPoint(x: start.x - 100, y: start.y)))
        XCTAssertEqual(window.frame.minX, anchored.minX - 100)
        bar.mouseDragged(with: mouse(.leftMouseDragged, in: window,
                                          atScreen: NSPoint(x: start.x - 100, y: start.y + 40)))
        bar.mouseUp(with: mouse(.leftMouseUp, in: window, atScreen: NSPoint(x: start.x - 100, y: start.y + 40)))
        XCTAssertEqual(window.frame.minX, anchored.minX - 100)
        XCTAssertEqual(window.frame.minY, anchored.minY + 40)
        XCTAssertEqual(offsets["bottomRight"], NoticeStackOffset(dx: -100, dy: 40))
    }

    func testDragPastTheScreenEdgeIsClamped() {
        let window = window(.bottomRight)
        window.arrange(views: [card("a")], visible: visible)
        let start = barCenter(of: window)
        let bar = window.chrome.bar
        bar.mouseDown(with: mouse(.leftMouseDown, in: window, atScreen: start))
        bar.mouseDragged(with: mouse(.leftMouseDragged, in: window,
                                          atScreen: NSPoint(x: start.x + 5000, y: start.y + 5000)))
        XCTAssertEqual(window.frame.maxX, visible.maxX)
        XCTAssertEqual(window.frame.maxY, visible.maxY)
        bar.mouseDragged(with: mouse(.leftMouseDragged, in: window,
                                          atScreen: NSPoint(x: start.x - 9000, y: start.y - 9000)))
        XCTAssertEqual(window.frame.minX, visible.minX)
        XCTAssertEqual(window.frame.minY, visible.minY)
        bar.mouseUp(with: mouse(.leftMouseUp, in: window, atScreen: start))
        XCTAssertTrue(visible.contains(window.frame))
    }

    func testGapsAndMarginsAreClickThroughWithChromeHiddenOrShown() throws {
        let window = window(.bottomRight)
        let cards = [card("a"), card("b")]
        window.arrange(views: cards, visible: visible)
        let content = try XCTUnwrap(window.contentView)
        let ordered = cards.map(\.frame).sorted { $0.minY < $1.minY }
        let gap = NSPoint(x: ordered[0].midX, y: (ordered[0].maxY + ordered[1].minY) / 2)
        XCTAssertGreaterThan(ordered[1].minY - ordered[0].maxY, 1, "the cards have a gap")
        let margin = NSPoint(x: 3, y: 3)

        for shown in [false, true] {
            window.setChromeVisible(shown, animated: false)
            for point in [gap, margin] {
                XCTAssertNil(window.chrome.hitTest(point), "chrome shown: \(shown) at \(point)")
                XCTAssertNil(content.hitTest(content.convert(point, to: content.superview)),
                             "content shown: \(shown) at \(point)")
            }
        }
        let bar = window.chrome.bar
        let inBar = bar.convert(NSPoint(x: bar.bounds.midX, y: bar.bounds.midY), to: content)
        window.setChromeVisible(false, animated: false)
        XCTAssertNil(window.chrome.hitTest(inBar), "a hidden bar takes no mouse")
        window.setChromeVisible(true, animated: false)
        XCTAssertNotNil(window.chrome.hitTest(inBar))
    }

    func testLayoutMidDragDoesNotSnapTheWindowBack() {
        let window = window(.bottomRight)
        window.arrange(views: [card("a")], visible: visible)
        let start = barCenter(of: window)
        let bar = window.chrome.bar
        bar.mouseDown(with: mouse(.leftMouseDown, in: window, atScreen: start))
        bar.mouseDragged(with: mouse(.leftMouseDragged, in: window,
                                          atScreen: NSPoint(x: start.x - 200, y: start.y)))
        let dragged = window.frame

        window.arrange(views: [card("a"), card("b")], visible: visible)
        XCTAssertEqual(window.frame, dragged, "a new notice must not move a window being dragged")

        bar.mouseUp(with: mouse(.leftMouseUp, in: window, atScreen: NSPoint(x: start.x - 200, y: start.y)))
        XCTAssertEqual(window.frame.minX, dragged.minX, "the drop holds, with the new card laid out")
        XCTAssertGreaterThan(window.frame.height, dragged.height)
    }

    // MARK: Hover without a mouse move

    func testArrangeSyncsHoverWithThePointer() {
        let window = window()
        let cards = [card("a")]
        cards[0].startAutoDismiss(after: 30)
        window.arrange(views: cards, visible: visible)
        XCTAssertFalse(window.isHovered)

        pointer = NSPoint(x: window.frame.midX, y: window.frame.midY)
        window.arrange(views: cards, visible: visible)
        XCTAssertTrue(window.isHovered, "the window grew under a still pointer")
        XCTAssertTrue(window.isChromeVisible)
        XCTAssertFalse(cards[0].isCountdownRunning)

        pointer = NSPoint(x: -5000, y: -5000)
        window.arrange(views: cards, visible: visible)
        XCTAssertFalse(window.isHovered)
        XCTAssertTrue(cards[0].isCountdownRunning)
        cards[0].stop()
    }

    func testFinishDragSyncsHoverWithThePointer() {
        let window = window()
        window.arrange(views: [card("a")], visible: visible)
        window.setFrameOrigin(NSPoint(x: window.frame.minX - 300, y: window.frame.minY))
        pointer = NSPoint(x: window.frame.midX, y: window.frame.midY)
        window.finishDrag()
        XCTAssertTrue(window.isHovered)

        window.setFrameOrigin(NSPoint(x: window.frame.minX - 300, y: window.frame.minY))
        window.finishDrag()
        XCTAssertFalse(window.isHovered, "the pointer was left behind")
    }

    // MARK: Fade-out delay

    func testChromeFadesOutAfterTheDelayAndReentryCancelsIt() async throws {
        let window = window()
        window.hideDelay = 0.05
        window.arrange(views: [card("a")], visible: visible)

        window.setHovered(true)
        window.setHovered(false)
        XCTAssertTrue(window.isChromeVisible, "still showing during the delay")
        window.setHovered(true)
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertTrue(window.isChromeVisible, "re-entering cancelled the fade")

        window.setHovered(false)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertFalse(window.isChromeVisible)
    }

    // MARK: A display goes away

    func testStackOnAVanishedDisplayMovesToTheMainOneAndItsWindowCloses() throws {
        guard let mainID = NSScreen.main?.noticeDisplayID else { throw XCTSkip("no screen") }
        let gone: UInt32 = 987_654
        let toasts = ToastPresenter(rules: { [unowned self] in rules }, showHistory: {}, store: store)
        toasts.displays = { _ in [mainID, gone] }
        toasts.show(Notice(id: "a", source: "ci", title: "a"), profiles: [toast(.bottomRight)], actions: .inert)
        XCTAssertEqual(toasts.stackWindowCount, 2)

        toasts.screensDidChange()
        XCTAssertEqual(toasts.displayIDs(of: "a"), [mainID], "the copy on the lost display is dropped")
        XCTAssertEqual(toasts.stackWindowCount, 1, "the lost display's window closed")

        toasts.remove(id: "a")
        XCTAssertEqual(toasts.stackWindowCount, 0)

        toasts.displays = { _ in [gone] }
        toasts.show(Notice(id: "b", source: "ci", title: "b"), profiles: [toast(.topLeft)], actions: .inert)
        toasts.screensDidChange()
        XCTAssertEqual(toasts.displayIDs(of: "b"), [mainID], "a lone copy is rehomed")
        XCTAssertEqual(toasts.stackWindowCount, 1)
        XCTAssertTrue(toasts.panels(of: "b")[0] is ToastStackWindow)
        toasts.remove(id: "b")
        XCTAssertEqual(toasts.stackWindowCount, 0)
    }

    private func toast(_ position: NoticeProfile.Position) -> NoticeProfile {
        NoticeProfile(style: .toast, position: position)
    }

    func testBorderRepaintsOnAnAppearanceFlip() {
        let border = ToastStackBorderView()
        border.layer?.borderColor = nil
        border.appearance = NSAppearance(named: .darkAqua)
        border.viewDidChangeEffectiveAppearance()
        XCTAssertNotNil(border.layer?.borderColor, "the flip re-resolves the outline")
        border.layer?.borderColor = nil
        border.appearance = NSAppearance(named: .aqua)
        border.viewDidChangeEffectiveAppearance()
        XCTAssertNotNil(border.layer?.borderColor)
    }
}
