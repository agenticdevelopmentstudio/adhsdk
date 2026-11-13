import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitDiff.parse")
struct GitDiffParserTests {
    // git appends a tab to a ---/+++ path that contains a space.
    private static let patch = """
        diff --git a/src/x.swift b/src/x.swift
        index 1111111..2222222 100644
        --- a/src/x.swift
        +++ b/src/x.swift
        @@ -3,4 +3,5 @@ func x()
         let a = 1
        -let b = 2
        +let b = 3
        +let c = 4
         let d = 5
         let e = 6
        @@ -20,2 +21,2 @@
         tail
        -old end
        \\ No newline at end of file
        +new end
        \\ No newline at end of file
        diff --git a/added.txt b/added.txt
        new file mode 100644
        index 0000000..3333333
        --- /dev/null
        +++ b/added.txt
        @@ -0,0 +1,2 @@
        +one
        +two
        diff --git a/gone.txt b/gone.txt
        deleted file mode 100644
        index 4444444..0000000
        --- a/gone.txt
        +++ /dev/null
        @@ -1 +0,0 @@
        -bye
        diff --git a/old name.txt b/new name.txt
        similarity index 87%
        rename from old name.txt
        rename to new name.txt
        index 5555555..6666666 100644
        --- a/old name.txt\t
        +++ b/new name.txt\t
        @@ -1 +1 @@
        -hello
        +hullo

        """

    @Test("modified, added, deleted and renamed files with their hunks and line numbers")
    func parsesModifiedAddedDeletedRenamed() throws {
        let files = GitDiff.parse(patch: Self.patch).files
        try #require(files.count == 4)

        let modified = files[0]
        #expect(modified.change == .modified)
        #expect(modified.oldPath == "src/x.swift")
        #expect(modified.newPath == "src/x.swift")
        #expect(modified.path == "src/x.swift")
        #expect(modified.id == "src/x.swift")
        #expect(!modified.isBinary)
        try #require(modified.hunks.count == 2)
        let first = modified.hunks[0]
        #expect(first.oldStart == 3)
        #expect(first.oldCount == 4)
        #expect(first.newStart == 3)
        #expect(first.newCount == 5)
        #expect(first.section == "func x()")
        #expect(first.lines == [
            GitDiffLine(kind: .context, text: "let a = 1", oldNumber: 3, newNumber: 3),
            GitDiffLine(kind: .removed, text: "let b = 2", oldNumber: 4, newNumber: nil),
            GitDiffLine(kind: .added, text: "let b = 3", oldNumber: nil, newNumber: 4),
            GitDiffLine(kind: .added, text: "let c = 4", oldNumber: nil, newNumber: 5),
            GitDiffLine(kind: .context, text: "let d = 5", oldNumber: 5, newNumber: 6),
            GitDiffLine(kind: .context, text: "let e = 6", oldNumber: 6, newNumber: 7)
        ])
        let second = modified.hunks[1]
        #expect(second.section == "")
        #expect(second.oldStart == 20)
        #expect(second.newStart == 21)
        #expect(second.lines.map(\.kind) == [.context, .removed, .noNewlineAtEnd, .added, .noNewlineAtEnd])
        #expect(second.lines[1] == GitDiffLine(kind: .removed, text: "old end", oldNumber: 21, newNumber: nil))
        #expect(second.lines[2].oldNumber == nil)
        #expect(second.lines[2].newNumber == nil)
        #expect(second.lines[3] == GitDiffLine(kind: .added, text: "new end", oldNumber: nil, newNumber: 22))

        let added = files[1]
        #expect(added.change == .added)
        #expect(added.oldPath == nil)
        #expect(added.newPath == "added.txt")
        #expect(added.path == "added.txt")
        #expect(added.hunks.first?.lines == [
            GitDiffLine(kind: .added, text: "one", oldNumber: nil, newNumber: 1),
            GitDiffLine(kind: .added, text: "two", oldNumber: nil, newNumber: 2)
        ])
        #expect(added.hunks.first?.oldCount == 0)

        let deleted = files[2]
        #expect(deleted.change == .deleted)
        #expect(deleted.oldPath == "gone.txt")
        #expect(deleted.newPath == nil)
        #expect(deleted.path == "gone.txt")
        #expect(deleted.hunks.first?.lines == [GitDiffLine(kind: .removed, text: "bye", oldNumber: 1, newNumber: nil)])
        #expect(deleted.hunks.first?.newCount == 0)

        let renamed = files[3]
        #expect(renamed.change == .renamed(similarity: 87))
        #expect(renamed.oldPath == "old name.txt")
        #expect(renamed.newPath == "new name.txt")
        #expect(renamed.path == "new name.txt")
        #expect(renamed.hunks.first?.lines.map(\.text) == ["hello", "hullo"])
    }

    @Test("a binary file is one header with no hunks")
    func parsesBinaryFile() throws {
        let patch = """
            diff --git a/img.png b/img.png
            index 1111111..2222222 100644
            Binary files a/img.png and b/img.png differ

            """
        let files = GitDiff.parse(patch: patch).files
        try #require(files.count == 1)
        #expect(files[0].isBinary)
        #expect(files[0].hunks.isEmpty)
        #expect(files[0].path == "img.png")
        #expect(files[0].change == .modified)
    }

    @Test("C-quoted paths are unquoted, tabs and octal UTF-8 bytes included")
    func unquotesQuotedPaths() throws {
        let patch = #"""
            diff --git "a/t\tab" "b/t\tab"
            index 1111111..2222222 100644
            --- "a/t\tab"
            +++ "b/t\tab"
            @@ -1 +1 @@
            -x
            +y
            diff --git "a/\303\274.txt" "b/\303\274.txt"
            index 3333333..4444444 100644
            Binary files "a/\303\274.txt" and "b/\303\274.txt" differ

            """#
        let files = GitDiff.parse(patch: patch).files
        try #require(files.count == 2)
        #expect(files[0].path == "t\tab")
        #expect(files[0].oldPath == "t\tab")
        #expect(files[0].hunks.count == 1)
        #expect(files[1].path == "ü.txt")
        #expect(files[1].oldPath == "ü.txt")
        #expect(GitPathUnquoting.unquote(#""a\\b\"c""#) == #"a\b"c"#)
        #expect(GitPathUnquoting.unquote("plain name") == "plain name")
    }

    @Test("a mode-only change is modified with no hunks")
    func parsesModeOnlyChange() throws {
        let patch = """
            diff --git a/run.sh b/run.sh
            old mode 100644
            new mode 100755
            diff --git a/link b/link
            old mode 100644
            new mode 120000

            """
        let files = GitDiff.parse(patch: patch).files
        try #require(files.count == 2)
        #expect(files[0].change == .modified)
        #expect(files[0].hunks.isEmpty)
        #expect(!files[0].isBinary)
        #expect(files[0].path == "run.sh")
        #expect(files[1].change == .typeChanged)
    }

    @Test("a copy carries its similarity; empty input has no files")
    func parsesCopyAndEmpty() throws {
        let patch = """
            diff --git a/a.txt b/b.txt
            similarity index 100%
            copy from a.txt
            copy to b.txt

            """
        let files = GitDiff.parse(patch: patch).files
        try #require(files.count == 1)
        #expect(files[0].change == .copied(similarity: 100))
        #expect(files[0].oldPath == "a.txt")
        #expect(files[0].newPath == "b.txt")
        #expect(GitDiff.parse(patch: "").files.isEmpty)
    }
}
