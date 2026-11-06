import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKNotifications

/// Full screen: a dimmed window over each selected screen with the notice's
/// card in the middle. Unlike every other style it takes the keyboard,
/// because it covers the user's work and their keystrokes must not keep going
/// to an app they can no longer see. Its panel is still non-activating: it
/// becomes key without activating the host app, so it never depends on
/// `NSApp.activate()`, which macOS 14 and later treat as a request. Esc
/// snoozes it for five minutes. It never times out.
///
/// With several up at once the newest has the keyboard; when it goes, the
/// newest one left takes it back.
@MainActor
public final class FullScreenPresenter: NoticePresenter {

    private struct Placement {
        let displayID: UInt32
        let panel: NoticePanel
        let view: FullScreenNoticeView
    }

    private let rules: @MainActor () -> NoticeRoutingRules
    private let windowing: NoticeWindowing
    private let screens: NoticeScreenProvider
    public private(set) var shownIDs: [String] = []
    private var placements: [String: [Placement]] = [:]
    private var screenObserver: NSObjectProtocol?

    public convenience init(rules: @escaping @MainActor () -> NoticeRoutingRules) {
        self.init(rules: rules, windowing: LiveNoticeWindowing(), screens: ScreenSelector.noticeScreens)
    }

    /// With the windows and screens injected, so tests put nothing on screen.
    init(
        rules: @escaping @MainActor () -> NoticeRoutingRules,
        windowing: NoticeWindowing,
        screens: @escaping NoticeScreenProvider
    ) {
        self.rules = rules
        self.windowing = windowing
        self.screens = screens
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

    /// A keyboard-taking panel exactly covering `frame` (a screen's whole
    /// frame, menu bar and Dock included). At least at status-bar level
    /// whatever the profile's layer, so it is never under the menu bar or
    /// another app's floating window.
    static func makePanel(frame: CGRect, layer: NoticeProfile.Layer, hideFromSharing: Bool) -> NoticePanel {
        let panel = NoticePanel(layer: layer, hideFromSharing: hideFromSharing, takesFocus: true)
        panel.level = NSWindow.Level(rawValue: max(panel.level.rawValue, NSWindow.Level.statusBar.rawValue))
        panel.hasShadow = false
        panel.setFrame(frame, display: false)
        return panel
    }

    /// The panels showing `id`, first screen first. For tests.
    func panels(for id: String) -> [NoticePanel] {
        placements[id]?.map(\.panel) ?? []
    }

    // MARK: NoticePresenter

    public func show(_ notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        if placements[notice.id] != nil {
            remove(id: notice.id)
        }
        let hideFromSharing = rules().hideFromScreenSharing
        var made: [Placement] = []
        for screen in screens(profile.screens) {
            let panel = Self.makePanel(frame: screen.frame, layer: profile.layer, hideFromSharing: hideFromSharing)
            let view = FullScreenNoticeView(notice: notice, actions: actions)
            panel.contentView = view
            made.append(Placement(displayID: screen.displayID, panel: panel, view: view))
        }
        guard !made.isEmpty else { return }
        placements[notice.id] = made
        shownIDs.append(notice.id)
        for placement in made {
            windowing.present(placement.panel)
        }
        // The newest one, on the first screen, takes the keyboard.
        if let first = made.first {
            windowing.makeKey(first.panel, firstResponder: first.view)
        }
    }

    public func remove(id: String) {
        guard let removed = placements.removeValue(forKey: id) else { return }
        shownIDs.removeAll { $0 == id }
        for placement in removed {
            placement.view.card.stop()
            windowing.dismiss(placement.panel)
        }
        // Ordering a non-activating panel out hands key back to the active
        // app; with another full screen still up, it takes the keyboard.
        if let next = shownIDs.last, let placement = placements[next]?.first {
            windowing.makeKey(placement.panel, firstResponder: placement.view)
        }
    }

    public func replace(oldID: String, with notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        guard placements[oldID] != nil else {
            show(notice, profile: profile, actions: actions)
            return
        }
        if oldID != notice.id {
            remove(id: notice.id)
        }
        guard let existing = placements.removeValue(forKey: oldID) else { return }
        for placement in existing {
            placement.view.update(notice: notice, actions: actions)
        }
        placements[notice.id] = existing
        if let index = shownIDs.firstIndex(of: oldID) {
            shownIDs[index] = notice.id
        }
    }

    @discardableResult
    public func focusReply(id: String) -> Bool {
        placements[id]?.first?.view.card.focusReply() ?? false
    }

    // MARK: Screens

    /// Refits every panel to its screen after a display was added, removed
    /// or rearranged.
    func screensDidChange() {
        let byID = Dictionary(screens(.all).map { ($0.displayID, $0) }, uniquingKeysWith: { first, _ in first })
        for placement in placements.values.flatMap({ $0 }) {
            guard let screen = byID[placement.displayID] else { continue }
            placement.panel.setFrame(screen.frame, display: true)
        }
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
