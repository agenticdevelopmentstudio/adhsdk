import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

/// How the center fans one notice's style set out to its presenters.
@MainActor
final class NoticePresentationCenterStyleSetTests: XCTestCase {

    private struct Harness {
        let center: NoticePresentationCenter
        let handler: RecordingHandler
        let toast: RecordingPresenter
        let alert: RecordingPresenter
        let crawl: RecordingPresenter
        let system: RecordingPresenter
        let clock: Clock
    }

    private func harness(_ rules: NoticeRoutingRules = .defaults) -> Harness {
        let handler = RecordingHandler()
        let clock = Clock()
        let center = NoticePresentationCenter(
            handler: handler, rules: { rules }, filter: { NoticeFilter() },
            idle: IdleMonitor(idleSeconds: { 0 }), clock: { clock.now })
        let toast = RecordingPresenter()
        let alert = RecordingPresenter()
        let crawl = RecordingPresenter()
        let system = RecordingPresenter()
        center.presenters = [.toast: toast, .alert: alert, .crawl: crawl, .system: system]
        return Harness(
            center: center, handler: handler, toast: toast, alert: alert, crawl: crawl, system: system, clock: clock)
    }

    private func rules(
        _ urgency: Notice.Urgency, _ items: [NoticeProfile.Style], autoDismiss: TimeInterval? = nil,
        snooze: SnoozeSettings = .init()
    ) -> NoticeRoutingRules {
        var rules = NoticeRoutingRules.defaults
        rules.styles[urgency] = NoticeStyleSet(
            items: items.map { NoticeProfile(style: $0) }, autoDismiss: autoDismiss, snooze: snooze)
        return rules
    }

    private func notice(
        _ id: String, urgency: Notice.Urgency = .soon, key: String? = nil, source: String = "ci", at clock: Clock
    ) -> Notice {
        Notice(id: id, timestamp: clock.now, source: source, title: id, urgency: urgency, key: key)
    }

    func testSetWithToastAndSystemCallsBothPresentersOnce() {
        let env = harness(rules(.soon, [.toast, .system]))
        env.center.receive(notice("a", at: env.clock))
        XCTAssertEqual(env.toast.shown.map(\.id), ["a"])
        XCTAssertEqual(env.system.shown.map(\.id), ["a"])
        XCTAssertEqual(env.toast.profiles["a"]?.map(\.style), [.toast])
        XCTAssertEqual(env.system.profiles["a"]?.map(\.style), [.system])
        XCTAssertTrue(env.alert.shown.isEmpty)
        XCTAssertEqual(env.center.presentedStyles(of: "a"), [.toast, .system])
    }

    func testTwoItemsOfOneStyleReachThatPresenterInOneCall() {
        var rules = NoticeRoutingRules.defaults
        rules.styles[.soon] = NoticeStyleSet(items: [
            NoticeProfile(style: .toast, position: .bottomLeft), NoticeProfile(style: .toast, position: .topLeft)
        ])
        let env = harness(rules)
        env.center.receive(notice("a", at: env.clock))
        XCTAssertEqual(env.toast.shown.map(\.id), ["a"], "one call, not one per item")
        XCTAssertEqual(env.toast.profiles["a"]?.map(\.position), [.bottomLeft, .topLeft])
    }

    func testEmptySetShowsNothing() {
        let env = harness(rules(.soon, []))
        env.center.receive(notice("a", at: env.clock))
        for presenter in [env.toast, env.alert, env.crawl, env.system] {
            XCTAssertTrue(presenter.shown.isEmpty)
        }
        XCTAssertEqual(env.center.presentedStyles(of: "a"), [])
        XCTAssertNil(env.center.newestShownID)
    }

    func testAutoDismissIsStampedFromSet() {
        let env = harness(rules(.soon, [.toast, .system], autoDismiss: 12))
        env.center.receive(notice("a", at: env.clock))
        XCTAssertEqual(env.toast.profiles["a"]?.map(\.autoDismiss), [12])
        XCTAssertEqual(env.system.profiles["a"]?.map(\.autoDismiss), [12])
    }

    func testUnsnoozableSetHasNilSnoozeAction() {
        let env = harness(rules(.soon, [.toast], snooze: SnoozeSettings(isEnabled: false)))
        env.center.receive(notice("a", at: env.clock))
        let actions = env.toast.actions["a"]
        XCTAssertNotNil(actions)
        XCTAssertNil(actions?.snooze)
        XCTAssertNotNil(actions?.archive)

        env.center.snooze(id: "a", option: .oneHour)
        XCTAssertTrue(env.handler.calls.isEmpty, "a set that does not snooze ignores a snooze")
        XCTAssertEqual(env.toast.shownIDs, ["a"])
    }

    func testEmptySnoozeOptionsAreUnsnoozable() {
        let env = harness(rules(.soon, [.toast], snooze: SnoozeSettings(isEnabled: true, options: [])))
        env.center.receive(notice("a", at: env.clock))
        XCTAssertNil(env.toast.actions["a"]?.snooze)
    }

    func testSnoozeOptionsFollowSet() {
        let env = harness(rules(.soon, [.toast], snooze: SnoozeSettings(options: [.oneHour, .fiveMinutes])))
        env.center.receive(notice("a", at: env.clock))
        XCTAssertEqual(env.toast.actions["a"]?.snoozeOptions, [.fiveMinutes, .oneHour])
        XCTAssertNotNil(env.toast.actions["a"]?.snooze)
    }

    func testReplaceRemovesStylesThatLeftTheSet() {
        var rules = rules(.soon, [.toast, .system])
        rules.styles[.fyi] = NoticeStyleSet(items: [NoticeProfile(style: .toast), NoticeProfile(style: .crawl)])
        let env = harness(rules)
        env.center.receive(notice("run", urgency: .soon, key: "build", at: env.clock))
        env.center.receive(notice("pass", urgency: .fyi, key: "build", at: env.clock))

        XCTAssertEqual(env.toast.replaced.map(\.old), ["run"], "toast stayed, so it is replaced in place")
        XCTAssertEqual(env.toast.shownIDs, ["pass"])
        XCTAssertEqual(env.system.removed, ["run"], "system left the set")
        XCTAssertTrue(env.system.shownIDs.isEmpty)
        XCTAssertEqual(env.crawl.shown.map(\.id), ["pass"], "crawl joined the set")
        XCTAssertEqual(env.center.presentedStyles(of: "pass"), [.toast, .crawl])
    }

    func testHideOverrideShowsNothing() {
        var rules = NoticeRoutingRules.defaults
        rules.overrides = [.init(source: "noisy", target: .hide)]
        let env = harness(rules)
        env.center.receive(notice("a", source: "noisy", at: env.clock))
        env.center.receive(notice("b", source: "ci", at: env.clock))
        XCTAssertEqual(env.toast.shownIDs, ["b"])
        XCTAssertEqual(env.center.presentedStyles(of: "a"), [])
    }

    func testStyleOverrideUsesThatUrgencysSet() {
        var rules = rules(.now, [.crawl, .system])
        rules.overrides = [.init(source: "deploy", target: .style(.now))]
        let env = harness(rules)
        env.center.receive(notice("a", urgency: .fyi, source: "deploy", at: env.clock))
        XCTAssertEqual(env.center.presentedStyles(of: "a"), [.crawl, .system])
        XCTAssertTrue(env.toast.shown.isEmpty)
    }

    func testCloseRemovesFromEveryPresentedStyle() {
        let env = harness(rules(.soon, [.toast, .crawl, .system]))
        env.center.receive(notice("a", at: env.clock))
        env.toast.actions["a"]?.close()
        for presenter in [env.toast, env.crawl, env.system] {
            XCTAssertTrue(presenter.shownIDs.isEmpty)
            XCTAssertTrue(presenter.removed.contains("a"))
        }
        XCTAssertEqual(env.handler.calls, [.setState("a", .read)])
    }

    func testActFocusesTheFirstStyleWithAReplyField() {
        let env = harness(rules(.soon, [.crawl, .toast]))
        env.crawl.hasReplyField = false
        env.center.receive(Notice(
            id: "a", timestamp: env.clock.now, source: "ci", title: "a", urgency: .soon,
            actions: [.init(id: "r", label: "Reply", kind: .reply(placeholder: nil))]))
        env.center.act(id: "a")
        XCTAssertEqual(env.toast.focusedReplies, ["a"])
        XCTAssertTrue(env.handler.calls.isEmpty, "a field took it, so history does not open")
    }

    func testEscalationMovesTheNoticeToTheEscalatedSet() {
        let env = harness(rules(.now, [.alert, .system]))
        env.center.receive(notice("a", urgency: .soon, at: env.clock))
        env.clock.now.addTimeInterval(901)
        env.center.tick()
        XCTAssertEqual(env.toast.removed, ["a"])
        XCTAssertEqual(env.alert.shown.map(\.urgency), [.now])
        XCTAssertEqual(env.system.shown.map(\.id), ["a"])
        XCTAssertEqual(env.center.presentedStyles(of: "a"), [.alert, .system])
    }

    func testFloodSummaryIsOneUnsnoozableToast() {
        var rules = rules(.fyi, [.crawl, .system], autoDismiss: 8)
        rules.flood = .init(threshold: 1, window: 10)
        let env = harness(rules)
        env.center.receive(notice("n0", urgency: .fyi, at: env.clock))
        env.center.receive(notice("n1", urgency: .fyi, at: env.clock))
        XCTAssertEqual(env.toast.shownIDs, ["flood:ci"])
        XCTAssertEqual(env.toast.profiles["flood:ci"], [NoticeProfile(style: .toast, position: .bottomRight)])
        XCTAssertNil(env.toast.actions["flood:ci"]?.snooze)
        XCTAssertFalse(env.system.shownIDs.contains("flood:ci"))
        XCTAssertEqual(env.center.presentedStyles(of: "flood:ci"), [.toast])
    }
}
