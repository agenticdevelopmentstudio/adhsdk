import AppKit
import Combine

/// A settings form generated from an App's schema, writing through `DesktopAppSettings`.
@MainActor
final class DesktopSettingsFormViewController: NSViewController {
    private let schema: DesktopAppSettingsSchema
    private let settings: DesktopAppSettings
    private var subscription: AnyCancellable?

    init(schema: DesktopAppSettingsSchema, settings: DesktopAppSettings) {
        self.schema = schema
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        var rows = schema.fields.map(row(for:))
        if schema.fields.isEmpty {
            rows.append(NSTextField(labelWithString: "This App has no settings."))
        }
        view = DesktopSettingsRows.formView(rows)
        refreshControls()
        // Read-only: refreshing controls never writes.
        subscription = settings.changes.sink { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshControls() }
        }
    }

    // MARK: Rows

    private func row(for field: DesktopAppSettingsSchema.Field) -> NSView {
        let control = controlView(for: field)
        var views: [NSView] = [DesktopSettingsRows.labeledRow(field.label, control)]
        if let help = field.help {
            let note = NSTextField(wrappingLabelWithString: help)
            note.font = .systemFont(ofSize: 11)
            note.textColor = .secondaryLabelColor
            views.append(note)
        }
        let column = NSStackView(views: views)
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 4
        return column
    }

    private func controlView(for field: DesktopAppSettingsSchema.Field) -> NSView {
        let identifier = NSUserInterfaceItemIdentifier(field.key)
        switch field.kind {
        case .toggle:
            let toggle = NSSwitch()
            toggle.identifier = identifier
            toggle.target = self
            toggle.action = #selector(toggleChanged(_:))
            return toggle
        case let .text(_, placeholder):
            let text = NSTextField()
            text.identifier = identifier
            text.placeholderString = placeholder
            text.widthAnchor.constraint(equalToConstant: 220).isActive = true
            wire(text, action: #selector(textChanged(_:)))
            return text
        case let .integer(_, range):
            let text = NSTextField()
            text.identifier = identifier
            text.widthAnchor.constraint(equalToConstant: 70).isActive = true
            wire(text, action: #selector(integerFieldChanged(_:)))
            let stepper = NSStepper()
            stepper.identifier = identifier
            stepper.minValue = Double(range.lowerBound)
            stepper.maxValue = Double(range.upperBound)
            stepper.increment = 1
            stepper.valueWraps = false
            stepper.target = self
            stepper.action = #selector(stepperChanged(_:))
            let pair = NSStackView(views: [text, stepper])
            pair.spacing = 4
            return pair
        case let .choice(_, options):
            let popUp = NSPopUpButton()
            popUp.identifier = identifier
            for option in options {
                popUp.addItem(withTitle: option.label)
                popUp.lastItem?.representedObject = option.id
            }
            popUp.target = self
            popUp.action = #selector(choiceChanged(_:))
            return popUp
        }
    }

    private func wire(_ field: NSTextField, action: Selector) {
        field.target = self
        field.action = action
        (field.cell as? NSTextFieldCell)?.sendsActionOnEndEditing = true
    }

    // MARK: Control values

    private func controls<T: NSView>(of type: T.Type, key: String) -> [T] {
        guard isViewLoaded else { return [] }
        return Self.descendants(of: view).compactMap { $0 as? T }.filter { $0.identifier?.rawValue == key }
    }

    private static func descendants(of view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { descendants(of: $0) }
    }

    private func refreshControls() {
        for field in schema.fields {
            switch field.kind {
            case .toggle:
                let value = settings.bool(field.key)
                for toggle in controls(of: NSSwitch.self, key: field.key) { toggle.state = value ? .on : .off }
            case .text:
                let value = settings.string(field.key)
                for text in controls(of: NSTextField.self, key: field.key) where text.stringValue != value {
                    text.stringValue = value
                }
            case .integer:
                let value = settings.integer(field.key)
                for text in controls(of: NSTextField.self, key: field.key) { text.integerValue = value }
                for stepper in controls(of: NSStepper.self, key: field.key) { stepper.integerValue = value }
            case .choice:
                let value = settings.choice(field.key)
                for popUp in controls(of: NSPopUpButton.self, key: field.key) {
                    let index = popUp.itemArray.firstIndex { ($0.representedObject as? String) == value }
                    if let index { popUp.selectItem(at: index) }
                }
            }
        }
    }

    // MARK: Actions

    @objc private func toggleChanged(_ sender: NSSwitch) {
        guard let key = sender.identifier?.rawValue else { return }
        settings.setBool(sender.state == .on, for: key)
    }

    @objc private func textChanged(_ sender: NSTextField) {
        guard let key = sender.identifier?.rawValue else { return }
        settings.setString(sender.stringValue, for: key)
    }

    @objc private func integerFieldChanged(_ sender: NSTextField) {
        guard let key = sender.identifier?.rawValue else { return }
        let parsed = Int(sender.stringValue.trimmingCharacters(in: .whitespaces)) ?? settings.integer(key)
        settings.setInteger(parsed, for: key)
        refreshControls()
    }

    @objc private func stepperChanged(_ sender: NSStepper) {
        guard let key = sender.identifier?.rawValue else { return }
        settings.setInteger(sender.integerValue, for: key)
        refreshControls()
    }

    @objc private func choiceChanged(_ sender: NSPopUpButton) {
        guard let key = sender.identifier?.rawValue,
              let id = sender.selectedItem?.representedObject as? String else { return }
        settings.setChoice(id, for: key)
    }
}
