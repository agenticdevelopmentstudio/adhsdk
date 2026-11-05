import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import AgenticDeveloperHubSDK

/// GitHub's alert callouts, which adh's markdown authors use.
///
/// Each maps onto a semantic role the theme already defines, so an alert is
/// coloured by the same rule that colours a warning banner anywhere else.
public enum MarkdownAlert: String, Sendable, CaseIterable {
    case note
    case tip
    case important
    case warning
    case caution

    public var role: ThemeRole {
        switch self {
        case .note: return .info
        case .tip: return .success
        case .important: return .accent
        case .warning: return .warning
        case .caution: return .danger
        }
    }

    public var label: String { rawValue.uppercased() }

    /// The literal tag an author writes: `[!NOTE]`. Uppercase only, which is
    /// what GitHub renders and what this renderer has always matched.
    public var tag: String { "[!\(label)]" }

    /// The alert this tag names, or `nil` — `[!SHOUT]` is an ordinary quote.
    static func alert(forTag tag: String) -> MarkdownAlert? {
        allCases.first { $0.tag == tag }
    }
}

/// Renders a whole markdown *document*, as opposed to the message fragment
/// `MarkdownRenderer` handles.
///
/// The three differences are all document-only, which is why they are here and
/// not in the renderer: a chat bubble has no frontmatter to hide, and a message
/// that says `> [!NOTE]` means to show those characters.
public struct MarkdownDocumentRenderer: Sendable {

    private let renderer: MarkdownRenderer

    public init(highlighter: (any CodeHighlighter)? = nil) {
        self.renderer = MarkdownRenderer(highlighter: highlighter)
    }

    public func render(
        _ content: String,
        palette: SemanticPalette,
        textColor: PlatformColor
    ) -> NSAttributedString {
        let body = Frontmatter.split(content).body
        // Alerts are found on the SOURCE, where `FenceScanner` already knows
        // which lines are fenced and which are quote lines, and marked with a
        // sentinel that survives rendering. See `markAlerts` for why they are
        // not found on the rendered string.
        let marked = Self.markAlerts(in: body)
        let prepared = Self.rewriteTaskListMarkers(in: Self.hardenQuoteLineBreaks(in: marked.source))
        let output = renderer.renderReportingBlocks(prepared, palette: palette, textColor: textColor)
        let rendered = NSMutableAttributedString(attributedString: output.text)
        // Colour first (attributes only, so `output.blocks` still describes the
        // string), then swap the sentinels for their labels, and only then
        // collapse task markers — both of those change the string's length.
        Self.colorAlerts(marked.alerts, in: rendered, blocks: output.blocks, palette: palette)
        Self.replaceAlertSentinels(marked.alerts, in: rendered)
        Self.collapseTaskListMarkers(in: rendered)
        return rendered
    }

    // MARK: - Blockquote line breaks

    /// `AttributedString(markdown:)` treats a single newline inside a block as
    /// a soft break and collapses it to a space, so a two-line `> [!WARNING]` /
    /// `> mind the gap` quote would otherwise render as one run-on line. A
    /// trailing hard-break (two spaces before the newline) is CommonMark for
    /// "keep this line break", which the parser honours as a literal `\n` —
    /// so every quote line that is followed by another quote line gets one,
    /// unless it already ends in a hard break of its own (backslash or two-
    /// plus trailing spaces already), in which case appending another would
    /// push a CommonMark backslash escape off the end of the line and leave
    /// it as a visible `\` instead of consuming it. Only quote lines outside
    /// a fence are touched.
    ///
    /// Lines are split on `Character.isNewline` rather than the `"\n"`
    /// scalar — see `Frontmatter.parse`'s comment for why a `"\r\n"`-authored
    /// document needs this — and rejoined with a plain `"\n"`, which
    /// normalises CRLF to LF in the text handed to `MarkdownRenderer`. That
    /// is fine on this render-only path; it is not what stores the document.
    static func hardenQuoteLineBreaks(in source: String) -> String {
        let lines = FenceScanner.classify(source)
        var result: [String] = []
        for (index, line) in lines.enumerated() {
            guard !line.isFenced else { result.append(line.text); continue }
            let text = line.text
            let isQuoteLine = text.trimmingCharacters(in: .whitespaces).hasPrefix(">")
            let next = index + 1 < lines.count ? lines[index + 1] : nil
            let nextIsQuoteLine = next.map { !$0.isFenced && $0.text.trimmingCharacters(in: .whitespaces).hasPrefix(">") }
                ?? false
            let alreadyHardBroken = text.hasSuffix("\\") || text.hasSuffix("  ")
            result.append(isQuoteLine && nextIsQuoteLine && !alreadyHardBroken ? text + "  " : text)
        }
        return result.joined(separator: "\n")
    }

    // MARK: - Task lists

    /// `AttributedString(markdown:)` leaves GFM's `[ ]` / `[x]` as literal text
    /// inside the list item, so the substitution happens on the source. Only
    /// list-item lines outside a fence are touched.
    ///
    /// Lines are split on `Character.isNewline` rather than the `"\n"`
    /// scalar — see `Frontmatter.parse`'s comment for why a `"\r\n"`-authored
    /// document needs this — and rejoined with a plain `"\n"`, which
    /// normalises CRLF to LF in the text handed to `MarkdownRenderer`. That
    /// is fine on this render-only path; it is not what stores the document.
    static func rewriteTaskListMarkers(in source: String) -> String {
        var lines: [String] = []
        for line in FenceScanner.classify(source) {
            let text = line.text
            guard !line.isFenced else { lines.append(text); continue }
            lines.append(
                text.replacingOccurrences(
                    of: "^(\\s*[-*+]\\s+)\\[ \\]\\s+",
                    with: "$1☐\u{00A0}",
                    options: .regularExpression
                ).replacingOccurrences(
                    of: "^(\\s*[-*+]\\s+)\\[[xX]\\]\\s+",
                    with: "$1☑\u{00A0}",
                    options: .regularExpression
                ))
        }
        return lines.joined(separator: "\n")
    }

    /// The renderer has no notion of a task list, so a rewritten item still
    /// renders through the ordinary bullet path: `"•\t☐\u{00A0}todo"`. A task
    /// item shows only its checkbox where an ordinary item shows a bullet, so
    /// the bullet, its tab, and the marker's non-breaking space collapse into
    /// the checkbox followed by a plain tab — the same shape
    /// `MarkdownRenderer` gives every other list marker.
    static func collapseTaskListMarkers(in rendered: NSMutableAttributedString) {
        for checkbox in ["☐", "☑"] {
            let target = "•\t\(checkbox)\u{00A0}"
            let replacement = "\(checkbox)\t"
            var searchStart = 0
            while searchStart < rendered.length {
                let searchRange = NSRange(location: searchStart, length: rendered.length - searchStart)
                let found = (rendered.string as NSString).range(of: target, range: searchRange)
                guard found.location != NSNotFound else { break }
                rendered.replaceCharacters(
                    in: found,
                    with: NSAttributedString(
                        string: replacement,
                        attributes: rendered.attributes(at: found.location, effectiveRange: nil)))
                searchStart = found.location + (replacement as NSString).length
            }
        }
    }

    // MARK: - Alerts

    /// One alert found in the source, and the sentinel standing in for its tag
    /// in the text handed to the renderer.
    struct SourceAlert: Equatable {
        let alert: MarkdownAlert
        let sentinel: String
    }

    /// Every blockquote that OPENS with an alert tag, with the tag replaced by
    /// a sentinel.
    ///
    /// **Detection happens here, on the source, not on the rendered string.**
    /// The rendered string has lost the two facts that decide the question:
    /// which lines were fenced, and where one block ends. The previous pass
    /// tried to recover both by substring search and got three things wrong — a
    /// fence that merely *documented* `[!NOTE]` suppressed every real alert in
    /// the document (the exclusion list keyed on the tag text, not on where it
    /// was); that list was computed once, before a loop that shortened the
    /// string by three units per rewritten alert, so it drifted off its own
    /// ranges; and the coloured run was delimited by the first literal `"\n\n"`,
    /// which is not a block boundary — it painted the rest of a table.
    /// `FenceScanner.classify` knows the fencing for free, so a fenced line is
    /// simply never a candidate and no exclusion list exists at all.
    ///
    /// The sentinel is a private-use pair around the alert's index. It is inert
    /// to the markdown parser, it cannot collide with anything an author wrote,
    /// and it survives into the rendered string — which is what lets the colour
    /// pass locate each alert exactly rather than by searching for its label. It
    /// is swapped for the label afterwards.
    ///
    /// The tag must be alone on the FIRST line of its quote, which is GitHub's
    /// own rule for an alert.
    static func markAlerts(in source: String) -> (source: String, alerts: [SourceAlert]) {
        var lines: [String] = []
        var alerts: [SourceAlert] = []
        var previousWasQuoteLine = false
        for line in FenceScanner.classify(source) {
            let text = line.text
            guard !line.isFenced, let content = Self.blockquoteContent(of: text) else {
                lines.append(text)
                previousWasQuoteLine = false
                continue
            }
            guard !previousWasQuoteLine, let alert = MarkdownAlert.alert(forTag: content) else {
                lines.append(text)
                previousWasQuoteLine = true
                continue
            }
            let sentinel = Self.alertSentinel(alerts.count)
            alerts.append(SourceAlert(alert: alert, sentinel: sentinel))
            lines.append(text.replacingOccurrences(of: alert.tag, with: sentinel))
            previousWasQuoteLine = true
        }
        return (lines.joined(separator: "\n"), alerts)
    }

    /// A blockquote line's text with its `>` markers and surrounding whitespace
    /// removed, or `nil` when the line is not a blockquote line at all. A
    /// `[!NOTE]` in a table cell is not one, which is why the table no longer
    /// gets recoloured.
    private static func blockquoteContent(of line: String) -> String? {
        var rest = Substring(line).drop { $0 == " " || $0 == "\t" }
        guard rest.first == ">" else { return nil }
        while rest.first == ">" {
            rest = rest.dropFirst().drop { $0 == " " || $0 == "\t" }
        }
        return String(rest).trimmingCharacters(in: .whitespaces)
    }

    /// U+E000/U+E001 are private-use code points: no markdown meaning, no
    /// chance of appearing in a document, and passed through the parser as
    /// ordinary text.
    static func alertSentinel(_ index: Int) -> String { "\u{E000}\(index)\u{E001}" }

    /// Paint each alert's whole blockquote — every rendered block the quote
    /// owns, not the run up to the first blank line.
    ///
    /// Attributes only: this must not change the string's length, because
    /// `blocks` describes the string exactly as the renderer emitted it.
    static func colorAlerts(
        _ alerts: [SourceAlert],
        in rendered: NSMutableAttributedString,
        blocks: [MarkdownRenderer.RenderedBlock],
        palette: SemanticPalette
    ) {
        let text = rendered.string as NSString
        for detected in alerts {
            let found = text.range(of: detected.sentinel)
            guard found.location != NSNotFound else { continue }
            rendered.addAttribute(
                .foregroundColor,
                value: palette.platformColor(detected.alert.role),
                range: Self.quoteSpan(containing: found.location, blocks: blocks))
        }
    }

    /// The rendered range of the whole blockquote the block at `location`
    /// belongs to: that block plus every following block carrying the same
    /// outermost `.blockQuote` identity, the separators between them included.
    /// Two adjacent blockquotes have different identities, so the colour stops
    /// at the first one's end.
    private static func quoteSpan(
        containing location: Int,
        blocks: [MarkdownRenderer.RenderedBlock]
    ) -> NSRange {
        guard let index = blocks.firstIndex(where: { NSLocationInRange(location, $0.range) }) else {
            return NSRange(location: location, length: 0)
        }
        let first = blocks[index]
        guard let identity = first.quoteIdentity else { return first.range }
        var last = index
        while last + 1 < blocks.count, blocks[last + 1].quoteIdentity == identity {
            last += 1
        }
        let end = blocks[last].range.location + blocks[last].range.length
        return NSRange(location: first.range.location, length: end - first.range.location)
    }

    /// Sentinels out, labels in — after the colouring, so each label inherits
    /// its alert's colour from the run it replaces.
    static func replaceAlertSentinels(_ alerts: [SourceAlert], in rendered: NSMutableAttributedString) {
        for detected in alerts {
            let found = (rendered.string as NSString).range(of: detected.sentinel)
            guard found.location != NSNotFound else { continue }
            rendered.replaceCharacters(
                in: found,
                with: NSAttributedString(
                    string: detected.alert.label,
                    attributes: rendered.attributes(at: found.location, effectiveRange: nil)))
        }
    }
}
