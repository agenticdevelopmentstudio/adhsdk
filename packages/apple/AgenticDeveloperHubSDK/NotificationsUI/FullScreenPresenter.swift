import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKNotifications

/// Full screen: a dimmed window over each selected screen with the notice's
/// card in the middle. Unlike every other style it takes the keyboard,
/// because it covers the user's work and their keystrokes must not keep going
/// to an app they can no longer see. Its panel is still non-activating: it
/// becomes key without activating the host app, so it never depends on
/// `NSApp.activate()`, which macOS 14 and later treat as a request. Esc
/// snoozes it (five minutes if the set offers that, else its first option),
/// or closes it when the set cannot be snoozed. It never times out.
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
    private let blur: WindowBackgroundBlur
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
        screens: @escaping NoticeScreenProvider,
        blur: WindowBackgroundBlur = .live
    ) {
        self.rules = rules
        self.windowing = windowing
        self.screens = screens
        self.blur = blur
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

    /// Draws `profiles[0]` only: one full screen per notice, on `rules().screens`.
    public func show(_ notice: Notice, profiles: [NoticeProfile], actions: NoticeCardActions) {
        if placements[notice.id] != nil {
            remove(id: notice.id)
        }
        guard let profile = profiles.first else { return }
        let hideFromSharing = rules().hideFromScreenSharing
        var made: [Placement] = []
        for screen in screens(rules().screens) {
            let panel = Self.makePanel(frame: screen.frame, layer: profile.layer, hideFromSharing: hideFromSharing)
            let view = FullScreenNoticeView(
                notice: notice, actions: actions, appearance: profile.fullScreen, blur: blur)
            panel.contentView = view
            made.append(Placement(displayID: screen.displayID, panel: panel, view: view))
        }
        guard !made.isEmpty else { return }
        placements[notice.id] = made
        shownIDs.append(notice.id)
        for placement in made {
            windowing.present(placement.panel)
            // The panel has a window-server window only once it is ordered in.
            placement.view.paintBackdrop()
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

    public func replace(oldID: String, with notice: Notice, profiles: [NoticeProfile], actions: NoticeCardActions) {
        guard placements[oldID] != nil, let profile = profiles.first else {
            remove(id: oldID)
            show(notice, profiles: profiles, actions: actions)
            return
        }
        if oldID != notice.id {
            remove(id: notice.id)
        }
        guard let existing = placements.removeValue(forKey: oldID) else { return }
        for placement in existing {
            placement.view.update(notice: notice, actions: actions, appearance: profile.fullScreen)
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

/// The backdrop and the card centered on it. The backdrop is a blur of what
/// is behind the panel, then a tint over it. The blur is the window server's
/// per-window radius (`WindowBackgroundBlur`); where that is unavailable it
/// falls back to an `NSVisualEffectView`, which can only blur fully or not at
/// all. The view is the panel's first responder, so Esc reaches it.
@MainActor
final class FullScreenNoticeView: NSView {

    let card: NoticeCardView
    let blurView = NSVisualEffectView()
    private let tintView = NSView()
    private var actions: NoticeCardActions
    private var backdrop: NoticeProfile.FullScreenAppearance
    private let blur: WindowBackgroundBlur
    /// The radius last set on the window, or nil while the fallback view blurs.
    private(set) var appliedBlurRadius: Int?
    private var palette: SemanticPalette = ThemePaletteObserver.currentPalette
    private var observer: ThemePaletteObserver?

    /// The tint's layer, whose `backgroundColor` is the resolved color at the
    /// item's opacity.
    var tintLayer: CALayer { tintView.layer ?? CALayer() }

    init(
        notice: Notice,
        actions: NoticeCardActions,
        appearance: NoticeProfile.FullScreenAppearance = .init(),
        blur: WindowBackgroundBlur = .live
    ) {
        self.actions = actions
        self.backdrop = appearance
        self.blur = blur
        card = NoticeCardView(notice: notice, actions: actions, style: .alert)
        super.init(frame: .zero)
        blurView.material = .fullScreenUI
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        tintView.wantsLayer = true
        for layerView in [blurView, tintView] {
            layerView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(layerView)
            NSLayoutConstraint.activate([
                layerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                layerView.trailingAnchor.constraint(equalTo: trailingAnchor),
                layerView.topAnchor.constraint(equalTo: topAnchor),
                layerView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
        addSubview(card)
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel(notice.title)
        // Paints now, then follows the live theme, for a Theme color.
        observer = ThemePaletteObserver(host: self) { [weak self] palette in
            self?.palette = palette
            self?.paintBackdrop()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func update(notice: Notice, actions: NoticeCardActions, appearance: NoticeProfile.FullScreenAppearance) {
        self.actions = actions
        self.backdrop = appearance
        card.update(notice: notice, actions: actions)
        setAccessibilityLabel(notice.title)
        paintBackdrop()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        paintBackdrop()
    }

    /// Sets the blur and the tint from the appearance. The radius needs the
    /// panel's window-server window, which exists once it is ordered in.
    func paintBackdrop() {
        let radius = WindowBackgroundBlur.radius(for: backdrop.blur)
        if let window, window.windowNumber > 0, blur.apply(window, radius) {
            appliedBlurRadius = radius
            blurView.isHidden = true
        } else {
            appliedBlurRadius = nil
            // All or nothing: below an alpha of 1 the window server drops it.
            blurView.isHidden = radius == 0
            blurView.alphaValue = 1
        }
        let color = backdrop.color.resolved(system: .black, themeRole: .windowBackground, palette: palette)
        tintView.layer?.backgroundColor = color.withAlphaComponent(backdrop.opacity).cgColor
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Esc, through the responder chain.
    override func cancelOperation(_ sender: Any?) {
        dismissWithEscape()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            dismissWithEscape()
        } else {
            super.keyDown(with: event)
        }
    }

    /// The backdrop swallows clicks, so nothing behind it is pressed by
    /// accident; only the card acts.
    override func mouseDown(with event: NSEvent) {}

    /// Esc snoozes for five minutes when the set offers that, else for the
    /// first option it does offer; a set that cannot be snoozed closes.
    private func dismissWithEscape() {
        let options = actions.snoozeOptions
        guard let snooze = actions.snooze,
              let option = options.contains(.fiveMinutes) ? SnoozeOption.fiveMinutes : options.first
        else {
            actions.close()
            return
        }
        snooze(option)
    }
}
