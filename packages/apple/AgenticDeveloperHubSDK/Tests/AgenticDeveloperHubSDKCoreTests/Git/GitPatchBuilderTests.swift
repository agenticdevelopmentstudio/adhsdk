import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// `GitPatchBuilder` over hand-built diffs: which lines each direction keeps, drops or
/// turns into context, and the headers it recomputes.
@Suite("GitPatchBuilder")
struct GitPatchBuilderTests {
    // MARK: - Building blocks

    private static func context(_ text: String) -> GitDiffLine {
        GitDiffLine(kind: .context, text: text, oldNumber: 0, newNumber: 0)
    }

    private static func added(_ text: String) -> GitDiffLine {
        GitDiffLine(kind: .added, text: text, oldNumber: nil, newNumber: 0)
    }

    private static func removed(_ text: String) -> GitDiffLine {
        GitDiffLine(kind: .removed, text: text, oldNumber: 0, newNumber: nil)
    }

    private static let marker = GitDiffLine(kind: .noNewlineAtEnd, text: "No newline at end of file",
                                            oldNumber: nil, newNumber: nil)

    private static func hunk(_ old: (Int, Int), _ new: (Int, Int), _ lines: [GitDiffLine]) -> GitDiffHunk {
        GitDiffHunk(oldStart: old.0, oldCount: old.1, newStart: new.0, newCount: new.1, section: "func f()",
                    lines: lines)
    }

    private static func modified(_ hunks: [GitDiffHunk], path: String = "a.txt") -> GitFileDiff {
        GitFileDiff(oldPath: path, newPath: path, change: .modified, isBinary: false, hunks: hunks)
    }

    private static let header = "diff --git a/a.txt b/a.txt\n--- a/a.txt\n+++ b/a.txt\n"

    private static func patch(_ file: GitFileDiff, _ lines: [Int: [Int]], _ direction: GitPatchDirection)
        -> String? {
        GitPatchBuilder.patch(GitPatchSelection(file: file, lines: lines.mapValues { IndexSet($0) }),
                              direction: direction)
    }

    // MARK: - Lines

    /// `a`, `+x`, `+y`, `b`.
    private static let twoAdded = modified([hunk((1, 2), (1, 4),
                                                 [context("a"), added("x"), added("y"), context("b")])])

    @Test("one added line of two: forward drops the other, reverse keeps it as context")
    func oneAddedLineOfTwo() {
        #expect(Self.patch(Self.twoAdded, [0: [1]], .forward) == Self.header + """
            @@ -1,2 +1,3 @@
             a
            +x
             b

            """)
        #expect(Self.patch(Self.twoAdded, [0: [1]], .reverse) == Self.header + """
            @@ -1,3 +1,4 @@
             a
            +x
             y
             b

            """)
    }

    /// `a`, `-b`, `+c`, `d`.
    private static let replaced = modified([hunk((1, 3), (1, 3),
                                                 [context("a"), removed("b"), added("c"), context("d")])])

    @Test("an unselected removal next to a selected addition: context forward, dropped reverse")
    func unselectedRemovalBesideSelectedAddition() {
        #expect(Self.patch(Self.replaced, [0: [2]], .forward) == Self.header + """
            @@ -1,3 +1,4 @@
             a
             b
            +c
             d

            """)
        #expect(Self.patch(Self.replaced, [0: [2]], .reverse) == Self.header + """
            @@ -1,2 +1,3 @@
             a
            +c
             d

            """)
    }

    @Test("a selected removal next to an unselected addition: the addition dropped forward, context reverse")
    func selectedRemovalBesideUnselectedAddition() {
        #expect(Self.patch(Self.replaced, [0: [1]], .forward) == Self.header + """
            @@ -1,3 +1,2 @@
             a
            -b
             d

            """)
        #expect(Self.patch(Self.replaced, [0: [1]], .reverse) == Self.header + """
            @@ -1,4 +1,3 @@
             a
            -b
             c
             d

            """)
    }

    // MARK: - Hunks

    /// Hunk 0 adds two lines at the top; hunk 1 replaces a line further down.
    private static let twoHunks = modified([
        hunk((1, 2), (1, 4), [context("a"), added("x"), added("y"), context("b")]),
        hunk((10, 3), (12, 3), [context("p"), removed("q"), added("r"), context("s")])
    ])

    @Test("a later hunk's other side moves by the net change of the hunks written before it")
    func laterHunkShifts() {
        #expect(Self.patch(Self.twoHunks, [0: [1], 1: [1, 2]], .forward) == Self.header + """
            @@ -1,2 +1,3 @@
             a
            +x
             b
            @@ -10,3 +11,3 @@
             p
            -q
            +r
             s

            """)
        #expect(Self.patch(Self.twoHunks, [0: [1], 1: [1, 2]], .reverse) == Self.header + """
            @@ -1,3 +1,4 @@
             a
            +x
             y
             b
            @@ -11,3 +12,3 @@
             p
            -q
            +r
             s

            """)
    }

    @Test("a hunk with nothing selected is left out and moves nothing")
    func unselectedHunkLeftOut() {
        #expect(Self.patch(Self.twoHunks, [1: [1, 2]], .forward) == Self.header + """
            @@ -10,3 +10,3 @@
             p
            -q
            +r
             s

            """)
        #expect(Self.patch(Self.twoHunks, [0: [0, 3], 1: [1, 2]], .reverse) == Self.header + """
            @@ -12,3 +12,3 @@
             p
            -q
            +r
             s

            """)
    }

    @Test("the hunk selection is every changed line of that hunk")
    func hunkSelection() {
        let selection = GitPatchSelection.hunk(1, of: Self.twoHunks)
        #expect(selection.lines == [1: IndexSet([1, 2])])
        #expect(GitPatchSelection.hunk(5, of: Self.twoHunks).lines.isEmpty)
        #expect(GitPatchBuilder.patch(selection, direction: .forward) == Self.patch(Self.twoHunks, [1: [1, 2]],
                                                                                     .forward))
    }

    // MARK: - No newline at end of file

    /// `+x` at the top, then `a`, `b`, and `+c` as a last line with no newline.
    private static let lastLineWithoutNewline = modified([
        hunk((1, 2), (1, 4), [added("x"), context("a"), context("b"), added("c"), marker])
    ])

    @Test("the no-newline marker goes with its line: kept when the line is, as itself or as context")
    func noNewlineMarker() {
        let marker = "\\ No newline at end of file"
        #expect(Self.patch(Self.lastLineWithoutNewline, [0: [3]], .forward) == Self.header + """
            @@ -1,2 +1,3 @@
             a
             b
            +c
            \(marker)

            """)
        #expect(Self.patch(Self.lastLineWithoutNewline, [0: [0]], .forward) == Self.header + """
            @@ -1,2 +1,3 @@
            +x
             a
             b

            """)
        #expect(Self.patch(Self.lastLineWithoutNewline, [0: [0]], .reverse) == Self.header + """
            @@ -1,3 +1,4 @@
            +x
             a
             b
             c
            \(marker)

            """)
    }

    /// `x`, then `-a` with no newline, `+a`, and `+b` with no newline: appending after an old
    /// side that ended without one.
    private static let appendedAfterNoNewline = modified([
        hunk((1, 2), (1, 3), [context("x"), removed("a"), marker, added("a"), added("b"), marker])
    ])

    @Test("a dropped change that moves one side's end gets that side its own marker")
    func markerFollowsTheMovedEnd() {
        let marker = "\\ No newline at end of file"
        // Forward, `+b` alone: `-a` turns into context that ends the old side without a
        // newline but not the new one, so it is written as `-a` and `+a`.
        #expect(Self.patch(Self.appendedAfterNoNewline, [0: [4]], .forward) == Self.header + """
            @@ -1,2 +1,3 @@
             x
            -a
            \(marker)
            +a
            +b
            \(marker)

            """)
        // Reverse, `+b` alone: `-a` is dropped and `+a` is context, which ends the old side
        // with a newline.
        #expect(Self.patch(Self.appendedAfterNoNewline, [0: [4]], .reverse) == Self.header + """
            @@ -1,2 +1,3 @@
             x
             a
            +b
            \(marker)

            """)
    }

    // MARK: - Files

    /// Naming both paths would make `git apply` rename the file as well: reversed, a staged
    /// rename's line would be unstaged by moving the file back. So a rename's patch names
    /// the path it is applied to on both sides: the old path forward, the new one reversed.
    @Test("a rename's header names the path the patch is applied to, on both sides")
    func renameHeader() {
        let file = GitFileDiff(oldPath: "old name.txt", newPath: "dir/new.txt", change: .renamed(similarity: 90),
                               isBinary: false, hunks: Self.replaced.hunks)
        #expect(GitPatchBuilder.canBuild(for: file))
        #expect(Self.patch(file, [0: [1, 2]], .forward) == """
            diff --git a/old name.txt b/old name.txt
            --- a/old name.txt
            +++ b/old name.txt
            @@ -1,3 +1,3 @@
             a
            -b
            +c
             d

            """)
        #expect(Self.patch(file, [0: [1, 2]], .reverse) == """
            diff --git a/dir/new.txt b/dir/new.txt
            --- a/dir/new.txt
            +++ b/dir/new.txt
            @@ -1,3 +1,3 @@
             a
            -b
            +c
             d

            """)
    }

    @Test("only a modified or renamed text file with hunks and one-line paths can be built")
    func canBuild() {
        let hunks = Self.replaced.hunks
        #expect(GitPatchBuilder.canBuild(for: Self.replaced))
        let refused: [GitFileDiff] = [
            // Added, which is also how an untracked file's diff reads.
            GitFileDiff(oldPath: nil, newPath: "a.txt", change: .added, isBinary: false, hunks: hunks),
            GitFileDiff(oldPath: "a.txt", newPath: nil, change: .deleted, isBinary: false, hunks: hunks),
            GitFileDiff(oldPath: "a.txt", newPath: "a.txt", change: .modified, isBinary: true, hunks: []),
            GitFileDiff(oldPath: "a.txt", newPath: "a.txt", change: .modified, isBinary: true, hunks: hunks),
            GitFileDiff(oldPath: "a.txt", newPath: "b.txt", change: .copied(similarity: 80), isBinary: false,
                        hunks: hunks),
            GitFileDiff(oldPath: "a.txt", newPath: "a.txt", change: .typeChanged, isBinary: false, hunks: hunks),
            GitFileDiff(oldPath: "a.txt", newPath: "b.txt", change: .renamed(similarity: 100), isBinary: false,
                        hunks: []),
            Self.modified(hunks, path: "tab\there.txt"),
            Self.modified(hunks, path: "line\nbreak.txt")
        ]
        for file in refused {
            #expect(!GitPatchBuilder.canBuild(for: file), "\(file.change) \(file.path)")
            #expect(Self.patch(file, [0: [1, 2]], .forward) == nil)
        }
    }

    @Test("nothing selected, or only context selected, is no patch")
    func emptySelection() {
        #expect(Self.patch(Self.twoHunks, [:], .forward) == nil)
        #expect(Self.patch(Self.twoHunks, [0: []], .reverse) == nil)
        #expect(Self.patch(Self.twoHunks, [0: [0, 3], 1: [0, 3, 99]], .forward) == nil)
        #expect(Self.patch(Self.twoHunks, [7: [1]], .forward) == nil)
    }
}
