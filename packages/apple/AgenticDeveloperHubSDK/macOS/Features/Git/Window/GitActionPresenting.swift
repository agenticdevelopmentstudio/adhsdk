import AppKit
import os
import AgenticDeveloperHubSDKCore

/// A yes/no question asked before an action runs (recipe `workspace/git/git-window`,
/// "Asking the user").
public struct GitConfirmation: Equatable, Sendable {
    public var title: String
    public var message: String
    public var actionTitle: String
    /// Marks the action button destructive (a hard reset, a forced delete).
    public var isDestructive: Bool

    public init(title: String, message: String, actionTitle: String, isDestructive: Bool) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.isDestructive = isDestructive
    }
}

/// One text field of a `GitTextRequest`.
public struct GitTextField: Equatable, Sendable {
    public var label: String
    public var initial: String
    /// An optional field may be left empty; a required one keeps the action disabled until filled.
    public var isOptional: Bool

    public init(label: String, initial: String, isOptional: Bool) {
        self.label = label
        self.initial = initial
        self.isOptional = isOptional
    }
}

/// Asks for one or more pieces of text: a branch name, a tag and its message.
public struct GitTextRequest: Equatable, Sendable {
    public var title: String
    public var message: String
    public var fields: [GitTextField]
    public var actionTitle: String

    public init(title: String, message: String, fields: [GitTextField], actionTitle: String) {
        self.title = title
        self.message = message
        self.fields = fields
        self.actionTitle = actionTitle
    }

    /// Whether `values` (one per field) can be submitted: every required field holds
    /// something other than whitespace.
    public func isComplete(_ values: [String]) -> Bool {
        guard values.count == fields.count else { return false }
        return zip(fields, values).allSatisfy { field, value in
            field.isOptional || !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

/// How the Git window asks the user before and after an action. The session talks to
/// this, never to `NSAlert`, so its tests answer with a fake.
@MainActor
public protocol GitActionPresenting: AnyObject {
    /// True when the user chose the action.
    func confirm(_ request: GitConfirmation) async -> Bool
    /// One value per field, trimmed; nil when cancelled.
    func askForText(_ request: GitTextRequest) async -> [String]?
    func showFailure(title: String, message: String)
}

/// `GitActionPresenting` as `NSAlert` sheets on the Git window. Never runs a modal
/// loop and never activates the app: with no window to attach to it answers no
/// (false / nil) and logs.
@MainActor
public final class GitAlertPresenter: GitActionPresenting {
    private let window: @MainActor () -> NSWindow?

    public init(window: @escaping @MainActor () -> NSWindow?) {
        self.window = window
    }

    public func confirm(_ request: GitConfirmation) async -> Bool {
        let alert = NSAlert()
        alert.alertStyle = request.isDestructive ? .critical : .warning
        alert.messageText = request.title
        alert.informativeText = request.message
        let action = alert.addButton(withTitle: request.actionTitle)
        action.setAccessibilityIdentifier("git.prompt.action")
        alert.addButton(withTitle: "Cancel").setAccessibilityIdentifier("git.prompt.cancel")
        alert.window.setAccessibilityIdentifier("git.prompt.confirm")
        if request.isDestructive { alert.buttons.first?.hasDestructiveAction = true }
        guard let response = await present(alert, purpose: "confirmation") else { return false }
        return response == .alertFirstButtonReturn
    }

    public func askForText(_ request: GitTextRequest) async -> [String]? {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = request.title
        alert.informativeText = request.message
        let action = alert.addButton(withTitle: request.actionTitle)
        action.setAccessibilityIdentifier("git.prompt.action")
        alert.addButton(withTitle: "Cancel").setAccessibilityIdentifier("git.prompt.cancel")
        alert.window.setAccessibilityIdentifier("git.prompt.text")

        let fields = request.fields.enumerated().map { index, field in
            let textField = NSTextField(string: field.initial)
            textField.placeholderString = field.label
            textField.setAccessibilityLabel(field.label)
            textField.setAccessibilityIdentifier("git.prompt.field.\(index)")
            return textField
        }
        let enabler = FieldEnabler(request: request, fields: fields, action: action)
        alert.accessoryView = Self.stack(request.fields, fields)
        enabler.update()
        alert.layout()
        alert.window.initialFirstResponder = fields.first

        guard let response = await present(alert, purpose: "text request") else { return nil }
        // Held until the sheet ends: the fields' delegate is weak.
        withExtendedLifetime(enabler) {}
        guard response == .alertFirstButtonReturn else { return nil }
        return fields.map { $0.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    public func showFailure(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK").setAccessibilityIdentifier("git.prompt.ok")
        alert.window.setAccessibilityIdentifier("git.prompt.failure")
        Task { _ = await present(alert, purpose: "failure") }
    }

    // MARK: Private

    /// Runs `alert` as a sheet on the window and returns how it ended; nil when there
    /// is no window to attach it to.
    private func present(_ alert: NSAlert, purpose: String) async -> NSApplication.ModalResponse? {
        guard let window = window() else {
            Self.logger.error("Git \(purpose, privacy: .public) not shown: the Git window has no window")
            return nil
        }
        return await withCheckedContinuation { continuation in
            alert.beginSheetModal(for: window) { response in
                continuation.resume(returning: response)
            }
        }
    }

    /// Label and field per row, labels in one column.
    private static func stack(_ specs: [GitTextField], _ fields: [NSTextField]) -> NSView {
        let rows = zip(specs, fields).map { spec, field in
            let label = NSTextField(labelWithString: spec.label)
            return [label, field]
        }
        let grid = NSGridView(views: rows)
        grid.setAccessibilityIdentifier("git.prompt.fields")
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.columnSpacing = 8
        grid.rowSpacing = 8
        grid.frame = NSRect(x: 0, y: 0, width: 300, height: grid.fittingSize.height)
        for field in fields {
            field.widthAnchor.constraint(greaterThanOrEqualToConstant: 220).isActive = true
        }
        grid.frame.size = grid.fittingSize
        return grid
    }
}

extension GitAlertPresenter: Loggable {
    public static nonisolated let logger = makeLogger()
}

/// Enables the action button only while the request is complete, as the user types.
@MainActor
private final class FieldEnabler: NSObject, NSTextFieldDelegate {
    private let request: GitTextRequest
    private let fields: [NSTextField]
    private weak var action: NSButton?

    init(request: GitTextRequest, fields: [NSTextField], action: NSButton) {
        self.request = request
        self.fields = fields
        self.action = action
        super.init()
        for field in fields { field.delegate = self }
    }

    func update() {
        action?.isEnabled = request.isComplete(fields.map(\.stringValue))
    }

    func controlTextDidChange(_ obj: Notification) {
        update()
    }
}
