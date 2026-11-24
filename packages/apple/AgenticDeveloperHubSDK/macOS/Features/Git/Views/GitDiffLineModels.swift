import Foundation
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage

/// Where a diff row came from: hunk `hunk` of the file diff, and the index of the line in
/// that hunk's `lines`, nil for the hunk's header row.
public struct GitDiffLineRef: Hashable, Sendable {
    public var hunk: Int
    public var line: Int?

    public init(hunk: Int, line: Int?) {
        self.hunk = hunk
        self.line = line
    }
}

/// A file diff as one `LineViewerDataSource` (recipe `workspace/git/git-views`, "Diff"):
/// per hunk a header row (`@@ -o,c +n,c @@ section`), then its lines, with the old and new
/// line numbers in two gutter columns, `.removed`/`.added` backgrounds, each line's syntax
/// runs from the matching old or new `StyledLine` by line number, and, when word
/// highlighting is on, the changed words of each paired removed and added line as
/// `.emphasis` runs. A binary file is one header row, `Binary file`.
///
/// Built once per diff, colouring and toggle; it never changes after `init`.
@MainActor
public final class GitInlineDiffModel: LineViewerDataSource {

    public let rows: [LineViewerRow]
    /// One per row: the hunk line it shows, the hunk alone for a header, nil for the binary row.
    public let lineRefs: [GitDiffLineRef?]
    private let numberWidth: Int

    public convenience init(diff: GitFileDiff, oldLines: [StyledLine]?, newLines: [StyledLine]?,
                            wordHighlights: Bool) {
        self.init(diff: diff, oldLines: oldLines, newLines: newLines,
                  emphasis: GitDiffEmphasis(diff: diff, enabled: wordHighlights))
    }

    /// The rows with `emphasis` already worked out, so recolouring does not redo the word diff.
    public init(diff: GitFileDiff, oldLines: [StyledLine]?, newLines: [StyledLine]?, emphasis: GitDiffEmphasis) {
        numberWidth = GitDiffRows.numberWidth(diff)
        guard !diff.isBinary else {
            rows = [GitDiffRows.binary]
            lineRefs = [nil]
            return
        }
        var rows: [LineViewerRow] = []
        var refs: [GitDiffLineRef?] = []
        for (hunkIndex, hunk) in diff.hunks.enumerated() {
            rows.append(GitDiffRows.header(hunk))
            refs.append(GitDiffLineRef(hunk: hunkIndex, line: nil))
            let emphasis = emphasis.runs(inHunk: hunkIndex)
            for (index, line) in hunk.lines.enumerated() {
                refs.append(GitDiffLineRef(hunk: hunkIndex, line: index))
                let syntax: [LineViewerRun]
                let background: LineViewerBackground
                switch line.kind {
                case .context:
                    syntax = GitDiffRows.syntax(newLines, line.newNumber)
                        ?? GitDiffRows.syntax(oldLines, line.oldNumber) ?? []
                    background = .none
                case .removed:
                    syntax = GitDiffRows.syntax(oldLines, line.oldNumber) ?? []
                    background = .removed
                case .added:
                    syntax = GitDiffRows.syntax(newLines, line.newNumber) ?? []
                    background = .added
                case .noNewlineAtEnd:
                    rows.append(GitDiffRows.noNewline(line))
                    continue
                }
                rows.append(LineViewerRow(text: line.displayText, runs: syntax + (emphasis[index] ?? []),
                                          background: background,
                                          gutter: [line.oldNumber.map(String.init), line.newNumber.map(String.init)]))
            }
        }
        self.rows = rows
        self.lineRefs = refs
    }

    public var gutterColumnCount: Int { 2 }
    public var rowCount: Int { rows.count }
    public func row(at index: Int) -> LineViewerRow { rows[index] }
    public func gutterColumnWidth(_ column: Int) -> Int { numberWidth }
}

/// One side of a side-by-side diff: one gutter column of that side's line numbers.
@MainActor
public final class GitDiffSideModel: LineViewerDataSource {

    public let rows: [LineViewerRow]
    /// One per row: the hunk line it shows, the hunk alone for a header, nil for a filler
    /// and the binary row.
    public let lineRefs: [GitDiffLineRef?]
    private let numberWidth: Int

    init(rows: [LineViewerRow], lineRefs: [GitDiffLineRef?], numberWidth: Int) {
        self.rows = rows
        self.lineRefs = lineRefs
        self.numberWidth = numberWidth
    }

    public var gutterColumnCount: Int { 1 }
    public var rowCount: Int { rows.count }
    public func row(at index: Int) -> LineViewerRow { rows[index] }
    public func gutterColumnWidth(_ column: Int) -> Int { numberWidth }
}

/// A file diff as two aligned `LineViewerDataSource`s, old on the left and new on the
/// right (recipe `workspace/git/git-views`, "Diff"). Context lines sit on both sides; in
/// each change block the removed lines go left and the added lines right, row by row, and
/// the shorter side is padded with `.filler` rows so both sides have the same row count.
/// Headers, syntax runs, emphasis and the binary row are as in `GitInlineDiffModel`.
public enum GitSideBySideDiffModel {

    @MainActor
    public static func make(diff: GitFileDiff, oldLines: [StyledLine]?, newLines: [StyledLine]?,
                            wordHighlights: Bool) -> (left: GitDiffSideModel, right: GitDiffSideModel) {
        make(diff: diff, oldLines: oldLines, newLines: newLines,
             emphasis: GitDiffEmphasis(diff: diff, enabled: wordHighlights))
    }

    /// The two sides with `emphasis` already worked out.
    @MainActor
    public static func make(diff: GitFileDiff, oldLines: [StyledLine]?, newLines: [StyledLine]?,
                            emphasis: GitDiffEmphasis) -> (left: GitDiffSideModel, right: GitDiffSideModel) {
        let width = GitDiffRows.numberWidth(diff)
        guard !diff.isBinary else {
            return (GitDiffSideModel(rows: [GitDiffRows.binary], lineRefs: [nil], numberWidth: width),
                    GitDiffSideModel(rows: [GitDiffRows.binary], lineRefs: [nil], numberWidth: width))
        }
        var left = Side()
        var right = Side()
        var removed = Side()
        var added = Side()
        func flush() {
            let count = max(removed.rows.count, added.rows.count)
            left.append(removed, padTo: count)
            right.append(added, padTo: count)
            removed = Side()
            added = Side()
        }
        for (hunkIndex, hunk) in diff.hunks.enumerated() {
            let header = GitDiffRows.header(hunk)
            left.append(header, GitDiffLineRef(hunk: hunkIndex, line: nil))
            right.append(header, GitDiffLineRef(hunk: hunkIndex, line: nil))
            let emphasis = emphasis.runs(inHunk: hunkIndex)
            var previous: GitDiffLine.Kind?
            for (index, line) in hunk.lines.enumerated() {
                let marks = emphasis[index] ?? []
                let ref = GitDiffLineRef(hunk: hunkIndex, line: index)
                switch line.kind {
                case .context:
                    flush()
                    left.append(GitDiffRows.sideRow(line, number: line.oldNumber, lines: oldLines, marks: [],
                                                    background: .none), ref)
                    right.append(GitDiffRows.sideRow(line, number: line.newNumber, lines: newLines, marks: [],
                                                     background: .none), ref)
                case .removed:
                    if !added.rows.isEmpty { flush() }
                    removed.append(GitDiffRows.sideRow(line, number: line.oldNumber, lines: oldLines, marks: marks,
                                                       background: .removed), ref)
                case .added:
                    added.append(GitDiffRows.sideRow(line, number: line.newNumber, lines: newLines, marks: marks,
                                                     background: .added), ref)
                case .noNewlineAtEnd:
                    // The marker belongs to the line before it: that line's side, or both for context.
                    let marker = GitDiffRows.noNewline(line)
                    switch previous {
                    case .removed: removed.append(marker, ref)
                    case .added: added.append(marker, ref)
                    default:
                        flush()
                        left.append(marker, ref)
                        right.append(marker, ref)
                    }
                    continue
                }
                previous = line.kind
            }
            flush()
        }
        return (GitDiffSideModel(rows: left.rows, lineRefs: left.refs, numberWidth: width),
                GitDiffSideModel(rows: right.rows, lineRefs: right.refs, numberWidth: width))
    }

    /// One side's rows and their line refs, built together so they stay the same length.
    private struct Side {
        var rows: [LineViewerRow] = []
        var refs: [GitDiffLineRef?] = []

        mutating func append(_ row: LineViewerRow, _ ref: GitDiffLineRef?) {
            rows.append(row)
            refs.append(ref)
        }

        /// `block`'s rows, then fillers up to `count` rows.
        mutating func append(_ block: Side, padTo count: Int) {
            rows += block.rows + Array(repeating: GitDiffRows.filler, count: count - block.rows.count)
            refs += block.refs + Array(repeating: nil, count: count - block.refs.count)
        }
    }
}

/// The row-building rules both diff models share.
enum GitDiffRows {

    static let binary = LineViewerRow(kind: .header, text: "Binary file", background: .header)
    static let filler = LineViewerRow(text: "", background: .filler, gutter: [nil])

    static func header(_ hunk: GitDiffHunk) -> LineViewerRow {
        var text = "@@ -\(hunk.oldStart),\(hunk.oldCount) +\(hunk.newStart),\(hunk.newCount) @@"
        if !hunk.section.isEmpty { text += " " + hunk.section }
        return LineViewerRow(kind: .header, text: text, background: .header)
    }

    /// `\ No newline at end of file`, git's own wording, with no line numbers.
    static func noNewline(_ line: GitDiffLine) -> LineViewerRow {
        LineViewerRow(text: "\\" + line.text)
    }

    static func sideRow(_ line: GitDiffLine, number: Int?, lines: [StyledLine]?, marks: [LineViewerRun],
                        background: LineViewerBackground) -> LineViewerRow {
        LineViewerRow(text: line.displayText, runs: (syntax(lines, number) ?? []) + marks, background: background,
                      gutter: [number.map(String.init)])
    }

    /// Line `number`'s syntax runs (1-based), or nil when there are no lines or the number
    /// is past their end.
    static func syntax(_ lines: [StyledLine]?, _ number: Int?) -> [LineViewerRun]? {
        guard let lines, let number, number >= 1, number <= lines.count else { return nil }
        return lines[number - 1].runs.map {
            LineViewerRun(range: $0.range, foreground: $0.foreground, fontStyle: $0.fontStyle)
        }
    }

    /// Wide enough for the diff's largest line number, and never under 3.
    static func numberWidth(_ diff: GitFileDiff) -> Int {
        let largest = diff.hunks.flatMap(\.lines).reduce(0) { max($0, $1.oldNumber ?? 0, $1.newNumber ?? 0) }
        return max(3, String(largest).count)
    }
}

/// The word-highlight runs of a whole file diff: per hunk, the `.emphasis` runs of each
/// paired removed and added line by index into the hunk's `lines`. Worked out once per
/// diff and toggle within one `GitWordDiff.Budget`, so a long line or a diff of many pairs
/// falls back to line-level highlighting instead of stalling the main thread.
public struct GitDiffEmphasis: Sendable {
    private let hunks: [[Int: [LineViewerRun]]]
    /// The diff this was worked out for, and whether highlighting was on.
    let diff: GitFileDiff
    let enabled: Bool

    /// Nothing when `enabled` is false. `budget` is what the whole diff may spend.
    public init(diff: GitFileDiff, enabled: Bool, budget: GitWordDiff.Budget = GitWordDiff.Budget()) {
        self.diff = diff
        self.enabled = enabled
        guard enabled else {
            hunks = []
            return
        }
        var budget = budget
        hunks = diff.hunks.map { hunk in
            var result: [Int: [LineViewerRun]] = [:]
            for pair in GitWordDiff.pairs(in: hunk) {
                guard let ranges = GitWordDiff.changedRanges(old: hunk.lines[pair.removed].displayText,
                                                             new: hunk.lines[pair.added].displayText,
                                                             budget: &budget) else { continue }
                result[pair.removed] = ranges.old.map { LineViewerRun(range: $0, highlight: .emphasis) }
                result[pair.added] = ranges.new.map { LineViewerRun(range: $0, highlight: .emphasis) }
            }
            return result
        }
    }

    /// Hunk `index`'s runs by line index; empty past the end or when highlighting is off.
    public func runs(inHunk index: Int) -> [Int: [LineViewerRun]] {
        hunks.indices.contains(index) ? hunks[index] : [:]
    }

    /// Whether this was worked out for `diff` with highlighting `enabled`.
    func matches(_ diff: GitFileDiff, enabled: Bool) -> Bool {
        self.enabled == enabled && self.diff == diff
    }
}
