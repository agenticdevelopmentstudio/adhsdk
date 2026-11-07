import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKNotifications

/// The engine under the toast and alert presenters: each notice becomes one
/// card in its own `NoticePanel` per position its set asks for, on every
/// screen the rules select, and the cards on one screen at one position form
/// a stack laid out by `ToastStackLayout`, newest nearest the anchor.
///
/// A stack shows at most `visibleLimit` cards; the rest are hidden behind a
/// "+N more" pill that opens the history, and their countdowns hold until they
/// come back into view. A presenter that `groupsIntoStackWindow` (toasts) puts
/// each stack in one `ToastStackWindow`; the others (alerts) give each card its
/// own panel. Either way the gaps between cards stay click-through to
/// whatever is underneath. Which id sits where is `CardStackModel`'s; this
/// class owns only the windows.
@MainActor
class CardStackPresenter: NoticePresenter {

    typealias StackKey = CardStackModel.StackKey

    private struct Placement {
        var key: StackKey
        /// The card's own panel, or the stack's shared window.
        var panel: NoticePanel
        let layer: NoticeProfile.Layer
        let card: NoticeCardView
    }

    private struct Pill {
        /// `nil` when the pill lives in a stack window.
        let panel: NoticePanel?
        let view: MorePillView
    }

    let rules: @MainActor () -> NoticeRoutingRules
    let cardStyle: NoticeCardView.Style
    private let showHistory: @MainActor () -> Void
    private let store: SettingsStore

    private(set) var shownIDs: [String] = []
    private var placements: [String: [Placement]] = [:]
    /// The screen selection each shown notice was placed with, so a replace
    /// can tell "the selection changed" from "the displays changed".
    private var selections: [String: NoticeProfile.ScreenSelection] = [:]
    private var model = CardStackModel()
    private var pills: [StackKey: Pill] = [:]
    private var stackWindows: [StackKey: ToastStackWindow] = [:]
    private var screenObserver: NSObjectProtocol?

    /// The displays a screen selection resolves to right now. Internal so a
    /// test can stand in fixed displays for the live ones.
    var displays: @MainActor (NoticeProfile.ScreenSelection) -> [UInt32] = { selection in
        ScreenSelector.current(for: selection).map(\.noticeDisplayID)
    }

    init(
        rules: @escaping @MainActor () -> NoticeRoutingRules,
        cardStyle: NoticeCardView.Style,
        showHistory: @escaping @MainActor () -> Void,
        store: SettingsStore = UserSettings.shared
    ) {
        self.store = store
        self.rules = rules
        self.cardStyle = cardStyle
        self.showHistory = showHistory
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.screensDidChange() }
        }
    }

    isolated deinit {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    /// Whether a stack is one shared window (toasts) rather than a panel per
    /// card (alerts).
    var groupsIntoStackWindow: Bool { false }

    /// How many cards one stack shows before the rest fold behind the pill.
    var visibleLimit: Int { .max }

    /// The countdown a card in this presenter runs, if any.
    func autoDismiss(for profile: NoticeProfile) -> TimeInterval? { profile.autoDismiss }

    // MARK: NoticePresenter

    /// The items this presenter draws from a set's items of its style.
    /// Toasts draw one per distinct position (the first of two at the same
    /// position wins); an alert overrides this to draw only the first item.
    func drawn(_ profiles: [NoticeProfile]) -> [NoticeProfile] {
        var seen: Set<NoticeProfile.Position> = []
        return profiles.filter { seen.insert($0.position).inserted }
    }

    /// One card per drawn item per screen.
    func show(_ notice: Notice, profiles: [NoticeProfile], actions: NoticeCardActions) {
        if placements[notice.id] != nil {
            remove(id: notice.id)
        }
        let profiles = drawn(profiles)
        guard !profiles.isEmpty else { return }
        let rules = rules()
        let hideFromSharing = rules.hideFromScreenSharing
        var made: [Placement] = []
        for profile in profiles {
            for displayID in displays(rules.screens) {
                let key = StackKey(displayID: displayID, position: profile.position)
                let panel = groupsIntoStackWindow
                    ? stackWindow(for: key, layer: profile.layer)
                    : NoticePanel(layer: profile.layer, hideFromSharing: hideFromSharing)
                let card = NoticeCardView(notice: notice, actions: actions, style: cardStyle)
                card.onHoverChange = { [weak self, weak card] hovered in
                    guard let self, let card else { return }
                    self.hoverChanged(on: card, hovered: hovered)
                }
                if !groupsIntoStackWindow {
                    panel.contentView = card
                }
                // Hidden until a layout puts it in its stack's visible prefix.
                card.setInOverflow(true)
                card.startAutoDismiss(after: autoDismiss(for: profile))
                made.append(Placement(key: key, panel: panel, layer: profile.layer, card: card))
                model.insert(notice.id, in: key)
            }
        }
        guard !made.isEmpty else { return }
        placements[notice.id] = made
        selections[notice.id] = rules.screens
        shownIDs.append(notice.id)
        for key in Set(made.map(\.key)) {
            layout(key)
        }
    }

    func remove(id: String) {
        guard let removed = placements.removeValue(forKey: id) else { return }
        selections[id] = nil
        shownIDs.removeAll { $0 == id }
        for placement in removed {
            close(placement)
        }
        for key in model.remove(id) {
            layout(key)
        }
        closeOrphanedPills()
        closeOrphanedStackWindows()
    }

    func replace(oldID: String, with notice: Notice, profiles: [NoticeProfile], actions: NoticeCardActions) {
        let profiles = drawn(profiles)
        guard !profiles.isEmpty else {
            remove(id: oldID)
            return
        }
        let selection = rules().screens
        func profile(at position: NoticeProfile.Position) -> NoticeProfile? {
            profiles.first { $0.position == position }
        }
        // In place only while every card would land exactly where it stands:
        // the same positions, the same layer at each, the same screen
        // *selection*. Changing the setting from `.main` to `.all`, say, moves
        // them. The selection is compared, not the displays it resolves to
        // right now: a display coming or going is `screensDidChange`'s
        // business, not a replace's.
        guard let existing = placements[oldID],
              selections[oldID] == selection,
              Set(existing.map(\.key.position)) == Set(profiles.map(\.position)),
              existing.allSatisfy({ placement in
                  profile(at: placement.key.position).map { $0.layer == placement.layer } ?? false
              })
        else {
            remove(id: oldID)
            show(notice, profiles: profiles, actions: actions)
            return
        }
        placements[oldID] = nil
        selections[oldID] = nil
        if oldID != notice.id {
            remove(id: notice.id)
        }
        for placement in existing {
            placement.card.update(notice: notice, actions: actions)
            placement.card.startAutoDismiss(
                after: profile(at: placement.key.position).flatMap { autoDismiss(for: $0) })
        }
        let touched = model.replace(oldID, with: notice.id)
        placements[notice.id] = existing
        selections[notice.id] = selection
        if let index = shownIDs.firstIndex(of: oldID) {
            shownIDs[index] = notice.id
        }
        for key in touched {
            layout(key)
        }
    }

    /// The displays a notice's cards are on, for tests.
    func displayIDs(of id: String) -> [UInt32] {
        placements[id]?.map(\.key.displayID) ?? []
    }

    /// The panels a notice's cards live in, for tests that tell an in-place
    /// replace from a remove-and-show.
    func panels(of id: String) -> [NoticePanel] {
        placements[id]?.map(\.panel) ?? []
    }

    @discardableResult
    func focusReply(id: String) -> Bool {
        placements[id]?.first?.card.focusReply() ?? false
    }

    // MARK: Hover

    /// The pointer moved onto or off one placement: every other copy of the
    /// same notice holds still with it, and the stack the card grew or shrank
    /// in is laid out again.
    private func hoverChanged(on card: NoticeCardView, hovered: Bool) {
        guard let group = placements.values.first(where: { $0.contains { $0.card === card } }) else { return }
        for placement in group where placement.card !== card {
            placement.card.setPeerHovered(hovered)
        }
        if let key = group.first(where: { $0.card === card })?.key {
            layout(key)
        }
    }

    // MARK: Screens

    /// Displays came, went or moved. Stacks on a display that is gone move to
    /// the main one; every stack is laid out against its display's current frame.
    func screensDidChange() {
        let live = Set(NSScreen.screens.map(\.noticeDisplayID))
        guard let fallback = (NSScreen.main ?? NSScreen.screens.first)?.noticeDisplayID else { return }
        for key in model.keys where !live.contains(key.displayID) {
            let target = key.onDisplay(fallback)
            for id in model.ids(in: key) {
                rehome(id, from: key, to: target)
            }
            closePill(key)
        }
        for key in model.keys {
            layout(key)
        }
        closeOrphanedPills()
        closeOrphanedStackWindows()
    }

    private func rehome(_ id: String, from source: StackKey, to target: StackKey) {
        guard var group = placements[id], let index = group.firstIndex(where: { $0.key == source }) else { return }
        if group.contains(where: { $0.key == target }) {
            // Shown on every screen: the copy that lost its screen just goes.
            close(group.remove(at: index))
        } else {
            group[index].key = target
            if group[index].panel is ToastStackWindow {
                group[index].card.removeFromSuperview()
                group[index].panel = stackWindow(for: target, layer: group[index].layer)
            }
        }
        placements[id] = group
        model.move(id, from: source, to: target)
    }

    // MARK: Layout

    private func placement(of id: String, in key: StackKey) -> Placement? {
        placements[id]?.first { $0.key == key }
    }

    private func screen(for displayID: UInt32) -> NSScreen? {
        NSScreen.screens.first { $0.noticeDisplayID == displayID }
    }

    private func close(_ placement: Placement) {
        placement.card.stop()
        if placement.panel is ToastStackWindow {
            // The stack's window outlives the card; the next layout drops or
            // closes it.
            placement.card.removeFromSuperview()
        } else {
            placement.panel.orderOut(nil)
            placement.panel.close()
        }
    }

    /// Takes a card out of sight: its own panel goes off screen, or it leaves
    /// the stack window at the next arrangement.
    private func hide(_ placement: Placement) {
        placement.card.setInOverflow(true)
        if !(placement.panel is ToastStackWindow) {
            placement.panel.orderOut(nil)
        }
    }

    // MARK: Stack windows

    private func stackWindow(for key: StackKey, layer: NoticeProfile.Layer) -> ToastStackWindow {
        if let window = stackWindows[key] { return window }
        let window = ToastStackWindow(
            position: key.position, layer: layer,
            hideFromSharing: rules().hideFromScreenSharing, store: store)
        let position = key.position
        window.onOffsetChange = { [weak self] in self?.offsetChanged(for: position) }
        stackWindows[key] = window
        return window
    }

    private func closeStackWindow(_ key: StackKey) {
        guard let window = stackWindows.removeValue(forKey: key) else { return }
        window.orderOut(nil)
        window.close()
    }

    private func closeOrphanedStackWindows() {
        for key in Array(stackWindows.keys) where model.ids(in: key).isEmpty {
            closeStackWindow(key)
        }
    }

    /// A drag or reset moved one stack: its position's stacks on the other
    /// screens follow.
    private func offsetChanged(for position: NoticeProfile.Position) {
        for key in model.keys where key.position == position {
            layout(key)
        }
    }

    private func layout(_ key: StackKey) {
        let split = model.split(key, limit: visibleLimit)
        let visible = split.visible.compactMap { placement(of: $0, in: key) }
        for placement in split.hidden.compactMap({ placement(of: $0, in: key) }) {
            hide(placement)
        }
        guard !visible.isEmpty, let screen = screen(for: key.displayID) else {
            // Nothing left here, or the display is gone and
            // `screensDidChange` is about to move the stack.
            for placement in visible {
                hide(placement)
            }
            closePill(key)
            if visible.isEmpty {
                closeStackWindow(key)
            } else {
                stackWindows[key]?.orderOut(nil)
            }
            return
        }
        if groupsIntoStackWindow {
            layoutStackWindow(key, visible: visible, pillCount: split.pillCount, screen: screen)
            return
        }

        var sizes = visible.map { placement in
            placement.card.layoutSubtreeIfNeeded()
            return placement.card.fittingSize
        }
        let pill = split.pillCount > 0
            ? makePill(key, count: split.pillCount, layer: visible.first?.layer ?? .floating) : nil
        if let pill {
            sizes.append(pill.view.fittingSize)
        }
        let frames = ToastStackLayout.frames(sizes: sizes, in: screen.visibleFrame, position: key.position)

        for (placement, frame) in zip(visible, frames) {
            placement.panel.setFrame(frame, display: true)
            if !placement.panel.isVisible {
                placement.panel.orderFrontRegardless()
            }
            placement.card.setInOverflow(false)
        }
        if let pill, let panel = pill.panel, let frame = frames.last {
            panel.setFrame(frame, display: true)
            panel.orderFrontRegardless()
        } else {
            closePill(key)
        }
    }

    private func layoutStackWindow(_ key: StackKey, visible: [Placement], pillCount: Int, screen: NSScreen) {
        let layer: NoticeProfile.Layer = visible.contains { $0.layer == .floating } ? .floating : .normal
        let window = stackWindow(for: key, layer: layer)
        window.apply(layer: layer)
        var views: [NSView] = visible.map(\.card)
        if pillCount > 0 {
            views.append(makePill(key, count: pillCount, layer: layer).view)
        } else {
            closePill(key)
        }
        window.arrange(views: views, visible: screen.visibleFrame)
        for placement in visible {
            placement.card.setInOverflow(false)
        }
        if !window.isVisible {
            window.orderFrontRegardless()
        }
    }

    private func makePill(_ key: StackKey, count: Int, layer: NoticeProfile.Layer) -> Pill {
        if let pill = pills[key] {
            pill.view.count = count
            return pill
        }
        let view = MorePillView(count: count, width: cardStyle.width) { [weak self] in self?.showHistory() }
        guard !groupsIntoStackWindow else {
            let pill = Pill(panel: nil, view: view)
            pills[key] = pill
            return pill
        }
        let panel = NoticePanel(layer: layer, hideFromSharing: rules().hideFromScreenSharing)
        panel.contentView = view
        let pill = Pill(panel: panel, view: view)
        pills[key] = pill
        return pill
    }

    private func closePill(_ key: StackKey) {
        guard let pill = pills.removeValue(forKey: key) else { return }
        guard let panel = pill.panel else {
            pill.view.removeFromSuperview()
            return
        }
        panel.orderOut(nil)
        panel.close()
    }

    /// A pill whose stack emptied out goes with it.
    private func closeOrphanedPills() {
        for key in Array(pills.keys) where model.ids(in: key).isEmpty {
            closePill(key)
        }
    }
}

/// "+N more": the last row of a stack that has more cards than it shows.
/// Clicking it opens the history, where every notice is.
@MainActor
final class MorePillView: NSView {

    var count: Int { didSet { label.stringValue = Self.text(count) } }

    private let label = ThemedLabel(role: .secondaryText, textRole: .caption, weight: .semibold)
    private let background = ThemedBox(fill: .elevatedSurface, stroke: .outline, cornerRadius: 12)
    private let onClick: @MainActor () -> Void

    init(count: Int, width: CGFloat, onClick: @escaping @MainActor () -> Void) {
        self.count = count
        self.onClick = onClick
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        label.stringValue = Self.text(count)
        label.alignment = .center
        background.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)
        addSubview(label)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel(Self.text(count))
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: width),
            heightAnchor.constraint(equalToConstant: 26),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private static func text(_ count: Int) -> String { "+\(count) more" }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        super.hitTest(point) == nil ? nil : self
    }

    override func mouseDown(with event: NSEvent) {}

    override func mouseUp(with event: NSEvent) {
        guard bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        onClick()
    }
}
