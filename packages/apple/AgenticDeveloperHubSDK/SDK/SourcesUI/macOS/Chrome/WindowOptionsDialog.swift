import AppKit

/// A gear button and the dialog it raises: the standing place for a window's
/// own appearance switches — text size, transparency, whether it floats — as
/// distinct from the app's settings.
///
/// It is a component rather than something each window assembles because the
/// gear's *position* is the convention. A reader who finds it at the trailing
/// edge of one window's title bar looks for it there in the next one, and a
/// window that puts it somewhere else has spent that recognition for nothing.
/// The controls differ per window; where the button sits does not.
///
/// **A small modal window, not a popover.** A popover is anchored to the gear,
/// so it rides the window it is configuring: every slider that changes the
/// window's size moved the panel out from under the pointer, and the only way
/// that was ever made to work was to freeze the window's size for as long as
/// the panel was up — which meant nothing a slider did could be seen until it
/// was dismissed. A dialog centred on the screen is not attached to anything,
/// so the window behind it is free to resize live under every change.
///
/// The controls are built when the dialog opens rather than at construction,
/// so a host's closures read live values and a window pays nothing for the
/// panel at launch.
@MainActor
public final class WindowOptionsDialog: NSObject {

    /// Place this in the window's chrome — `makeTitlebarAccessory()` does it
    /// the conventional way, but a borderless window with no title bar can put
    /// the same button in its own content instead.
    public let gearButton: NSButton

    /// Whether the dialog is on screen.
    public var isShown: Bool { dialogWindow != nil }

    /// The dialog's name — its window title. Settable, because a host whose
    /// title can change — a pane named by its content — would otherwise keep
    /// the name it had at construction at the head of an otherwise live panel.
    public var title: String {
        didSet {
            guard title != oldValue else { return }
            dialogWindow?.title = title
            rebuildControls()
        }
    }

    private let makeControls: @MainActor () -> [NSView]

    /// How wide the dialog's body lays its rows out.
    ///
    /// A host knob rather than one number for everyone: most of these hold
    /// sliders and checkboxes, which the default suits, but a host whose rows
    /// carry something wider — a provider picker with a popup, a model name and
    /// a trailing button — would otherwise have that row cramped to fit a width
    /// chosen for somebody else's checkbox.
    private let width: CGFloat

    /// Held only while it is up. `nil` is the whole of "closed": there is no
    /// second flag to keep in step with it.
    private var dialogWindow: NSWindow?

    /// Held only while the dialog is up: the observation that keeps its level
    /// in step with the host's. See `startFollowingHostLevel(_:)`.
    private var levelObserver: NSObjectProtocol?

    public init(
        title: String,
        tooltip: String = "Window appearance",
        width: CGFloat = OptionsDialogViewController.defaultWidth,
        makeControls: @escaping @MainActor () -> [NSView]
    ) {
        self.title = title
        self.width = width
        self.makeControls = makeControls
        self.gearButton = Self.makeGearButton(tooltip: tooltip)
        super.init()

        gearButton.target = self
        gearButton.action = #selector(gearTapped)
    }

    /// The gear, drawn the way this chrome draws every gear: borderless, the
    /// `gearshape` symbol, tinted with the theme's secondary text.
    ///
    /// Public and separate from the dialog because the *drawing* and the
    /// *panel* are two different pieces of knowledge. A host whose gear raises
    /// a menu instead is still showing this chrome's gear, and a second
    /// spelling of these six lines is a second place to miss when the symbol or
    /// the tint changes (`dry`). The caller supplies target and action;
    /// everything about how it looks comes from here.
    public static func makeGearButton(tooltip: String) -> NSButton {
        let button = NSButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .accessoryBarAction
        button.isBordered = false
        button.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: tooltip)
        button.imagePosition = .imageOnly
        button.toolTip = tooltip
        button.observeTheme { button, palette in
            button.contentTintColor = palette.nsColor(.secondaryText)
        }
        return button
    }

    /// A right-hand title bar accessory holding the gear, plus whatever
    /// window-specific chrome the host wants to its left.
    ///
    /// The container is given an explicit frame on purpose:
    /// `NSTitlebarAccessoryViewController` lays its view out by frame, not by
    /// auto layout, so a purely constraint-driven view reports zero width and
    /// never appears.
    public func makeTitlebarAccessory(
        leading: [NSView] = [],
        // 240, which is what this was in the layer above before it moved down
        // here. `install(leading:)` is the documented way for a host to put its
        // own chrome next to the gear and passes no width, so halving the
        // default silently halved the room every one of those hosts had.
        width: CGFloat = 240
    ) -> NSTitlebarAccessoryViewController {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 28))
        container.autoresizingMask = [.minXMargin]

        let row = NSStackView(views: leading + [gearButton])
        row.orientation = .horizontal
        row.spacing = 6
        row.alignment = .centerY
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            row.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 8),
            row.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        let controller = NSTitlebarAccessoryViewController()
        controller.view = container
        controller.layoutAttribute = .right
        return controller
    }

    @objc private func gearTapped() { toggle() }

    /// Builds the dialog's body afresh, so its controls read live values again.
    ///
    /// The controls are built from a closure over the host's state, which is
    /// right while the dialog is the only thing changing these settings — and
    /// wrong the moment something else does. A keyboard shortcut that moves the
    /// text size leaves an open slider showing the number it had before. A
    /// closed dialog has nothing to rebuild: the next open builds it anyway.
    public func rebuildControls() {
        guard let window = dialogWindow else { return }
        let body = makeBody()
        window.contentViewController = body
        window.setContentSize(body.view.fittingSize)
    }

    public func toggle() {
        if isShown { close() } else { present() }
    }

    /// Raises the dialog app-modally and returns once it has been dismissed.
    ///
    /// App-modal, like every other dialog in this chrome: the window behind is
    /// still visible — and still resizes live as the sliders move — but it is
    /// not being typed into while its own appearance is being changed.
    ///
    /// Safe to call from a button's action, which is where it *is* called from.
    /// `runModal` may not be entered from a SwiftUI action, and must never be
    /// deferred onto `DispatchQueue.main` to get around that.
    public func present() {
        guard let window = beginDialog() else { return }
        NSApp.runModal(for: window)
        endDialog(window)
    }

    /// Everything `present()` does short of entering the modal loop: build the
    /// window, adopt it, put it on its screen, and start following the host's
    /// level. `nil` when one is already up.
    ///
    /// Split out with `endDialog(_:)` so that opening and closing can be
    /// asserted at all. A test that called `present()` would sit in an app-modal
    /// run loop forever, which left the re-entrancy guard, the positioning and
    /// everything that happens *while* the dialog is up with no way to be
    /// covered — the seam is what makes them testable.
    @discardableResult
    func beginDialog() -> NSWindow? {
        guard dialogWindow == nil else { return nil }
        let window = makeDialogWindow()
        dialogWindow = window
        position(window)
        startFollowingHostLevel(window)
        return window
    }

    /// The other half: what `present()` does once the modal loop has ended.
    ///
    /// Whatever ended the loop — `close()`, or something else stopping the
    /// app's modal session — the dialog is no longer up.
    func endDialog(_ window: NSWindow) {
        stopFollowingHostLevel()
        if dialogWindow === window {
            dialogWindow = nil
            window.orderOut(nil)
        }
    }

    /// Takes the dialog down. A no-op when it is not up, because a window can
    /// be closed by its button, by `Done`, and by ⌘W alike.
    public func close() {
        guard let window = dialogWindow else { return }
        dialogWindow = nil
        stopFollowingHostLevel()
        window.orderOut(nil)
        // Only our own session: `close()` is reachable with the dialog up but
        // no modal loop running — the seam above, a host tearing down — and a
        // blind `stopModal()` would then end somebody else's session instead.
        if NSApp.modalWindow === window {
            NSApp.stopModal()
        }
    }

    /// The dialog's window, built but not shown.
    ///
    /// Split from `present()` so the assembly can be asserted without entering
    /// a modal loop — a test that called `present()` would never return.
    func makeDialogWindow() -> NSWindow {
        let window = NSWindow(contentViewController: makeBody())
        window.styleMask = [.titled, .closable]
        window.title = title
        window.appearance = ThemePaletteObserver.currentPalette.standardAppearance
        window.backgroundColor = ThemePaletteObserver.currentPalette.windowBackgroundColor
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.level = hostLevel
        return window
    }

    /// The level the dialog opens at: the one its host window is using.
    ///
    /// Matching rather than defaulting to `.normal` is what keeps the dialog
    /// with the window it belongs to whenever that window is not at the
    /// ordinary level. A HUD the user has asked to float above other apps would
    /// otherwise raise its own options *behind* itself; and a host sunk below
    /// the desktop picture — a test, or an automated session driving the app
    /// while someone works in another application — would have this dialog be
    /// the one window that appeared in front of them, which is precisely what
    /// the sinking is there to prevent.
    private var hostLevel: NSWindow.Level {
        gearButton.window?.level ?? .normal
    }

    /// Keeps the open dialog at the host's level for as long as it is up, not
    /// just at the moment it opened.
    ///
    /// The level is sampled once in `makeDialogWindow()`, and one of the
    /// controls *inside* the dialog changes it: "always on top" raises the host
    /// to `.floating`, which — while the dialog is app-modal — puts the host in
    /// front of the only window that can be interacted with. The app looks
    /// frozen, and the way out is a dialog nobody can see.
    ///
    /// `didUpdateNotification` is the hook because there is no notification for
    /// a level change and `level` is not KVO-observable. AppKit posts it on
    /// every pass of the event loop that touches the window, which during a
    /// modal session is every event — so the dialog catches the host's move on
    /// the very next one.
    private func startFollowingHostLevel(_ window: NSWindow) {
        levelObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didUpdateNotification, object: window, queue: nil
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let dialog = self.dialogWindow else { return }
                let wanted = self.hostLevel
                if dialog.level != wanted { dialog.level = wanted }
            }
        }
    }

    private func stopFollowingHostLevel() {
        guard let levelObserver else { return }
        NotificationCenter.default.removeObserver(levelObserver)
        self.levelObserver = nil
    }

    /// The body: no heading, because the window's own title bar is already
    /// carrying the name.
    private func makeBody() -> OptionsDialogViewController {
        let body = OptionsDialogViewController(
            heading: nil,
            rows: makeControls(),
            width: width,
            accessibilityPrefix: "window.options")
        body.onDone = { [weak self] in self?.close() }
        return body
    }

    /// Centred on the screen the host window is on — not on the host window,
    /// and not wherever the gear happens to be. A window dragged to the corner
    /// of a large display would otherwise raise its options in the corner too.
    private func position(_ window: NSWindow) {
        let screen = gearButton.window?.screen ?? NSScreen.main
        guard let visible = screen?.visibleFrame else {
            window.center()
            return
        }
        let size = window.frame.size
        window.setFrameOrigin(NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2))
    }
}

extension WindowOptionsDialog: NSWindowDelegate {

    /// The close button routes through `close()` so the modal session is ended
    /// exactly once, by the one method that knows how; letting AppKit close the
    /// window instead would leave the app in a modal loop with nothing on
    /// screen.
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        close()
        return false
    }
}

/// A titled slider with a caption that updates as it moves.
///
/// The caption is the point. A slider between two unlabelled ends tells a
/// reader only that they have moved it; "120%" tells them where they are and
/// lets them put it back.
///
/// Title and caption are at the **standard** control size, not the small one
/// they used to be. These are a window's own settings, read and aimed at like
/// any other control, and the small size made the dialog look like a tooltip
/// about the gear rather than the place the settings live.
@MainActor
public final class WindowOptionsSlider: NSView {

    private let slider = NSSlider()
    private let captionLabel = NSTextField(labelWithString: "")
    private let caption: (Double) -> String
    private let onChange: (Double) -> Void

    public var value: Double { slider.doubleValue }

    public init(
        title: String,
        value: Double,
        range: ClosedRange<Double>,
        caption: @escaping (Double) -> String,
        onChange: @escaping (Double) -> Void
    ) {
        self.caption = caption
        self.onChange = onChange
        super.init(frame: .zero)

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)

        captionLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        captionLabel.textColor = .secondaryLabelColor
        captionLabel.alignment = .right
        captionLabel.stringValue = caption(value)

        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.doubleValue = Swift.max(range.lowerBound, Swift.min(range.upperBound, value))
        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(sliderMoved)

        let header = NSStackView(views: [titleLabel, captionLabel])
        header.orientation = .horizontal
        header.distribution = .fill
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        captionLabel.setContentHuggingPriority(.required, for: .horizontal)

        let stack = NSStackView(views: [header, slider])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            header.widthAnchor.constraint(equalTo: stack.widthAnchor),
            slider.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    @objc private func sliderMoved() {
        captionLabel.stringValue = caption(slider.doubleValue)
        onChange(slider.doubleValue)
    }
}

/// A checkbox that reports its new state.
@MainActor
public final class WindowOptionsToggle: NSView {

    private let checkbox: NSButton
    private let onChange: (Bool) -> Void

    /// Settable, because the value a row shows can move while the dialog is
    /// open — another scope changed underneath it, or a Reset button in the same
    /// dialog cleared the override the row was reporting. Assigning does *not*
    /// call `onChange`: this direction is the owner telling the row what is
    /// true, and echoing it back as a user edit would write the value it just
    /// read.
    public var isOn: Bool {
        get { checkbox.state == .on }
        set { checkbox.state = newValue ? .on : .off }
    }

    public init(title: String, isOn: Bool, onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
        checkbox = NSButton(checkboxWithTitle: title, target: nil, action: nil)
        super.init(frame: .zero)

        checkbox.state = isOn ? .on : .off
        checkbox.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        checkbox.target = self
        checkbox.action = #selector(toggled)
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.topAnchor.constraint(equalTo: topAnchor),
            checkbox.bottomAnchor.constraint(equalTo: bottomAnchor),
            checkbox.leadingAnchor.constraint(equalTo: leadingAnchor),
            checkbox.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Names the checkbox, not the box it sits in.
    ///
    /// `NSView.accessibilityID(_:)` would label this wrapper, which is layout
    /// and nothing a script can press; what a script presses is the `NSButton`
    /// inside. It cannot simply be shadowed — Swift refuses to override a
    /// non-`@objc` method declared in an extension of a superclass — so this
    /// carries its own name, and the name says which view it lands on.
    @discardableResult
    public func checkboxAccessibilityID(_ identifier: String) -> Self {
        checkbox.setAccessibilityIdentifier(identifier)
        return self
    }

    @objc private func toggled() {
        onChange(isOn)
    }
}

/// The "Reset to Defaults" button at the foot of a window's options dialog,
/// centered under the last row.
///
/// A component rather than a button each window spells out, because the wording
/// and the position are the shared part: a reader who finds the reset centered
/// at the bottom of one window's dialog looks for it there in the next one.
/// *What* it puts back is that window's own business — each one owns a
/// different set of settings — so a host passes a closure and nothing else.
@MainActor
public final class WindowOptionsResetButton: NSView {

    /// One name for the action, so two dialogs cannot end up offering "Reset"
    /// and "Restore Defaults" for the same button.
    public static let title = "Reset to Defaults"

    private let onReset: () -> Void

    public init(onReset: @escaping () -> Void) {
        self.onReset = onReset
        super.init(frame: .zero)

        let button = NSButton(title: Self.title, target: nil, action: nil)
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(pressed)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        // Centered rather than stretched to the dialog width: every row above
        // it spans the full width, and a reset that did the same would read as
        // one more of them instead of the action underneath them.
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: button.trailingAnchor)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    @objc private func pressed() { onReset() }
}
