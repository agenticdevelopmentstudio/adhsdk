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
    var authorizationRequests = 0

    func requestAuthorization() { authorizationRequests += 1 }
    func post(_ request: UNNotificationRequest) { posted.append(request) }
    func removeDelivered(withIdentifiers identifiers: [String]) { removed.append(identifiers) }
}

@MainActor
final class FullScreenAndSystemPresenterTests: XCTestCase {

    private final class Recorder {
        var snoozes: [SnoozeOption] = []
        var acts: [String] = []
    }

    private func actions(_ recorder: Recorder, id: String = "a") -> NoticeCardActions {
        NoticeCardActions(
            act: { recorder.acts.append(id) }, respond: { _, _ in },
            snooze: { recorder.snoozes.append($0) }, archive: {}, close: {})
    }

    private let profile = NoticeRoutingRules.defaults.profiles[.emergency]!

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

    func testFullScreenPanelCoversTheScreenAndTakesFocus() {
        _ = NSApplication.shared
        let frame = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let panel = FullScreenPresenter.makePanel(frame: frame, layer: .floating, hideFromSharing: true)
        defer { panel.close() }
        XCTAssertTrue(panel.takesFocus)
        XCTAssertTrue(panel.canBecomeKey)
        XCTAssertFalse(panel.styleMask.contains(.nonactivatingPanel))
        XCTAssertEqual(panel.frame, frame)
        XCTAssertEqual(panel.sharingType, .none)
    }

    // MARK: System

    func testSystemPresenterPostsUnderTheNoticeID() throws {
        let poster = FakePoster()
        let presenter = SystemNotificationPresenter(poster: poster, playsSound: { false })
        let notice = Notice(
            id: "n1", source: "ci", title: "Build failed", body: "3 tests red", category: "builds")
        presenter.show(notice, profile: profile, actions: .inert)

        XCTAssertEqual(poster.authorizationRequests, 1)
        let request = try XCTUnwrap(poster.posted.first)
        XCTAssertEqual(request.identifier, "n1")
        XCTAssertEqual(request.content.title, "Build failed")
        XCTAssertEqual(request.content.body, "3 tests red")
        XCTAssertEqual(request.content.subtitle, "ci · builds")
        XCTAssertNil(request.content.sound)
        XCTAssertEqual(presenter.shownIDs, ["n1"])

        presenter.show(Notice(id: "n2", source: "ci", title: "x", subtitle: "own"), profile: profile, actions: .inert)
        XCTAssertEqual(poster.posted.last?.content.subtitle, "own", "a notice's own subtitle wins")
        XCTAssertEqual(poster.authorizationRequests, 1, "authorization is asked once")
    }

    func testSystemPresenterRemoveAndReplace() {
        let poster = FakePoster()
        let presenter = SystemNotificationPresenter(poster: poster, playsSound: { true })
        presenter.show(Notice(id: "a", source: "ci", title: "running"), profile: profile, actions: .inert)
        XCTAssertNotNil(poster.posted.last?.content.sound)

        presenter.replace(
            oldID: "a", with: Notice(id: "b", source: "ci", title: "passed"), profile: profile, actions: .inert)
        XCTAssertEqual(poster.removed, [["a"]])
        XCTAssertEqual(poster.posted.last?.identifier, "b")
        XCTAssertEqual(presenter.shownIDs, ["b"])

        presenter.remove(id: "b")
        XCTAssertEqual(poster.removed.last, ["b"])
        XCTAssertTrue(presenter.shownIDs.isEmpty)
    }

    func testTapRoutesToAct() {
        let poster = FakePoster()
        let presenter = SystemNotificationPresenter(poster: poster, playsSound: { false })
        let recorder = Recorder()
        presenter.show(Notice(id: "a", source: "ci", title: "x"), profile: profile, actions: actions(recorder))
        presenter.handleTap(identifier: "a")
        XCTAssertEqual(recorder.acts, ["a"])

        presenter.handleTap(identifier: "unknown")
        XCTAssertEqual(recorder.acts, ["a"], "a banner this presenter no longer tracks does nothing")
    }
}
