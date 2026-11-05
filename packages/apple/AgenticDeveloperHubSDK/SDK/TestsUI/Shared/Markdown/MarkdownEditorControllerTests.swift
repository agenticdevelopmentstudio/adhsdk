import Testing
import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// AppKit and UIKit name the same "lay out now" hook differently and neither
/// declares the other's. That one call is the only thing about these tests that
/// is platform-specific, so it is the only thing behind an `#if` — the suite
/// itself is compiled into both test bundles from this one file.
@MainActor
func layoutNow(_ view: PlatformView) {
    #if os(macOS)
    view.layoutSubtreeIfNeeded()
    #else
    view.layoutIfNeeded()
    #endif
}

@MainActor
@Suite("MarkdownEditorController")
struct MarkdownEditorControllerTests {

    private var palette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedDark) }

    private func loadedEditor(_ content: String = "") -> MarkdownEditorController {
        let editor = MarkdownEditorController(palette: palette)
        editor.content = content
        editor.view.frame = CGRect(x: 0, y: 0, width: 900, height: 600)
        _ = editor.view
        return editor
    }

    @Test("the editor pane shows the document source, frontmatter and all")
    func editorShowsSource() {
        let editor = loadedEditor("---\ntitle: x\n---\n# Body\n")
        #expect(editor.editorPane.text == "---\ntitle: x\n---\n# Body\n")
    }

    @Test("the preview shows the rendered document, without the frontmatter")
    func previewShowsRendered() {
        let editor = loadedEditor("---\ntitle: x\n---\n# Body\n")
        editor.flushPendingRender()
        #expect(editor.viewer.pane.text == "Body")
    }

    @Test("typing reports the new content to the host")
    func typingReportsContent() {
        let editor = loadedEditor("a")
        var reported: [String] = []
        editor.onContentChange = { reported.append($0) }
        editor.editorPane.text = "ab"
        editor.editorPane.onTextChange?("ab")
        #expect(reported == ["ab"])
        #expect(editor.content == "ab")
    }

    @Test("an edit that leaves the text identical is not a change")
    func noOpEditIsNotAChange() {
        let editor = loadedEditor("a")
        editor.flushPendingRender()
        let countBefore = editor.renderCount
        var reported: [String] = []
        editor.onContentChange = { reported.append($0) }

        editor.editorPane.onTextChange?("a")

        #expect(reported.isEmpty)
        editor.flushPendingRender()
        // One render for the explicit flush, and none scheduled by the no-op.
        #expect(editor.renderCount == countBefore + 1)
    }

    @Test("setting content programmatically does not echo back as an edit")
    func programmaticSetDoesNotEcho() {
        let editor = loadedEditor("a")
        var reported: [String] = []
        editor.onContentChange = { reported.append($0) }
        editor.content = "b"
        #expect(reported.isEmpty)
        #expect(editor.editorPane.text == "b")
    }

    @Test("the preview lags behind typing until the debounce is flushed")
    func previewIsDebounced() {
        let editor = loadedEditor("# One")
        editor.flushPendingRender()
        editor.editorPane.onTextChange?("# Two")
        #expect(editor.viewer.pane.text == "One")   // not yet
        editor.flushPendingRender()
        #expect(editor.viewer.pane.text == "Two")
    }

    @Test("a wide editor shows source and preview side by side")
    func wideEditorSplits() {
        let editor = loadedEditor("# Hi")
        editor.view.frame = CGRect(x: 0, y: 0, width: 900, height: 600)
        layoutNow(editor.view)
        #expect(editor.mode == .split)
        #expect(editor.editorPane.superview != nil)
        #expect(editor.viewer.view.superview != nil)
    }

    @Test("a narrow editor falls back to one pane at a time")
    func narrowEditorTabs() {
        // The wide layout has to happen FIRST, or nothing narrows: loading the
        // view runs a layout pass at zero width, so the editor is already in
        // the two-mode set before the test body starts, and resizing to 500
        // then hits `applyLayoutForCurrentSize`'s "nothing changed" guard. The
        // assertions held, but they held before the resize — the transition
        // this test is named for was never exercised.
        let editor = loadedEditor("# Hi")
        editor.view.frame = CGRect(x: 0, y: 0, width: 900, height: 600)
        layoutNow(editor.view)
        #expect(editor.availableModes.contains(.split))
        #expect(editor.mode == .split)

        editor.view.frame = CGRect(x: 0, y: 0, width: 500, height: 600)
        layoutNow(editor.view)
        #expect(editor.availableModes == [.edit, .preview])
        #expect(editor.mode == .edit)
        #expect(editor.viewer.view.superview == nil)
    }

    @Test("an edit-only editor never offers a preview, however wide it is")
    func previewCanBeDisabled() {
        let editor = MarkdownEditorController(palette: palette)
        editor.isPreviewAvailable = false
        editor.view.frame = CGRect(x: 0, y: 0, width: 1200, height: 600)
        layoutNow(editor.view)
        #expect(editor.mode == .edit)
        #expect(editor.availableModes == [.edit])
    }

    @Test("setting a mode the current layout doesn't offer does not stick")
    func modeSetterClampsToAvailableModes() {
        let editor = MarkdownEditorController(palette: palette)
        editor.isPreviewAvailable = false
        editor.view.frame = CGRect(x: 0, y: 0, width: 1200, height: 600)
        layoutNow(editor.view)
        #expect(editor.availableModes == [.edit])

        editor.mode = .split
        #expect(editor.mode == .edit)
        #expect(editor.viewer.view.superview == nil)
    }

    @Test("cancelling a pending render means it never fires, not just that flushing is idempotent")
    func previewDebounceIsActuallyCancelled() async throws {
        let editor = loadedEditor("# One")
        editor.flushPendingRender()
        let countAfterFirstFlush = editor.renderCount

        // Schedules a debounced render ~0.3s out, then flushes it early —
        // this should both render now and cancel that pending work item.
        editor.editorPane.onTextChange?("# Two")
        editor.flushPendingRender()
        let countAfterSecondFlush = editor.renderCount
        #expect(countAfterSecondFlush == countAfterFirstFlush + 1)

        // If the original debounced work item had merely been left to fire
        // later rather than actually cancelled, it would still land around
        // now and bump the count again — even though it would render the
        // same (already-current) text, which is why a text comparison alone
        // can't tell the two cases apart.
        try await Task.sleep(nanoseconds: UInt64((MarkdownEditorController.renderDebounce + 0.2) * 1_000_000_000))
        #expect(editor.renderCount == countAfterSecondFlush)
    }

    @Test("the syntax reference covers the syntax the editor claims to support")
    func syntaxReferenceIsComplete() {
        let syntaxes = Set(MarkdownSyntaxReference.rows.map(\.syntax))
        for expected in ["# Heading", "**bold**", "- item", "1. item", "> quote", "`code`",
                         "```lang", "[text](url)", #"\| a \| b \|"#, "---", "- [ ] task"] {
            #expect(syntaxes.contains(expected), "missing reference row for \(expected)")
        }
    }

    @Test("every syntax reference row renders as one two-cell table row")
    func syntaxReferenceRendersAsATable() {
        // The sheet is rendered by the code it documents, so the assertion has
        // to be against the *rendered* string: comparing the row list to the
        // markdown it was generated from is the same constant twice, and it is
        // exactly why an unescaped `|` in the table row shipped — under GFM a
        // pipe splits a cell even inside a code span, exploding that row into
        // seven cells of a two-column table.
        let palette = SemanticPalette(theme: BuiltInThemes.solarizedDark)
        let rendered = MarkdownDocumentRenderer()
            .render(MarkdownSyntaxReference.markdown,
                    palette: palette,
                    textColor: palette.platformColor(.primaryText))
            .string

        let tableLines = rendered
            .split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline })
            .filter { $0.contains("\t") }
        // The header row plus one row per entry, each with exactly one tab
        // between its two cells.
        #expect(tableLines.count == MarkdownSyntaxReference.rows.count + 1)
        for line in tableLines {
            #expect(line.filter { $0 == "\t" }.count == 1, "row split into extra cells: \(line)")
        }

        #expect(rendered.contains("Syntax\tMeans"))
        for row in MarkdownSyntaxReference.rows {
            // The escapes are markdown, not content: the reader sees the pipes.
            let syntax = row.syntax.replacingOccurrences(of: #"\"#, with: "")
            let meaning = row.meaning.replacingOccurrences(of: #"\"#, with: "")
            #expect(rendered.contains("\(syntax)\t\(meaning)"),
                    "reference row missing or mangled in the rendered sheet: \(syntax)")
        }
    }

    @Test("the help and import buttons are shown by default")
    func helpAndImportButtonsAreShownByDefault() {
        let editor = MarkdownEditorController(palette: palette)
        #expect(editor.showsHelpButton)
        #expect(editor.showsImportButton)
    }

    @Test("hiding the help and import buttons survives view loading")
    func hidingTheHelpAndImportButtonsSurvivesViewLoading() {
        let editor = MarkdownEditorController(palette: palette)
        editor.showsHelpButton = false
        editor.showsImportButton = false
        editor.loadViewIfNeeded()
        #expect(!editor.showsHelpButton)
        #expect(!editor.showsImportButton)
    }
}
