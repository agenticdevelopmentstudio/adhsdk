import Testing
import UIKit
import Foundation
@testable import AgenticDeveloperHubSDKUI

/// The one genuinely platform-specific pane test: driving the real `UITextView`
/// so this exercises the pane's `delegate = self` wiring rather than only the
/// delegate method's body in isolation. `insertText(_:)` is `UIKeyInput`'s real
/// entry point — the same one UIKit calls for an actual keystroke. Everything
/// else about the pane is asserted once, for both platforms, in `TestsUI/Shared`.
@MainActor
@Suite("MarkdownTextPane input (UIKit)")
struct MarkdownTextPaneInputTests {

    @Test("a simulated user edit fires onTextChange with the new text")
    func userEditFiresOnTextChange() {
        let pane = MarkdownTextPane(editable: true)
        var received: String?
        pane.onTextChange = { received = $0 }

        let textView = pane.subviews.compactMap { $0 as? UITextView }.first
        textView?.insertText("typed")

        #expect(received == "typed")
    }
}
