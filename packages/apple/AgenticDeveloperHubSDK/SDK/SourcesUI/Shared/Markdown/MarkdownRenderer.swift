import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import AgenticDeveloperHubSDK

/// Supplies syntax colouring for fenced code blocks. ADT ships no highlighter:
/// the web side gets this from Shiki, and pulling an equivalent grammar stack
/// into a framework customers embed is not a trade worth making. A host that
/// already has one injects it here.
public protocol CodeHighlighter: Sendable {
    func highlight(_ code: String, language: String?, palette: SemanticPalette) -> NSAttributedString?
}

/// Turns a message's markdown into a themed `NSAttributedString`.
///
/// Moved here from `SourcesUI/macOS` in Task 8b, once
/// `SemanticPalette.platformColor(_:)`/`platformFont(_:)` gave both platforms
/// the same accessor shape (`PlatformColor`/`PlatformFont`) — this type reads
/// a palette through those, never through `nsColor(_:)`/`font(_:)` directly,
/// so it compiles unchanged into both the macOS and iOS UI targets.
///
/// Block structure comes from `AttributedString(markdown:)`'s
/// `presentationIntent`: runs are grouped by block, blocks are rejoined with a
/// blank line, and a fenced block is offered to `highlighter` before falling
/// back to themed monospaced text. Unhighlighted code is correct, just
/// monochrome.
public struct MarkdownRenderer: Sendable {

    /// Absent by default — the shipped behaviour. A host with its own grammar
    /// stack injects one and every fenced block routes through it.
    public let highlighter: (any CodeHighlighter)?

    public init(highlighter: (any CodeHighlighter)? = nil) {
        self.highlighter = highlighter
    }

    /// One block-level run of the rendered output, with the structure the
    /// renderer knew when it emitted it.
    ///
    /// Block boundaries are not recoverable from the rendered string: the
    /// separators are `"\t"`, `"\n"` and `"\n\n"` depending on what the two
    /// neighbouring blocks are, so a caller that split on `"\n\n"` would run a
    /// table's rows together and a list's items together. `MarkdownDocumentRenderer`
    /// needs the real boundaries to colour a whole alert blockquote, so the
    /// renderer hands them out rather than making the caller guess.
    struct RenderedBlock {
        /// The block's own characters, not including the separator that
        /// precedes it.
        let range: NSRange
        /// Identity of the *outermost* `.blockQuote` intent this block sits
        /// in, or `nil` when it is not in a quote. Two adjacent blockquotes
        /// carry different identities, so a colour run cannot leak out of one
        /// quote and into the next.
        let quoteIdentity: Int?
    }

    public func render(_ markdown: String, palette: SemanticPalette, textColor: PlatformColor) -> NSAttributedString {
        renderReportingBlocks(markdown, palette: palette, textColor: textColor).text
    }

    func renderReportingBlocks(
        _ markdown: String,
        palette: SemanticPalette,
        textColor: PlatformColor
    ) -> (text: NSAttributedString, blocks: [RenderedBlock]) {
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: palette.platformFont(.body),
            .foregroundColor: textColor
        ]

        // `.returnPartiallyParsedIfPossible` rather than a throw: half-typed
        // markdown arrives on every streaming draft, and a parse failure must
        // degrade to plain text, never to an empty bubble.
        guard let parsed = try? AttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(
                allowsExtendedAttributes: true,
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible)
        ) else {
            return (NSAttributedString(string: markdown, attributes: bodyAttributes), [])
        }

        let output = NSMutableAttributedString()
        var blocks: [RenderedBlock] = []
        var previous: BlockShape?
        for (intent, range) in parsed.runs[\.presentationIntent] {
            let shape = Self.shape(intent)
            let separator = Self.separator(from: previous, to: shape)
            if !separator.isEmpty {
                output.append(NSAttributedString(string: separator, attributes: bodyAttributes))
            }
            previous = shape
            let blockStart = output.length
            defer {
                blocks.append(RenderedBlock(
                    range: NSRange(location: blockStart, length: output.length - blockStart),
                    quoteIdentity: shape.quoteIdentity))
            }

            let block = parsed[range]

            if shape.isCodeBlock {
                output.append(renderCodeBlock(
                    String(block.characters),
                    language: shape.codeLanguage,
                    palette: palette,
                    textColor: textColor))
                continue
            }

            if shape.isThematicBreak {
                output.append(NSAttributedString(
                    string: MarkdownBlockMetrics.thematicBreakRule,
                    attributes: [
                        .font: palette.platformFont(.body),
                        .foregroundColor: palette.platformColor(.divider)
                    ]))
                continue
            }

            let blockAttributes = Self.blockAttributes(
                shape, base: bodyAttributes, palette: palette, textColor: textColor)

            if let marker = shape.listMarker {
                output.append(NSAttributedString(string: marker + "\t", attributes: blockAttributes))
            }

            for run in block.runs {
                output.append(NSAttributedString(
                    string: String(parsed[run.range].characters),
                    attributes: Self.inlineAttributes(
                        for: run, base: blockAttributes, palette: palette, textColor: textColor)))
            }
        }
        return (output, blocks)
    }

    // MARK: Block shape

    /// What one block-level run is, flattened out of its nested
    /// `PresentationIntent` components.
    ///
    /// The components arrive innermost-first, so nesting depth is a count and
    /// the first `listItem` encountered is the one this block belongs to.
    struct BlockShape {
        var headerLevel: Int?
        var listDepth = 0
        var isOrderedList = false
        var ordinal: Int?
        var quoteDepth = 0
        /// The identity of the OUTERMOST `.blockQuote` intent this block sits
        /// in. Components arrive innermost-first, so the last one seen is the
        /// outermost — which is the one that says "these blocks are all one
        /// quote", including a nested quote inside it.
        var quoteIdentity: Int?
        var isThematicBreak = false
        var isCodeBlock = false
        var codeLanguage: String?
        /// -1 for a header row, the parser's row index for a body row, `nil`
        /// when the block is not in a table at all.
        var tableRow: Int?
        /// The identity of the `.table` intent this row belongs to. Row indices
        /// restart at each table, so two adjacent tables would otherwise look
        /// like one table's repeated row and be run together on a single line.
        var tableIdentity: Int?
        var isTableHeader = false

        var indent: CGFloat {
            CGFloat(listDepth + quoteDepth) * MarkdownBlockMetrics.indentStep
        }

        var listMarker: String? {
            guard listDepth > 0, let ordinal else { return nil }
            return isOrderedList ? "\(ordinal)." : "•"
        }
    }

    private static func shape(_ intent: PresentationIntent?) -> BlockShape {
        var shape = BlockShape()
        guard let intent else { return shape }
        for component in intent.components {
            switch component.kind {
            case .header(let level):
                shape.headerLevel = level
            // Only the INNERMOST list decides the marker, and components
            // arrive innermost-first — so `listDepth == 0` is how the
            // innermost one identifies itself. Letting every ancestor write
            // the flag made a bullet nested inside a numbered list render
            // with its parent's numeral.
            case .orderedList:
                if shape.listDepth == 0 { shape.isOrderedList = true }
                shape.listDepth += 1
            case .unorderedList:
                if shape.listDepth == 0 { shape.isOrderedList = false }
                shape.listDepth += 1
            case .listItem(let ordinal):
                if shape.ordinal == nil { shape.ordinal = ordinal }
            case .blockQuote:
                shape.quoteDepth += 1
                shape.quoteIdentity = component.identity
            case .thematicBreak:
                shape.isThematicBreak = true
            case .codeBlock(let languageHint):
                shape.isCodeBlock = true
                shape.codeLanguage = languageHint
            case .tableHeaderRow:
                shape.tableRow = -1
                shape.isTableHeader = true
            case .tableRow(let rowIndex):
                if shape.tableRow == nil { shape.tableRow = rowIndex }
            case .table:
                if shape.tableIdentity == nil { shape.tableIdentity = component.identity }
            default:
                break
            }
        }
        return shape
    }

    /// Blank line between blocks, single newline between siblings in one list
    /// or between rows of one table, tab between cells of one table row.
    ///
    /// Two adjacent tables are two blocks, not one: their row indices both
    /// restart, so the identity of the enclosing table — not the row index
    /// alone — is what says whether the next cell belongs to the row that came
    /// before it.
    private static func separator(from previous: BlockShape?, to current: BlockShape) -> String {
        guard let previous else { return "" }
        if let previousRow = previous.tableRow, let currentRow = current.tableRow,
           previous.tableIdentity == current.tableIdentity {
            return previousRow == currentRow ? "\t" : "\n"
        }
        if previous.listDepth > 0 && current.listDepth > 0 { return "\n" }
        return "\n\n"
    }

    private static func blockAttributes(
        _ shape: BlockShape,
        base: [NSAttributedString.Key: Any],
        palette: SemanticPalette,
        textColor: PlatformColor
    ) -> [NSAttributedString.Key: Any] {
        var attributes = base

        if let level = shape.headerLevel {
            attributes[.font] = headerFont(level: level, palette: palette)
        } else if shape.isTableHeader {
            attributes[.font] = palette.platformFont(.body).applying(bold: true, italic: false)
        }

        if shape.quoteDepth > 0 {
            attributes[.foregroundColor] = palette.platformColor(.secondaryText)
        }

        let style = NSMutableParagraphStyle()
        style.headIndent = shape.indent
        style.firstLineHeadIndent = shape.indent
        if shape.listDepth > 0 {
            // The marker sits at the indent and the text hangs off a tab stop
            // one step further in, so wrapped lines align under the text.
            style.tabStops = [NSTextTab(textAlignment: .left, location: shape.indent + MarkdownBlockMetrics.indentStep)]
            style.headIndent = shape.indent + MarkdownBlockMetrics.indentStep
        } else if shape.tableRow != nil {
            style.tabStops = (1...MarkdownBlockMetrics.tableColumnCount).map {
                NSTextTab(textAlignment: .left, location: CGFloat($0) * MarkdownBlockMetrics.tableColumnWidth)
            }
        }
        attributes[.paragraphStyle] = style

        return attributes
    }

    /// Level 1 and 2 get the palette's display roles, and 3 gets the same
    /// heading role at its own weight; 4 and below are body text wearing
    /// weight, because the palette has no smaller heading role and an
    /// invented one would drift from the rest of the toolkit's type scale.
    private static func headerFont(level: Int, palette: SemanticPalette) -> PlatformFont {
        switch level {
        case 1: return palette.platformFont(.title).applying(bold: true, italic: false)
        case 2: return palette.platformFont(.heading).applying(bold: true, italic: false)
        case 3: return palette.platformFont(.heading)
        default: return palette.platformFont(.body).applying(bold: true, italic: false)
        }
    }

    // MARK: Blocks

    private func renderCodeBlock(
        _ raw: String,
        language: String?,
        palette: SemanticPalette,
        textColor: PlatformColor
    ) -> NSAttributedString {
        // The parser leaves a fenced block's trailing newline in place; it
        // would render as a blank line on top of the blank line between
        // blocks.
        let code = raw.hasSuffix("\n") ? String(raw.dropLast()) : raw
        if let highlighted = highlighter?.highlight(code, language: language, palette: palette) {
            return highlighted
        }
        return NSAttributedString(string: code, attributes: [
            .font: palette.platformFont(.code),
            .foregroundColor: textColor,
            .backgroundColor: palette.platformColor(.controlBackground)
        ])
    }

    // MARK: Inline spans

    private static func inlineAttributes(
        for run: AttributedString.Runs.Run,
        base: [NSAttributedString.Key: Any],
        palette: SemanticPalette,
        textColor: PlatformColor
    ) -> [NSAttributedString.Key: Any] {
        var attributes = base
        let intent = run.inlinePresentationIntent ?? []

        if intent.contains(.code) {
            attributes[.font] = palette.platformFont(.code)
            attributes[.backgroundColor] = palette.platformColor(.controlBackground)
        } else {
            let bold = intent.contains(.stronglyEmphasized)
            let italic = intent.contains(.emphasized)
            if bold || italic {
                let blockFont = (base[.font] as? PlatformFont) ?? palette.platformFont(.body)
                attributes[.font] = blockFont.applying(bold: bold, italic: italic)
            }
        }
        // `NSUnderlineStyle` is declared by AppKit on macOS and UIKit on iOS,
        // so this file imports the platform framework the same way
        // `PlatformAppearance.swift` does. Being in Shared means "one source
        // for both platforms", not "Foundation only" — and the enum is worth
        // the import: hardcoding `1` would pin a framework's raw value in a
        // toolkit we ship, with nothing to catch it if that ever moved.
        let singleUnderline = NSUnderlineStyle.single.rawValue
        if intent.contains(.strikethrough) {
            attributes[.strikethroughStyle] = singleUnderline
        }
        if let link = run.link {
            attributes[.link] = link
            attributes[.foregroundColor] = palette.platformColor(.accent)
            attributes[.underlineStyle] = singleUnderline
        }
        return attributes
    }
}
