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
    private var answer: (@MainActor (Bool, Error?) -> Void)?

    func becomeDelegate() {}
    func isAuthorizationDenied(_ completion: @escaping @MainActor (Bool) -> Void) { completion(denied) }
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
        XCTAssertEqual(center.posted, [])
        XCTAssertEqual(denials, 1)

        show("b", on: presenter)
        XCTAssertEqual(center.posted, [])
        XCTAssertEqual(denials, 1, "once per launch")
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
