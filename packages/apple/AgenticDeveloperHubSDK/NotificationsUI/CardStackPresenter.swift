import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKNotifications

/// The engine under the toast and alert presenters: each notice becomes one
/// card in its own `NoticePanel` on every screen its profile selects, and the
/// cards on one screen at one position form a stack laid out by
/// `ToastStackLayout`, newest nearest the anchor.
///
/// A stack shows at most `visibleLimit` cards; the rest are hidden behind a
/// "+N more" pill that opens the history. Each card sits in its own panel
/// rather than one panel per stack, so the gaps between cards stay
/// click-through to whatever is underneath.
@MainActor
class CardStackPresenter: NoticePresenter {

    struct StackKey: Hashable {
        let displayID: UInt32
        let position: NoticeProfile.Position
    }

    private struct Placement {
        let key: StackKey
        let screen: NSScreen
        let panel: NoticePanel
        let card: NoticeCardView
    }

    private struct Pill {
        let panel: NoticePanel
        let view: MorePillView
    }

    let rules: @MainActor () -> NoticeRoutingRules
    let cardStyle: NoticeCardView.Style
    private let showHistory: @MainActor () -> Void

    private(set) var shownIDs: [String] = []
    private var placements: [String: [Placement]] = [:]
    /// Ids per stack, newest first.
    private var stacks: [StackKey: [String]] = [:]
    private var pills: [StackKey: Pill] = [:]

    init(
        rules: @escaping @MainActor () -> NoticeRoutingRules,
        cardStyle: NoticeCardView.Style,
        showHistory: @escaping @MainActor () -> Void
    ) {
        self.rules = rules
        self.cardStyle = cardStyle
        self.showHistory = showHistory
    }

    /// How many cards one stack shows before the rest fold behind the pill.
    var visibleLimit: Int { .max }

    /// The countdown a card in this presenter runs, if any.
    func autoDismiss(for profile: NoticeProfile) -> TimeInterval? { profile.autoDismiss }

    // MARK: NoticePresenter

    func show(_ notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        if placements[notice.id] != nil {
            remove(id: notice.id)
        }
        let hideFromSharing = rules().hideFromScreenSharing
        var made: [Placement] = []
        for screen in ScreenSelector.current(for: profile.screens) {
            let key = StackKey(displayID: screen.noticeDisplayID, position: profile.position)
            let panel = NoticePanel(layer: profile.layer, hideFromSharing: hideFromSharing)
            let card = NoticeCardView(notice: notice, actions: actions, style: cardStyle)
            card.onHoverChange = { [weak self] _ in self?.layout(key) }
            panel.contentView = card
            card.startAutoDismiss(after: autoDismiss(for: profile))
            made.append(Placement(key: key, screen: screen, panel: panel, card: card))
            stacks[key, default: []].insert(notice.id, at: 0)
        }
        guard !made.isEmpty else { return }
        placements[notice.id] = made
        shownIDs.append(notice.id)
        for key in Set(made.map(\.key)) {
            layout(key)
        }
    }

    func remove(id: String) {
        guard let removed = placements.removeValue(forKey: id) else { return }
        shownIDs.removeAll { $0 == id }
        for placement in removed {
            placement.card.stop()
            placement.panel.orderOut(nil)
            placement.panel.close()
            stacks[placement.key]?.removeAll { $0 == id }
        }
        for key in Set(removed.map(\.key)) {
            layout(key)
        }
    }

    func replace(oldID: String, with notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        guard let existing = placements[oldID],
              existing.allSatisfy({ $0.key.position == profile.position && $0.panel.level == level(profile) })
        else {
            remove(id: oldID)
            show(notice, profile: profile, actions: actions)
            return
        }
        placements[oldID] = nil
        if oldID != notice.id {
            remove(id: notice.id)
        }
        for placement in existing {
            placement.card.update(notice: notice, actions: actions)
            placement.card.startAutoDismiss(after: autoDismiss(for: profile))
            if let index = stacks[placement.key]?.firstIndex(of: oldID) {
                stacks[placement.key]?[index] = notice.id
            }
        }
        placements[notice.id] = existing
        if let index = shownIDs.firstIndex(of: oldID) {
            shownIDs[index] = notice.id
        }
        for key in Set(existing.map(\.key)) {
            layout(key)
        }
    }

    func focusReply(id: String) {
        placements[id]?.first?.card.focusReply()
    }

    // MARK: Layout

    private func level(_ profile: NoticeProfile) -> NSWindow.Level {
        profile.layer == .floating ? .statusBar : .normal
    }

    private func placement(of id: String, in key: StackKey) -> Placement? {
        placements[id]?.first { $0.key == key }
    }

    private func layout(_ key: StackKey) {
        let ids = stacks[key] ?? []
        guard let screen = ids.lazy.compactMap({ self.placement(of: $0, in: key)?.screen }).first else {
            stacks[key] = nil
            closePill(key)
            return
        }
        let limit = max(1, visibleLimit)
        let visible = ids.prefix(limit).compactMap { placement(of: $0, in: key) }
        let hiddenCount = ids.count - visible.count

        var sizes = visible.map { placement in
            placement.card.layoutSubtreeIfNeeded()
            return placement.card.fittingSize
        }
        let pill = hiddenCount > 0 ? makePill(key, count: hiddenCount, layer: visible.first?.panel.level) : nil
        if let pill {
            sizes.append(pill.view.fittingSize)
        }
        let frames = ToastStackLayout.frames(sizes: sizes, in: screen.visibleFrame, position: key.position)

        for (placement, frame) in zip(visible, frames) {
            placement.panel.setFrame(frame, display: true)
            if !placement.panel.isVisible {
                placement.panel.orderFrontRegardless()
            }
        }
        for id in ids.dropFirst(limit) {
            placement(of: id, in: key)?.panel.orderOut(nil)
        }
        if let pill, let frame = frames.last {
            pill.panel.setFrame(frame, display: true)
            pill.panel.orderFrontRegardless()
        } else {
            closePill(key)
        }
    }

    private func makePill(_ key: StackKey, count: Int, layer: NSWindow.Level?) -> Pill {
        if let pill = pills[key] {
            pill.view.count = count
            return pill
        }
        let panel = NoticePanel(
            layer: layer == .normal ? .normal : .floating, hideFromSharing: rules().hideFromScreenSharing)
        let view = MorePillView(count: count, width: cardStyle.width) { [weak self] in self?.showHistory() }
        panel.contentView = view
        let pill = Pill(panel: panel, view: view)
        pills[key] = pill
        return pill
    }

    private func closePill(_ key: StackKey) {
        guard let pill = pills.removeValue(forKey: key) else { return }
        pill.panel.orderOut(nil)
        pill.panel.close()
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
