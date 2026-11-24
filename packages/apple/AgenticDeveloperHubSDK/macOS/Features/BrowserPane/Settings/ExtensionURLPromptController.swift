//
//  ExtensionURLPromptController.swift
//  AgenticDeveloperHubSDK
//

import AppKit

/// The Extensions topic's URL… prompt: one field and OK / Cancel, shown as a
/// sheet on the settings window (or as an app-modal alert when there is no
/// window). OK is enabled only while the field names something installable
/// (`isValid`): a Chrome Web Store extension ID or link, or an http(s)
/// address of a `.crx`.
@MainActor
final class ExtensionURLPromptController: NSObject, NSTextFieldDelegate {

    let alert = NSAlert()
    let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
    /// The alert's OK button.
    let okButton: NSButton

    init(accessibilityPrefix: String) {
        // No instruction line: the placeholder shows the shape, and what URL…
        // accepts is in the Extensions topic's help ("Installing").
        alert.messageText = "Add an Extension from a URL"
        okButton = alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        super.init()
        field.placeholderString = "https://chromewebstore.google.com/detail/…"
        field.setAccessibilityLabel("Extension URL")
        field.setAccessibilityIdentifier("\(accessibilityPrefix).url.field")
        field.delegate = self
        okButton.setAccessibilityIdentifier("\(accessibilityPrefix).url.ok")
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        updateOK()
    }

    /// Whether `text` is something URL… can install: a Web Store ID or link,
    /// or an http(s) address whose path ends in `.crx`.
    static func isValid(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if WebStoreExtension.id(from: trimmed) != nil { return true }
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else { return false }
        return url.path.lowercased().hasSuffix(".crx")
    }

    /// Shows the prompt; `completion` gets the trimmed text on OK, nil on Cancel.
    func begin(on window: NSWindow?, completion: @escaping (String?) -> Void) {
        let finish: (NSApplication.ModalResponse) -> Void = { [field] response in
            let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            completion(response == .alertFirstButtonReturn && Self.isValid(text) ? text : nil)
        }
        if let window {
            alert.beginSheetModal(for: window, completionHandler: finish)
        } else {
            finish(alert.runModal())
        }
    }

    /// Types `text` into the field, as the person would.
    func setText(_ text: String) {
        field.stringValue = text
        updateOK()
    }

    func controlTextDidChange(_ notification: Notification) { updateOK() }

    private func updateOK() {
        okButton.isEnabled = Self.isValid(field.stringValue)
    }
}
