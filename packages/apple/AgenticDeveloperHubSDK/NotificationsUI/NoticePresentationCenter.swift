import Foundation
import AgenticDeveloperHubSDKNotifications

/// The single entry point for putting notices on screen.
///
/// The host hands it notices and state changes; it decides what to show and
/// drives the presenters, and talks back through a `NoticeActionHandler`. For
/// each incoming active notice it:
/// 1. drops it if the filter rejects it;
/// 2. replaces in place a shown notice with the same `source` + `key`;
/// 3. holds it while Focus is on and its urgency is below `now`;
/// 4. folds it into a per-source summary while that source is flooding;
/// 5. resolves its profile and hands it to that profile's presenter.
///
/// Every user action removes the card first and tells the host second, so the
/// screen never waits on the host's transport.
@MainActor
public final class NoticePresentationCenter {

    private struct Entry {
        var notice: Notice
        var profile: NoticeProfile
        var escalated = false
        var isSummary = false
    }

    private let handler: NoticeActionHandler
    private let rules: @MainActor () -> NoticeRoutingRules
    private let filter: @MainActor () -> NoticeFilter
    private let focus: NoticeFocusMonitor
    private let idle: IdleMonitor
    private let clock: () -> Date

    /// The presenters by the style they draw. Internal so tests can register
    /// recording presenters; a host adds others (full screen, crawl, system)
    /// through `setPresenter(_:for:)`, or takes them all from `standard`.
    var presenters: [NoticeProfile.Style: NoticePresenter] = [:]

    /// The calendar snooze times ("tomorrow at 9:00") are computed in.
    public var calendar = Calendar.current

    private var entries: [String: Entry] = [:]
    /// Shown ids in the order they were presented, oldest first.
    private var order: [String] = []
    private var held: [Notice] = []
    private var floodFolder = FloodFolder()
    /// Ids already counted into a flood summary, with their source, so a
    /// reconcile does not count them twice or show them after all, and a
    /// summary goes once nothing it folded is still active.
    private var foldedIDs: [String: String] = [:]
    /// Ids routed to no style and not forwarded: evaluated once and drawn
    /// nowhere. Remembered so each reconcile does not feed them to the flood
    /// folder again and conjure a summary out of one quiet notice.
    private var evaluatedIDs: Set<String> = []
    /// Ids the user has just acted on. Their card is gone, but until the host
    /// applies the change its active list still has them, and a reconcile in
    /// that gap must not bring the card back.
    private var actedIDs: Set<String> = []
    private var escalationTimer: Timer?
    /// Ids snoozed "until I'm back", with when that snooze ends on its own:
    /// woken early, as `unread`, the first time the user returns from being
    /// idle. Kept in `untilBackStore`, when there is one, so a relaunch while
    /// the user is away still wakes them.
    private var untilBack: [String: Date] = [:]
    private let untilBackStore: UserDefaults?
    static let untilBackKey = "NoticePresentationCenter.untilBack"

    public init(
        handler: NoticeActionHandler,
        rules: @escaping @MainActor () -> NoticeRoutingRules,
        filter: @escaping @MainActor () -> NoticeFilter,
        focus: NoticeFocusMonitor = NeverFocused(),
        idle: IdleMonitor = IdleMonitor(),
        untilBackStore: UserDefaults? = nil,
        clock: @escaping () -> Date = Date.init
    ) {
        self.handler = handler
        self.rules = rules
        self.filter = filter
        self.focus = focus
        self.idle = idle
        self.untilBackStore = untilBackStore
        self.clock = clock
        presenters[.toast] = ToastPresenter(
            rules: rules, showHistory: { [weak handler] in handler?.showHistory() })
        presenters[.alert] = AlertPresenter(rules: rules)
        idle.onReturn = { [weak self] in self?.wakeUntilBack() }
        restoreUntilBack()
    }

    isolated deinit {
        escalationTimer?.invalidate()
        idle.stop()
    }

    /// A center with every style the SDK draws: toast and alert, plus crawl,
    /// full screen and the system's own Notification Center. What a host
    /// normally wants; the plain initializer leaves the last three to it.
    public static func standard(
        handler: NoticeActionHandler,
        rules: @escaping @MainActor () -> NoticeRoutingRules,
        filter: @escaping @MainActor () -> NoticeFilter,
        focus: NoticeFocusMonitor = NeverFocused(),
        systemSound: @escaping @MainActor () -> Bool = { true },
        untilBackStore: UserDefaults? = .standard
    ) -> NoticePresentationCenter {
        let center = NoticePresentationCenter(
            handler: handler, rules: rules, filter: filter, focus: focus, untilBackStore: untilBackStore)
        center.setPresenter(CrawlPresenter(rules: rules), for: .crawl)
        center.setPresenter(FullScreenPresenter(rules: rules), for: .fullScreen)
        center.setPresenter(SystemNotificationPresenter(playsSound: systemSound), for: .system)
        return center
    }

    /// Adds or replaces the presenter for a style.
    public func setPresenter(_ presenter: NoticePresenter, for style: NoticeProfile.Style) {
        presenters[style] = presenter
    }

    /// Brings up the host's history (the history hotkey, a menu item).
    public func showHistory() {
        handler.showHistory()
    }

    // MARK: Queries

    /// The most recently presented notice still on screen.
    public var newestShownID: String? { order.last }

    /// The style a notice is presented in, or `nil` when it is not on screen.
    public func presentedStyle(of id: String) -> NoticeProfile.Style? {
        entries[id]?.profile.style
    }

    // MARK: Input

    public func receive(_ notice: Notice) {
        let now = clock()
        guard notice.state.isActive else { return }
        // Back before the user returned (it was unsnoozed some other way).
        forgetUntilBack(notice.id)
        if let expiresAt = notice.expiresAt, expiresAt <= now { return }
        guard filter().admits(notice) else { return }
        let rules = rules()

        // Already on screen (a re-post, or a reconcile racing a broadcast):
        // refresh it where it stands.
        if let existing = entries[notice.id] {
            replace(oldID: notice.id, existing: existing, with: notice, profile: rules.profile(for: notice))
            return
        }

        if let key = notice.key,
           let oldID = order.first(where: { id in
               guard let entry = entries[id], !entry.isSummary else { return false }
               return entry.notice.source == notice.source && entry.notice.key == key
           }),
           let existing = entries[oldID] {
            replace(oldID: oldID, existing: existing, with: notice, profile: rules.profile(for: notice))
            return
        }

        if focus.isFocused, notice.urgency.rank < Notice.Urgency.now.rank {
            held.removeAll { $0.id == notice.id }
            held.append(notice)
            return
        }

        guard foldedIDs[notice.id] == nil, !evaluatedIDs.contains(notice.id) else { return }
        floodFolder.configuration = rules.flood
        if case let .fold(source, count) = floodFolder.admit(notice, at: now) {
            foldedIDs[notice.id] = source
            showSummary(source: source, count: count, like: notice, rules: rules, now: now)
            return
        }

        present(notice, profile: rules.profile(for: notice))
    }

    /// A state change the host broadcast. Anything but `unread` takes the
    /// notice off screen; it is not echoed back to the handler.
    public func apply(_ change: NoticeStateChange) {
        guard change.state != .unread else { return }
        if change.state != .snoozed {
            forgetUntilBack(change.id)
        }
        held.removeAll { $0.id == change.id }
        foldedIDs[change.id] = nil
        evaluatedIDs.remove(change.id)
        actedIDs.remove(change.id)
        dismiss(change.id)
        dropSpentSummaries()
    }

    /// Makes the screen match the host's list of active notices: removes every
    /// card not in it and presents any that are missing.
    public func reconcile(active: [Notice]) {
        let activeIDs = Set(active.map(\.id))
        for id in order where entries[id]?.isSummary == false && !activeIDs.contains(id) {
            dismiss(id)
        }
        held.removeAll { !activeIDs.contains($0.id) }
        foldedIDs = foldedIDs.filter { activeIDs.contains($0.key) }
        evaluatedIDs.formIntersection(activeIDs)
        actedIDs.formIntersection(activeIDs)
        dropSpentSummaries()
        let heldIDs = Set(held.map(\.id))
        for notice in active.sorted(by: { $0.timestamp < $1.timestamp })
        where entries[notice.id] == nil && !heldIDs.contains(notice.id) && !actedIDs.contains(notice.id) {
            receive(notice)
        }
    }

    /// Re-checks escalation now. The timer calls this; tests call it directly.
    public func tick() {
        let now = clock()
        let rules = rules()
        for id in order {
            guard let entry = entries[id], !entry.escalated, !entry.isSummary,
                  let urgency = rules.escalation.escalated(entry.notice, now: now) else { continue }
            var shown = entry.notice
            shown.urgency = urgency
            let profile = rules.profile(for: entry.notice, effectiveUrgency: urgency)
            if profile.style == entry.profile.style {
                presenters[profile.style]?.replace(
                    oldID: id, with: shown, profile: profile, actions: cardActions(for: id))
            } else {
                presenters[entry.profile.style]?.remove(id: id)
                presenters[profile.style]?.show(shown, profile: profile, actions: cardActions(for: id))
            }
            entries[id] = Entry(notice: entry.notice, profile: profile, escalated: true)
        }
        rearmEscalation()
    }

    /// Call when the Focus monitor's answer may have changed. Releases what
    /// was held once Focus is off.
    public func focusDidChange() {
        guard !focus.isFocused else { return }
        let released = held
        held = []
        for notice in released {
            receive(notice)
        }
    }

    // MARK: User actions

    /// The card was clicked: run the primary action.
    public func act(id: String) {
        guard let entry = entries[id] else { return }
        if entry.isSummary {
            dismiss(id)
            handler.showHistory()
            return
        }
        guard let action = entry.notice.primaryAction else {
            userDismiss(id)
            handler.setState(id, .read)
            return
        }
        if case .reply = action.kind {
            // Crawl and system draw no field: the history is where it can
            // be answered.
            if presenters[entry.profile.style]?.focusReply(id: id) != true {
                handler.showHistory()
            }
            return
        }
        userDismiss(id)
        perform(action, of: id, text: nil)
    }

    /// One action button, with reply text for a reply action.
    public func respond(id: String, actionID: String, text: String?) {
        guard let entry = entries[id], !entry.isSummary,
              let action = entry.notice.actions.first(where: { $0.id == actionID }) else { return }
        userDismiss(id)
        perform(action, of: id, text: text)
    }

    public func archive(id: String) {
        guard let entry = entries[id] else { return }
        if entry.isSummary {
            dismiss(id)
        } else {
            userDismiss(id)
            handler.setState(id, .archived)
        }
    }

    public func snooze(id: String, option: SnoozeOption) {
        guard let entry = entries[id] else { return }
        if entry.isSummary {
            dismiss(id)
        } else {
            userDismiss(id)
            let until = option.until(now: clock(), calendar: calendar)
            handler.snooze(id, until: until)
            if option == .untilBack {
                untilBack[id] = until
                saveUntilBack()
                idle.start()
            }
        }
    }

    // MARK: Until I'm back

    /// Whether any notice is waiting for the user to come back.
    var hasUntilBackNotices: Bool { !untilBack.isEmpty }

    private func wakeUntilBack() {
        let now = clock()
        let woken = untilBack.filter { $0.value > now }.keys.sorted()
        untilBack = [:]
        saveUntilBack()
        idle.stop()
        for id in woken {
            handler.setState(id, .unread)
        }
    }

    private func forgetUntilBack(_ id: String) {
        guard untilBack.removeValue(forKey: id) != nil else { return }
        saveUntilBack()
        if untilBack.isEmpty {
            idle.stop()
        }
    }

    /// Picks up what a previous launch left, minus snoozes that have since
    /// run out on their own, and watches for the user's return again.
    private func restoreUntilBack() {
        guard let stored = untilBackStore?.dictionary(forKey: Self.untilBackKey) as? [String: Double] else { return }
        let now = clock()
        untilBack = stored.mapValues(Date.init(timeIntervalSince1970:)).filter { $0.value > now }
        if untilBack.count != stored.count {
            saveUntilBack()
        }
        if !untilBack.isEmpty {
            idle.start()
        }
    }

    private func saveUntilBack() {
        guard let untilBackStore else { return }
        if untilBack.isEmpty {
            untilBackStore.removeObject(forKey: Self.untilBackKey)
        } else {
            untilBackStore.set(untilBack.mapValues(\.timeIntervalSince1970), forKey: Self.untilBackKey)
        }
    }

    /// The close button or an auto-dismiss expiry: off screen, marked `read`.
    public func close(id: String) {
        guard let entry = entries[id] else { return }
        if entry.isSummary {
            dismiss(id)
        } else {
            userDismiss(id)
            handler.setState(id, .read)
        }
    }

    // MARK: Presenting

    private func present(_ notice: Notice, profile: NoticeProfile) {
        guard profile.style != .none || profile.forwardToSystem else {
            evaluatedIDs.insert(notice.id)
            return
        }
        entries[notice.id] = Entry(notice: notice, profile: profile)
        order.append(notice.id)
        let actions = cardActions(for: notice.id)
        if profile.style != .none {
            presenters[profile.style]?.show(notice, profile: profile, actions: actions)
        }
        if Self.forwards(profile) {
            presenters[.system]?.show(notice, profile: profile, actions: actions)
        }
        rearmEscalation()
    }

    private func replace(oldID: String, existing: Entry, with notice: Notice, profile: NoticeProfile) {
        let actions = cardActions(for: notice.id)
        entries[oldID] = nil
        order.removeAll { $0 == oldID }
        entries[notice.id] = Entry(notice: notice, profile: profile)
        order.append(notice.id)
        if profile.style == existing.profile.style {
            presenters[profile.style]?.replace(oldID: oldID, with: notice, profile: profile, actions: actions)
        } else {
            presenters[existing.profile.style]?.remove(id: oldID)
            presenters[profile.style]?.show(notice, profile: profile, actions: actions)
        }
        // The system copy follows: the old one goes, and the new one is
        // posted if the new profile forwards.
        if Self.forwards(existing.profile) {
            presenters[.system]?.remove(id: oldID)
        }
        if Self.forwards(profile) {
            presenters[.system]?.show(notice, profile: profile, actions: actions)
        }
        rearmEscalation()
    }

    /// Whether a profile also posts to the system presenter, beside its own style.
    private static func forwards(_ profile: NoticeProfile) -> Bool {
        profile.forwardToSystem && profile.style != .system
    }

    private func showSummary(source: String, count: Int, like notice: Notice, rules: NoticeRoutingRules, now: Date) {
        let id = "flood:\(source)"
        let summary = Notice(
            id: id, timestamp: now, source: source, title: "\(count) from \(source)",
            body: "Click to see them in history.", app: notice.app, level: .info, urgency: .fyi)
        var profile = rules.profile(for: notice)
        profile.style = .toast
        profile.autoDismiss = nil
        profile.forwardToSystem = false
        let actions = cardActions(for: id, summary: true)

        if entries[id] != nil {
            entries[id] = Entry(notice: summary, profile: profile, isSummary: true)
            order.removeAll { $0 == id }
            order.append(id)
            presenters[.toast]?.replace(oldID: id, with: summary, profile: profile, actions: actions)
        } else {
            entries[id] = Entry(notice: summary, profile: profile, isSummary: true)
            order.append(id)
            presenters[.toast]?.show(summary, profile: profile, actions: actions)
        }
    }

    /// Off screen everywhere. Every presenter is told, tracked or not, because
    /// a notice that escalated or was forwarded may be on more than one, and a
    /// presenter may hold a card this center has already forgotten.
    private func dismiss(_ id: String) {
        entries[id] = nil
        order.removeAll { $0 == id }
        var seen: Set<ObjectIdentifier> = []
        for presenter in presenters.values where seen.insert(ObjectIdentifier(presenter)).inserted {
            presenter.remove(id: id)
        }
        rearmEscalation()
    }

    /// Off screen because the user acted, so a reconcile racing the host's
    /// broadcast leaves it off.
    private func userDismiss(_ id: String) {
        actedIDs.insert(id)
        dismiss(id)
    }

    /// A flood summary goes once nothing it folded is still active.
    private func dropSpentSummaries() {
        let folding = Set(foldedIDs.values)
        for id in order {
            guard let entry = entries[id], entry.isSummary, !folding.contains(entry.notice.source) else { continue }
            dismiss(id)
        }
    }

    private func perform(_ action: Notice.Action, of id: String, text: String?) {
        if case let .open(url) = action.kind {
            handler.openURL(url)
        }
        handler.respond(id, actionID: action.id, text: text)
    }

    private func cardActions(for id: String, summary: Bool = false) -> NoticeCardActions {
        var snooze: (@MainActor (SnoozeOption) -> Void)?
        var archive: (@MainActor () -> Void)?
        if !summary {
            snooze = { [weak self] option in self?.snooze(id: id, option: option) }
            archive = { [weak self] in self?.archive(id: id) }
        }
        return NoticeCardActions(
            act: { [weak self] in self?.act(id: id) },
            respond: { [weak self] actionID, text in self?.respond(id: id, actionID: actionID, text: text) },
            snooze: snooze,
            archive: archive,
            close: { [weak self] in self?.close(id: id) })
    }

    // MARK: Escalation timer

    private func rearmEscalation() {
        escalationTimer?.invalidate()
        escalationTimer = nil
        let policy = rules().escalation
        let next = entries.values
            .filter { !$0.escalated && !$0.isSummary }
            .compactMap { policy.nextCheck(for: $0.notice) }
            .min()
        guard let next else { return }
        let interval = max(0.5, next.timeIntervalSince(clock()))
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        escalationTimer = timer
    }
}
