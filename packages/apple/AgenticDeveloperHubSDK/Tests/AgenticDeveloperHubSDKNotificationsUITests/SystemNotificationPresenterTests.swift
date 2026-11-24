import UserNotifications
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

/// A Notification Center the test answers by hand.
@MainActor
private final class ControlledCenter: SystemNotificationPosting {
    var denied = false
    var posted: [String] = []
    var addError: Error?
    var authorizationRequests = 0
    /// Holds `isAuthorizationDenied` answers until `releaseDeniedAnswers()`.
    var holdDeniedAnswers = false
    private var heldDeniedAnswers: [@MainActor (Bool) -> Void] = []
    private var answer: (@MainActor (Bool, Error?) -> Void)?

    func becomeDelegate() {}
    func isAuthorizationDenied(_ completion: @escaping @MainActor (Bool) -> Void) {
        if holdDeniedAnswers {
            heldDeniedAnswers.append(completion)
        } else {
            completion(denied)
        }
    }

    func releaseDeniedAnswers() {
        holdDeniedAnswers = false
        let held = heldDeniedAnswers
        heldDeniedAnswers = []
        held.forEach { $0(denied) }
    }
    func requestAuthorization(_ completion: @escaping @MainActor (Bool, Error?) -> Void) {
        authorizationRequests += 1
        answer = completion
    }
    func post(_ request: UNNotificationRequest, completion: @escaping @MainActor (Error?) -> Void) {
        posted.append(request.identifier)
        completion(addError)
    }
    func removeDelivered(withIdentifiers identifiers: [String]) {}
    func removePending(withIdentifiers identifiers: [String]) {}

    func answerAuthorization(granted: Bool, error: Error? = nil) { answer?(granted, error) }
}

@MainActor
final class SystemNotificationPresenterTests: XCTestCase {

    private let profile = NoticeRoutingRules.defaults.styles[.emergency]!.items[0]

    private func show(_ id: String, on presenter: SystemNotificationPresenter) {
        presenter.show(Notice(id: id, source: "ci", title: id), profiles: [profile], actions: .inert)
    }

    func testShowWaitsForGrantThenPosts() {
        let center = ControlledCenter()
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        show("a", on: presenter)
        show("b", on: presenter)
        XCTAssertEqual(center.posted, [], "nothing posts before the answer")
        XCTAssertEqual(center.authorizationRequests, 1)

        center.answerAuthorization(granted: true)
        XCTAssertEqual(center.posted, ["a", "b"])
        show("c", on: presenter)
        XCTAssertEqual(center.posted, ["a", "b", "c"])
        XCTAssertEqual(center.authorizationRequests, 1)
    }

    func testDeniedDropsQueueAndCallsDeniedOnce() {
        let center = ControlledCenter()
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        var denials = 0
        presenter.onAuthorizationDenied = { denials += 1 }
        show("a", on: presenter)
        center.answerAuthorization(granted: false)
        center.denied = true
        XCTAssertEqual(center.posted, [])
        XCTAssertEqual(denials, 1)

        show("b", on: presenter)
        XCTAssertEqual(center.posted, [])
        XCTAssertEqual(denials, 1, "once per denial episode")
    }

    func testAlreadyDeniedSettingsDropsWithoutAsking() {
        let center = ControlledCenter()
        center.denied = true
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        var denials = 0
        presenter.onAuthorizationDenied = { denials += 1 }
        show("a", on: presenter)
        XCTAssertEqual(denials, 1)
        XCTAssertEqual(center.authorizationRequests, 0)
        XCTAssertEqual(center.posted, [])
    }

    func testDenialLiftedLaterPostsAgainAndReportsOncePerEpisode() {
        let center = ControlledCenter()
        center.denied = true
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        var denials = 0
        presenter.onAuthorizationDenied = { denials += 1 }
        show("a", on: presenter)
        show("b", on: presenter)
        XCTAssertEqual(denials, 1)
        XCTAssertEqual(center.posted, [])

        center.denied = false
        show("c", on: presenter)
        XCTAssertEqual(center.authorizationRequests, 1, "granted state is re-resolved through the normal path")
        center.answerAuthorization(granted: true)
        XCTAssertEqual(center.posted, ["c"])
        XCTAssertEqual(denials, 1)
    }

    func testBecomingActiveClearsALiftedDenial() {
        let center = ControlledCenter()
        center.denied = true
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        presenter.onAuthorizationDenied = {}
        show("a", on: presenter)
        center.denied = false
        presenter.appBecameActive()
        XCTAssertEqual(center.authorizationRequests, 0, "becoming active asks nothing")
        show("b", on: presenter)
        XCTAssertEqual(center.authorizationRequests, 1)
    }

    func testStillDeniedOnRecheckStaysSilent() {
        let center = ControlledCenter()
        center.denied = true
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        var denials = 0
        presenter.onAuthorizationDenied = { denials += 1 }
        show("a", on: presenter)
        presenter.appBecameActive()
        show("b", on: presenter)
        XCTAssertEqual(denials, 1)
        XCTAssertEqual(center.authorizationRequests, 0)
    }

    /// A notice closed while the recheck's answer is out never comes back.
    func testRemoveDuringRecheckNeverPosts() {
        let center = ControlledCenter()
        center.denied = true
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        presenter.onAuthorizationDenied = {}
        show("a", on: presenter)
        center.denied = false
        center.holdDeniedAnswers = true
        show("c", on: presenter)
        presenter.remove(id: "c")
        center.releaseDeniedAnswers()
        XCTAssertEqual(center.authorizationRequests, 0, "nothing left to show, so nothing is asked")
        XCTAssertEqual(center.posted, [])
    }

    /// Lifted, then turned off again: a new episode, reported again.
    func testReDenialAfterALiftReportsAgain() {
        let center = ControlledCenter()
        center.denied = true
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        var denials = 0
        presenter.onAuthorizationDenied = { denials += 1 }
        show("a", on: presenter)
        XCTAssertEqual(denials, 1)

        center.denied = false
        show("b", on: presenter)
        center.answerAuthorization(granted: false)
        XCTAssertEqual(denials, 2, "a denial after a lift is a new episode")
        XCTAssertEqual(center.posted, [])
    }

    func testAddErrorIsLoggedNotFatal() {
        let center = ControlledCenter()
        center.addError = NSError(domain: "test", code: 1)
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        show("a", on: presenter)
        center.answerAuthorization(granted: true)
        show("b", on: presenter)
        XCTAssertEqual(center.posted, ["a", "b"], "a failed add does not stop later posts")
    }

    func testAuthorizationErrorIsNotADenial() {
        let center = ControlledCenter()
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        var denials = 0
        presenter.onAuthorizationDenied = { denials += 1 }
        show("a", on: presenter)
        center.answerAuthorization(granted: false, error: NSError(domain: "test", code: 2))
        XCTAssertEqual(denials, 0)
        XCTAssertEqual(center.posted, [], "the queue is dropped")

        show("b", on: presenter)
        XCTAssertEqual(center.authorizationRequests, 2, "the next show asks again")
        center.answerAuthorization(granted: true)
        XCTAssertEqual(center.posted, ["b"])
        XCTAssertEqual(denials, 0)
    }

    func testRemoveWhilePendingNeverPosts() {
        let center = ControlledCenter()
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        show("a", on: presenter)
        show("b", on: presenter)
        presenter.remove(id: "a")
        center.answerAuthorization(granted: true)
        XCTAssertEqual(center.posted, ["b"])
    }

    /// A banner left in Notification Center after its card was handled (or
    /// from before a relaunch) has no tracked actions. Its tap and dismiss go
    /// to the host instead of being dropped.
    func testUntrackedTapAndDismissReachTheHost() {
        let center = ControlledCenter()
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        var taps: [String] = []
        var dismissals: [String] = []
        presenter.onUntrackedTap = { taps.append($0) }
        presenter.onUntrackedDismiss = { dismissals.append($0) }

        presenter.handleTap(identifier: "gone")
        presenter.handleDismiss(identifier: "old")
        XCTAssertEqual(taps, ["gone"])
        XCTAssertEqual(dismissals, ["old"])
    }

    /// A tracked banner runs its own actions; the host's callbacks stay quiet.
    func testTrackedTapAndDismissSkipTheHostCallbacks() {
        let center = ControlledCenter()
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        var acts: [String] = []
        var closes: [String] = []
        var untracked: [String] = []
        presenter.onUntrackedTap = { untracked.append("tap \($0)") }
        presenter.onUntrackedDismiss = { untracked.append("dismiss \($0)") }
        let actions = NoticeCardActions(
            act: { acts.append("a") }, respond: { _, _ in }, snooze: nil, archive: nil,
            close: { closes.append("a") })
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: [profile], actions: actions)

        presenter.handleTap(identifier: "a")
        presenter.handleDismiss(identifier: "a")
        XCTAssertEqual(acts, ["a"])
        XCTAssertEqual(closes, ["a"])
        XCTAssertEqual(untracked, [])
    }

    func testReplaceWhilePendingPostsOnlyTheNewOne() {
        let center = ControlledCenter()
        let presenter = SystemNotificationPresenter(poster: center, playsSound: { false })
        show("a", on: presenter)
        presenter.replace(
            oldID: "a", with: Notice(id: "b", source: "ci", title: "b"), profiles: [profile], actions: .inert)
        center.answerAuthorization(granted: true)
        XCTAssertEqual(center.posted, ["b"])
    }
}
