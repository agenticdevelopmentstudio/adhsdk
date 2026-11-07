import AppKit
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

/// A toast item per position: one notice, one card per position per display.
@MainActor
final class CardStackPresenterTests: XCTestCase {

    private var rules = NoticeRoutingRules.defaults

    // Fake display ids with no NSScreen: layout orders their panels out, so
    // nothing reaches the real screen.
    private func presenter(displays: [UInt32] = [1]) -> ToastPresenter {
        let presenter = ToastPresenter(rules: { [unowned self] in rules }, showHistory: {})
        presenter.displays = { _ in displays }
        return presenter
    }

    private func toast(_ position: NoticeProfile.Position, layer: NoticeProfile.Layer = .floating) -> NoticeProfile {
        NoticeProfile(style: .toast, position: position, layer: layer)
    }

    private func notice(_ id: String) -> Notice { Notice(id: id, source: "ci", title: id) }

    func testToastWithTwoPositionsPlacesTwoCards() {
        let presenter = presenter()
        presenter.show(notice("a"), profiles: [toast(.bottomRight), toast(.topLeft)], actions: .inert)
        XCTAssertEqual(presenter.panels(of: "a").count, 2)
        XCTAssertEqual(presenter.shownIDs, ["a"], "one notice, however many cards")
        presenter.remove(id: "a")
    }

    func testTwoPositionsOnTwoDisplaysPlaceFourCards() {
        let presenter = presenter(displays: [1, 2])
        presenter.show(notice("a"), profiles: [toast(.bottomRight), toast(.topLeft)], actions: .inert)
        XCTAssertEqual(presenter.panels(of: "a").count, 4, "a placement is per position per display")
        presenter.remove(id: "a")
    }

    func testRemoveTakesDownEveryPosition() {
        let presenter = presenter()
        presenter.show(notice("a"), profiles: [toast(.bottomRight), toast(.topLeft), toast(.center)], actions: .inert)
        XCTAssertEqual(presenter.panels(of: "a").count, 3)
        presenter.remove(id: "a")
        XCTAssertTrue(presenter.panels(of: "a").isEmpty)
        XCTAssertTrue(presenter.shownIDs.isEmpty)
    }

    func testDuplicatePositionsCountOnce() {
        let presenter = presenter()
        presenter.show(
            notice("a"), profiles: [toast(.bottomRight), toast(.bottomRight, layer: .normal)], actions: .inert)
        XCTAssertEqual(presenter.panels(of: "a").count, 1)
        presenter.remove(id: "a")
    }

    func testReplaceKeepsEachPositionInPlace() {
        let presenter = presenter()
        let profiles = [toast(.bottomRight), toast(.topLeft)]
        presenter.show(notice("a"), profiles: profiles, actions: .inert)
        let before = presenter.panels(of: "a")
        presenter.replace(oldID: "a", with: notice("b"), profiles: profiles, actions: .inert)
        let after = presenter.panels(of: "b")
        XCTAssertEqual(before.count, 2)
        XCTAssertEqual(after.count, 2)
        for (old, new) in zip(before, after) {
            XCTAssertTrue(old === new, "the panel was replaced instead of updated in place")
        }
        XCTAssertTrue(presenter.panels(of: "a").isEmpty)
        presenter.remove(id: "b")
    }

    func testKeyedReplaceOntoAnIdAlreadyShownKeepsTheStackOpen() {
        let presenter = presenter()
        let profiles = [toast(.bottomRight)]
        presenter.show(notice("a"), profiles: profiles, actions: .inert)
        presenter.show(notice("b"), profiles: profiles, actions: .inert)
        let windowsBefore = presenter.stackWindowCount
        let panelOfA = presenter.panels(of: "a")
        presenter.replace(oldID: "a", with: notice("b"), profiles: profiles, actions: .inert)
        XCTAssertEqual(presenter.shownIDs, ["b"])
        XCTAssertEqual(presenter.panels(of: "b").count, 1)
        XCTAssertTrue(presenter.panels(of: "b").first === panelOfA.first, "a's card carries the new notice")
        XCTAssertEqual(presenter.stackWindowCount, windowsBefore, "the stack the card lives in stays open")
        presenter.remove(id: "b")
    }

    func testReplaceWithAnotherSetOfPositionsRebuilds() {
        let presenter = presenter()
        presenter.show(notice("a"), profiles: [toast(.bottomRight), toast(.topLeft)], actions: .inert)
        presenter.replace(oldID: "a", with: notice("b"), profiles: [toast(.bottomRight)], actions: .inert)
        XCTAssertEqual(presenter.panels(of: "b").count, 1)
        XCTAssertTrue(presenter.panels(of: "a").isEmpty)
        presenter.remove(id: "b")
    }

    func testAlertDrawsOnlyTheFirstProfile() {
        let alert = AlertPresenter(rules: { [unowned self] in rules })
        alert.displays = { _ in [1] }
        alert.show(
            notice("a"),
            profiles: [
                NoticeProfile(style: .alert, position: .center), NoticeProfile(style: .alert, position: .topLeft)
            ],
            actions: .inert)
        XCTAssertEqual(alert.panels(of: "a").count, 1)
        alert.remove(id: "a")
    }

    // MARK: Card

    func testCardHidesSnoozeWhenNotSnoozable() {
        _ = NSApplication.shared
        var actions = NoticeCardActions.inert
        let card = NoticeCardView(notice: notice("a"), actions: actions, style: .toast)
        XCTAssertFalse(card.snoozeButton.isHidden)

        actions.snooze = nil
        card.update(notice: notice("a"), actions: actions)
        XCTAssertTrue(card.snoozeButton.isHidden)

        actions.snooze = { _ in }
        card.update(notice: notice("a"), actions: actions)
        XCTAssertFalse(card.snoozeButton.isHidden, "a set that can be snoozed shows the control again")
    }
}
