import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// `GitAlertPresenter` (recipe `workspace/git/git-window`, "Asking the user"): the
/// alerts it builds, its answer with no window, and a sheet whose window closes first.
/// No sheet is ever shown: beginning and ending one are fakes.
@Suite("GitAlertPresenter", .serialized)
@MainActor
struct GitAlertPresenterTests {

    /// Records the sheets begun and ended, and keeps each one's handler for the test to call.
    private final class FakeSheets {
        var begun: [NSAlert] = []
        var ended: [NSAlert] = []
        var handlers: [(NSApplication.ModalResponse) -> Void] = []
        var windowsBegun: [NSWindow] = []
        var windowsEnded: [NSWindow] = []
    }

    private static func presenter(window: NSWindow?, sheets: FakeSheets) -> GitAlertPresenter {
        GitAlertPresenter(
            window: { window },
            beginSheet: { alert, _, handler in
                sheets.begun.append(alert)
                sheets.handlers.append(handler)
            },
            endSheet: { alert, _ in sheets.ended.append(alert) },
            beginWindowSheet: { sheet, _, handler in
                sheets.windowsBegun.append(sheet)
                sheets.handlers.append(handler)
            },
            endWindowSheet: { sheet, _ in sheets.windowsEnded.append(sheet) })
    }

    private static func rebasePlan() -> GitRebasePlan {
        GitRebasePlan(onto: String(repeating: "b", count: 40), entries: [
            GitRebaseEntry(commit: String(repeating: "1", count: 40), subject: "one"),
            GitRebaseEntry(commit: String(repeating: "2", count: 40), subject: "two")
        ])
    }

    private static func window() -> NSWindow {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
                              styleMask: [.titled, .closable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        return window
    }

    /// Lets a task started by the test run up to its first suspension.
    private static func settle(until condition: () -> Bool) async {
        for _ in 0..<100 where !condition() { await Task.yield() }
    }

    @Test("with no window it answers no and nil and begins nothing")
    func noWindow() async {
        let sheets = FakeSheets()
        let presenter = Self.presenter(window: nil, sheets: sheets)
        let confirmed = await presenter.confirm(
            GitConfirmation(title: "T", message: "M", actionTitle: "Go", isDestructive: false))
        let text = await presenter.askForText(GitTextRequest(
            title: "T", message: "", fields: [GitTextField(label: "Name", initial: "x", isOptional: false)],
            actionTitle: "Go"))
        presenter.showFailure(title: "Push failed", message: "No.")
        await Task.yield()
        #expect(confirmed == false)
        #expect(text == nil)
        #expect(sheets.begun.isEmpty)
    }

    @Test("a confirmation puts the action first and Cancel second, destructive when asked")
    func confirmationAlert() {
        let destructive = GitAlertPresenter.confirmationAlert(GitConfirmation(
            title: "Reset main?", message: "Lost.", actionTitle: "Reset", isDestructive: true))
        #expect(destructive.messageText == "Reset main?")
        #expect(destructive.informativeText == "Lost.")
        #expect(destructive.buttons.map(\.title) == ["Reset", "Cancel"])
        #expect(destructive.buttons[0].hasDestructiveAction)
        #expect(destructive.buttons[0].accessibilityIdentifier() == "git.prompt.action")
        #expect(destructive.buttons[1].accessibilityIdentifier() == "git.prompt.cancel")
        #expect(destructive.alertStyle == .critical)

        let plain = GitAlertPresenter.confirmationAlert(GitConfirmation(
            title: "Delete?", message: "", actionTitle: "Delete", isDestructive: false))
        #expect(!plain.buttons[0].hasDestructiveAction)
        #expect(plain.alertStyle == .warning)
    }

    @Test("a text request has one field per request field, prefilled, with no placeholder")
    func textAlert() {
        let prompt = GitAlertPresenter.textAlert(GitTextRequest(
            title: "New Tag", message: "At abc",
            fields: [GitTextField(label: "Name", initial: "v1", isOptional: false),
                     GitTextField(label: "Message", initial: "", isOptional: true)],
            actionTitle: "Create Tag"))
        #expect(prompt.alert.messageText == "New Tag")
        #expect(prompt.alert.buttons.map(\.title) == ["Create Tag", "Cancel"])
        #expect(prompt.fields.map(\.stringValue) == ["v1", ""])
        #expect(prompt.fields.allSatisfy { $0.placeholderString == nil })
        #expect(prompt.fields.map { $0.accessibilityIdentifier() } == ["git.prompt.field.0", "git.prompt.field.1"])
        #expect(prompt.fields.map { $0.accessibilityLabel() } == ["Name", "Message"])
        #expect(prompt.alert.buttons[0].isEnabled)
        #expect(prompt.alert.window.initialFirstResponder === prompt.fields[0])
    }

    @Test("a required field left empty keeps the action disabled")
    func emptyRequiredFieldDisables() {
        let prompt = GitAlertPresenter.textAlert(GitTextRequest(
            title: "New Branch", message: "",
            fields: [GitTextField(label: "Name", initial: "", isOptional: false)], actionTitle: "Create Branch"))
        #expect(!prompt.alert.buttons[0].isEnabled)
    }

    @Test("a failure is one OK button")
    func failureAlert() {
        let alert = GitAlertPresenter.failureAlert(title: "Push failed", message: "No remote.")
        #expect(alert.messageText == "Push failed")
        #expect(alert.informativeText == "No remote.")
        #expect(alert.buttons.map(\.title) == ["OK"])
        #expect(alert.buttons[0].accessibilityIdentifier() == "git.prompt.ok")
    }

    @Test("a sheet's answer resumes the caller: the first button confirms")
    func sheetAnswers() async {
        let sheets = FakeSheets()
        let window = Self.window()
        let presenter = Self.presenter(window: window, sheets: sheets)
        let answer = Task {
            await presenter.confirm(GitConfirmation(title: "T", message: "", actionTitle: "Go", isDestructive: false))
        }
        await Self.settle { !sheets.handlers.isEmpty }
        sheets.handlers.first?(.alertFirstButtonReturn)
        #expect(await answer.value == true)

        NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: window)
        #expect(sheets.ended.isEmpty)
    }

    @Test("a window closing under a sheet ends it and answers cancelled, once")
    func windowClosingResumes() async {
        let sheets = FakeSheets()
        let window = Self.window()
        let presenter = Self.presenter(window: window, sheets: sheets)
        let answer = Task {
            await presenter.askForText(GitTextRequest(
                title: "T", message: "", fields: [GitTextField(label: "Name", initial: "x", isOptional: false)],
                actionTitle: "Go"))
        }
        await Self.settle { !sheets.handlers.isEmpty }
        #expect(sheets.begun.count == 1)

        NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: window)
        #expect(await answer.value == nil)
        #expect(sheets.ended.count == 1)
        #expect(sheets.ended.first === sheets.begun.first)

        // The sheet's own handler arriving late changes nothing.
        sheets.handlers.first?(.alertFirstButtonReturn)
        NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: window)
        #expect(sheets.ended.count == 1)
    }

    @Test("the rebase editor is a sheet; Start Rebase answers the edited plan and ends it")
    func rebaseEditorStarts() async throws {
        let sheets = FakeSheets()
        let window = Self.window()
        let presenter = Self.presenter(window: window, sheets: sheets)
        let answer = Task { await presenter.editRebase(Self.rebasePlan()) }
        await Self.settle { !sheets.windowsBegun.isEmpty }
        let sheet = try #require(sheets.windowsBegun.first)
        #expect(sheet.title == "Interactive Rebase")
        #expect(sheet.accessibilityIdentifier() == "git.rebase.sheet")
        let editor = try #require(sheet.contentViewController as? GitRebaseEditorViewController)
        editor.moveEntry(from: 1, to: 0)
        editor.startButton.performClick(nil)
        let edited = await answer.value
        #expect(edited?.entries.map(\.subject) == ["two", "one"])
        #expect(sheets.windowsEnded.count == 1)
        #expect(sheets.windowsEnded.first === sheet)
    }

    @Test("Cancel in the rebase editor answers nil")
    func rebaseEditorCancels() async throws {
        let sheets = FakeSheets()
        let window = Self.window()
        let presenter = Self.presenter(window: window, sheets: sheets)
        let answer = Task { await presenter.editRebase(Self.rebasePlan()) }
        await Self.settle { !sheets.windowsBegun.isEmpty }
        let editor = try #require(sheets.windowsBegun.first?.contentViewController as? GitRebaseEditorViewController)
        editor.cancelButton.performClick(nil)
        #expect(await answer.value == nil)
        #expect(sheets.windowsEnded.count == 1)
    }

    @Test("a window closing under the rebase editor ends its sheet and answers nil, once")
    func rebaseEditorWindowCloses() async throws {
        let sheets = FakeSheets()
        let window = Self.window()
        let presenter = Self.presenter(window: window, sheets: sheets)
        let answer = Task { await presenter.editRebase(Self.rebasePlan()) }
        await Self.settle { !sheets.windowsBegun.isEmpty }
        let editor = try #require(sheets.windowsBegun.first?.contentViewController as? GitRebaseEditorViewController)

        NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: window)
        #expect(await answer.value == nil)
        #expect(sheets.windowsEnded.count == 1)
        #expect(editor.onFinish == nil, "closing breaks the editor's hold on its sheet")

        editor.startButton.performClick(nil)
        #expect(sheets.windowsEnded.count == 1)
    }
}
