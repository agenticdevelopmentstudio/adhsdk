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
        ToastStackWindow(position: position, layer: .floating, hideFromSharing: false, store: store)
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

    private func toast(_ position: NoticeProfile.Position) -> NoticeProfile {
        NoticeProfile(style: .toast, position: position)
    }
}
