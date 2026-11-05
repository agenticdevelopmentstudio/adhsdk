import Testing
import AppKit
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The one genuinely platform-specific pane test: driving the real `NSTextView`
/// so this exercises the pane's `delegate = self` wiring rather than only the
/// delegate method's body in isolation. Everything else about the pane is
/// asserted once, for both platforms, in `TestsUI/Shared`.
@MainActor
@Suite("MarkdownTextPane input (AppKit)")
struct MarkdownTextPaneInputTests {

    @Test("a simulated user edit fires onTextChange with the new text")
    func userEditFiresOnTextChange() {
        let pane = MarkdownTextPane(editable: true)
        var received: String?
        pane.onTextChange = { received = $0 }

        let textView = pane.subviews
            .compactMap { $0 as? NSScrollView }
            .first?.documentView as? NSTextView
        textView?.insertText("typed", replacementRange: NSRange(location: 0, length: 0))

        #expect(received == "typed")
    }

    @Test("the pane's text view has the native find bar enabled")
    func textViewEnablesTheFindBar() {
        let pane = MarkdownTextPane(editable: true)

        let textView = pane.subviews
            .compactMap { $0 as? NSScrollView }
            .first?.documentView as? NSTextView

        #expect(textView?.usesFindBar == true)
        #expect(textView?.isIncrementalSearchingEnabled == true)
    }

    @Test("focusing the editor puts the caret in a text view, not a container")
    func focusEditorReachesTheTextView() {
        let controller = MarkdownEditorController(palette: SemanticPalette(theme: BuiltInThemes.solarizedDark))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled], backing: .buffered, defer: false)
        window.contentViewController = controller
        window.makeKeyAndOrderFront(nil)
        window.contentView?.layoutSubtreeIfNeeded()

        controller.focusEditor()

        #expect(window.firstResponder is NSTextView)
    }
}
