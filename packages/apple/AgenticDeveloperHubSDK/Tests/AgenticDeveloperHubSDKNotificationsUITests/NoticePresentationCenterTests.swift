import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

@MainActor
private final class RecordingHandler: NoticeActionHandler {

    enum Call: Equatable {
        case setState(String, Notice.Lifecycle)
        case snooze(String, Date)
        case respond(String, String, String?)
        case openURL(URL)
        case showHistory
        case sendTest(String)
    }

    var calls: [Call] = []

    func setState(_ id: String, _ state: Notice.Lifecycle) { calls.append(.setState(id, state)) }
    func snooze(_ id: String, until: Date) { calls.append(.snooze(id, until)) }
    func respond(_ id: String, actionID: String, text: String?) { calls.append(.respond(id, actionID, text)) }
    func openURL(_ url: URL) { calls.append(.openURL(url)) }
    func showHistory() { calls.append(.showHistory) }
    func sendTest(_ notice: Notice) { calls.append(.sendTest(notice.id)) }
}

@MainActor
private final class RecordingPresenter: NoticePresenter {

    private(set) var shownIDs: [String] = []
    private(set) var shown: [Notice] = []
    private(set) var removed: [String] = []
    private(set) var replaced: [(old: String, new: String)] = []
    private(set) var focusedReplies: [String] = []
    private(set) var actions: [String: NoticeCardActions] = [:]
    private(set) var notices: [String: Notice] = [:]

    func show(_ notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        shown.append(notice)
        shownIDs.append(notice.id)
        self.actions[notice.id] = actions
        notices[notice.id] = notice
    }

    func remove(id: String) {
        removed.append(id)
        shownIDs.removeAll { $0 == id }
    }

    func replace(oldID: String, with notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        replaced.append((oldID, notice.id))
        if let index = shownIDs.firstIndex(of: oldID) {
            shownIDs[index] = notice.id
        } else {
            shownIDs.append(notice.id)
        }
        self.actions[notice.id] = actions
        notices[notice.id] = notice
    }

    func focusReply(id: String) { focusedReplies.append(id) }
}

private struct StubFocus: NoticeFocusMonitor {
    let box: FocusBox
    var isFocused: Bool { box.focused }
}

private final class FocusBox {
    var focused = true
}

private final class Clock {
    var now = Date(timeIntervalSince1970: 1_800_000_000)
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
        focus: NoticeFocusMonitor = NeverFocused()
    ) -> Harness {
        let handler = RecordingHandler()
        let clock = Clock()
        let center = NoticePresentationCenter(
            handler: handler, rules: { rules }, filter: { filter }, focus: focus, clock: { clock.now })
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
        XCTAssertEqual(env.center.presentedStyle(of: "soon"), .toast)
        XCTAssertEqual(env.center.presentedStyle(of: "now"), .alert)
        // No fullScreen presenter is registered, yet the routing is recorded.
        XCTAssertEqual(env.center.presentedStyle(of: "emergency"), .fullScreen)
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
        XCTAssertNil(env.center.presentedStyle(of: "run"))
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
        XCTAssertEqual(env.center.presentedStyle(of: "a"), .alert)

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
        env.center.register(system, for: .system)
        return (env, system)
    }

    private func rules(_ edit: (inout NoticeProfile) -> Void, for urgency: Notice.Urgency) -> NoticeRoutingRules {
        var rules = NoticeRoutingRules.defaults
        var profile = rules.profile(for: Notice(source: "x", title: "x", urgency: urgency))
        edit(&profile)
        rules.profiles[urgency] = profile
        return rules
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

    func testActedIDIsForgottenWhenItLeavesTheActiveList() {
        let env = harness()
        let shown = notice("a", at: env.clock)
        env.center.receive(shown)
        env.center.archive(id: "a")
        env.center.reconcile(active: [])
        env.center.reconcile(active: [shown])
        XCTAssertEqual(env.toast.shownIDs, ["a"], "absent once, so a later active copy is real")
    }

    func testForwardToSystemShowsOnBothPresenters() {
        let (env, system) = harnessWithSystem(rules: rules({ $0.forwardToSystem = true }, for: .soon))
        env.center.receive(notice("a", at: env.clock))
        XCTAssertEqual(env.toast.shownIDs, ["a"])
        XCTAssertEqual(system.shownIDs, ["a"])
        env.center.close(id: "a")
        XCTAssertTrue(system.shownIDs.isEmpty)
    }

    func testReplaceByKeyUpdatesTheSystemPresenter() {
        let (env, system) = harnessWithSystem(rules: rules({ $0.forwardToSystem = true }, for: .soon))
        env.center.receive(notice("run", key: "build", at: env.clock))
        env.center.receive(notice("pass", key: "build", at: env.clock))
        XCTAssertTrue(system.removed.contains("run"))
        XCTAssertEqual(system.shownIDs, ["pass"])
    }

    func testReplaceIntoAProfileThatDoesNotForwardLeavesTheSystemPresenter() {
        var rules = rules({ $0.forwardToSystem = true }, for: .soon)
        rules.profiles[.fyi]?.forwardToSystem = false
        let (env, system) = harnessWithSystem(rules: rules)
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

    func testNoneStyleNoticeIsNotRecountedIntoAFalseFlood() {
        var rules = rules({ $0.style = .none }, for: .fyi)
        rules.flood = .init(threshold: 2, window: 60)
        let env = harness(rules: rules)
        let quiet = notice("q", urgency: .fyi, at: env.clock)
        for _ in 0..<5 {
            env.center.reconcile(active: [quiet])
        }
        XCTAssertTrue(env.toast.shownIDs.isEmpty, "a notice drawn nowhere is evaluated once, not folded")
        XCTAssertTrue(env.toast.shown.isEmpty)
    }
}
