import Foundation
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage

/// One pane of the merge view: one gutter column of that pane's line numbers.
@MainActor
public final class GitMergePaneModel: LineViewerDataSource {

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

/// The syntax colours of the three texts a conflicted file holds: ours (the common text
/// and every conflict's ours lines), theirs (the common text and the theirs lines) and
/// base (the common text and every base that was recorded). Any may be nil, uncoloured.
public struct GitMergeColours {
    public var ours: [StyledLine]?
    public var theirs: [StyledLine]?
    public var base: [StyledLine]?

    public init(ours: [StyledLine]?, theirs: [StyledLine]?, base: [StyledLine]?) {
        self.ours = ours
        self.theirs = theirs
        self.base = base
    }
}

/// A conflicted file as the merge view's three panes (recipe `workspace/git/git-merge-view`).
///
/// Ours and theirs sit side by side, row for row: the common text on both, plain, and
/// each conflict's two sides padded with `.filler` rows to the same length. A conflict's
/// rows are `.emphasis` until it is chosen; then the chosen side's rows are `.added` and
/// the other's plain (both sides for Both, neither for Base). The result pane is the
/// common text, plain, and each chosen conflict's lines as `.added`; a conflict not yet
/// chosen is one empty `.emphasis` row. With every conflict chosen, the result has one
/// row per line of `GitConflictDocument.resolved(_:)`.
public struct GitMergeLayout {
    public let ours: GitMergePaneModel
    public let theirs: GitMergePaneModel
    public let result: GitMergePaneModel
    /// Each conflict's first row in the ours and theirs panes, by conflict index.
    public let sideStarts: [Int]
    /// Each conflict's first row in the result pane, by conflict index.
    public let resultStarts: [Int]

    @MainActor
    public static func make(document: GitConflictDocument, choices: [Int: GitConflictDocument.Choice],
                            colours: GitMergeColours?) -> GitMergeLayout {
        var builder = Builder(colours: colours)
        var conflict = 0
        for segment in document.segments {
            switch segment {
            case .common(let lines):
                builder.appendCommon(lines)
            case let .conflict(ours, base, theirs, _, _):
                builder.appendConflict(ours: ours, base: base, theirs: theirs, choice: choices[conflict])
                conflict += 1
            }
        }
        return builder.layout()
    }

    /// The three texts the panes colour, in `GitMergeColours`' order: each the common
    /// lines with that side's conflict lines in place, joined by newlines.
    public static func texts(of document: GitConflictDocument) -> (ours: String, theirs: String, base: String) {
        var ours: [String] = []
        var theirs: [String] = []
        var base: [String] = []
        for segment in document.segments {
            switch segment {
            case .common(let lines):
                ours += lines
                theirs += lines
                base += lines
            case let .conflict(oursLines, baseLines, theirsLines, _, _):
                ours += oursLines
                theirs += theirsLines
                base += baseLines ?? []
            }
        }
        return (ours.joined(separator: "\n"), theirs.joined(separator: "\n"), base.joined(separator: "\n"))
    }

    /// The rows of all three panes, built in one pass with each text's line counter.
    private struct Builder {
        let colours: GitMergeColours?
        var oursRows: [LineViewerRow] = []
        var theirsRows: [LineViewerRow] = []
        var resultRows: [LineViewerRow] = []
        var sideStarts: [Int] = []
        var resultStarts: [Int] = []
        var oursLine = 0
        var theirsLine = 0
        var baseLine = 0
        var resultLine = 0

        init(colours: GitMergeColours?) {
            self.colours = colours
        }

        mutating func appendCommon(_ lines: [String]) {
            for line in lines {
                oursLine += 1
                theirsLine += 1
                baseLine += 1
                oursRows.append(Self.row(line, colours?.ours, oursLine, .none))
                theirsRows.append(Self.row(line, colours?.theirs, theirsLine, .none))
                appendResult(line, colours?.ours, oursLine, .none)
            }
        }

        mutating func appendConflict(ours: [String], base: [String]?, theirs: [String],
                                     choice: GitConflictDocument.Choice?) {
            sideStarts.append(oursRows.count)
            resultStarts.append(resultRows.count)
            let backgrounds = Self.backgrounds(for: choice)
            let oursFirst = oursLine + 1
            let theirsFirst = theirsLine + 1
            let baseFirst = baseLine + 1
            for line in ours {
                oursLine += 1
                oursRows.append(Self.row(line, colours?.ours, oursLine, backgrounds.ours))
            }
            for line in theirs {
                theirsLine += 1
                theirsRows.append(Self.row(line, colours?.theirs, theirsLine, backgrounds.theirs))
            }
            baseLine += base?.count ?? 0
            let height = max(ours.count, theirs.count)
            oursRows += Array(repeating: GitDiffRows.filler, count: height - ours.count)
            theirsRows += Array(repeating: GitDiffRows.filler, count: height - theirs.count)

            let oursPick = (ours, colours?.ours, oursFirst)
            let theirsPick = (theirs, colours?.theirs, theirsFirst)
            let picks: [([String], [StyledLine]?, Int)]?
            switch choice {
            case .ours: picks = [oursPick]
            case .theirs: picks = [theirsPick]
            case .oursThenTheirs: picks = [oursPick, theirsPick]
            case .theirsThenOurs: picks = [theirsPick, oursPick]
            case .base: picks = base.map { [($0, colours?.base, baseFirst)] }
            case nil: picks = nil
            }
            guard let picks else {
                resultRows.append(LineViewerRow(text: "", background: .emphasis, gutter: [nil]))
                return
            }
            for (lines, styled, first) in picks {
                for (offset, line) in lines.enumerated() {
                    appendResult(line, styled, first + offset, .added)
                }
            }
        }

        mutating func appendResult(_ line: String, _ styled: [StyledLine]?, _ number: Int,
                                   _ background: LineViewerBackground) {
            resultLine += 1
            resultRows.append(LineViewerRow(text: line, runs: GitDiffRows.syntax(styled, number) ?? [],
                                            background: background, gutter: [String(resultLine)]))
        }

        /// The ours and theirs backgrounds of a conflict chosen as `choice`.
        static func backgrounds(
            for choice: GitConflictDocument.Choice?
        ) -> (ours: LineViewerBackground, theirs: LineViewerBackground) {
            switch choice {
            case nil: (.emphasis, .emphasis)
            case .ours: (.added, .none)
            case .theirs: (.none, .added)
            case .oursThenTheirs, .theirsThenOurs: (.added, .added)
            case .base: (.none, .none)
            }
        }

        static func row(_ line: String, _ styled: [StyledLine]?, _ number: Int,
                        _ background: LineViewerBackground) -> LineViewerRow {
            LineViewerRow(text: line, runs: GitDiffRows.syntax(styled, number) ?? [], background: background,
                          gutter: [String(number)])
        }

        @MainActor
        func layout() -> GitMergeLayout {
            let largest = max(oursLine, theirsLine, resultLine)
            let width = max(3, String(largest).count)
            return GitMergeLayout(ours: GitMergePaneModel(rows: oursRows, numberWidth: width),
                                  theirs: GitMergePaneModel(rows: theirsRows, numberWidth: width),
                                  result: GitMergePaneModel(rows: resultRows, numberWidth: width),
                                  sideStarts: sideStarts, resultStarts: resultStarts)
        }
    }
}
