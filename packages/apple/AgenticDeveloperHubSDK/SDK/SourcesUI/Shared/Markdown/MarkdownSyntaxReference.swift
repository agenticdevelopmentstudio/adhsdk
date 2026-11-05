import Foundation

public struct MarkdownSyntaxRow: Equatable, Sendable {
    public let syntax: String
    public let meaning: String

    public init(syntax: String, meaning: String) {
        self.syntax = syntax
        self.meaning = meaning
    }
}

/// The syntax the editor's renderer actually handles, in the order a writer
/// meets it. Anything absent here is a gap in the renderer, not in the help.
public enum MarkdownSyntaxReference {

    public static let rows: [MarkdownSyntaxRow] = [
        MarkdownSyntaxRow(syntax: "# Heading", meaning: "Heading, one to six hashes"),
        MarkdownSyntaxRow(syntax: "**bold**", meaning: "Bold"),
        MarkdownSyntaxRow(syntax: "*italic*", meaning: "Italic"),
        MarkdownSyntaxRow(syntax: "~~struck~~", meaning: "Strikethrough"),
        MarkdownSyntaxRow(syntax: "- item", meaning: "Bulleted list"),
        MarkdownSyntaxRow(syntax: "1. item", meaning: "Numbered list"),
        MarkdownSyntaxRow(syntax: "- [ ] task", meaning: "Task list; use [x] when done"),
        MarkdownSyntaxRow(syntax: "> quote", meaning: "Blockquote"),
        MarkdownSyntaxRow(syntax: "> [!NOTE]", meaning: "Callout: NOTE, TIP, IMPORTANT, WARNING, CAUTION"),
        MarkdownSyntaxRow(syntax: "`code`", meaning: "Inline code"),
        MarkdownSyntaxRow(syntax: "```lang", meaning: "Fenced code block"),
        MarkdownSyntaxRow(syntax: "[text](url)", meaning: "Link"),
        // The pipes are escaped because `markdown` below emits every row *as a
        // table row*: under GFM a `|` splits a cell even inside a code span, so
        // an unescaped `| a | b |` explodes into seven cells in a two-column
        // table — and this sheet is rendered by the code it documents, so that
        // is the row the reader sees broken.
        MarkdownSyntaxRow(syntax: #"\| a \| b \|"#, meaning: #"Table row; follow the header with \| --- \|"#),
        MarkdownSyntaxRow(syntax: "---", meaning: "Horizontal rule; at the very top, frontmatter")
    ]

    /// The reference as a markdown table, so the help sheet is rendered by the
    /// same code it documents.
    public static var markdown: String {
        var lines = ["## Markdown syntax", "", "| Syntax | Means |", "| --- | --- |"]
        for row in rows {
            lines.append("| \(codeSpan(row.syntax)) | \(row.meaning) |")
        }
        return lines.joined(separator: "\n")
    }

    /// `text` as a code span that survives being *rendered*.
    ///
    /// A single backtick cannot delimit content that contains backticks —
    /// `` `code` `` and ```` ```lang ```` are two of the rows this sheet
    /// documents — so the delimiter is one longer than the longest run inside,
    /// which is CommonMark's rule. Content that begins or ends with a backtick
    /// is padded with a space the parser strips again, so the delimiters stay
    /// distinguishable from the content.
    static func codeSpan(_ text: String) -> String {
        var longestRun = 0
        var currentRun = 0
        for character in text {
            currentRun = character == "`" ? currentRun + 1 : 0
            longestRun = max(longestRun, currentRun)
        }
        let delimiter = String(repeating: "`", count: longestRun + 1)
        let padding = text.hasPrefix("`") || text.hasSuffix("`") ? " " : ""
        return delimiter + padding + text + padding + delimiter
    }
}
