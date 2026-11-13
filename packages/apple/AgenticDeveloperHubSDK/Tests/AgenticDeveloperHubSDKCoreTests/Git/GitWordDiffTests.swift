import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitWordDiff")
struct GitWordDiffTests {
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
