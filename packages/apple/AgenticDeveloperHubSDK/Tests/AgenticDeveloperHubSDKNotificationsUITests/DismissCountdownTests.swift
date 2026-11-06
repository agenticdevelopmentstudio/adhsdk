import AppKit
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

/// A scheduler driven by hand: nothing fires until the test advances time.
@MainActor
final class ManualCountdownScheduler: CountdownScheduler {

    private final class Token: CountdownToken {
        let fireAt: Date
        let fire: @MainActor () -> Void
        var cancelled = false
        init(fireAt: Date, fire: @escaping @MainActor () -> Void) {
            self.fireAt = fireAt
            self.fire = fire
        }
        func cancel() { cancelled = true }
    }

    var now = Date(timeIntervalSince1970: 1_800_000_000)
    private var tokens: [Token] = []

    var pendingCount: Int { tokens.filter { !$0.cancelled }.count }

    func schedule(after interval: TimeInterval, _ fire: @escaping @MainActor () -> Void) -> CountdownToken {
        let token = Token(fireAt: now.addingTimeInterval(interval), fire: fire)
        tokens.append(token)
        return token
    }

    func advance(by interval: TimeInterval) {
        now.addTimeInterval(interval)
        let due = tokens.filter { !$0.cancelled && $0.fireAt <= now }
        tokens.removeAll { $0.cancelled || $0.fireAt <= now }
        for token in due {
            token.fire()
        }
    }
}

@MainActor
final class DismissCountdownTests: XCTestCase {

    private func countdown(_ scheduler: ManualCountdownScheduler) -> DismissCountdown {
        DismissCountdown(scheduler: scheduler, clock: { scheduler.now })
    }

    func testExpiresOnceAfterTheInterval() {
        let scheduler = ManualCountdownScheduler()
        let countdown = countdown(scheduler)
        var fired = 0
        countdown.start(after: 8) { fired += 1 }
        scheduler.advance(by: 7.9)
        XCTAssertEqual(fired, 0)
        scheduler.advance(by: 0.2)
        XCTAssertEqual(fired, 1)
        scheduler.advance(by: 100)
        XCTAssertEqual(fired, 1)
        XCTAssertFalse(countdown.isRunning)
    }

    func testNilIntervalNeverExpires() {
        let scheduler = ManualCountdownScheduler()
        let countdown = countdown(scheduler)
        var fired = 0
        countdown.start(after: nil) { fired += 1 }
        scheduler.advance(by: 1000)
        XCTAssertEqual(fired, 0)
        XCTAssertEqual(scheduler.pendingCount, 0)
    }

    func testHoverPausesAndResumesWithTheRemainingTime() {
        let scheduler = ManualCountdownScheduler()
        let countdown = countdown(scheduler)
        var fired = 0
        countdown.start(after: 8) { fired += 1 }
        scheduler.advance(by: 5)
        countdown.setPaused(true, for: .hover)
        scheduler.advance(by: 60)
        XCTAssertEqual(fired, 0, "paused while hovered")
        countdown.setPaused(false, for: .hover)
        scheduler.advance(by: 2.9)
        XCTAssertEqual(fired, 0)
        scheduler.advance(by: 0.2)
        XCTAssertEqual(fired, 1, "resumes with the 3 s that were left")
    }

    func testEveryReasonMustClearBeforeItRuns() {
        let scheduler = ManualCountdownScheduler()
        let countdown = countdown(scheduler)
        var fired = 0
        countdown.setPaused(true, for: .hidden)
        countdown.start(after: 8) { fired += 1 }
        XCTAssertEqual(scheduler.pendingCount, 0, "a card that starts hidden does not count down")
        countdown.setPaused(true, for: .hover)
        countdown.setPaused(false, for: .hidden)
        scheduler.advance(by: 30)
        XCTAssertEqual(fired, 0, "still hovered")
        countdown.setPaused(false, for: .hover)
        scheduler.advance(by: 8)
        XCTAssertEqual(fired, 1)
    }

    func testRepeatedPauseAndResumeDoNotStackTimers() {
        let scheduler = ManualCountdownScheduler()
        let countdown = countdown(scheduler)
        var fired = 0
        countdown.start(after: 8) { fired += 1 }
        countdown.setPaused(false, for: .hover)
        countdown.setPaused(false, for: .hover)
        XCTAssertEqual(scheduler.pendingCount, 1)
        countdown.setPaused(true, for: .hidden)
        countdown.setPaused(true, for: .hidden)
        XCTAssertEqual(scheduler.pendingCount, 0)
        countdown.setPaused(false, for: .hidden)
        scheduler.advance(by: 8)
        XCTAssertEqual(fired, 1)
    }

    func testStopCancels() {
        let scheduler = ManualCountdownScheduler()
        let countdown = countdown(scheduler)
        var fired = 0
        countdown.start(after: 8) { fired += 1 }
        countdown.stop()
        scheduler.advance(by: 100)
        XCTAssertEqual(fired, 0)
        countdown.setPaused(true, for: .hover)
        countdown.setPaused(false, for: .hover)
        scheduler.advance(by: 100)
        XCTAssertEqual(fired, 0, "a stopped countdown does not come back on resume")
    }

    func testRestartReplacesTheRunningCountdown() {
        let scheduler = ManualCountdownScheduler()
        let countdown = countdown(scheduler)
        var fired: [String] = []
        countdown.start(after: 8) { fired.append("first") }
        scheduler.advance(by: 6)
        countdown.start(after: 8) { fired.append("second") }
        scheduler.advance(by: 6)
        XCTAssertEqual(fired, [])
        scheduler.advance(by: 2)
        XCTAssertEqual(fired, ["second"])
    }

    // MARK: Through the card

    func testCardClosesOnceOnExpiryAndHoverPausesIt() {
        _ = NSApplication.shared
        let scheduler = ManualCountdownScheduler()
        var closes = 0
        var actions = NoticeCardActions.inert
        actions.close = { closes += 1 }
        let card = NoticeCardView(
            notice: Notice(source: "ci", title: "t"), actions: actions, style: .toast,
            scheduler: scheduler, clock: { scheduler.now })
        card.startAutoDismiss(after: 8)
        scheduler.advance(by: 4)
        card.setHovered(true)
        scheduler.advance(by: 60)
        XCTAssertEqual(closes, 0)
        card.setHovered(false)
        scheduler.advance(by: 4)
        XCTAssertEqual(closes, 1)
        scheduler.advance(by: 60)
        XCTAssertEqual(closes, 1)
    }

    func testCardInOverflowDoesNotExpire() {
        _ = NSApplication.shared
        let scheduler = ManualCountdownScheduler()
        var closes = 0
        var actions = NoticeCardActions.inert
        actions.close = { closes += 1 }
        let card = NoticeCardView(
            notice: Notice(source: "ci", title: "t"), actions: actions, style: .toast,
            scheduler: scheduler, clock: { scheduler.now })
        card.setInOverflow(true)
        card.startAutoDismiss(after: 8)
        scheduler.advance(by: 60)
        XCTAssertEqual(closes, 0, "a hidden card is never dismissed unseen")
        card.setInOverflow(false)
        scheduler.advance(by: 8)
        XCTAssertEqual(closes, 1, "it gets its full time once it is visible")
    }

    func testHoveringAnotherPlacementHoldsThisCardToo() {
        _ = NSApplication.shared
        let scheduler = ManualCountdownScheduler()
        var closes = 0
        var actions = NoticeCardActions.inert
        actions.close = { closes += 1 }
        let card = NoticeCardView(
            notice: Notice(source: "ci", title: "t"), actions: actions, style: .toast,
            scheduler: scheduler, clock: { scheduler.now })
        card.startAutoDismiss(after: 8)
        card.setPeerHovered(true)
        scheduler.advance(by: 60)
        XCTAssertEqual(closes, 0)
        card.setPeerHovered(false)
        scheduler.advance(by: 8)
        XCTAssertEqual(closes, 1)
    }

    func testCardActionButtonsAcceptTheFirstClick() {
        _ = NSApplication.shared
        let notice = Notice(source: "ci", title: "t", actions: [.init(id: "a", label: "Open", kind: .callback)])
        let card = NoticeCardView(notice: notice, actions: .inert, style: .toast)
        XCTAssertFalse(card.actionButtons.isEmpty)
        XCTAssertTrue(card.actionButtons.allSatisfy { $0.acceptsFirstMouse(for: nil) },
                      "a never-key panel must not swallow the first click on an action")
        XCTAssertTrue(card.closeButton.acceptsFirstMouse(for: nil))
        XCTAssertTrue(card.acceptsFirstMouse(for: nil))
    }
}
