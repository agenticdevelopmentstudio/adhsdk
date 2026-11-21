import AppKit
import Testing
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The secret row: dots, copy, the eye, and every way a shown secret is
/// hidden again (secure-text-edit-view vectors 008–017).
@Suite(.serialized)
@MainActor
struct SecureTextEditViewTests {

    /// A row over an in-memory value, with a private pasteboard.
    private final class Harness {
        var stored: String
        let model: ComposableSettings.ViewModel<String>
        let row: ComposableSettings.SecureTextEditView
        let pasteboard = NSPasteboard(name: .init("SecureTextEditViewTests-\(UUID().uuidString)"))

        @MainActor
        init(_ value: String) {
            stored = value
            var box: Harness?
            model = ComposableSettings.ViewModel<String>(
                title: "API Key", get: { box?.stored ?? value }, set: { box?.stored = $0 })
            row = ComposableSettings.SecureTextEditView(with: model)
            row.pasteboard = pasteboard
            box = self
        }

        deinit { pasteboard.releaseGlobally() }
    }

    /// Lets the observer's change report run: a write through the view
    /// model reaches the row on the next main-queue turn, never in the write.
    private func drainMainQueue() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    private func host(_ view: NSView) -> NSWindow {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 80),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        return window
    }

    // MARK: - Showing

    @Test func aStoredSecretShowsAsDots() {
        let harness = Harness("sk-123")
        #expect(harness.row.textField is NSSecureTextField)
        #expect(harness.row.textField.stringValue == "sk-123")
        #expect(!harness.row.textField.isHidden)
        #expect(harness.row.revealField.isHidden)
        #expect(!harness.row.isRevealed)
    }

    @Test func theEyeTogglesPlainTextAndItsIconTracksTheState() {
        let harness = Harness("sk-123")
        #expect(harness.row.revealButton.accessibilityLabel() == "Show")

        harness.row.revealButton.performClick(nil)

        #expect(harness.row.isRevealed)
        #expect(!harness.row.revealField.isHidden)
        #expect(harness.row.textField.isHidden)
        #expect(harness.row.revealField.stringValue == "sk-123")
        #expect(harness.row.revealButton.accessibilityLabel() == "Hide")

        harness.row.revealButton.performClick(nil)

        #expect(!harness.row.isRevealed)
        #expect(harness.row.revealButton.accessibilityLabel() == "Show")
    }

    @Test func revealingKeepsAnUncommittedEditAndTheFocus() {
        let harness = Harness("sk-123")
        let window = host(harness.row)
        #expect(window.makeFirstResponder(harness.row.textField))
        harness.row.textField.stringValue = "sk-1234"

        harness.row.setRevealed(true)

        #expect(harness.row.revealField.stringValue == "sk-1234")
        #expect(harness.row.revealField.currentEditor() != nil, "the shown field takes the focus")
    }

    @Test func anEmptyValueStillToggles() {
        let harness = Harness("")
        harness.row.revealButton.performClick(nil)
        #expect(harness.row.isRevealed)
    }

    @Test func twoRowsHaveTheirOwnShownState() {
        let first = Harness("a")
        let second = Harness("b")
        first.row.setRevealed(true)
        #expect(first.row.isRevealed)
        #expect(!second.row.isRevealed)
    }

    // MARK: - Copy

    @Test func copyPutsThePlainSecretOnThePasteboardInEitherState() {
        let harness = Harness("sk-123")
        harness.row.copyButton.performClick(nil)
        #expect(harness.pasteboard.string(forType: .string) == "sk-123")

        harness.pasteboard.clearContents()
        harness.row.setRevealed(true)
        harness.row.copyButton.performClick(nil)
        #expect(harness.pasteboard.string(forType: .string) == "sk-123")
    }

    @Test func copyIsDisabledWhileTheFieldIsEmpty() {
        let harness = Harness("")
        #expect(!harness.row.copyButton.isEnabled)
        harness.model.settingObserver.value = "sk-1"
        drainMainQueue()
        #expect(harness.row.copyButton.isEnabled)
    }

    @Test func theButtonsAreLabelledForAccessibility() {
        let harness = Harness("sk-123")
        #expect(harness.row.copyButton.accessibilityLabel() == "Copy")
        #expect(harness.row.textField.nextKeyView === harness.row.copyButton)
        #expect(harness.row.copyButton.nextKeyView === harness.row.revealButton)
    }

    /// secure-text-edit-view-024: both fields, obscured and shown, are titled
    /// by the row's label.
    @Test func bothFieldsAreTitledByTheLabel() {
        let harness = Harness("sk-123")
        #expect(harness.row.textField.accessibilityTitleUIElement() as AnyObject? === harness.row.label)
        #expect(harness.row.revealField.accessibilityTitleUIElement() as AnyObject? === harness.row.label)
    }

    // MARK: - Hiding again

    @Test func theWindowResigningKeyHidesTheSecret() {
        let harness = Harness("sk-123")
        let window = host(harness.row)
        harness.row.setRevealed(true)

        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)

        #expect(!harness.row.isRevealed)
    }

    @Test func anotherWindowResigningKeyLeavesItShown() {
        let harness = Harness("sk-123")
        _ = host(harness.row)
        let other = host(NSView())
        harness.row.setRevealed(true)

        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: other)

        #expect(harness.row.isRevealed)
    }

    @Test func theAppResigningActiveHidesTheSecret() {
        let harness = Harness("sk-123")
        harness.row.setRevealed(true)

        NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: NSApp)

        #expect(!harness.row.isRevealed)
    }

    @Test func leavingTheWindowHidesTheSecret() {
        let harness = Harness("sk-123")
        let window = host(harness.row)
        harness.row.setRevealed(true)

        window.contentView = NSView()

        #expect(!harness.row.isRevealed)
    }

    @Test func anOutsideChangeHidesTheSecretBeforeShowingTheNewValue() {
        let harness = Harness("sk-123")
        harness.row.setRevealed(true)

        harness.model.settingObserver.value = "sk-999"
        drainMainQueue()

        #expect(!harness.row.isRevealed)
        #expect(harness.row.textField.stringValue == "sk-999")
    }

    @Test func aRefreshToADifferentValueHidesTheSecret() {
        let harness = Harness("sk-123")
        harness.row.setRevealed(true)
        harness.stored = "sk-999"

        harness.model.revert()

        #expect(!harness.row.isRevealed)
        #expect(harness.row.textField.stringValue == "sk-999")
    }

    // MARK: - Committing

    @Test func anEditCommitsWhileShownAndStaysShown() {
        let harness = Harness("sk-123")
        harness.row.setRevealed(true)
        harness.row.revealField.stringValue = "sk-456"

        harness.row.textFieldChanged(harness.row.revealField)

        #expect(harness.stored == "sk-456")
        #expect(harness.row.isRevealed, "the row's own commit is not an outside change")
    }

    @Test func anEditCommitsWhileHidden() {
        let harness = Harness("sk-123")
        harness.row.textField.stringValue = "sk-789"

        harness.row.textFieldChanged(harness.row.textField)

        #expect(harness.stored == "sk-789")
    }

    @Test func theShownStateIsNotStored() {
        let harness = Harness("sk-123")
        harness.row.setRevealed(true)
        let again = ComposableSettings.SecureTextEditView(with: harness.model)
        #expect(!again.isRevealed, "a new row over the same setting starts hidden")
    }
}
