import AppKit
import UserNotifications
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

/// Posts nothing to the real Notification Center.
@MainActor
private final class FakePoster: SystemNotificationPosting {
    var posted: [UNNotificationRequest] = []
    var removed: [[String]] = []
    var removedPending: [[String]] = []
    var authorizationRequests = 0
    var delegations = 0

    func becomeDelegate() { delegations += 1 }
    func requestAuthorization() { authorizationRequests += 1 }
    func post(_ request: UNNotificationRequest) { posted.append(request) }
    func removeDelivered(withIdentifiers identifiers: [String]) { removed.append(identifiers) }
    func removePending(withIdentifiers identifiers: [String]) { removedPending.append(identifiers) }
}

@MainActor
final class FullScreenAndSystemPresenterTests: XCTestCase {

    private final class Recorder {
        var snoozes: [SnoozeOption] = []
        var acts: [String] = []
        var closes: [String] = []
    }

    private func actions(_ recorder: Recorder, id: String = "a") -> NoticeCardActions {
        NoticeCardActions(
            act: { recorder.acts.append(id) }, respond: { _, _ in },
            snooze: { recorder.snoozes.append($0) }, archive: {}, close: { recorder.closes.append(id) })
    }

    private let profile = NoticeRoutingRules.defaults.styles[.emergency]!.items[0]

    // MARK: Full screen

    func testEscapeSnoozesFiveMinutes() throws {
        _ = NSApplication.shared
        let recorder = Recorder()
        let view = FullScreenNoticeView(
            notice: Notice(source: "pager", title: "Prod down", urgency: .emergency), actions: actions(recorder))
        view.cancelOperation(nil)
        XCTAssertEqual(recorder.snoozes, [.fiveMinutes])

        let escape = try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil,
            characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false, keyCode: 53))
        view.keyDown(with: escape)
        XCTAssertEqual(recorder.snoozes, [.fiveMinutes, .fiveMinutes])
        XCTAssertTrue(view.acceptsFirstResponder)
    }

    /// Non-activating, so it takes the keyboard without waiting on a
    /// cooperative `NSApp.activate()`; above the menu bar whatever its layer.
    func testFullScreenPanelCoversTheScreenAndTakesFocus() {
        _ = NSApplication.shared
        let frame = CGRect(x: 0, y: 0, width: 1512, height: 982)
        for layer in NoticeProfile.Layer.allCases {
            let panel = FullScreenPresenter.makePanel(frame: frame, layer: layer, hideFromSharing: true)
            defer { panel.close() }
            XCTAssertTrue(panel.takesFocus)
            XCTAssertTrue(panel.canBecomeKey)
            XCTAssertTrue(panel.styleMask.contains(.nonactivatingPanel))
            XCTAssertGreaterThanOrEqual(panel.level.rawValue, NSWindow.Level.statusBar.rawValue, "\(layer)")
            XCTAssertEqual(panel.frame, frame)
            XCTAssertEqual(panel.sharingType, .none)
        }
    }

    private func fullScreen(_ windowing: RecordingWindowing, screens: @escaping () -> [NoticeScreen])
        -> FullScreenPresenter {
        _ = NSApplication.shared
        return FullScreenPresenter(
            rules: { .defaults }, windowing: windowing, screens: { _ in screens() })
    }

    func testRemovingTheKeyFullScreenHandsKeyToTheNextOne() throws {
        let windowing = RecordingWindowing()
        let presenter = fullScreen(windowing) { [testScreen(1)] }
        presenter.show(Notice(id: "a", source: "pager", title: "a"), profiles: [profile], actions: .inert)
        presenter.show(Notice(id: "b", source: "pager", title: "b"), profiles: [profile], actions: .inert)
        let panelA = try XCTUnwrap(presenter.panels(for: "a").first)
        let panelB = try XCTUnwrap(presenter.panels(for: "b").first)
        XCTAssertTrue(windowing.keyed.last === panelB, "the newest takes the keyboard")
        XCTAssertTrue(panelB.firstResponder is FullScreenNoticeView)

        presenter.remove(id: "b")
        XCTAssertTrue(windowing.dismissed.contains { $0 === panelB })
        XCTAssertTrue(windowing.keyed.last === panelA, "the one left takes the keyboard back")
        XCTAssertEqual(presenter.shownIDs, ["a"])

        let keyCount = windowing.keyed.count
        presenter.remove(id: "a")
        XCTAssertEqual(windowing.keyed.count, keyCount, "none left, nothing to make key")
    }

    func testScreenChangeRefitsFullScreenPanels() throws {
        let windowing = RecordingWindowing()
        var screens = [testScreen(1)]
        let presenter = fullScreen(windowing) { screens }
        presenter.show(Notice(id: "a", source: "pager", title: "a"), profiles: [profile], actions: .inert)
        let panel = try XCTUnwrap(presenter.panels(for: "a").first)
        XCTAssertEqual(panel.frame, screens[0].frame)
        screens = [testScreen(1, width: 2560)]
        presenter.screensDidChange()
        XCTAssertEqual(panel.frame, screens[0].frame)
        presenter.remove(id: "a")
    }

    /// Esc while replying in full screen hands the keyboard back to the
    /// backdrop, so a second Esc still snoozes.
    func testEndingAFullScreenReplyRestoresTheBackdrop() throws {
        _ = NSApplication.shared
        let notice = Notice(
            id: "q", source: "agent", title: "Which branch?", urgency: .emergency,
            actions: [.init(id: "answer", label: "Reply", kind: .reply(placeholder: nil))])
        let panel = FullScreenPresenter.makePanel(
            frame: CGRect(x: 0, y: 0, width: 800, height: 600), layer: .floating, hideFromSharing: false)
        defer { panel.close() }
        let view = FullScreenNoticeView(notice: notice, actions: .inert)
        panel.contentView = view
        XCTAssertTrue(view.card.focusReply())
        view.card.endReply()
        XCTAssertTrue(panel.firstResponder === view)
    }

    // MARK: System

    func testSystemPresenterPostsUnderTheNoticeID() throws {
        let poster = FakePoster()
        let presenter = SystemNotificationPresenter(poster: poster, playsSound: { false })
        let notice = Notice(
            id: "n1", source: "ci", title: "Build failed", body: "3 tests red", category: "builds")
        presenter.show(notice, profiles: [profile], actions: .inert)

        XCTAssertEqual(poster.authorizationRequests, 1)
        let request = try XCTUnwrap(poster.posted.first)
        XCTAssertEqual(request.identifier, "n1")
        XCTAssertEqual(request.content.title, "Build failed")
        XCTAssertEqual(request.content.body, "3 tests red")
        XCTAssertEqual(request.content.subtitle, "ci · builds")
        XCTAssertNil(request.content.sound)
        XCTAssertEqual(presenter.shownIDs, ["n1"])

        presenter.show(
            Notice(id: "n2", source: "ci", title: "x", subtitle: "own"), profiles: [profile], actions: .inert)
        XCTAssertEqual(poster.posted.last?.content.subtitle, "own", "a notice's own subtitle wins")
        XCTAssertEqual(poster.authorizationRequests, 1, "authorization is asked once")
    }

    func testSystemPresenterRemoveAndReplace() {
        let poster = FakePoster()
        let presenter = SystemNotificationPresenter(poster: poster, playsSound: { true })
        presenter.show(Notice(id: "a", source: "ci", title: "running"), profiles: [profile], actions: .inert)
        XCTAssertNotNil(poster.posted.last?.content.sound)

        presenter.replace(
            oldID: "a", with: Notice(id: "b", source: "ci", title: "passed"), profiles: [profile], actions: .inert)
        XCTAssertEqual(poster.removed, [["a"]])
        XCTAssertEqual(poster.posted.last?.identifier, "b")
        XCTAssertEqual(presenter.shownIDs, ["b"])

        presenter.remove(id: "b")
        XCTAssertEqual(poster.removed.last, ["b"])
        XCTAssertTrue(presenter.shownIDs.isEmpty)
    }

    func testStartBecomesTheDelegateBeforeAnyNotice() {
        let poster = FakePoster()
        let presenter = SystemNotificationPresenter(poster: poster, playsSound: { false })
        presenter.start()
        presenter.start()
        XCTAssertEqual(poster.delegations, 1, "once, at launch, so banner clicks after a relaunch arrive")
        XCTAssertTrue(poster.posted.isEmpty)
    }

    func testRemoveWithdrawsPendingAndDelivered() {
        let poster = FakePoster()
        let presenter = SystemNotificationPresenter(poster: poster, playsSound: { false })
        presenter.show(Notice(id: "a", source: "ci", title: "x"), profiles: [profile], actions: .inert)
        XCTAssertEqual(
            poster.posted.last?.content.categoryIdentifier, SystemNotificationPresenter.categoryIdentifier,
            "the category asks for the dismiss callback")
        presenter.remove(id: "a")
        XCTAssertEqual(poster.removed, [["a"]])
        XCTAssertEqual(poster.removedPending, [["a"]])
    }

    func testClearingABannerClosesTheNotice() {
        let poster = FakePoster()
        let presenter = SystemNotificationPresenter(poster: poster, playsSound: { false })
        let recorder = Recorder()
        presenter.show(Notice(id: "a", source: "ci", title: "x"), profiles: [profile], actions: actions(recorder))
        presenter.handleDismiss(identifier: "a")
        XCTAssertEqual(recorder.closes, ["a"], "a banner the user cleared leaves the newest-shown order")
        presenter.handleDismiss(identifier: "unknown")
        XCTAssertEqual(recorder.closes, ["a"])
    }

    func testTapRoutesToAct() {
        let poster = FakePoster()
        let presenter = SystemNotificationPresenter(poster: poster, playsSound: { false })
        let recorder = Recorder()
        presenter.show(Notice(id: "a", source: "ci", title: "x"), profiles: [profile], actions: actions(recorder))
        presenter.handleTap(identifier: "a")
        XCTAssertEqual(recorder.acts, ["a"])

        presenter.handleTap(identifier: "unknown")
        XCTAssertEqual(recorder.acts, ["a"], "a banner this presenter no longer tracks does nothing")
    }
}

/// Finding 7: `replace` keeps a card in place only when the rules still put
/// it on the same screens.
@MainActor
final class CardStackReplaceTests: XCTestCase {

    private var rules = NoticeRoutingRules.defaults

    // Fake display ids with no NSScreen: layout orders their panels out, so
    // nothing reaches the real screen.
    private func presenter() -> ToastPresenter {
        let presenter = ToastPresenter(rules: { [unowned self] in rules }, showHistory: {})
        presenter.displays = { selection in
            switch selection {
            case .main: [1]
            case .all: [1, 2]
            }
        }
        return presenter
    }

    private let profiles = [NoticeProfile(style: .toast, position: .bottomRight)]

    private let actions = NoticeCardActions(
        act: {}, respond: { _, _ in }, snooze: nil, archive: nil, close: {})

    func testReplaceOntoOtherScreensMovesTheCard() {
        rules.screens = .main
        let presenter = presenter()
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: profiles, actions: actions)
        XCTAssertEqual(presenter.displayIDs(of: "a"), [1])

        rules.screens = .all
        presenter.replace(
            oldID: "a", with: Notice(id: "a", source: "ci", title: "a"), profiles: profiles, actions: actions)

        XCTAssertEqual(Set(presenter.displayIDs(of: "a")), [1, 2])
        XCTAssertEqual(presenter.shownIDs, ["a"])
        presenter.remove(id: "a")
    }

    func testReplaceOntoTheSameScreensStaysInPlace() {
        rules.screens = .all
        let presenter = presenter()
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: profiles, actions: actions)
        let before = presenter.panels(of: "a")
        XCTAssertEqual(before.count, 2)

        presenter.replace(
            oldID: "a", with: Notice(id: "b", source: "ci", title: "b"), profiles: profiles, actions: actions)

        XCTAssertEqual(Set(presenter.displayIDs(of: "b")), [1, 2])
        XCTAssertEqual(presenter.displayIDs(of: "a"), [])
        XCTAssertEqual(presenter.shownIDs, ["b"])
        assertSamePanels(before, presenter.panels(of: "b"))
        presenter.remove(id: "b")
    }

    func testReplaceKeepsACardInPlaceWhenTheSameSelectionResolvesToOtherDisplays() {
        rules.screens = .main
        let presenter = presenter()
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: profiles, actions: actions)
        let before = presenter.panels(of: "a")
        XCTAssertEqual(presenter.displayIDs(of: "a"), [1])

        // The main screen is now display 3; the selection is still `.main`.
        presenter.displays = { _ in [3] }
        presenter.replace(
            oldID: "a", with: Notice(id: "b", source: "ci", title: "b"), profiles: profiles, actions: actions)

        assertSamePanels(before, presenter.panels(of: "b"))
        XCTAssertEqual(presenter.displayIDs(of: "b"), [1], "the card stays where it was shown")
        presenter.remove(id: "b")
    }

    func testReplaceWithNoProfilesRemovesTheCard() {
        let presenter = presenter()
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: profiles, actions: actions)
        presenter.replace(
            oldID: "a", with: Notice(id: "b", source: "ci", title: "b"), profiles: [], actions: actions)
        XCTAssertTrue(presenter.shownIDs.isEmpty)
        XCTAssertEqual(presenter.displayIDs(of: "a"), [])
        XCTAssertEqual(presenter.displayIDs(of: "b"), [])
    }

    private func assertSamePanels(
        _ before: [NoticePanel], _ after: [NoticePanel], file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertEqual(before.count, after.count, file: file, line: line)
        for (old, new) in zip(before, after) {
            XCTAssertTrue(old === new, "the panel was replaced instead of updated in place", file: file, line: line)
        }
    }
}
