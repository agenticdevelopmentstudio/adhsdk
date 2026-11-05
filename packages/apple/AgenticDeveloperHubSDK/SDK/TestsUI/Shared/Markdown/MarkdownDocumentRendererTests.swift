import Testing
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

@MainActor
@Suite("MarkdownDocumentRenderer")
struct MarkdownDocumentRendererTests {

    private var palette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedDark) }

    private func render(_ text: String) -> NSAttributedString {
        MarkdownDocumentRenderer()
            .render(text, palette: palette, textColor: palette.platformColor(.primaryText))
    }

    @Test("frontmatter is a header, not content, so it is not rendered")
    func frontmatterIsDropped() {
        #expect(render("---\ntitle: Hi\npinned: true\n---\n# Body\n").string == "Body")
    }

    @Test("a document with no frontmatter renders whole")
    func noFrontmatterRendersWhole() {
        #expect(render("# Body\n").string == "Body")
    }

    @Test("an alert callout is labelled and colored by its kind")
    func alertIsLabelled() {
        let rendered = render("> [!WARNING]\n> mind the gap")
        #expect(rendered.string == "WARNING\nmind the gap")
        #expect(rendered.attributes(at: 0, effectiveRange: nil)[.foregroundColor] as? PlatformColor
                == palette.platformColor(.warning))
    }

    @Test("every alert kind maps to a distinct role")
    func alertKindsMapToRoles() {
        #expect(MarkdownAlert.note.role == .info)
        #expect(MarkdownAlert.tip.role == .success)
        #expect(MarkdownAlert.important.role == .accent)
        #expect(MarkdownAlert.warning.role == .warning)
        #expect(MarkdownAlert.caution.role == .danger)
    }

    @Test("an unrecognised bracket tag stays an ordinary quote")
    func unknownTagIsNotAnAlert() {
        #expect(render("> [!SHOUT]\n> hello").string == "[!SHOUT]\nhello")
    }

    @Test("a task list renders checkboxes rather than brackets")
    func taskListUsesCheckboxes() {
        #expect(render("- [ ] todo\n- [x] done").string == "☐\ttodo\n☑\tdone")
    }

    @Test("an ordinary list is untouched by the task-list rewrite")
    func ordinaryListIsUnchanged() {
        #expect(render("- plain").string == "•\tplain")
    }

    @Test("a checkbox inside a fenced block stays literal text")
    func fencedContentIsNotRewritten() {
        #expect(render("```\n- [ ] literal\n```").string.contains("- [ ] literal"))
    }

    @Test("a tilde fence protects its contents exactly as a backtick fence does")
    func tildeFencedContentIsNotRewritten() {
        #expect(render("~~~\n- [ ] literal\n~~~").string.contains("- [ ] literal"))
        // The renderer no longer republishes this: it classifies the source
        // directly, so the scanner is asserted where it lives.
        #expect(FenceScanner.fencedBlockContents(in: "~~~\n- [ ] literal\n~~~")
                == ["- [ ] literal"])
    }

    @Test("a fence marker inside a block of the other marker is content, not a close")
    func mixedFenceMarkersDoNotCloseEachOther() {
        let document = "```\n~~~\n- [ ] literal\n```\n\n- [ ] real"
        #expect(FenceScanner.fencedBlockContents(in: document) == ["~~~\n- [ ] literal"])
        let rendered = render(document).string
        #expect(rendered.contains("- [ ] literal"))   // inside the block: untouched
        #expect(rendered.contains("☐"))               // outside it: a real checkbox
    }

    @Test("an alert tag documented inside a fenced block is not recoloured, but a real alert elsewhere still is")
    func alertSyntaxInsideFenceIsNotRecolored() {
        let document = """
        Here is how to write an alert:

        ```
        > [!NOTE]
        > Example only.
        ```

        > [!NOTE]
        > Real alert.
        """
        let rendered = render(document)
        #expect(rendered.string.contains("> [!NOTE]\n> Example only."))
        #expect(rendered.string.contains("NOTE\nReal alert."))

        let realAlertRange = (rendered.string as NSString).range(of: "NOTE\nReal alert.")
        #expect(realAlertRange.location != NSNotFound)
        let realAlertColor = rendered.attributes(at: realAlertRange.location,
                                               effectiveRange: nil)[.foregroundColor]
        #expect(realAlertColor as? PlatformColor == palette.platformColor(.info))
    }

    @Test("a CRLF-authored document renders identically to its LF twin")
    func crlfDocumentMatchesLFTwin() {
        let lineFeed = "> [!WARNING]\n> mind the gap\n\n- [ ] todo\n- [x] done"
        let crlf = "> [!WARNING]\r\n> mind the gap\r\n\r\n- [ ] todo\r\n- [x] done"
        #expect(render(crlf).string == render(lineFeed).string)
    }

    @Test("a quote line already ending in a backslash hard break is not corrupted")
    func backslashHardBreakIsPreserved() {
        let rendered = render("> line one\\\n> line two")
        #expect(rendered.string == "line one\nline two")
        #expect(!rendered.string.contains("\\"))
    }

    @Test("a nested task list item also renders a checkbox")
    func nestedTaskListUsesCheckboxes() {
        #expect(render("- [ ] todo\n  - [ ] nested").string.contains("☐\tnested"))
    }

    // MARK: - Alerts detected on the source

    /// The colour of the run at the first occurrence of `text`, or `nil` when
    /// the text is not there at all.
    private func color(at text: String, in rendered: NSAttributedString) -> PlatformColor? {
        let found = (rendered.string as NSString).range(of: text)
        guard found.location != NSNotFound else { return nil }
        return rendered.attributes(at: found.location, effectiveRange: nil)[.foregroundColor] as? PlatformColor
    }

    @Test("a bare [!NOTE] inside a fence does not suppress the real alert after it")
    func bareTagInFenceDoesNotSuppressLaterAlert() {
        // The fenced text is `[!NOTE]` with no `> ` prefix, so it is textually
        // identical to the real alert's tag: the old pass excluded BOTH.
        let rendered = render("```\n[!NOTE]\n```\n\n> [!NOTE]\n> Real.")
        #expect(rendered.string.contains("[!NOTE]"))        // the fenced one, literal
        #expect(rendered.string.contains("NOTE\nReal."))    // the real one, relabelled
        #expect(color(at: "NOTE\nReal.", in: rendered) == palette.platformColor(.info))
        #expect(color(at: "[!NOTE]", in: rendered) != palette.platformColor(.info))
    }

    @Test("the same document with the fence after the alert behaves identically")
    func bareTagInFenceAfterTheAlert() {
        // Ordering was never a fix: with the fence second, the old pass
        // suppressed the alert at offset 0 instead.
        let rendered = render("> [!NOTE]\n> Real.\n\n```\n[!NOTE]\n```")
        #expect(rendered.string.contains("NOTE\nReal."))
        #expect(rendered.string.contains("[!NOTE]"))
        #expect(color(at: "NOTE\nReal.", in: rendered) == palette.platformColor(.info))
        #expect(color(at: "[!NOTE]", in: rendered) != palette.platformColor(.info))
    }

    @Test("two real alerts with a fenced block between them are both relabelled")
    func twoAlertsAcrossAFence() {
        let rendered = render("> [!NOTE]\n> First.\n\n```\ncode\n```\n\n> [!WARNING]\n> Second.")
        #expect(rendered.string.contains("NOTE\nFirst."))
        #expect(rendered.string.contains("WARNING\nSecond."))
        #expect(color(at: "NOTE\nFirst.", in: rendered) == palette.platformColor(.info))
        #expect(color(at: "WARNING\nSecond.", in: rendered) == palette.platformColor(.warning))
    }

    @Test("five preceding alerts do not push a fenced tag out of its exclusion")
    func fencedTagSurvivesManyPrecedingAlerts() {
        // Each rewrite used to shorten the string by three units without
        // re-deriving the exclusion snapshot; five of them drifted it by 15 and
        // the fenced `[!WARNING]` was recoloured as a real alert.
        let alerts = (1...5).map { "> [!NOTE]\n> Body \($0)." }.joined(separator: "\n\n")
        let rendered = render(alerts + "\n\n```\n[!WARNING]\n```")
        #expect(rendered.string.contains("[!WARNING]"))
        #expect(color(at: "[!WARNING]", in: rendered) != palette.platformColor(.warning))
        #expect(color(at: "NOTE\nBody 5.", in: rendered) == palette.platformColor(.info))
    }

    @Test("a table cell that reads [!NOTE] is not an alert and recolours nothing")
    func tableCellIsNotAnAlert() {
        let document = """
        | Tag | Meaning |
        | --- | --- |
        | [!NOTE] | a note |
        | [!TIP] | a tip |
        """
        let rendered = render(document)
        #expect(rendered.string.contains("[!NOTE]"))
        #expect(color(at: "[!NOTE]", in: rendered) != palette.platformColor(.info))
        // The old run started at the cell and ran to the first literal "\n\n",
        // which a table never contains — so it painted every following row.
        // The `contains` is load-bearing for the same reason as in
        // `adjacentQuoteIsNotColored`: a missing subject makes `color(at:in:)`
        // `nil`, and `nil != aColor` passes.
        #expect(rendered.string.contains("a tip"))
        #expect(color(at: "a tip", in: rendered) != palette.platformColor(.info))
    }

    @Test("an alert whose quote spans several blocks colours all of them")
    func multiBlockAlertQuoteIsFullyColored() {
        let rendered = render("> [!NOTE]\n> - one\n> - two")
        #expect(rendered.string.contains("one"))
        #expect(rendered.string.contains("two"))
        #expect(color(at: "NOTE", in: rendered) == palette.platformColor(.info))
        #expect(color(at: "one", in: rendered) == palette.platformColor(.info))
        #expect(color(at: "two", in: rendered) == palette.platformColor(.info))
    }

    @Test("the colour of one alert quote does not leak into the next quote")
    func adjacentQuoteIsNotColored() {
        let rendered = render("> [!NOTE]\n> First.\n\n> Plain quote.")
        #expect(color(at: "NOTE", in: rendered) == palette.platformColor(.info))
        // `color(at:in:)` is `nil` when the text is absent, and `nil != aColor`
        // is `true` — so without this line the assertion below would keep
        // reporting success in the one case that most obviously breaks the
        // guarantee it names: the plain quote vanishing from the output.
        #expect(rendered.string.contains("Plain quote."))
        #expect(color(at: "Plain quote.", in: rendered) != palette.platformColor(.info))
    }

    @Test("a tag on the second line of a quote is body text, not an alert")
    func tagOnLaterQuoteLineIsNotAnAlert() {
        let rendered = render("> Heads up.\n> [!NOTE]")
        #expect(rendered.string.contains("[!NOTE]"))
        #expect(color(at: "[!NOTE]", in: rendered) != palette.platformColor(.info))
    }
}
