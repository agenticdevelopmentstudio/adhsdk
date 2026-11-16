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
    /// The plan as the user edited it in the rebase editor; nil when cancelled.
    func editRebase(_ plan: GitRebasePlan) async -> GitRebasePlan?
    /// The new pull request's form for branch `head`, filled with `defaultTitle` and
    /// `defaultBody`, its base picked from `bases`; nil when cancelled
    /// (GitAlertPresenter+PullRequest.swift).
    func createPullRequest(head: String, defaultTitle: String, defaultBody: String,
                           bases: [String]) async -> GitPullRequestDraft?
}

/// `GitActionPresenting` as `NSAlert` sheets and the rebase editor's window sheet on
/// the Git window. Never runs a modal loop and never activates the app: with no window
/// to attach to it answers no (false / nil) and logs. A sheet still up when its window
/// closes is ended and answered as cancelled, so whoever waits on it always resumes.
@MainActor
public final class GitAlertPresenter: GitActionPresenting {
    /// Begins `alert` as a sheet on a window, calling the handler when it ends.
    typealias SheetBeginner = @MainActor (NSAlert, NSWindow, @escaping (NSApplication.ModalResponse) -> Void) -> Void
    /// Ends the sheet `alert` shows on a window.
    typealias SheetEnder = @MainActor (NSAlert, NSWindow) -> Void
    /// Begins a window (the rebase editor's) as a sheet on the Git window.
    typealias WindowSheetBeginner = @MainActor (NSWindow, NSWindow, @escaping (NSApplication.ModalResponse) -> Void)
        -> Void
    /// Ends a window's sheet on the Git window.
    typealias WindowSheetEnder = @MainActor (NSWindow, NSWindow) -> Void

    private let window: @MainActor () -> NSWindow?
    private let beginSheet: SheetBeginner
    private let endSheet: SheetEnder
    private let beginWindowSheet: WindowSheetBeginner
    private let endWindowSheet: WindowSheetEnder

    public convenience init(window: @escaping @MainActor () -> NSWindow?) {
        self.init(
            window: window,
            beginSheet: { alert, window, handler in alert.beginSheetModal(for: window, completionHandler: handler) },
            endSheet: { alert, window in window.endSheet(alert.window, returnCode: .cancel) })
    }

    /// How a sheet begins and ends is injected, so a test shows none.
    init(window: @escaping @MainActor () -> NSWindow?, beginSheet: @escaping SheetBeginner,
         endSheet: @escaping SheetEnder,
         beginWindowSheet: @escaping WindowSheetBeginner = { sheet, window, handler in
             window.beginSheet(sheet, completionHandler: handler)
         },
         endWindowSheet: @escaping WindowSheetEnder = { sheet, window in
             window.endSheet(sheet, returnCode: .cancel)
         }) {
        self.window = window
        self.beginSheet = beginSheet
        self.endSheet = endSheet
        self.beginWindowSheet = beginWindowSheet
        self.endWindowSheet = endWindowSheet
    }

    public func confirm(_ request: GitConfirmation) async -> Bool {
        let alert = Self.confirmationAlert(request)
        guard let response = await present(alert, purpose: "confirmation") else { return false }
        return response == .alertFirstButtonReturn
    }

    public func askForText(_ request: GitTextRequest) async -> [String]? {
        let prompt = Self.textAlert(request)
        guard let response = await present(prompt.alert, purpose: "text request") else { return nil }
        // Held until the sheet ends: the fields' delegate is weak.
        withExtendedLifetime(prompt.enabler) {}
        guard response == .alertFirstButtonReturn else { return nil }
        return prompt.fields.map { $0.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    public func showFailure(title: String, message: String) {
        let alert = Self.failureAlert(title: title, message: message)
        Task { _ = await present(alert, purpose: "failure") }
    }

    /// Shows the rebase editor as a sheet. Start Rebase answers its plan, Cancel and the
    /// window closing under it nil.
    public func editRebase(_ plan: GitRebasePlan) async -> GitRebasePlan? {
        let editor = GitRebaseEditorViewController(plan: plan)
        let sheet = Self.rebaseSheet(editor)
        let beginWindowSheet = beginWindowSheet
        let endWindowSheet = endWindowSheet
        let response = await present(
            purpose: "rebase editor",
            begin: { window, handler in
                editor.onFinish = { edited in
                    // Answer first: ending the sheet calls the handler again, which then does nothing.
                    handler(edited == nil ? .cancel : .OK)
                    endWindowSheet(sheet, window)
                }
                beginWindowSheet(sheet, window, handler)
            },
            end: { window in
                // Breaks sheet -> editor -> onFinish -> sheet when the window closes first.
                editor.onFinish = nil
                endWindowSheet(sheet, window)
            })
        guard response == .OK else { return nil }
        return editor.plan
    }

    // MARK: Alerts

    /// The action button first, Cancel second; the first destructive when the request is.
    static func confirmationAlert(_ request: GitConfirmation) -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = request.isDestructive ? .critical : .warning
        alert.messageText = request.title
        alert.informativeText = request.message
        let action = alert.addButton(withTitle: request.actionTitle)
        action.setAccessibilityIdentifier("git.prompt.action")
        alert.addButton(withTitle: "Cancel").setAccessibilityIdentifier("git.prompt.cancel")
        alert.window.setAccessibilityIdentifier("git.prompt.confirm")
        if request.isDestructive { action.hasDestructiveAction = true }
        return alert
    }

    /// A text request's alert, its fields (one per request field, the first focused) and
    /// the delegate that keeps the action button enabled only while they are complete.
    static func textAlert(_ request: GitTextRequest) -> TextPrompt {
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
            textField.setAccessibilityLabel(field.label)
            textField.setAccessibilityIdentifier("git.prompt.field.\(index)")
            return textField
        }
        let enabler = FieldEnabler(request: request, fields: fields, action: action)
        alert.accessoryView = Self.stack(request.fields, fields)
        enabler.update()
        alert.layout()
        alert.window.initialFirstResponder = fields.first
        return TextPrompt(alert: alert, fields: fields, enabler: enabler)
    }

    /// An informational alert with one OK button.
    static func failureAlert(title: String, message: String) -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK").setAccessibilityIdentifier("git.prompt.ok")
        alert.window.setAccessibilityIdentifier("git.prompt.failure")
        return alert
    }

    /// The rebase editor in a titled window of its own, for a sheet.
    static func rebaseSheet(_ editor: GitRebaseEditorViewController) -> NSWindow {
        let sheet = NSWindow(contentViewController: editor)
        sheet.styleMask = [.titled, .resizable]
        sheet.title = "Interactive Rebase"
        sheet.isReleasedWhenClosed = false
        sheet.setContentSize(editor.preferredContentSize)
        sheet.setAccessibilityIdentifier("git.rebase.sheet")
        return sheet
    }

    /// A built text request: the alert, its fields in order, and what enables its action.
    struct TextPrompt {
        let alert: NSAlert
        let fields: [NSTextField]
        let enabler: NSObject
    }

    // MARK: Private

    /// Runs `alert` as a sheet on the window and returns how it ended; nil when there
    /// is no window to attach it to. The window closing first ends the sheet and
    /// answers `.cancel`.
    func present(_ alert: NSAlert, purpose: String) async -> NSApplication.ModalResponse? {
        let endSheet = endSheet
        let beginSheet = beginSheet
        return await present(
            purpose: purpose,
            begin: { window, handler in beginSheet(alert, window, handler) },
            end: { window in endSheet(alert, window) })
    }

    /// Runs a sheet `begin` starts on the window, handing it the handler that answers, and
    /// returns how it ended; nil when there is no window. The window closing first calls
    /// `end` and answers `.cancel`; whichever comes first answers, once.
    private func present(
        purpose: String,
        begin: @escaping @MainActor (NSWindow, @escaping (NSApplication.ModalResponse) -> Void) -> Void,
        end: @escaping @MainActor (NSWindow) -> Void
    ) async -> NSApplication.ModalResponse? {
        guard let window = window() else {
            Self.logger.error("Git \(purpose, privacy: .public) not shown: the Git window has no window")
            return nil
        }
        return await withCheckedContinuation { continuation in
            let completion = SheetCompletion(continuation, window: window, end: end)
            completion.observer = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification, object: window, queue: .main
            ) { _ in
                MainActor.assumeIsolated { completion.windowWillClose() }
            }
            begin(window) { response in completion.finish(response) }
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

/// Resumes a sheet's continuation exactly once, whichever comes first, the sheet ending
/// or its window closing, and stops watching the window then.
@MainActor
private final class SheetCompletion {
    private var continuation: CheckedContinuation<NSApplication.ModalResponse?, Never>?
    private weak var window: NSWindow?
    private let end: @MainActor (NSWindow) -> Void
    var observer: NSObjectProtocol?

    init(_ continuation: CheckedContinuation<NSApplication.ModalResponse?, Never>,
         window: NSWindow, end: @escaping @MainActor (NSWindow) -> Void) {
        self.continuation = continuation
        self.window = window
        self.end = end
    }

    /// Ends the sheet, then answers cancelled if ending it did not already answer.
    func windowWillClose() {
        if continuation != nil, let window { end(window) }
        finish(.cancel)
    }

    func finish(_ response: NSApplication.ModalResponse) {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        continuation?.resume(returning: response)
        continuation = nil
    }
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
