import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKNotifications

/// Full screen: a dimmed window over each selected screen with the notice's
/// card in the middle. Unlike every other style it takes focus, because it
/// covers the user's work and their keystrokes must not keep going to an app
/// they can no longer see. Esc snoozes it for five minutes. It never times
/// out.
@MainActor
public final class FullScreenPresenter: NoticePresenter {

    private struct Placement {
        let panel: NoticePanel
        let view: FullScreenNoticeView
    }

    private let rules: @MainActor () -> NoticeRoutingRules
    private let activate: @MainActor () -> Void
    public private(set) var shownIDs: [String] = []
    private var placements: [String: [Placement]] = [:]

    /// - Parameter activate: brings the host app forward so the panel gets
    ///   the keyboard; defaults to `NSApp.activate()`.
    public init(
        rules: @escaping @MainActor () -> NoticeRoutingRules,
        activate: @escaping @MainActor () -> Void = { NSApp.activate() }
    ) {
        self.rules = rules
        self.activate = activate
    }

    /// A focus-taking panel exactly covering `frame` (a screen's whole frame,
    /// menu bar and Dock included).
    static func makePanel(frame: CGRect, layer: NoticeProfile.Layer, hideFromSharing: Bool) -> NoticePanel {
        let panel = NoticePanel(layer: layer, hideFromSharing: hideFromSharing, takesFocus: true)
        panel.hasShadow = false
        panel.setFrame(frame, display: false)
        return panel
    }

    // MARK: NoticePresenter

    public func show(_ notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        if placements[notice.id] != nil {
            remove(id: notice.id)
        }
        let hideFromSharing = rules().hideFromScreenSharing
        var made: [Placement] = []
        for screen in ScreenSelector.current(for: profile.screens) {
            let panel = Self.makePanel(frame: screen.frame, layer: profile.layer, hideFromSharing: hideFromSharing)
            let view = FullScreenNoticeView(notice: notice, actions: actions)
            panel.contentView = view
            made.append(Placement(panel: panel, view: view))
        }
        guard !made.isEmpty else { return }
        placements[notice.id] = made
        shownIDs.append(notice.id)
        activate()
        for placement in made {
            placement.panel.orderFrontRegardless()
        }
        // The newest one, on the first screen, takes the keyboard.
        if let first = made.first {
            first.panel.makeKeyAndOrderFront(nil)
            first.panel.makeFirstResponder(first.view)
        }
    }

    public func remove(id: String) {
        guard let removed = placements.removeValue(forKey: id) else { return }
        shownIDs.removeAll { $0 == id }
        for placement in removed {
            placement.panel.orderOut(nil)
            placement.panel.close()
        }
    }

    public func replace(oldID: String, with notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        guard let existing = placements.removeValue(forKey: oldID) else {
            show(notice, profile: profile, actions: actions)
            return
        }
        for placement in existing {
            placement.view.update(notice: notice, actions: actions)
        }
        placements[notice.id] = existing
        if let index = shownIDs.firstIndex(of: oldID) {
            shownIDs[index] = notice.id
        }
    }

    public func focusReply(id: String) {
        placements[id]?.first?.view.card.focusReply()
    }
}

/// The dimmed backdrop with the card centered on it. It is the panel's first
/// responder, so Esc reaches it.
@MainActor
final class FullScreenNoticeView: NSView {

    let card: NoticeCardView
    private var actions: NoticeCardActions

    init(notice: Notice, actions: NoticeCardActions) {
        self.actions = actions
        card = NoticeCardView(notice: notice, actions: actions, style: .alert)
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.55).cgColor
        addSubview(card)
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel(notice.title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func update(notice: Notice, actions: NoticeCardActions) {
        self.actions = actions
        card.update(notice: notice, actions: actions)
        setAccessibilityLabel(notice.title)
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Esc, through the responder chain.
    override func cancelOperation(_ sender: Any?) {
        snoozeBriefly()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            snoozeBriefly()
        } else {
            super.keyDown(with: event)
        }
    }

    /// The backdrop swallows clicks, so nothing behind it is pressed by
    /// accident; only the card acts.
    override func mouseDown(with event: NSEvent) {}

    private func snoozeBriefly() {
        actions.snooze?(.fiveMinutes)
    }
}
