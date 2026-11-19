import AppKit
import AgenticDeveloperHubSDKCore

extension ComposableSettings {

    /// A secret's row: the value shows as one dot per character, with a copy
    /// button and an eye button trailing the field. The eye shows the value as
    /// plain text until it is pressed again, the window resigns key, the app
    /// resigns active, the row leaves its window, or the setting changes from
    /// outside the row. The shown state lives only in the view; nothing stores it.
    ///
    /// AppKit has no reveal mode on `NSSecureTextField`, so showing swaps in a
    /// plain `NSTextField` stacked in the same place, carrying the same text
    /// and keeping first responder. Both fields commit through the row's one
    /// commit path.
    @MainActor
    public final class SecureTextEditView: TextEditView, NSTextFieldDelegate {

        /// The plain field shown while the value is revealed.
        public let revealField = NSTextField(string: "")
        public let copyButton = NSButton()
        public let revealButton = NSButton()

        /// Where Copy writes. Injected so tests do not touch the user's clipboard.
        public var pasteboard: NSPasteboard = .general

        /// Whether the value shows as plain text.
        public private(set) var isRevealed = false

        private weak var observedWindow: NSWindow?

        public override init(with viewModel: ViewModel<String>) {
            super.init(with: viewModel)
            revealField.stringValue = viewModel.value
            textField.delegate = self
            revealField.delegate = self

            configure(copyButton, symbol: "doc.on.doc", action: #selector(copyValue(_:)))
            configure(revealButton, symbol: "eye", action: #selector(toggleReveal(_:)))
            copyButton.setAccessibilityLabel("Copy")
            copyButton.toolTip = "Copy"

            let slug = AccessibilityID.slug(viewModel.title)
            textField.accessibilityID("settings.secure.\(slug).field")
            revealField.accessibilityID("settings.secure.\(slug).revealed")
            copyButton.accessibilityID("settings.secure.\(slug).copy")
            revealButton.accessibilityID("settings.secure.\(slug).reveal")

            textField.nextKeyView = copyButton
            revealField.nextKeyView = copyButton
            copyButton.nextKeyView = revealButton

            NotificationCenter.default.addObserver(
                self, selector: #selector(obscureForNotification(_:)),
                name: NSApplication.didResignActiveNotification, object: nil)

            applyRevealState()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public override static func makeTextField(initialValue: String) -> NSTextField {
            NSSecureTextField(string: initialValue)
        }

        // MARK: - TextEditView hooks

        override func makeControlView() -> NSView {
            // The two fields overlap; exactly one is visible.
            let fieldStack = NSView()
            fieldStack.translatesAutoresizingMaskIntoConstraints = false
            for field in [textField, revealField] {
                field.translatesAutoresizingMaskIntoConstraints = false
                fieldStack.addSubview(field)
                Self.pinToEdges(field, of: fieldStack)
            }
            fieldStack.setContentHuggingPriority(.init(1), for: .horizontal)
            revealField.setContentHuggingPriority(.init(1), for: .horizontal)

            let control = NSStackView(views: [fieldStack, copyButton, revealButton])
            control.orientation = .horizontal
            control.alignment = .centerY
            control.spacing = ComposableSettings.SettingsLayout.default[.rowSpacing]
            control.translatesAutoresizingMaskIntoConstraints = false
            control.setContentHuggingPriority(.init(1), for: .horizontal)
            for button in [copyButton, revealButton] {
                button.translatesAutoresizingMaskIntoConstraints = false
                button.setContentCompressionResistancePriority(.required, for: .horizontal)
                button.setContentHuggingPriority(.required, for: .horizontal)
                NSLayoutConstraint.activate([
                    button.heightAnchor.constraint(equalTo: fieldStack.heightAnchor),
                    button.widthAnchor.constraint(equalTo: button.heightAnchor)
                ])
            }
            return control
        }

        override var editableFields: [NSTextField] { [textField, revealField] }

        override func storedValueDidChange(_ value: String) {
            // A value other than the one the row shows came from outside the
            // row: hide it before it is put in the fields, so it arrives as dots.
            if value != shownText { setRevealed(false) }
            textField.stringValue = value
            revealField.stringValue = value
            updateCopyEnabled()
        }

        override func reloadStoredValue(_ value: String, force: Bool) {
            if value != shownText { setRevealed(false) }
            super.reloadStoredValue(value, force: force)
            updateCopyEnabled()
        }

        // MARK: - Reveal

        /// Shows the value as plain text (`true`) or as dots (`false`), keeping
        /// the text, any unsaved edit and the keyboard focus.
        public func setRevealed(_ revealed: Bool) {
            guard revealed != isRevealed else { return }
            let previous = activeField
            let text = previous.stringValue
            let hadFocus = Self.isEditing(previous)
            isRevealed = revealed
            let next = activeField
            next.stringValue = text
            applyRevealState()
            if hadFocus, let window = next.window, window.makeFirstResponder(next) {
                let end = (text as NSString).length
                next.currentEditor()?.selectedRange = NSRange(location: end, length: 0)
            }
        }

        /// The field the reader currently sees.
        private var activeField: NSTextField { isRevealed ? revealField : textField }

        /// The text the row shows, including an edit not yet committed.
        private var shownText: String { activeField.stringValue }

        private func applyRevealState() {
            textField.isHidden = isRevealed
            revealField.isHidden = !isRevealed
            let label = isRevealed ? "Hide" : "Show"
            revealButton.image = NSImage(
                systemSymbolName: isRevealed ? "eye.slash" : "eye", accessibilityDescription: label)
            revealButton.setAccessibilityLabel(label)
            revealButton.toolTip = label
            updateCopyEnabled()
        }

        private func updateCopyEnabled() {
            copyButton.isEnabled = !shownText.isEmpty
        }

        private static func isEditing(_ field: NSTextField) -> Bool {
            guard let editor = field.currentEditor() else { return false }
            return field.window?.firstResponder === editor
        }

        // MARK: - Actions

        @objc private func toggleReveal(_ sender: Any?) {
            setRevealed(!isRevealed)
        }

        /// Puts the shown text — the plain value, in either state — on the pasteboard.
        @objc private func copyValue(_ sender: Any?) {
            let text = shownText
            guard !text.isEmpty else { return }
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        }

        public func controlTextDidChange(_ obj: Notification) {
            updateCopyEnabled()
        }

        // MARK: - Re-obscuring

        public override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let observedWindow {
                NotificationCenter.default.removeObserver(
                    self, name: NSWindow.didResignKeyNotification, object: observedWindow)
            }
            observedWindow = window
            guard let window else {
                setRevealed(false)
                return
            }
            NotificationCenter.default.addObserver(
                self, selector: #selector(obscureForNotification(_:)),
                name: NSWindow.didResignKeyNotification, object: window)
        }

        @objc private func obscureForNotification(_ note: Notification) {
            setRevealed(false)
        }

        // MARK: - Buttons

        private func configure(_ button: NSButton, symbol: String, action: Selector) {
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            button.imagePosition = .imageOnly
            button.isBordered = false
            button.bezelStyle = .inline
            button.target = self
            button.action = action
            button.observeTheme { button, palette in
                button.contentTintColor = palette.secondaryTextColor
            }
        }
    }
}
