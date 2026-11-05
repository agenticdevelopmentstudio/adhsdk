import Testing
import AppKit
@testable import AgenticDeveloperHubSDKUI

/// The helper every view in this framework tags itself with. It answers here,
/// from the chrome tier, so a chrome view does not have to reach up into a
/// framework above it to be addressable by a UI test.
@MainActor
@Suite("AccessibilityID")
struct AccessibilityIDTests {

    @Test("tagging a view sets the identifier AppKit exposes")
    func viewIsTagged() {
        let view = NSView()
        view.accessibilityID("pane.close")
        #expect(view.accessibilityIdentifier() == "pane.close")
    }

    /// The return value is what makes `let label = ThemedLabel(…).accessibilityID(…)`
    /// read as one statement, and it has to be `Self` rather than `NSView` or
    /// the assignment loses the concrete type.
    @Test("tagging returns the same object, at its own type")
    func taggingIsChainable() {
        let button = NSButton()
        let returned: NSButton = button.accessibilityID("pane.zoom")
        #expect(returned === button)
    }

    @Test("menu items and windows tag the same way")
    func menuItemsAndWindowsAreTaggable() {
        let item = NSMenuItem()
        item.accessibilityID("whippet.menu.file.open-project")
        #expect(item.accessibilityIdentifier() == "whippet.menu.file.open-project")

        let window = NSWindow()
        window.accessibilityID("project-chooser.window")
        #expect(window.accessibilityIdentifier() == "project-chooser.window")
    }

    @Test("slug splits on whitespace, punctuation and camelCase")
    func slugSplitsOnEveryBoundary() {
        #expect(AccessibilityID.slug("aiChat") == "ai-chat")
        #expect(AccessibilityID.slug("Session Window") == "session-window")
        #expect(AccessibilityID.slug("Quick Note!") == "quick-note")
    }
}
