import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitWordDiff")
struct GitWordDiffTests {
    @Test("within a budget: the same ranges as unbudgeted, with the table's cells spent")
    func budgetedPairMatchesUnbudgeted() throws {
        var budget = GitWordDiff.Budget()
        let ranges = try #require(GitWordDiff.changedRanges(old: "let x = 1", new: "let y = 1", budget: &budget))
        let plain = GitWordDiff.changedRanges(old: "let x = 1", new: "let y = 1")
        #expect(ranges.old == plain.old)
        #expect(ranges.new == plain.new)
        #expect(budget.remainingCells < GitWordDiff.Budget.maximumDiffCells)
    }

    @Test("a line over the length limit, a pair over the table limit, or a spent budget: no ranges")
    func overBudgetIsNil() {
        var budget = GitWordDiff.Budget()
        let long = String(repeating: "x", count: GitWordDiff.Budget.maximumLineLength + 1)
        #expect(GitWordDiff.changedRanges(old: long, new: "y", budget: &budget) == nil)
        #expect(budget.remainingCells == GitWordDiff.Budget.maximumDiffCells)

        // About 400 tokens a side, under the length limit: a table of some 160,000 cells.
        let old = (0..<200).map { "a\($0)" }.joined(separator: " ")
        let new = (0..<200).map { "b\($0)" }.joined(separator: " ")
        #expect(old.utf16.count <= GitWordDiff.Budget.maximumLineLength)
        #expect(GitWordDiff.changedRanges(old: old, new: new, budget: &budget) == nil)
        #expect(budget.remainingCells == GitWordDiff.Budget.maximumDiffCells)

        var spent = GitWordDiff.Budget(cells: 1)
        #expect(GitWordDiff.changedRanges(old: "one two", new: "three four", budget: &spent) == nil)
        #expect(spent.remainingCells == 1)
    }
    @Test("only the changed word is marked, in UTF-16 offsets")
    func changedRangesMarksOnlyTheChangedWord() {
        let changed = GitWordDiff.changedRanges(old: "let x = 1", new: "let y = 1")
        #expect(changed.old == [NSRange(location: 4, length: 1)])
        #expect(changed.new == [NSRange(location: 4, length: 1)])

        let same = GitWordDiff.changedRanges(old: "same line", new: "same line")
        #expect(same.old.isEmpty)
        #expect(same.new.isEmpty)

        let emoji = GitWordDiff.changedRanges(old: "a 😀 b", new: "a 😀 c")
        #expect(emoji.old == [NSRange(location: 5, length: 1)])
        #expect(emoji.new == [NSRange(location: 5, length: 1)])
    }

    @Test("adjacent changed tokens merge; insertions mark only the new side")
    func mergesAdjacentAndInsertions() {
        let merged = GitWordDiff.changedRanges(old: "foo(bar)", new: "foo[baz]")
        #expect(merged.old == [NSRange(location: 3, length: 5)])
        #expect(merged.new == [NSRange(location: 3, length: 5)])

        let inserted = GitWordDiff.changedRanges(old: "a b", new: "a new b")
        #expect(inserted.old.isEmpty)
        #expect(inserted.new == [NSRange(location: 2, length: 4)])
    }

    @Test("the i-th removed line pairs with the i-th added line of each block")
    func pairsRemovedWithAdded() {
        func line(_ kind: GitDiffLine.Kind, _ text: String) -> GitDiffLine {
            GitDiffLine(kind: kind, text: text, oldNumber: nil, newNumber: nil)
        }
        let hunk = GitDiffHunk(
            oldStart: 1, oldCount: 3, newStart: 1, newCount: 3, section: "",
            lines: [line(.removed, "a"), line(.removed, "b"), line(.added, "c"), line(.context, "x"), line(.added, "d")]
        )
        let pairs = GitWordDiff.pairs(in: hunk)
        #expect(pairs.map(\.removed) == [0])
        #expect(pairs.map(\.added) == [2])

        let noNewline = GitDiffHunk(
            oldStart: 1, oldCount: 1, newStart: 1, newCount: 1, section: "",
            lines: [line(.removed, "a"), line(.noNewlineAtEnd, ""), line(.added, "b"), line(.noNewlineAtEnd, "")]
        )
        let across = GitWordDiff.pairs(in: noNewline)
        #expect(across.map(\.removed) == [0])
        #expect(across.map(\.added) == [2])
    }
}
