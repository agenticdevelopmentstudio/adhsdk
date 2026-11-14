import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKLanguage
@testable import AgenticDeveloperHubSDKMacOS

/// Diff fixtures shared by the diff model and view tests.
enum GitDiffFixtures {
    static func context(_ text: String, _ old: Int, _ new: Int) -> GitDiffLine {
        GitDiffLine(kind: .context, text: text, oldNumber: old, newNumber: new)
    }

    static func removed(_ text: String, _ old: Int) -> GitDiffLine {
        GitDiffLine(kind: .removed, text: text, oldNumber: old, newNumber: nil)
    }

    static func added(_ text: String, _ new: Int) -> GitDiffLine {
        GitDiffLine(kind: .added, text: text, oldNumber: nil, newNumber: new)
    }

    /// Recipe vector 040: two hunks, the first with a changed line, the second an insertion.
    static func twoHunks(path: String = "a.swift") -> GitFileDiff {
        let first = GitDiffHunk(oldStart: 1, oldCount: 3, newStart: 1, newCount: 3, section: "func a()", lines: [
            context("let a = 1", 1, 1),
            removed("let b = 2", 2),
            added("let b = 3", 2),
            context("let c = 4", 3, 3)
        ])
        let second = GitDiffHunk(oldStart: 10, oldCount: 2, newStart: 10, newCount: 3, section: "", lines: [
            context("x", 10, 10),
            added("y", 11),
            context("z", 11, 12)
        ])
        return GitFileDiff(oldPath: path, newPath: path, change: .modified, isBinary: false, hunks: [first, second])
    }

    /// Recipe vector 042: three removed lines against one added.
    static func threeForOne() -> GitFileDiff {
        let hunk = GitDiffHunk(oldStart: 1, oldCount: 5, newStart: 1, newCount: 3, section: "", lines: [
            context("c", 1, 1),
            removed("r1 old", 2),
            removed("r2", 3),
            removed("r3", 4),
            added("r1 new", 2),
            context("d", 5, 3)
        ])
        return GitFileDiff(oldPath: "f", newPath: "f", change: .modified, isBinary: false, hunks: [hunk])
    }

    static let binary = GitFileDiff(oldPath: "img.png", newPath: "img.png", change: .modified, isBinary: true,
                                    hunks: [])
}

@Suite("GitDiffLineModels")
@MainActor
struct GitDiffLineModelsTests {

    private typealias Fixture = GitDiffFixtures

    private static let red = RGBAColor(red: 1, green: 0, blue: 0, alpha: 1)
    private static let blue = RGBAColor(red: 0, green: 0, blue: 1, alpha: 1)

    /// `count` lines, line n with one run of length n in `color`.
    private static func styled(_ count: Int, _ color: RGBAColor) -> [StyledLine] {
        (1...count).map { StyledLine(runs: [SyntaxRun(range: NSRange(location: 0, length: $0), foreground: color,
                                                      fontStyle: [])]) }
    }

    private static func rows(_ source: LineViewerDataSource) -> [LineViewerRow] {
        (0..<source.rowCount).map(source.row(at:))
    }

    private static func emphasis(_ row: LineViewerRow) -> [NSRange] {
        row.runs.filter { $0.highlight == .emphasis }.map(\.range)
    }

    // MARK: - Inline

    @Test("inline rows, gutters and backgrounds for a two-hunk diff")
    func inlineRows() {
        let model = GitInlineDiffModel(diff: Fixture.twoHunks(), oldLines: nil, newLines: nil, wordHighlights: false)
        let rows = Self.rows(model)

        #expect(model.gutterColumnCount == 2)
        #expect(rows.map(\.text) == ["@@ -1,3 +1,3 @@ func a()", "let a = 1", "let b = 2", "let b = 3",
                                     "let c = 4", "@@ -10,2 +10,3 @@", "x", "y", "z"])
        #expect(rows.map(\.kind) == [.header, .text, .text, .text, .text, .header, .text, .text, .text])
        #expect(rows.map(\.background) == [.header, .none, .removed, .added, .none, .header, .none, .added, .none])
        #expect(rows.map(\.gutter) == [[], ["1", "1"], ["2", nil], [nil, "2"], ["3", "3"], [],
                                       ["10", "10"], [nil, "11"], ["11", "12"]])
        #expect(rows.allSatisfy { $0.runs.isEmpty })
    }

    @Test("a no-newline marker is a plain row with no gutter values")
    func noNewlineMarker() {
        let hunk = GitDiffHunk(oldStart: 1, oldCount: 1, newStart: 1, newCount: 1, section: "", lines: [
            Fixture.removed("a", 1),
            GitDiffLine(kind: .noNewlineAtEnd, text: " No newline at end of file", oldNumber: nil, newNumber: nil),
            Fixture.added("b", 1)
        ])
        let diff = GitFileDiff(oldPath: "f", newPath: "f", change: .modified, isBinary: false, hunks: [hunk])
        let rows = Self.rows(GitInlineDiffModel(diff: diff, oldLines: nil, newLines: nil, wordHighlights: false))

        #expect(rows[2].text == "\\ No newline at end of file")
        #expect(rows[2].kind == .text)
        #expect(rows[2].background == .none)
        #expect(rows[2].gutter == [])
    }

    @Test("word emphasis ranges are present when on and absent when off")
    func inlineWordEmphasis() {
        let withEmphasis = Self.rows(GitInlineDiffModel(diff: Fixture.twoHunks(), oldLines: nil, newLines: nil,
                                                        wordHighlights: true))
        #expect(Self.emphasis(withEmphasis[2]) == [NSRange(location: 8, length: 1)])
        #expect(Self.emphasis(withEmphasis[3]) == [NSRange(location: 8, length: 1)])
        #expect(withEmphasis[2].runs.allSatisfy { $0.foreground == nil })
        #expect(Self.emphasis(withEmphasis[7]).isEmpty)

        let off = Self.rows(GitInlineDiffModel(diff: Fixture.twoHunks(), oldLines: nil, newLines: nil,
                                               wordHighlights: false))
        #expect(off.allSatisfy { Self.emphasis($0).isEmpty })
    }

    @Test("syntax runs land on the matching old or new line number")
    func inlineSyntaxRuns() throws {
        let old = Self.styled(11, Self.red)
        let new = Self.styled(11, Self.blue)
        let rows = Self.rows(GitInlineDiffModel(diff: Fixture.twoHunks(), oldLines: old, newLines: new,
                                                wordHighlights: true))

        // Context `let a = 1` (1, 1) takes new line 1.
        #expect(rows[1].runs == [LineViewerRun(range: NSRange(location: 0, length: 1), foreground: Self.blue)])
        // Removed old line 2 takes old line 2, then its emphasis.
        #expect(rows[2].runs == [LineViewerRun(range: NSRange(location: 0, length: 2), foreground: Self.red),
                                 LineViewerRun(range: NSRange(location: 8, length: 1), highlight: .emphasis)])
        // Added new line 2 takes new line 2.
        #expect(rows[3].runs.first == LineViewerRun(range: NSRange(location: 0, length: 2), foreground: Self.blue))
        // Added new line 11 takes new line 11.
        #expect(rows[7].runs == [LineViewerRun(range: NSRange(location: 0, length: 11), foreground: Self.blue)])
        // Context (11, 12): new line 12 is past the end, so old line 11.
        #expect(rows[8].runs == [LineViewerRun(range: NSRange(location: 0, length: 11), foreground: Self.red)])
        // Headers carry none.
        #expect(rows[0].runs.isEmpty)
    }

    @Test("a line number past both sides' ends carries no syntax runs")
    func inlineRunsPastTheEnd() {
        let rows = Self.rows(GitInlineDiffModel(diff: Fixture.twoHunks(), oldLines: Self.styled(1, Self.red),
                                                newLines: Self.styled(1, Self.blue), wordHighlights: false))
        #expect(rows[2].runs.isEmpty)
        #expect(rows[3].runs.isEmpty)
        #expect(rows[8].runs.isEmpty)
    }

    @Test("a binary file is one header row")
    func inlineBinary() {
        let model = GitInlineDiffModel(diff: Fixture.binary, oldLines: nil, newLines: nil, wordHighlights: true)
        #expect(Self.rows(model) == [LineViewerRow(kind: .header, text: "Binary file", background: .header)])
    }

    @Test("gutter columns are wide enough for the largest line number")
    func inlineGutterWidth() {
        let hunk = GitDiffHunk(oldStart: 12345, oldCount: 1, newStart: 12345, newCount: 1, section: "", lines: [
            Fixture.context("x", 12345, 12345)
        ])
        let diff = GitFileDiff(oldPath: "f", newPath: "f", change: .modified, isBinary: false, hunks: [hunk])
        let model = GitInlineDiffModel(diff: diff, oldLines: nil, newLines: nil, wordHighlights: false)
        #expect(model.gutterColumnWidth(0) == 5)
        #expect(GitInlineDiffModel(diff: Fixture.twoHunks(), oldLines: nil, newLines: nil,
                                   wordHighlights: false).gutterColumnWidth(1) == 3)
    }

    // MARK: - Side by side

    @Test("side by side aligns three removed lines against one added with fillers")
    func sideBySideFillers() {
        let (left, right) = GitSideBySideDiffModel.make(diff: Fixture.threeForOne(), oldLines: nil, newLines: nil,
                                                        wordHighlights: true)
        let leftRows = Self.rows(left)
        let rightRows = Self.rows(right)

        #expect(left.gutterColumnCount == 1)
        #expect(right.gutterColumnCount == 1)
        #expect(leftRows.count == 6)
        #expect(rightRows.count == 6)
        #expect(leftRows.map(\.text) == ["@@ -1,5 +1,3 @@", "c", "r1 old", "r2", "r3", "d"])
        #expect(rightRows.map(\.text) == ["@@ -1,5 +1,3 @@", "c", "r1 new", "", "", "d"])
        #expect(leftRows.map(\.background) == [.header, .none, .removed, .removed, .removed, .none])
        #expect(rightRows.map(\.background) == [.header, .none, .added, .filler, .filler, .none])
        #expect(leftRows.map(\.gutter) == [[], ["1"], ["2"], ["3"], ["4"], ["5"]])
        #expect(rightRows.map(\.gutter) == [[], ["1"], ["2"], [nil], [nil], ["3"]])
        #expect(Self.emphasis(leftRows[2]) == [NSRange(location: 3, length: 3)])
        #expect(Self.emphasis(rightRows[2]) == [NSRange(location: 3, length: 3)])
        #expect(Self.emphasis(leftRows[3]).isEmpty)
    }

    @Test("side by side without word highlighting carries no emphasis")
    func sideBySideNoEmphasis() {
        let (left, right) = GitSideBySideDiffModel.make(diff: Fixture.threeForOne(), oldLines: nil, newLines: nil,
                                                        wordHighlights: false)
        #expect((Self.rows(left) + Self.rows(right)).allSatisfy { Self.emphasis($0).isEmpty })
    }

    @Test("side by side pads an added-only run on the left")
    func sideBySideAddedOnly() {
        let (left, right) = GitSideBySideDiffModel.make(diff: Fixture.twoHunks(), oldLines: nil, newLines: nil,
                                                        wordHighlights: false)
        let leftRows = Self.rows(left)
        let rightRows = Self.rows(right)
        #expect(leftRows.map(\.text) == ["@@ -1,3 +1,3 @@ func a()", "let a = 1", "let b = 2", "let c = 4",
                                         "@@ -10,2 +10,3 @@", "x", "", "z"])
        #expect(rightRows.map(\.text) == ["@@ -1,3 +1,3 @@ func a()", "let a = 1", "let b = 3", "let c = 4",
                                          "@@ -10,2 +10,3 @@", "x", "y", "z"])
        #expect(leftRows[6].background == .filler)
        #expect(rightRows[6].background == .added)
    }

    @Test("side by side takes syntax runs from each side's own lines")
    func sideBySideSyntaxRuns() {
        let (left, right) = GitSideBySideDiffModel.make(diff: Fixture.twoHunks(), oldLines: Self.styled(11, Self.red),
                                                        newLines: Self.styled(12, Self.blue), wordHighlights: false)
        let leftRows = Self.rows(left)
        let rightRows = Self.rows(right)
        #expect(leftRows[2].runs == [LineViewerRun(range: NSRange(location: 0, length: 2), foreground: Self.red)])
        #expect(rightRows[2].runs == [LineViewerRun(range: NSRange(location: 0, length: 2), foreground: Self.blue)])
        // Context (11, 12): old line 11 on the left, new line 12 on the right.
        #expect(leftRows[7].runs == [LineViewerRun(range: NSRange(location: 0, length: 11), foreground: Self.red)])
        #expect(rightRows[7].runs == [LineViewerRun(range: NSRange(location: 0, length: 12), foreground: Self.blue)])
    }

    @Test("a no-newline marker follows its line's side, with a filler opposite")
    func sideBySideNoNewline() {
        let marker = GitDiffLine(kind: .noNewlineAtEnd, text: " No newline at end of file", oldNumber: nil,
                                 newNumber: nil)
        let hunk = GitDiffHunk(oldStart: 1, oldCount: 1, newStart: 1, newCount: 1, section: "", lines: [
            Fixture.removed("a", 1), marker, Fixture.added("b", 1)
        ])
        let diff = GitFileDiff(oldPath: "f", newPath: "f", change: .modified, isBinary: false, hunks: [hunk])
        let (left, right) = GitSideBySideDiffModel.make(diff: diff, oldLines: nil, newLines: nil,
                                                        wordHighlights: false)
        #expect(Self.rows(left).map(\.text) == ["@@ -1,1 +1,1 @@", "a", "\\ No newline at end of file"])
        #expect(Self.rows(right).map(\.text) == ["@@ -1,1 +1,1 @@", "b", ""])
        #expect(Self.rows(right)[2].background == .filler)
    }

    @Test("a binary file is one header row on each side")
    func sideBySideBinary() {
        let (left, right) = GitSideBySideDiffModel.make(diff: Fixture.binary, oldLines: nil, newLines: nil,
                                                        wordHighlights: false)
        let header = LineViewerRow(kind: .header, text: "Binary file", background: .header)
        #expect(Self.rows(left) == [header])
        #expect(Self.rows(right) == [header])
    }
}
