import Testing
import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// Conformance vectors mtpane-001 to mtpane-030 for the `text-pane` recipe, the
/// behaviors both platforms share. The platform-specific ones (theme, smart
/// substitutions, scrollers, find bar, insets, focus) follow below behind `#if`.
/// The pane keeps its text view private, so `PaneProbe` finds it in the view tree.
@MainActor
@Suite("MarkdownTextPane conformance")
struct MarkdownTextPaneConformanceTests {

    @Test("mtpane-001: editable: true creates a pane whose text view is editable")
    func editablePaneIsEditable() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).textView.isEditable)
    }

    @Test("mtpane-002: editable: false creates a pane whose text view is not editable")
    func readOnlyPaneIsNotEditable() {
        #expect(PaneProbe(MarkdownTextPane(editable: false)).textView.isEditable == false)
    }

    @Test("mtpane-003: setting isEditable = true on a read-only pane enables editing")
    func settingEditableEnablesEditing() {
        let pane = MarkdownTextPane(editable: false)
        pane.isEditable = true

        #expect(pane.isEditable)
        #expect(PaneProbe(pane).textView.isEditable)
    }

    @Test("mtpane-004: setting isEditable = false on an editable pane disables editing")
    func settingEditableFalseDisablesEditing() {
        let pane = MarkdownTextPane(editable: true)
        pane.isEditable = false

        #expect(pane.isEditable == false)
        #expect(PaneProbe(pane).textView.isEditable == false)
    }

    @Test("mtpane-005: a user edit fires onTextChange with the complete text")
    func userEditFiresOnTextChange() {
        let pane = MarkdownTextPane(editable: true)
        var received: String?
        pane.onTextChange = { received = $0 }

        PaneProbe(pane).typeAsUser("Hello")

        #expect(received == "Hello")
    }

    @Test("mtpane-006: setting text programmatically does not fire onTextChange")
    func programmaticTextDoesNotFire() {
        let pane = MarkdownTextPane(editable: true)
        var fired = false
        pane.onTextChange = { _ in fired = true }

        pane.text = "Programmatic"

        #expect(fired == false)
    }

    @Test("mtpane-007: text reads back exactly what was set")
    func textRoundTrips() {
        let pane = MarkdownTextPane(editable: true)
        pane.text = "Sample text"

        #expect(pane.text == "Sample text")
    }

    @Test("mtpane-008: a fresh pane reads back an empty string")
    func freshPaneTextIsEmpty() {
        #expect(MarkdownTextPane(editable: true).text == "")
    }

    @Test("mtpane-009: attributed text keeps its attributes when read back")
    func attributedTextKeepsAttributes() {
        let pane = MarkdownTextPane(editable: true)
        let styled = NSAttributedString(string: "Styled", attributes: [
            .font: PaneProbe.boldFont,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ])

        pane.setAttributedText(styled)

        let read = pane.attributedText
        #expect(read.string == "Styled")
        #expect(read.attribute(.font, at: 0, effectiveRange: nil) as? PaneProbe.Font == PaneProbe.boldFont)
        #expect(read.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int == 1)
    }

    @Test("mtpane-011: focus() on a pane with no window returns false")
    func focusWithoutWindowFails() {
        #expect(MarkdownTextPane(editable: true).focus() == false)
    }

    @Test("mtpane-017: the pane is plain text, with no rich-text editing")
    func paneIsPlainText() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).editsOnlyPlainText)
    }

    @Test("mtpane-029: a read-only pane stays selectable so its text can be copied")
    func readOnlyPaneIsSelectable() {
        #expect(PaneProbe(MarkdownTextPane(editable: false)).textView.isSelectable)
    }

    @Test("mtpane-021: the text container is inset 8pt on every edge")
    func textIsInsetEightPoints() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).insets == [8, 8, 8, 8])
    }
}

#if os(macOS)
@MainActor
@Suite("MarkdownTextPane conformance (AppKit)")
struct MarkdownTextPaneMacOSConformanceTests {

    private var palette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedDark) }

    @Test("mtpane-010: focus() on an onscreen pane returns true and focuses the text view")
    func focusOnscreenSucceeds() {
        let pane = MarkdownTextPane(editable: true)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = pane
        window.makeKeyAndOrderFront(nil)

        #expect(pane.focus())
        #expect(window.firstResponder === PaneProbe(pane).textView)
        window.close()
    }

    @Test("mtpane-012: applyTheme sets background, text, cursor, selection and code font")
    func applyThemeUpdatesTheTextView() {
        let pane = MarkdownTextPane(editable: true)
        pane.applyTheme(palette)

        let textView = PaneProbe(pane).textView
        #expect(textView.backgroundColor == palette.nsColor(.windowBackground))
        #expect(textView.textColor == palette.nsColor(.primaryText))
        #expect(textView.insertionPointColor == palette.nsColor(.cursor))
        #expect(textView.font == palette.font(.code))
        let selected = textView.selectedTextAttributes
        #expect(selected[.backgroundColor] as? NSColor == palette.nsColor(.selection))
        #expect(selected[.foregroundColor] as? NSColor == palette.nsColor(.selectionText))
    }

    @Test("mtpane-015: quote substitution is off")
    func quoteSubstitutionIsOff() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).textView.isAutomaticQuoteSubstitutionEnabled == false)
    }

    @Test("mtpane-024: dash substitution is off")
    func dashSubstitutionIsOff() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).textView.isAutomaticDashSubstitutionEnabled == false)
    }

    @Test("mtpane-025: automatic spelling correction is off")
    func spellingCorrectionIsOff() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).textView.isAutomaticSpellingCorrectionEnabled == false)
    }

    @Test("mtpane-026: automatic text replacement is off")
    func textReplacementIsOff() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).textView.isAutomaticTextReplacementEnabled == false)
    }

    @Test("mtpane-016: the text view supports undo")
    func textViewAllowsUndo() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).textView.allowsUndo)
    }

    @Test("mtpane-018: the scroll view scrolls vertically")
    func scrollViewScrollsVertically() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).scrollView.hasVerticalScroller)
    }

    @Test("mtpane-019: the scrollers auto-hide")
    func scrollersAutoHide() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).scrollView.autohidesScrollers)
    }

    @Test("mtpane-028: the scroll view draws no border")
    func scrollViewHasNoBorder() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).scrollView.borderType == .noBorder)
    }

    @Test("mtpane-022: the text view uses the native find bar")
    func textViewUsesTheFindBar() {
        let textView = PaneProbe(MarkdownTextPane(editable: true)).textView
        #expect(textView.usesFindBar)
        #expect(textView.isIncrementalSearchingEnabled)
    }
}
#else
@MainActor
@Suite("MarkdownTextPane conformance (UIKit)")
struct MarkdownTextPaneIOSConformanceTests {

    private var palette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedDark) }

    @Test("mtpane-010: focus() on an onscreen pane returns true",
          .disabled("Keyboard focus needs a key window and the keyboard focus engine, absent in a unit test"))
    func focusOnscreenSucceeds() {}

    @Test("mtpane-027: applyTheme sets background, text color, font, and tints with the cursor color")
    func applyThemeUpdatesTheTextView() {
        let pane = MarkdownTextPane(editable: true)
        pane.applyTheme(palette)

        let textView = PaneProbe(pane).textView
        #expect(textView.backgroundColor == palette.uiColor(.windowBackground))
        #expect(textView.textColor == palette.uiColor(.primaryText))
        #expect(textView.font == palette.font(.code))
        #expect(textView.tintColor == palette.uiColor(.cursor))
    }

    @Test("mtpane-013: smart quotes are off")
    func smartQuotesAreOff() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).textView.smartQuotesType == .no)
    }

    @Test("mtpane-014: smart dashes are off")
    func smartDashesAreOff() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).textView.smartDashesType == .no)
    }

    @Test("mtpane-030: autocorrection is off")
    func autocorrectionIsOff() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).textView.autocorrectionType == .no)
    }

    @Test("mtpane-018: the text view scrolls vertically")
    func textViewScrolls() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).textView.isScrollEnabled)
    }

    @Test("mtpane-020: the text view bounces vertically")
    func textViewBounces() {
        #expect(PaneProbe(MarkdownTextPane(editable: true)).textView.alwaysBounceVertical)
    }

    @Test("mtpane-023: the system undo manager is left in place",
          .disabled("Shake-to-undo and hardware Cmd+Z cannot be driven from a unit test"))
    func systemUndoIsPreserved() {}
}
#endif

/// Reaches into the pane's private text view through the view tree.
@MainActor
private struct PaneProbe {
    let pane: MarkdownTextPane

    init(_ pane: MarkdownTextPane) { self.pane = pane }

    #if os(macOS)
    typealias Font = NSFont

    static var boldFont: NSFont { NSFont.boldSystemFont(ofSize: 14) }

    var scrollView: NSScrollView { pane.subviews.compactMap { $0 as? NSScrollView }.first ?? NSScrollView() }

    var textView: NSTextView { scrollView.documentView as? NSTextView ?? NSTextView() }

    var editsOnlyPlainText: Bool { textView.isRichText == false }

    var insets: [CGFloat] {
        let size = textView.textContainerInset
        return [size.height, size.width, size.height, size.width]
    }

    func typeAsUser(_ text: String) {
        textView.insertText(text, replacementRange: NSRange(location: 0, length: 0))
    }
    #else
    typealias Font = UIFont

    static var boldFont: UIFont { UIFont.boldSystemFont(ofSize: 14) }

    var textView: UITextView { pane.subviews.compactMap { $0 as? UITextView }.first ?? UITextView() }

    var editsOnlyPlainText: Bool { textView.allowsEditingTextAttributes == false }

    var insets: [CGFloat] {
        let edges = textView.textContainerInset
        return [edges.top, edges.left, edges.bottom, edges.right]
    }

    func typeAsUser(_ text: String) {
        textView.insertText(text)
    }
    #endif
}
