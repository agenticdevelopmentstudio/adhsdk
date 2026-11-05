import Foundation

/// Where one line of a markdown document sits relative to its fenced code
/// blocks.
public enum MarkdownLineRole: Equatable, Sendable {
    /// The line that opens a fenced block — the fence itself, not its contents.
    case openingFence
    /// The line that closes the block the most recent opener started.
    case closingFence
    /// A line inside a fenced block. An *unterminated* fence leaves every line
    /// after its opener in this role, right through to the end of the document,
    /// which is what keeps a stray fence from letting a `#` line inside the
    /// resulting code block become a document's title.
    case insideFence
    /// Ordinary markdown, outside every fence.
    case text
}

/// One line of a document with its fence role attached.
public struct MarkdownClassifiedLine: Equatable, Sendable {
    public let text: String
    public let role: MarkdownLineRole

    public init(text: String, role: MarkdownLineRole) {
        self.text = text
        self.role = role
    }

    /// `true` for a fence delimiter and for anything between a pair of them —
    /// the lines a title scan, a quote rewrite or a task-marker rewrite must
    /// leave alone.
    public var isFenced: Bool { role != .text }
}

/// The one place that decides what a fenced code block is.
///
/// Four call sites used to carry their own `hasPrefix("```")` toggle, so all
/// four missed the `~~~` form, the CommonMark rule that a closing fence must
/// use the opener's marker and be at least as long, and the unterminated fence
/// the spec requires be treated as running to EOF. Foundation only: this
/// compiles into all five platform frameworks.
public enum FenceScanner {

    /// A fence delimiter line, parsed.
    public struct Fence: Equatable, Sendable {
        /// `` ` `` or `~`.
        public let marker: Character
        /// How many delimiter characters the run has — at least three.
        public let length: Int
        /// Whether anything followed the run (`` ```swift ``). A closing fence
        /// may not carry one.
        public let hasInfoString: Bool

        public init(marker: Character, length: Int, hasInfoString: Bool) {
            self.marker = marker
            self.length = length
            self.hasInfoString = hasInfoString
        }
    }

    /// The fence this line is, or `nil` when it is ordinary text.
    ///
    /// Leading whitespace is skipped entirely rather than capped at
    /// CommonMark's three spaces: a fence nested in a list is indented further
    /// than that, and the previous per-site scans all trimmed without a cap, so
    /// this keeps their behaviour. A backtick run whose info string contains a
    /// backtick is not a fence, per CommonMark — that is `` `a``b` `` written
    /// badly, not a code block.
    public static func fence(in line: some StringProtocol) -> Fence? {
        let trimmed = line.drop { $0 == " " || $0 == "\t" }
        guard let marker = trimmed.first, marker == "`" || marker == "~" else { return nil }
        let run = trimmed.prefix { $0 == marker }
        guard run.count >= 3 else { return nil }
        let info = trimmed.dropFirst(run.count).trimmingCharacters(in: .whitespaces)
        if marker == "`", info.contains("`") { return nil }
        return Fence(marker: marker, length: run.count, hasInfoString: !info.isEmpty)
    }

    /// Every line of `source`, in order, tagged with its fence role.
    ///
    /// Lines are split on `Character.isNewline` rather than on the `"\n"`
    /// scalar: Swift's `String` groups a `"\r\n"` pair into a single extended
    /// grapheme cluster, so splitting on the `"\n"` `Character` alone silently
    /// fails to split a CRLF-authored document at all.
    public static func classify(_ source: some StringProtocol) -> [MarkdownClassifiedLine] {
        var result: [MarkdownClassifiedLine] = []
        var openFence: Fence?
        for line in source.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline }) {
            let text = String(line)
            let candidate = fence(in: line)
            if let open = openFence {
                if let candidate,
                   candidate.marker == open.marker,
                   candidate.length >= open.length,
                   !candidate.hasInfoString {
                    openFence = nil
                    result.append(MarkdownClassifiedLine(text: text, role: .closingFence))
                } else {
                    result.append(MarkdownClassifiedLine(text: text, role: .insideFence))
                }
            } else if let candidate {
                openFence = candidate
                result.append(MarkdownClassifiedLine(text: text, role: .openingFence))
            } else {
                result.append(MarkdownClassifiedLine(text: text, role: .text))
            }
        }
        return result
    }

    /// The literal contents of every *closed* fenced block in `source`, in
    /// document order, each block's lines joined with `"\n"`.
    ///
    /// An unterminated fence yields no block: there is no contents to speak of
    /// until the author closes it.
    public static func fencedBlockContents(in source: some StringProtocol) -> [String] {
        var blocks: [String] = []
        var current: [String] = []
        for line in classify(source) {
            switch line.role {
            case .openingFence: current = []
            case .insideFence: current.append(line.text)
            case .closingFence:
                blocks.append(current.joined(separator: "\n"))
                current = []
            case .text: continue
            }
        }
        return blocks
    }
}
