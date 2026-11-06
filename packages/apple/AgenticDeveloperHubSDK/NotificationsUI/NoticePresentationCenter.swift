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
    private let clock: () -> Date

    /// The presenters by the style they draw. Internal so tests can register
    /// recording presenters; a host adds others (full screen, crawl, system)
    /// through `register(_:for:)`.
    var presenters: [NoticeProfile.Style: NoticePresenter] = [:]

    /// The calendar snooze times ("tomorrow at 9:00") are computed in.
    public var calendar = Calendar.current

    private var entries: [String: Entry] = [:]
    /// Shown ids in the order they were presented, oldest first.
    private var order: [String] = []
    private var held: [Notice] = []
    private var floodFolder = FloodFolder()
    /// Ids already counted into a flood summary, so a reconcile does not count
    /// them twice or show them after all.
    private var foldedIDs: Set<String> = []
    private var escalationTimer: Timer?

    public init(
        handler: NoticeActionHandler,
        rules: @escaping @MainActor () -> NoticeRoutingRules,
        filter: @escaping @MainActor () -> NoticeFilter,
        focus: NoticeFocusMonitor = NeverFocused(),
        clock: @escaping () -> Date = Date.init
    ) {
        self.handler = handler
        self.rules = rules
        self.filter = filter
        self.focus = focus
        self.clock = clock
        presenters[.toast] = ToastPresenter(
            rules: rules, showHistory: { [weak handler] in handler?.showHistory() })
        presenters[.alert] = AlertPresenter(rules: rules)
    }

    /// Adds or replaces the presenter for a style.
    public func register(_ presenter: NoticePresenter, for style: NoticeProfile.Style) {
        presenters[style] = presenter
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

        guard !foldedIDs.contains(notice.id) else { return }
        floodFolder.configuration = rules.flood
        if case let .fold(source, count) = floodFolder.admit(notice, at: now) {
            foldedIDs.insert(notice.id)
            showSummary(source: source, count: count, like: notice, rules: rules, now: now)
            return
        }

        present(notice, profile: rules.profile(for: notice))
    }

    /// A state change the host broadcast. Anything but `unread` takes the
    /// notice off screen; it is not echoed back to the handler.
    public func apply(_ change: NoticeStateChange) {
        guard change.state != .unread else { return }
        held.removeAll { $0.id == change.id }
        foldedIDs.remove(change.id)
        dismiss(change.id)
    }

    /// Makes the screen match the host's list of active notices: removes every
    /// card not in it and presents any that are missing.
    public func reconcile(active: [Notice]) {
        let activeIDs = Set(active.map(\.id))
        for id in order where entries[id]?.isSummary == false && !activeIDs.contains(id) {
            dismiss(id)
        }
        held.removeAll { !activeIDs.contains($0.id) }
        foldedIDs.formIntersection(activeIDs)
        let heldIDs = Set(held.map(\.id))
        for notice in active.sorted(by: { $0.timestamp < $1.timestamp })
        where entries[notice.id] == nil && !heldIDs.contains(notice.id) {
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
            dismiss(id)
            handler.setState(id, .read)
            return
        }
        if case .reply = action.kind {
            presenters[entry.profile.style]?.focusReply(id: id)
            return
        }
        dismiss(id)
        perform(action, of: id, text: nil)
    }

    /// One action button, with reply text for a reply action.
    public func respond(id: String, actionID: String, text: String?) {
        guard let entry = entries[id], !entry.isSummary,
              let action = entry.notice.actions.first(where: { $0.id == actionID }) else { return }
        dismiss(id)
        perform(action, of: id, text: text)
    }

    public func archive(id: String) {
        guard let entry = entries[id] else { return }
        dismiss(id)
        if !entry.isSummary {
            handler.setState(id, .archived)
        }
    }

    public func snooze(id: String, option: SnoozeOption) {
        guard let entry = entries[id] else { return }
        dismiss(id)
        if !entry.isSummary {
            handler.snooze(id, until: option.until(now: clock(), calendar: calendar))
        }
    }

    /// The close button or an auto-dismiss expiry: off screen, marked `read`.
    public func close(id: String) {
        guard let entry = entries[id] else { return }
        dismiss(id)
        if !entry.isSummary {
            handler.setState(id, .read)
        }
    }

    // MARK: Presenting

    private func present(_ notice: Notice, profile: NoticeProfile) {
        guard profile.style != .none || profile.forwardToSystem else { return }
        entries[notice.id] = Entry(notice: notice, profile: profile)
        order.append(notice.id)
        let actions = cardActions(for: notice.id)
        if profile.style != .none {
            presenters[profile.style]?.show(notice, profile: profile, actions: actions)
        }
        if profile.forwardToSystem, profile.style != .system {
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
        rearmEscalation()
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

    /// Off screen everywhere. Every presenter is told, because a notice that
    /// escalated or was forwarded may be on more than one.
    private func dismiss(_ id: String) {
        guard entries.removeValue(forKey: id) != nil else { return }
        order.removeAll { $0 == id }
        var seen: Set<ObjectIdentifier> = []
        for presenter in presenters.values where seen.insert(ObjectIdentifier(presenter)).inserted {
            presenter.remove(id: id)
        }
        rearmEscalation()
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
