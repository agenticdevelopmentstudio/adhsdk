import Foundation
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage

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
    private let numberWidth: Int

    public init(diff: GitFileDiff, oldLines: [StyledLine]?, newLines: [StyledLine]?, wordHighlights: Bool) {
        numberWidth = GitDiffRows.numberWidth(diff)
        guard !diff.isBinary else {
            rows = [GitDiffRows.binary]
            return
        }
        var rows: [LineViewerRow] = []
        for hunk in diff.hunks {
            rows.append(GitDiffRows.header(hunk))
            let emphasis = GitDiffRows.emphasis(in: hunk, enabled: wordHighlights)
            for (index, line) in hunk.lines.enumerated() {
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
                rows.append(LineViewerRow(text: line.text, runs: syntax + (emphasis[index] ?? []),
                                          background: background,
                                          gutter: [line.oldNumber.map(String.init), line.newNumber.map(String.init)]))
            }
        }
        self.rows = rows
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
    private let numberWidth: Int

    init(rows: [LineViewerRow], numberWidth: Int) {
        self.rows = rows
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
        let width = GitDiffRows.numberWidth(diff)
        guard !diff.isBinary else {
            return (GitDiffSideModel(rows: [GitDiffRows.binary], numberWidth: width),
                    GitDiffSideModel(rows: [GitDiffRows.binary], numberWidth: width))
        }
        var left: [LineViewerRow] = []
        var right: [LineViewerRow] = []
        var removed: [LineViewerRow] = []
        var added: [LineViewerRow] = []
        func flush() {
            let count = max(removed.count, added.count)
            left += removed + Array(repeating: GitDiffRows.filler, count: count - removed.count)
            right += added + Array(repeating: GitDiffRows.filler, count: count - added.count)
            removed.removeAll()
            added.removeAll()
        }
        for hunk in diff.hunks {
            let header = GitDiffRows.header(hunk)
            left.append(header)
            right.append(header)
            let emphasis = GitDiffRows.emphasis(in: hunk, enabled: wordHighlights)
            var previous: GitDiffLine.Kind?
            for (index, line) in hunk.lines.enumerated() {
                let marks = emphasis[index] ?? []
                switch line.kind {
                case .context:
                    flush()
                    left.append(GitDiffRows.sideRow(line, number: line.oldNumber, lines: oldLines, marks: [],
                                                    background: .none))
                    right.append(GitDiffRows.sideRow(line, number: line.newNumber, lines: newLines, marks: [],
                                                     background: .none))
                case .removed:
                    if !added.isEmpty { flush() }
                    removed.append(GitDiffRows.sideRow(line, number: line.oldNumber, lines: oldLines, marks: marks,
                                                       background: .removed))
                case .added:
                    added.append(GitDiffRows.sideRow(line, number: line.newNumber, lines: newLines, marks: marks,
                                                     background: .added))
                case .noNewlineAtEnd:
                    // The marker belongs to the line before it: that line's side, or both for context.
                    let marker = GitDiffRows.noNewline(line)
                    switch previous {
                    case .removed: removed.append(marker)
                    case .added: added.append(marker)
                    default:
                        flush()
                        left.append(marker)
                        right.append(marker)
                    }
                    continue
                }
                previous = line.kind
            }
            flush()
        }
        return (GitDiffSideModel(rows: left, numberWidth: width), GitDiffSideModel(rows: right, numberWidth: width))
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
        LineViewerRow(text: line.text, runs: (syntax(lines, number) ?? []) + marks, background: background,
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

    /// The emphasis runs of each paired removed and added line, by index into `hunk.lines`;
    /// empty when word highlighting is off.
    static func emphasis(in hunk: GitDiffHunk, enabled: Bool) -> [Int: [LineViewerRun]] {
        guard enabled else { return [:] }
        var result: [Int: [LineViewerRun]] = [:]
        for pair in GitWordDiff.pairs(in: hunk) {
            let ranges = GitWordDiff.changedRanges(old: hunk.lines[pair.removed].text,
                                                   new: hunk.lines[pair.added].text)
            result[pair.removed] = ranges.old.map { LineViewerRun(range: $0, highlight: .emphasis) }
            result[pair.added] = ranges.new.map { LineViewerRun(range: $0, highlight: .emphasis) }
        }
        return result
    }

    /// Wide enough for the diff's largest line number, and never under 3.
    static func numberWidth(_ diff: GitFileDiff) -> Int {
        let largest = diff.hunks.flatMap(\.lines).reduce(0) { max($0, $1.oldNumber ?? 0, $1.newNumber ?? 0) }
        return max(3, String(largest).count)
    }
}
