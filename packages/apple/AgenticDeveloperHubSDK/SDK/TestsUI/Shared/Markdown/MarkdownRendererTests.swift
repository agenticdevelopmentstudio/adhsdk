import Testing
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// Encodes its inputs into its output instead of recording them into shared
/// state, so the assertions can pin both the language hint and the
/// substitution without a mutable, `Sendable`-hostile test double.
private struct StubHighlighter: CodeHighlighter {
    func highlight(_ code: String, language: String?, palette: SemanticPalette) -> NSAttributedString? {
        NSAttributedString(string: "HL[\(language ?? "none")]:\(code)")
    }
}

/// A host highlighter that recognises nothing — the documented fallback path.
private struct AbstainingHighlighter: CodeHighlighter {
    func highlight(_ code: String, language: String?, palette: SemanticPalette) -> NSAttributedString? { nil }
}

/// AppKit and UIKit spell the same symbolic trait differently (`.bold` vs
/// `.traitBold`) and neither declares the other's. That one name is the only
/// thing about this suite that is platform-specific, so it is the only thing
/// behind an `#if` — the renderer itself compiles into both UI frameworks, so
/// its tests live in `TestsUI/Shared` and compile into both test bundles.
func isBold(_ font: PlatformFont?) -> Bool {
    guard let font else { return false }
    #if os(macOS)
    return font.fontDescriptor.symbolicTraits.contains(.bold)
    #else
    return font.fontDescriptor.symbolicTraits.contains(.traitBold)
    #endif
}

@MainActor
@Suite("MarkdownRenderer")
struct MarkdownRendererTests {

    private var palette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedDark) }

    private func render(
        _ text: String,
        highlighter: (any CodeHighlighter)? = nil
    ) -> NSAttributedString {
        MarkdownRenderer(highlighter: highlighter)
            .render(text, palette: palette, textColor: palette.platformColor(.personaText))
    }

    @Test("plain text renders verbatim in the body font and the given color")
    func plainTextIsBodyText() {
        let rendered = render("hello world")
        #expect(rendered.string == "hello world")
        let attributes = rendered.attributes(at: 0, effectiveRange: nil)
        #expect(attributes[.font] as? PlatformFont == palette.platformFont(.body))
        #expect(attributes[.foregroundColor] as? PlatformColor == palette.platformColor(.personaText))
    }

    @Test("an inline code span drops its backticks and takes the code font")
    func inlineCodeSpanUsesCodeFont() {
        let rendered = render("call `reload()` now")
        #expect(rendered.string == "call reload() now")
        let location = (rendered.string as NSString).range(of: "reload()").location
        #expect(location != NSNotFound)
        #expect(rendered.attributes(at: location, effectiveRange: nil)[.font] as? PlatformFont
                == palette.platformFont(.code))
    }

    @Test("a fenced block drops its fences and renders as themed monospaced text")
    func fencedBlockIsMonospaced() {
        let rendered = render("before\n\n```\nlet x = 1\n```")
        #expect(!rendered.string.contains("```"))
        #expect(rendered.string.contains("let x = 1"))
        let location = (rendered.string as NSString).range(of: "let x = 1").location
        let attributes = rendered.attributes(at: location, effectiveRange: nil)
        #expect(attributes[.font] as? PlatformFont == palette.platformFont(.code))
        #expect(attributes[.foregroundColor] as? PlatformColor == palette.platformColor(.personaText))
    }

    @Test("an injected highlighter is given the block's code and language hint, and its output is used")
    func highlighterOutputIsUsed() {
        let rendered = render("```swift\nlet x = 1\n```", highlighter: StubHighlighter())
        #expect(rendered.string.contains("HL[swift]:let x = 1"))
    }

    @Test("a highlighter that abstains falls back to themed monospaced text")
    func abstainingHighlighterFallsBack() {
        let rendered = render("```swift\nlet x = 1\n```", highlighter: AbstainingHighlighter())
        #expect(rendered.string.contains("let x = 1"))
        let location = (rendered.string as NSString).range(of: "let x").location
        #expect(rendered.attributes(at: location, effectiveRange: nil)[.font] as? PlatformFont
                == palette.platformFont(.code))
    }

    @Test("inline code inside a paragraph does not reach the highlighter — only fenced blocks do")
    func inlineCodeIsNotHighlighted() {
        let rendered = render("call `reload()` now", highlighter: StubHighlighter())
        #expect(!rendered.string.contains("HL["))
    }

    @Test("emphasis renders bold rather than leaving the asterisks in the text")
    func strongEmphasisIsBold() {
        let rendered = render("a **loud** word")
        #expect(rendered.string == "a loud word")
        let location = (rendered.string as NSString).range(of: "loud").location
        let font = rendered.attributes(at: location, effectiveRange: nil)[.font] as? PlatformFont
        #expect(isBold(font))
    }

    @Test("two paragraphs stay two paragraphs")
    func paragraphsAreSeparated() {
        #expect(render("one\n\ntwo").string == "one\n\ntwo")
    }

    @Test("a heading loses its hashes and takes a heading font")
    func headingIsStyled() {
        let rendered = render("# Title\n\nbody")
        #expect(rendered.string == "Title\n\nbody")
        let font = rendered.attributes(at: 0, effectiveRange: nil)[.font] as? PlatformFont
        #expect(font == palette.platformFont(.title).applying(bold: true, italic: false))
    }

    @Test("heading levels step down through the type scale")
    func headingLevelsDiffer() {
        let one = render("# A").attributes(at: 0, effectiveRange: nil)[.font] as? PlatformFont
        let two = render("## A").attributes(at: 0, effectiveRange: nil)[.font] as? PlatformFont
        let four = render("#### A").attributes(at: 0, effectiveRange: nil)[.font] as? PlatformFont
        #expect(one != two)
        #expect(two != four)
    }

    @Test("an unordered list gets bullets, one line per item")
    func unorderedListHasBullets() {
        #expect(render("- a\n- b").string == "•\ta\n•\tb")
    }

    @Test("an ordered list keeps its numbering")
    func orderedListIsNumbered() {
        #expect(render("1. a\n2. b").string == "1.\ta\n2.\tb")
    }

    @Test("a nested list is indented further than its parent")
    func nestedListIndentsFurther() {
        let rendered = render("- a\n    - b")
        let outer = rendered.attributes(at: 0, effectiveRange: nil)[.paragraphStyle] as? NSParagraphStyle
        let innerLocation = (rendered.string as NSString).range(of: "b").location
        let inner = rendered.attributes(at: innerLocation, effectiveRange: nil)[.paragraphStyle] as? NSParagraphStyle
        #expect((inner?.headIndent ?? 0) > (outer?.headIndent ?? 0))
    }

    @Test("a bullet nested inside a numbered list keeps its bullet")
    func nestedBulletInsideOrderedListKeepsItsBullet() {
        // `nestedListIndentsFurther` above nests unordered in unordered, which
        // is exactly why this shipped: the list kind was one flag that ANY
        // ancestor `.orderedList` could set, and components arrive
        // innermost-first — so the outer numbered list overwrote the inner
        // bullet's kind and the sub-point rendered as "1." too.
        #expect(render("1. one\n   - bullet").string == "1.\tone\n•\tbullet")
    }

    @Test("a numbered list nested inside a bulleted one keeps its numbering")
    func nestedOrderedListInsideBulletedListKeepsItsNumbers() {
        // The inverse used to pass by luck rather than by rule; it is pinned
        // here so the fix cannot be "unordered always wins" either.
        #expect(render("- one\n  1. first\n  2. second").string == "•\tone\n1.\tfirst\n2.\tsecond")
    }

    @Test("a blockquote is indented and set in the secondary text color")
    func blockQuoteIsIndentedAndDimmed() {
        let rendered = render("> quoted")
        #expect(rendered.string == "quoted")
        let attributes = rendered.attributes(at: 0, effectiveRange: nil)
        #expect(attributes[.foregroundColor] as? PlatformColor == palette.platformColor(.secondaryText))
        #expect(((attributes[.paragraphStyle] as? NSParagraphStyle)?.headIndent ?? 0) > 0)
    }

    @Test("a thematic break renders as a rule rather than vanishing")
    func thematicBreakIsVisible() {
        #expect(render("a\n\n---\n\nb").string.contains(MarkdownBlockMetrics.thematicBreakRule))
    }

    @Test("a table keeps its rows and columns")
    func tableKeepsShape() {
        let rendered = render("| a | b |\n| --- | --- |\n| 1 | 2 |")
        #expect(rendered.string == "a\tb\n1\t2")
    }

    @Test("a table's header row is bold and its body rows are not")
    func tableHeaderIsBold() {
        let rendered = render("| a | b |\n| --- | --- |\n| 1 | 2 |")
        let header = rendered.attributes(at: 0, effectiveRange: nil)[.font] as? PlatformFont
        let bodyLocation = (rendered.string as NSString).range(of: "1").location
        let body = rendered.attributes(at: bodyLocation, effectiveRange: nil)[.font] as? PlatformFont
        #expect(isBold(header))
        #expect(!isBold(body))
    }

    @Test("two adjacent tables stay two tables, not one run-on row")
    func adjacentTablesAreSeparated() {
        // Row indices restart with each table, so comparing row index alone
        // read the second table's header as a continuation of the first
        // table's last row and joined them with a tab.
        let rendered = render("""
        | a | b |
        | --- | --- |
        | 1 | 2 |

        | c | d |
        | --- | --- |
        | 3 | 4 |
        """)
        #expect(rendered.string == "a\tb\n1\t2\n\nc\td\n3\t4")
    }

    @Test("a heading deeper than six hashes is not a heading at all")
    func headingBeyondLevelSixIsBodyText() {
        // CommonMark stops at six, so the parser hands `#######` back as a
        // paragraph — hashes and all. Pinning the shipped behaviour rather
        // than inventing a seventh heading level the palette has no font for.
        let rendered = render("####### Deep")
        #expect(rendered.string == "####### Deep")
        let font = rendered.attributes(at: 0, effectiveRange: nil)[.font] as? PlatformFont
        #expect(font == palette.platformFont(.body))
    }

    @Test("a table with a header and no body rows renders just its header")
    func emptyTableRendersItsHeader() {
        let rendered = render("| a | b |\n| --- | --- |")
        #expect(rendered.string == "a\tb")
        let font = rendered.attributes(at: 0, effectiveRange: nil)[.font] as? PlatformFont
        #expect(isBold(font))
    }

    @Test("list items still render their inline emphasis")
    func listItemsKeepInlineSpans() {
        let rendered = render("- a **loud** item")
        #expect(rendered.string == "•\ta loud item")
        let location = (rendered.string as NSString).range(of: "loud").location
        let font = rendered.attributes(at: location, effectiveRange: nil)[.font] as? PlatformFont
        #expect(isBold(font))
    }
}
