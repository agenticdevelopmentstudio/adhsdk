import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

private struct StubFocus: NoticeFocusMonitor {
    let box: FocusBox
    var isFocused: Bool { box.focused }
}

private final class FocusBox {
    var focused = true
}

@MainActor
final class NoticePresentationCenterTests: XCTestCase {

    private struct Harness {
        let center: NoticePresentationCenter
        let handler: RecordingHandler
        let toast: RecordingPresenter
        let alert: RecordingPresenter
        let clock: Clock
    }

    private func harness(
        rules: NoticeRoutingRules = .defaults,
        filter: NoticeFilter = NoticeFilter(),
        focus: NoticeFocusMonitor = NeverFocused(),
        idle: IdleMonitor = IdleMonitor(idleSeconds: { 0 }),
        untilBackStore: UserDefaults? = nil,
        clock: Clock = Clock()
    ) -> Harness {
        let handler = RecordingHandler()
        let center = NoticePresentationCenter(
            handler: handler, rules: { rules }, filter: { filter }, focus: focus, idle: idle,
            untilBackStore: untilBackStore, clock: { clock.now })
        let toast = RecordingPresenter()
        let alert = RecordingPresenter()
        center.presenters = [.toast: toast, .alert: alert]
        return Harness(center: center, handler: handler, toast: toast, alert: alert, clock: clock)
    }

    private func notice(
        _ id: String,
        source: String = "ci",
        level: Notice.Level = .info,
        urgency: Notice.Urgency = .soon,
        key: String? = nil,
        actions: [Notice.Action] = [],
        at clock: Clock
    ) -> Notice {
        Notice(id: id, timestamp: clock.now, source: source, title: id, level: level, urgency: urgency,
               actions: actions, key: key)
    }

    func testFilteredNoticeIsNotShown() {
        let env = harness(filter: NoticeFilter(minimumLevel: .error, excludedMetadata: ["ingested_by": "x"]))
        env.center.receive(notice("a", level: .info, at: env.clock))
        var ingested = notice("b", level: .error, at: env.clock)
        ingested.metadata = ["ingested_by": "x"]
        env.center.receive(ingested)
        XCTAssertTrue(env.toast.shown.isEmpty)
        XCTAssertNil(env.center.newestShownID)

        env.center.receive(notice("c", level: .error, at: env.clock))
        XCTAssertEqual(env.toast.shownIDs, ["c"])
    }

    func testRoutesByUrgencyToStyle() {
        let env = harness()
        env.center.receive(notice("soon", urgency: .soon, at: env.clock))
        env.center.receive(notice("now", urgency: .now, at: env.clock))
        env.center.receive(notice("emergency", urgency: .emergency, at: env.clock))

        XCTAssertEqual(env.toast.shownIDs, ["soon"])
        XCTAssertEqual(env.alert.shownIDs, ["now"])
        XCTAssertEqual(env.center.presentedStyles(of: "soon"), [.toast])
        XCTAssertEqual(env.center.presentedStyles(of: "now"), [.alert])
        // No fullScreen presenter is registered, yet the routing is recorded.
        XCTAssertEqual(env.center.presentedStyles(of: "emergency"), [.fullScreen])
        XCTAssertEqual(env.center.newestShownID, "emergency")
    }

    func testReplaceByKeyReplacesInPlace() {
        let env = harness()
        env.center.receive(notice("run", key: "build", at: env.clock))
        env.center.receive(notice("other", source: "deploy", key: "build", at: env.clock))
        env.center.receive(notice("pass", key: "build", at: env.clock))

        XCTAssertEqual(env.toast.replaced.map(\.old), ["run"])
        XCTAssertEqual(env.toast.replaced.map(\.new), ["pass"])
        XCTAssertEqual(env.toast.shownIDs, ["pass", "other"])
        XCTAssertEqual(env.center.presentedStyles(of: "run"), [])
        XCTAssertEqual(env.center.newestShownID, "pass")
    }

    func testStateChangeRemovesFromAllPresenters() {
        let env = harness()
        env.center.receive(notice("a", at: env.clock))
        env.center.apply(NoticeStateChange(id: "a", state: .archived, stateAt: env.clock.now))

        XCTAssertEqual(env.toast.removed, ["a"])
        XCTAssertEqual(env.alert.removed, ["a"])
        XCTAssertNil(env.center.newestShownID)
        XCTAssertTrue(env.handler.calls.isEmpty, "a broadcast state change is not echoed back")
    }

    func testUnreadChangeDoesNotRemove() {
        let env = harness()
        env.center.receive(notice("a", at: env.clock))
        env.center.apply(NoticeStateChange(id: "a", state: .unread, stateAt: env.clock.now))

        XCTAssertTrue(env.toast.removed.isEmpty)
        XCTAssertEqual(env.toast.shownIDs, ["a"])
    }

    func testFloodShowsSummary() {
        var rules = NoticeRoutingRules.defaults
        rules.flood = .init(threshold: 2, window: 10)
        let env = harness(rules: rules)
        for index in 0..<4 {
            env.center.receive(notice("n\(index)", urgency: .fyi, at: env.clock))
        }

        XCTAssertEqual(env.toast.shownIDs, ["n0", "n1", "flood:ci"])
        XCTAssertEqual(env.toast.replaced.map(\.old), ["flood:ci"], "the second fold updates the count in place")
        XCTAssertEqual(env.toast.notices["flood:ci"]?.title, "4 from ci")

        env.toast.actions["flood:ci"]?.act()
        XCTAssertEqual(env.handler.calls, [.showHistory])
        XCTAssertTrue(env.toast.removed.contains("flood:ci"))
    }

    func testCloseMarksRead() {
        let env = harness()
        env.center.receive(notice("a", at: env.clock))
        env.center.close(id: "a")

        XCTAssertEqual(env.handler.calls, [.setState("a", .read)])
        XCTAssertEqual(env.toast.removed.first, "a")
    }

    func testActOpenURLRespondsAndOpens() throws {
        let env = harness()
        let url = try XCTUnwrap(URL(string: "https://example.com/build/1"))
        env.center.receive(notice("a", actions: [.init(id: "open", label: "Open", kind: .open(url))], at: env.clock))
        env.center.act(id: "a")

        XCTAssertEqual(env.handler.calls, [.openURL(url), .respond("a", "open", nil)])
        XCTAssertEqual(env.toast.removed.first, "a", "the card goes before the host answers")
    }

    func testActWithoutActionMarksRead() {
        let env = harness()
        env.center.receive(notice("a", at: env.clock))
        env.center.act(id: "a")

        XCTAssertEqual(env.handler.calls, [.setState("a", .read)])
        XCTAssertEqual(env.toast.removed.first, "a")
    }

    func testActOnReplyFocusesTheField() {
        let env = harness()
        env.center.receive(notice("a", actions: [.init(id: "r", label: "Reply", kind: .reply(placeholder: nil))],
                                at: env.clock))
        env.center.act(id: "a")

        XCTAssertEqual(env.toast.focusedReplies, ["a"])
        XCTAssertTrue(env.handler.calls.isEmpty)
        XCTAssertEqual(env.toast.shownIDs, ["a"])
    }

    func testArchiveAndSnoozeRouteToHandler() {
        let env = harness()
        env.center.receive(notice("a", at: env.clock))
        env.center.receive(notice("b", at: env.clock))
        env.center.archive(id: "a")
        env.center.snooze(id: "b", option: .fiveMinutes)

        XCTAssertEqual(env.handler.calls, [
            .setState("a", .archived),
            .snooze("b", env.clock.now.addingTimeInterval(300))
        ])
        XCTAssertTrue(env.toast.shownIDs.isEmpty)
    }

    func testUntilBackWakesOnReturn() {
        let readings = IdleReadings([0, 301, 302, 1, 400, 2])
        let idle = IdleMonitor(idleSeconds: readings.next, threshold: 300, poll: 15)
        let env = harness(idle: idle)
        env.center.receive(notice("a", at: env.clock))
        env.center.receive(notice("b", at: env.clock))
        env.center.snooze(id: "a", option: .untilBack)
        env.center.snooze(id: "b", option: .fiveMinutes)
        env.center.apply(NoticeStateChange(id: "a", state: .snoozed, stateAt: env.clock.now))
        XCTAssertEqual(env.handler.calls, [
            .snooze("a", env.clock.now.addingTimeInterval(24 * 60 * 60)),
            .snooze("b", env.clock.now.addingTimeInterval(300))
        ])

        idle.step() // 0: active
        idle.step() // 301: idle
        idle.step() // 302: still idle
        XCTAssertEqual(env.handler.calls.count, 2, "nothing wakes while the user is away")
        idle.step() // 1: back
        XCTAssertEqual(env.handler.calls.last, .setState("a", .unread))
        XCTAssertEqual(env.handler.calls.count, 3, "only the until-back notice wakes")

        idle.step() // 400: away again
        idle.step() // 2: back again
        XCTAssertEqual(env.handler.calls.count, 3, "a woken notice is not woken twice")
    }

    func testUntilBackIsForgottenOnceTheNoticeIsConsumed() {
        let readings = IdleReadings([301, 1])
        let idle = IdleMonitor(idleSeconds: readings.next, threshold: 300, poll: 15)
        let env = harness(idle: idle)
        env.center.receive(notice("a", at: env.clock))
        env.center.snooze(id: "a", option: .untilBack)
        env.center.apply(NoticeStateChange(id: "a", state: .archived, stateAt: env.clock.now))
        idle.step()
        idle.step()
        XCTAssertFalse(env.handler.calls.contains(.setState("a", .unread)))
    }

    /// Until-back snoozes survive a relaunch: a new center over the same
    /// store still wakes them when the user returns.
    func testUntilBackSurvivesARelaunch() throws {
        let suite = "NoticePresentationCenterTests.untilBack.\(UUID().uuidString)"
        let store = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { store.removePersistentDomain(forName: suite) }
        let clock = Clock()
        do {
            let first = harness(untilBackStore: store, clock: clock)
            first.center.receive(notice("a", at: clock))
            first.center.receive(notice("b", at: clock))
            first.center.snooze(id: "a", option: .untilBack)
            first.center.snooze(id: "b", option: .untilBack)
            first.center.apply(NoticeStateChange(id: "b", state: .archived, stateAt: clock.now))
        }

        let readings = IdleReadings([301, 1])
        let idle = IdleMonitor(idleSeconds: readings.next, threshold: 300, poll: 15)
        let second = harness(idle: idle, untilBackStore: store, clock: clock)
        XCTAssertTrue(idle.isRunning, "a relaunch re-arms the idle watch")
        idle.step()
        idle.step()
        XCTAssertEqual(second.handler.calls, [.setState("a", .unread)])
        XCTAssertFalse(idle.isRunning)

        let third = harness(idle: IdleMonitor(idleSeconds: { 0 }), untilBackStore: store, clock: clock)
        XCTAssertFalse(third.center.hasUntilBackNotices, "a woken notice is forgotten in the store too")
    }

    /// Ruling 10: a notice archived (say, from the CLI) while the app was down
    /// is still in the persisted until-back set. On the user's return the wake
    /// goes to the host, the daemon refuses it, and no broadcast follows. The
    /// center must have dropped the id anyway: not retried on the next return,
    /// not left in the store, and nothing put on screen.
    func testARefusedUntilBackWakeIsDroppedAndNotRetried() throws {
        let suite = "NoticePresentationCenterTests.untilBack.\(UUID().uuidString)"
        let store = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { store.removePersistentDomain(forName: suite) }
        let clock = Clock()
        do {
            let first = harness(untilBackStore: store, clock: clock)
            first.center.receive(notice("a", at: clock))
            first.center.snooze(id: "a", option: .untilBack)
            // The app quits here; "a" is archived while it is down, so no
            // archived change ever reaches a center.
        }

        let readings = IdleReadings([301, 1, 400, 2])
        let idle = IdleMonitor(idleSeconds: readings.next, threshold: 300, poll: 15)
        let second = harness(idle: idle, untilBackStore: store, clock: clock)
        idle.step() // away
        idle.step() // back: the wake is sent, and the host refuses it
        XCTAssertEqual(second.handler.calls, [.setState("a", .unread)])
        XCTAssertFalse(second.center.hasUntilBackNotices)
        XCTAssertNil(store.object(forKey: NoticePresentationCenter.untilBackKey), "dropped from the store too")

        idle.start()
        idle.step() // away again
        idle.step() // back again
        XCTAssertEqual(second.handler.calls.count, 1, "a refused wake is not retried")
        XCTAssertTrue(second.toast.shownIDs.isEmpty, "nothing is shown")
        XCTAssertTrue(second.alert.shownIDs.isEmpty)
    }

    func testExpiredUntilBackSnoozesAreNotRearmed() throws {
        let suite = "NoticePresentationCenterTests.untilBack.\(UUID().uuidString)"
        let store = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { store.removePersistentDomain(forName: suite) }
        let clock = Clock()
        do {
            let first = harness(untilBackStore: store, clock: clock)
            first.center.receive(notice("a", at: clock))
            first.center.snooze(id: "a", option: .untilBack)
        }
        clock.now = clock.now.addingTimeInterval(25 * 60 * 60)
        let later = harness(idle: IdleMonitor(idleSeconds: { 0 }), untilBackStore: store, clock: clock)
        XCTAssertFalse(later.center.hasUntilBackNotices, "past the 24 h fallback the snooze already ended")
    }

    /// Crawl and system draw no reply field, so acting on a notice whose
    /// primary action is a reply opens the history, where it can be answered.
    func testActingOnAReplyWithoutAFieldOpensHistory() {
        var rules = NoticeRoutingRules.defaults
        rules.styles[.soon]?.items = [NoticeProfile(style: .crawl)]
        let env = harness(rules: rules)
        let crawl = RecordingPresenter()
        crawl.hasReplyField = false
        env.center.setPresenter(crawl, for: .crawl)
        env.center.receive(notice(
            "a", actions: [.init(id: "r", label: "Reply", kind: .reply(placeholder: nil))], at: env.clock))
        env.center.act(id: "a")
        XCTAssertEqual(crawl.focusedReplies, ["a"])
        XCTAssertEqual(env.handler.calls, [.showHistory])
        XCTAssertEqual(crawl.shownIDs, ["a"], "it stays up; nothing was answered")
    }

    func testShowHistoryReachesTheHandler() {
        let env = harness()
        env.center.showHistory()
        XCTAssertEqual(env.handler.calls, [.showHistory])
    }

    func testSetPresenterRegistersAStyle() {
        let crawl = RecordingPresenter()
        var rules = NoticeRoutingRules.defaults
        rules.styles[.soon]?.items = [NoticeProfile(style: .crawl)]
        let routed = harness(rules: rules)
        routed.center.setPresenter(crawl, for: .crawl)
        routed.center.receive(notice("a", urgency: .soon, at: routed.clock))
        XCTAssertEqual(crawl.shownIDs, ["a"])
    }

    func testStandardRegistersEveryStyle() {
        let center = NoticePresentationCenter.standard(
            handler: RecordingHandler(), rules: { .defaults }, filter: { NoticeFilter() })
        XCTAssertEqual(Set(center.presenters.keys), [.toast, .alert, .crawl, .fullScreen, .system])
    }

    func testReconcileRemovesStaleAndAddsMissing() {
        let env = harness()
        let first = notice("a", at: env.clock)
        let second = notice("b", at: env.clock)
        let third = notice("c", at: env.clock)
        env.center.receive(first)
        env.center.receive(second)
        env.center.reconcile(active: [second, third])

        XCTAssertEqual(env.toast.removed, ["a"])
        XCTAssertEqual(env.toast.shownIDs, ["b", "c"])
        XCTAssertEqual(env.toast.shown.filter { $0.id == "b" }.count, 1, "an already shown notice is not shown again")
    }

    func testEscalationRepresentsSoonAsNow() {
        let env = harness()
        env.center.receive(notice("a", urgency: .soon, at: env.clock))
        XCTAssertEqual(env.toast.shownIDs, ["a"])

        env.clock.now.addTimeInterval(899)
        env.center.tick()
        XCTAssertEqual(env.toast.shownIDs, ["a"], "not yet")

        env.clock.now.addTimeInterval(2)
        env.center.tick()
        XCTAssertEqual(env.toast.removed, ["a"])
        XCTAssertEqual(env.alert.shownIDs, ["a"])
        XCTAssertEqual(env.center.presentedStyles(of: "a"), [.alert])

        env.clock.now.addTimeInterval(1000)
        env.center.tick()
        XCTAssertEqual(env.alert.shown.count, 1, "escalates once")
    }

    func testFocusSeamHoldsNothingWhenNeverFocused() {
        let env = harness()
        env.center.receive(notice("a", urgency: .fyi, at: env.clock))
        XCTAssertEqual(env.toast.shownIDs, ["a"])
    }

    func testFocusHoldsBelowNowUntilFocusEnds() {
        let box = FocusBox()
        let env = harness(focus: StubFocus(box: box))
        env.center.receive(notice("quiet", urgency: .soon, at: env.clock))
        env.center.receive(notice("loud", urgency: .now, at: env.clock))
        XCTAssertTrue(env.toast.shownIDs.isEmpty)
        XCTAssertEqual(env.alert.shownIDs, ["loud"])

        box.focused = false
        env.center.focusDidChange()
        XCTAssertEqual(env.toast.shownIDs, ["quiet"])
    }

    // MARK: Fix round 1

    private func harnessWithSystem(rules: NoticeRoutingRules = .defaults) -> (Harness, RecordingPresenter) {
        let env = harness(rules: rules)
        let system = RecordingPresenter()
        env.center.setPresenter(system, for: .system)
        return (env, system)
    }

    private func rules(_ edit: (inout NoticeStyleSet) -> Void, for urgency: Notice.Urgency) -> NoticeRoutingRules {
        var rules = NoticeRoutingRules.defaults
        var set = rules.style(for: Notice(source: "x", title: "x", urgency: urgency))
        edit(&set)
        rules.styles[urgency] = set
        return rules
    }

    private static func addSystem(_ set: inout NoticeStyleSet) {
        set.items.append(NoticeProfile(style: .system))
    }

    func testReconcileDoesNotResurrectACardTheUserJustActedOn() {
        let env = harness()
        let shown = notice("a", at: env.clock)
        env.center.receive(shown)
        env.center.close(id: "a")
        // The host has not applied the read yet, so its active list still has it.
        env.center.reconcile(active: [shown])
        XCTAssertEqual(env.toast.shown.filter { $0.id == "a" }.count, 1, "the closed card came back")
        XCTAssertTrue(env.toast.shownIDs.isEmpty)

        // Once the host has caught up, the id is forgotten: a genuine re-post shows.
        env.center.apply(NoticeStateChange(id: "a", state: .read, stateAt: env.clock.now))
        env.center.receive(shown)
        XCTAssertEqual(env.toast.shownIDs, ["a"])
    }

    /// The host refused the change the user made (the daemon said the notice
    /// is finished, or it was unreachable): the id must not stay suppressed,
    /// so the next reconcile shows what the host still calls active.
    func testActionNotAppliedLetsTheNextReconcileShowTheCardAgain() {
        let env = harness()
        let shown = notice("a", at: env.clock)
        env.center.receive(shown)
        env.center.archive(id: "a")
        env.center.reconcile(active: [shown])
        XCTAssertTrue(env.toast.shownIDs.isEmpty, "still suppressed before the refusal")

        env.center.actionNotApplied(id: "a")
        env.center.reconcile(active: [shown])

        XCTAssertEqual(env.toast.shownIDs, ["a"])
    }

    func testActionNotAppliedForgetsAnUntilBackSnooze() {
        let readings = IdleReadings([301, 1])
        let idle = IdleMonitor(idleSeconds: readings.next, threshold: 300, poll: 15)
        let env = harness(idle: idle)
        env.center.receive(notice("a", at: env.clock))
        env.center.snooze(id: "a", option: .untilBack)

        env.center.actionNotApplied(id: "a")
        idle.step()
        idle.step()

        XCTAssertFalse(env.center.hasUntilBackNotices)
        XCTAssertFalse(env.handler.calls.contains(.setState("a", .unread)), "a refused snooze is not woken")
    }

    func testActedIDIsForgottenWhenItLeavesTheActiveList() {
        let env = harness()
        let shown = notice("a", at: env.clock)
        env.center.receive(shown)
        env.center.archive(id: "a")
        env.center.reconcile(active: [])
        env.center.reconcile(active: [shown])
        XCTAssertEqual(env.toast.shownIDs, ["a"], "absent once, so a later active copy is real")
    }

    func testSystemItemShowsOnBothPresenters() {
        let (env, system) = harnessWithSystem(rules: rules(Self.addSystem, for: .soon))
        env.center.receive(notice("a", at: env.clock))
        XCTAssertEqual(env.toast.shownIDs, ["a"])
        XCTAssertEqual(system.shownIDs, ["a"])
        env.center.close(id: "a")
        XCTAssertTrue(system.shownIDs.isEmpty)
    }

    func testReplaceByKeyUpdatesTheSystemPresenter() {
        let (env, system) = harnessWithSystem(rules: rules(Self.addSystem, for: .soon))
        env.center.receive(notice("run", key: "build", at: env.clock))
        env.center.receive(notice("pass", key: "build", at: env.clock))
        XCTAssertEqual(system.replaced.map(\.old), ["run"], "the system item stayed in the set, so it is replaced")
        XCTAssertEqual(system.shownIDs, ["pass"])
    }

    func testReplaceIntoASetWithoutASystemItemLeavesTheSystemPresenter() {
        let (env, system) = harnessWithSystem(rules: rules(Self.addSystem, for: .soon))
        env.center.receive(notice("run", urgency: .soon, key: "build", at: env.clock))
        env.center.receive(notice("pass", urgency: .fyi, key: "build", at: env.clock))
        XCTAssertTrue(system.shownIDs.isEmpty)
        XCTAssertEqual(env.toast.shownIDs, ["pass"])
    }

    func testApplyOnAnUntrackedIDStillReachesEveryPresenter() {
        let (env, system) = harnessWithSystem()
        env.center.apply(NoticeStateChange(id: "ghost", state: .read, stateAt: env.clock.now))
        XCTAssertEqual(env.toast.removed, ["ghost"])
        XCTAssertEqual(env.alert.removed, ["ghost"])
        XCTAssertEqual(system.removed, ["ghost"])
    }

    func testClosingTwiceTellsTheHostOnce() {
        let env = harness()
        env.center.receive(notice("a", at: env.clock))
        env.center.close(id: "a")
        env.center.close(id: "a")
        env.toast.actions["a"]?.close()
        XCTAssertEqual(env.handler.calls, [.setState("a", .read)])
    }

    func testApplyReleasesAHeldNotice() {
        let box = FocusBox()
        let env = harness(focus: StubFocus(box: box))
        env.center.receive(notice("quiet", urgency: .soon, at: env.clock))
        env.center.apply(NoticeStateChange(id: "quiet", state: .read, stateAt: env.clock.now))
        box.focused = false
        env.center.focusDidChange()
        XCTAssertTrue(env.toast.shownIDs.isEmpty, "a notice read elsewhere is not shown when Focus ends")
    }

    func testApplyForgetsAFoldedID() {
        var rules = NoticeRoutingRules.defaults
        rules.flood = .init(threshold: 1, window: 10)
        let env = harness(rules: rules)
        env.center.receive(notice("n0", urgency: .fyi, at: env.clock))
        let folded = notice("n1", urgency: .fyi, at: env.clock)
        env.center.receive(folded)
        XCTAssertEqual(env.toast.shownIDs, ["n0", "flood:ci"])
        env.center.apply(NoticeStateChange(id: "n1", state: .read, stateAt: env.clock.now))
        env.clock.now.addTimeInterval(60)
        env.center.receive(folded)
        XCTAssertTrue(env.toast.shownIDs.contains("n1"), "once applied, the id is no longer swallowed as folded")
    }

    func testClosingTheFloodSummaryDoesNotTellTheHost() {
        var rules = NoticeRoutingRules.defaults
        rules.flood = .init(threshold: 1, window: 10)
        let env = harness(rules: rules)
        env.center.receive(notice("n0", urgency: .fyi, at: env.clock))
        env.center.receive(notice("n1", urgency: .fyi, at: env.clock))
        env.toast.actions["flood:ci"]?.close()
        XCTAssertTrue(env.handler.calls.isEmpty)
        XCTAssertFalse(env.toast.shownIDs.contains("flood:ci"))
    }

    func testFloodSummaryGoesWhenNothingItFoldedIsStillActive() {
        var rules = NoticeRoutingRules.defaults
        rules.flood = .init(threshold: 1, window: 10)
        let env = harness(rules: rules)
        let first = notice("n0", urgency: .fyi, at: env.clock)
        let second = notice("n1", urgency: .fyi, at: env.clock)
        env.center.receive(first)
        env.center.receive(second)
        env.center.reconcile(active: [first, second])
        XCTAssertTrue(env.toast.shownIDs.contains("flood:ci"), "still folding n1")
        env.center.reconcile(active: [first])
        XCTAssertFalse(env.toast.shownIDs.contains("flood:ci"))
    }

    func testEmptySetNoticeIsNotRecountedIntoAFalseFlood() {
        var rules = rules({ $0.items = [] }, for: .fyi)
        rules.flood = .init(threshold: 2, window: 60)
        let env = harness(rules: rules)
        let quiet = notice("q", urgency: .fyi, at: env.clock)
        for _ in 0..<5 {
            env.center.reconcile(active: [quiet])
        }
        XCTAssertTrue(env.toast.shownIDs.isEmpty, "a notice drawn nowhere is evaluated once, not folded")
        XCTAssertTrue(env.toast.shown.isEmpty)
    }

    // MARK: Final review fixes

    /// Finding 1: the daemon broadcasts the new notice, then the old one's
    /// `archived` state. That frame is for a card already replaced in place,
    /// so it must not take the new card down.
    func testArchivedFrameForANoticeReplacedByKeyDoesNotRemoveTheReplacement() {
        let env = harness()
        env.center.receive(notice("old", key: "build", at: env.clock))
        env.center.receive(notice("new", key: "build", at: env.clock))
        env.center.apply(NoticeStateChange(id: "old", state: .archived, stateAt: env.clock.now))

        XCTAssertEqual(env.toast.replaced.map(\.old), ["old"])
        XCTAssertEqual(env.toast.replaced.map(\.new), ["new"])
        XCTAssertTrue(env.toast.removed.isEmpty, "the replaced card is not removed a second time")
        XCTAssertEqual(env.toast.shownIDs, ["new"])
        XCTAssertEqual(env.center.newestShownID, "new")
    }

    /// Finding 3: the app's backlog covers only part of what is shown. A card
    /// outside that part (an fyi toast) survives a reconcile that does not
    /// list it.
    func testReconcileLeavesCardsTheActiveListDoesNotCover() {
        let env = harness()
        env.center.receive(notice("fyi", urgency: .fyi, at: env.clock))
        env.center.receive(notice("soon", urgency: .soon, at: env.clock))

        env.center.reconcile(active: [], covering: { $0.urgency != .fyi })

        XCTAssertEqual(env.toast.removed, ["soon"])
        XCTAssertEqual(env.toast.shownIDs, ["fyi"])
    }

    /// Finding 4: escalation counts from when the card went up, not from the
    /// notice's timestamp, so a backlog notice does not escalate the moment
    /// it is first drawn.
    func testEscalationCountsFromPresentationNotFromTheTimestamp() {
        let env = harness()
        let posted = env.clock.now
        env.clock.now.addTimeInterval(3600)
        env.center.receive(Notice(id: "a", timestamp: posted, source: "ci", title: "a", urgency: .soon))
        env.center.tick()
        XCTAssertEqual(env.toast.shownIDs, ["a"], "an hour-old notice is not escalated on arrival")
        XCTAssertTrue(env.alert.shownIDs.isEmpty)

        env.clock.now.addTimeInterval(899)
        env.center.tick()
        XCTAssertTrue(env.alert.shownIDs.isEmpty, "not yet")

        env.clock.now.addTimeInterval(2)
        env.center.tick()
        XCTAssertEqual(env.alert.shownIDs, ["a"])
    }
}
