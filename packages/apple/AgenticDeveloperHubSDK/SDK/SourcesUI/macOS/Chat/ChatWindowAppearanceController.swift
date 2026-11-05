import AppKit

/// The gear on a chat window and the four switches behind it — text size,
/// transparency, whether the window floats, whether the caret blinks — wired
/// to a `WindowAppearanceDefaults` that outlives the launch.
///
/// In the toolkit rather than in each app because none of it is one app's:
/// every window that hosts an `InlineChatView` wants the same four switches,
/// in the same order, saved the same way, and restored on the way back up. An
/// app supplies the two things that really are its own — the panel's title and
/// the defaults namespace — and gets the rest.
///
/// The three appliers are the same code the dialog's controls call and the
/// same code `restore()` calls, so there is one description of what each
/// setting *does* rather than one for changing and one for restoring.
@MainActor
public final class ChatWindowAppearanceController {

    public let defaults: WindowAppearanceDefaults

    /// Held because `NSTitlebarAccessoryViewController` retains only the view:
    /// the component that owns the dialog and the gear's target has no other
    /// owner.
    private var options: WindowOptionsDialog?

    private let title: String

    /// What the backdrop switch is called. The toolkit has no name for what a
    /// host chose to draw back there — "Rain" for Olylo, something else for
    /// the next tool — so the host supplies the word.
    private let backdropToggleTitle: String

    private weak var window: NSWindow?
    private weak var chatView: InlineChatView?

    public init(
        window: NSWindow,
        chatView: InlineChatView,
        defaults: WindowAppearanceDefaults,
        title: String,
        backdropToggleTitle: String = "Background animation"
    ) {
        self.window = window
        self.chatView = chatView
        self.defaults = defaults
        self.title = title
        self.backdropToggleTitle = backdropToggleTitle
    }

    /// Puts the gear in the window's right title-bar accessory and replays
    /// what was saved.
    ///
    /// A real `NSTitlebarAccessoryViewController` even on a window that shows
    /// no title bar: as long as `.titled` is in the style mask the bar exists
    /// to hang an accessory on, whatever has been done to its material, its
    /// title and its traffic lights. Floating a button over the content
    /// instead would have to re-derive the position the title bar already
    /// knows, and would move with whatever it was floating over.
    public func install(leading: [NSView] = []) {
        guard let window else { return }
        let options = WindowOptionsDialog(title: title) { [weak self] in
            self?.makeControls() ?? []
        }
        window.addTitlebarAccessoryViewController(options.makeTitlebarAccessory(leading: leading))
        self.options = options
        chatView?.onTextScaleNudge = { [weak self] step in self?.nudgeTextScale(by: step) }
        restore()
    }

    /// ⌘+ / ⌘− / ⌘0, arriving from the chat view. One step is 10% of the
    /// theme's own size — coarse enough to be worth a keystroke, fine enough
    /// that overshooting costs one more. `0` is "back to the theme's size",
    /// which is the shortcut's meaning everywhere else it exists.
    public func nudgeTextScale(by step: Int) {
        let range = WindowAppearanceDefaults.textScaleRange
        let target = step == 0 ? 1 : defaults.textScale + Double(step) * 0.1
        let clamped = Swift.max(range.lowerBound, Swift.min(range.upperBound, target))
        guard clamped != defaults.textScale else { return }
        defaults.textScale = clamped
        applyTextScale(clamped)
        // The panel, if it happens to be open, is showing the old number.
        options?.rebuildControls()
    }

    /// Replays the saved settings onto the window and the chat, so the four
    /// switches survive a relaunch.
    public func restore() {
        applyTextScale(defaults.textScale)
        applyTransparency(defaults.transparency)
        applyFloating(defaults.isFloating)
        chatView?.blinksCaret = defaults.blinksCaret
        chatView?.showsBackdrop = defaults.showsBackdrop
    }

    /// Built on each open rather than at construction, so the controls read
    /// live values and a window pays nothing for the panel at launch.
    ///
    /// Internal rather than private so the tests can ask what the panel *would*
    /// show without putting a window on screen to open it.
    func makeControls() -> [NSView] {
        var controls: [NSView] = [
            WindowOptionsSlider(
                title: "Text Size",
                value: defaults.textScale,
                range: WindowAppearanceDefaults.textScaleRange,
                caption: { "\(Int(($0 * 100).rounded()))%" },
                onChange: { [weak self] scale in
                    self?.defaults.textScale = scale
                    self?.applyTextScale(scale)
                }),
            WindowOptionsSlider(
                title: "Transparency",
                value: defaults.transparency,
                range: WindowAppearanceDefaults.transparencyRange,
                caption: { "\(Int($0.rounded()))%" },
                onChange: { [weak self] transparency in
                    self?.defaults.transparency = transparency
                    self?.applyTransparency(transparency)
                }),
            WindowOptionsToggle(
                title: "Float above other windows",
                isOn: defaults.isFloating,
                onChange: { [weak self] floating in
                    self?.defaults.isFloating = floating
                    self?.applyFloating(floating)
                }),
            WindowOptionsToggle(
                title: "Blink caret",
                isOn: defaults.blinksCaret,
                onChange: { [weak self] blinks in
                    self?.defaults.blinksCaret = blinks
                    self?.chatView?.blinksCaret = blinks
                })
        ]
        // Only when there is something back there to switch off. A chat with
        // no backdrop is the default (`InlineChatView.backdrop` is `nil`), and
        // a switch that toggles a setting nothing reads is a switch that lies
        // — which is also what the documentation has always promised.
        if chatView?.backdrop != nil {
            controls.append(
                WindowOptionsToggle(
                    title: backdropToggleTitle,
                    isOn: defaults.showsBackdrop,
                    onChange: { [weak self] shows in
                        self?.defaults.showsBackdrop = shows
                        self?.chatView?.showsBackdrop = shows
                    }))
        }
        // Last rather than directly under the text-size slider: the three it
        // puts back are the first three rows, and a button wedged between them
        // and the caret switch would read as belonging to the rows below it.
        controls.append(WindowOptionsResetButton { [weak self] in self?.resetAppearance() })
        return controls
    }

    /// Puts text size, transparency and floating back to their defaults.
    ///
    /// The dialog is rebuilt afterwards because its controls read their values
    /// once, as they are built — the same reason `nudgeTextScale` rebuilds it.
    private func resetAppearance() {
        defaults.resetWindowAppearance()
        restore()
        options?.rebuildControls()
    }

    /// Through the chat's own `ThemeScope`, not `ThemeManager.textScale`.
    ///
    /// The manager's scale is the app's — one number for every window it has
    /// open — so driving it from a per-window slider resized every other
    /// window at the same time. The scope reaches exactly the views inside
    /// this chat: the transcript, the status line and the composer, and
    /// nothing else. Saved under this window's namespace, so two chats
    /// remember two sizes.
    private func applyTextScale(_ scale: Double) {
        chatView?.themeScope.textScale = scale
    }

    /// On the chat's surface, not the window's `alphaValue`. Fading the window
    /// faded the text, the prompt and the gear along with the background,
    /// which is not what "transparency" means here — see
    /// `InlineChatView.surfaceTransparency`.
    private func applyTransparency(_ transparency: Double) {
        chatView?.surfaceTransparency = transparency
    }

    private func applyFloating(_ floating: Bool) {
        window?.level = floating ? .floating : .normal
    }
}
