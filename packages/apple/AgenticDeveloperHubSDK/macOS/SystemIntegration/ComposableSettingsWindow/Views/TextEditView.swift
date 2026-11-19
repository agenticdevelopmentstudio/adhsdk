import AppKit
import AgenticDeveloperHubSDKCore

extension ComposableSettings {

    @MainActor
    public class TextEditView: NSView, SettingsViewProtocol {
        public let label: NSTextField
        public let textField: NSTextField

        let viewModel: ViewModel<String>

        /// Grey hint text shown while the field is empty, in the theme's
        /// placeholder color on every field the row shows.
        public var placeholder: String? {
            didSet {
                for field in editableFields {
                    field.placeholderString = placeholder
                    Self.applyTheme(to: field, palette: ThemePaletteObserver.currentPalette)
                }
            }
        }

        /// The view model's ``AbstractViewModel/explanation``, which the
        /// ``GroupView`` this is placed in draws under the row.
        public var settingTitle: String? { viewModel.title }
        public var settingExplanation: String? { viewModel.explanation }

        public init(with viewModel: ViewModel<String>) {
            self.viewModel = viewModel
            self.label = Self.createLabel(title: viewModel.title)
            self.textField = Self.makeTextField(initialValue: viewModel.value)

            super.init(frame: .zero)
            self.translatesAutoresizingMaskIntoConstraints = false

            // Below the row spacer's hugging, so the field — not the gap — takes
            // the width left over after the label. An empty field sized to its
            // own content is a few points wide and unclickable.
            self.textField.setContentHuggingPriority(.init(1), for: .horizontal)

            let row = Self.makeRow([self.label, makeControlView()])
            self.addSubview(row)
            Self.pinToEdges(row, of: self)

            // Every field the row edits commits through `textFieldChanged`, and
            // takes the theme here rather than by returning a `ThemedTextField`
            // from the factory, since subclasses substitute their own field
            // (`SecureTextEditView` returns an `NSSecureTextField`). Each is
            // titled by the row's label, so a screen reader names the field.
            for field in editableFields {
                field.target = self
                field.action = #selector(textFieldChanged(_:))
                field.setAccessibilityTitleUIElement(label)
                field.observeTheme { field, palette in Self.applyTheme(to: field, palette: palette) }
            }

            viewModel.onChange = { [weak self] _ in
                guard let self else { return }
                self.label.stringValue = viewModel.title
                self.storedValueDidChange(viewModel.value)
            }
            viewModel.refreshHandler = { [weak self] force in
                guard let self else { return }
                self.reloadStoredValue(viewModel.value, force: force)
            }
        }

        // MARK: - Subclass hooks (module-internal)

        /// The view beside the label. The plain row's is its text field.
        func makeControlView() -> NSView { textField }

        /// Every text field the row can edit through, each themed and wired
        /// to the same commit path.
        var editableFields: [NSTextField] { [textField] }

        /// The setting changed (from anywhere, this row's own commit included).
        func storedValueDidChange(_ value: String) {
            textField.stringValue = value
        }

        /// A refresh: `force` discards an edit in progress, otherwise an edit
        /// in progress is kept.
        func reloadStoredValue(_ value: String, force: Bool) {
            for field in editableFields {
                if force { FieldSync.force(field, value) } else { FieldSync.load(field, value) }
            }
        }

        static func applyTheme(to field: NSTextField, palette: SemanticPalette) {
            field.font = palette.font(.body)
            field.textColor = palette.primaryTextColor
            if let placeholder = field.placeholderString {
                field.placeholderAttributedString = NSAttributedString(
                    string: placeholder,
                    attributes: [
                        .foregroundColor: palette.placeholderTextColor,
                        .font: palette.font(.body)
                    ]
                )
            }
        }

        /// The one commit path: a field's action writes its text unless the
        /// setting already holds it.
        @objc func textFieldChanged(_ sender: NSTextField) {
            let newValue = sender.stringValue
            if viewModel.settingObserver.value != newValue {
                viewModel.settingObserver.value = newValue
            }
        }

        public override init(frame frameRect: NSRect) {
            fatalError("init(frame:) has not been implemented")
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        static func createLabel(title: String) -> NSTextField {
            ComposableSettings.makeRowLabel(title)
        }

        /// Override to substitute a different `NSTextField` subclass — e.g.
        /// `SecureTextEditView` returns an `NSSecureTextField`.
        open class func makeTextField(initialValue: String) -> NSTextField {
            NSTextField(string: initialValue)
        }
    }
}

extension ComposableSettings.TextEditView: ComposableSettings.ExplainedSettingsView {}
