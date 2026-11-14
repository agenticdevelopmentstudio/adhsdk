import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitFileListItem")
struct GitFileListItemTests {

    private static func diff(_ old: String?, _ new: String?, _ change: GitFileDiff.Change) -> GitFileDiff {
        GitFileDiff(oldPath: old, newPath: new, change: change, isBinary: false, hunks: [])
    }

    @Test("a working-copy change keeps its path and status and has no old path")
    func fromChange() {
        let modified = GitFileListItem(change: GitFileChange(path: "a.swift", status: .modified))
        #expect(modified == GitFileListItem(path: "a.swift", oldPath: nil, status: .modified))
        #expect(modified.title == "a.swift")
        #expect(modified.id == "a.swift")

        let untracked = GitFileListItem(change: GitFileChange(path: "new file.txt", status: .untracked))
        #expect(untracked == GitFileListItem(path: "new file.txt", oldPath: nil, status: .untracked))
    }

    @Test("a diff maps its change to a status, and only a rename or copy keeps a differing old path")
    func fromDiff() {
        #expect(GitFileListItem(diff: Self.diff(nil, "b", .added))
                == GitFileListItem(path: "b", oldPath: nil, status: .added))
        #expect(GitFileListItem(diff: Self.diff("old.c", nil, .deleted))
                == GitFileListItem(path: "old.c", oldPath: nil, status: .deleted))
        #expect(GitFileListItem(diff: Self.diff("m.py", "m.py", .modified))
                == GitFileListItem(path: "m.py", oldPath: nil, status: .modified))
        #expect(GitFileListItem(diff: Self.diff("link", "link", .typeChanged))
                == GitFileListItem(path: "link", oldPath: nil, status: .modified))

        let renamed = GitFileListItem(diff: Self.diff("src/a.swift", "src/b.swift", .renamed(similarity: 90)))
        #expect(renamed == GitFileListItem(path: "src/b.swift", oldPath: "src/a.swift", status: .renamed))
        #expect(renamed.title == "src/a.swift → src/b.swift")
        #expect(renamed.id == "src/b.swift")

        #expect(GitFileListItem(diff: Self.diff("x", "y", .copied(similarity: 100)))
                == GitFileListItem(path: "y", oldPath: "x", status: .copied))

        let same = GitFileListItem(diff: Self.diff("same", "same", .renamed(similarity: 100)))
        #expect(same == GitFileListItem(path: "same", oldPath: nil, status: .renamed))
        #expect(same.title == "same")
    }

    @Test("awkward paths pass through untouched")
    func awkwardPaths() {
        let path = "ünï cødé/a\tb\nc.json"
        let item = GitFileListItem(diff: Self.diff("x y.json", path, .renamed(similarity: 50)))
        #expect(item.path == path)
        #expect(item.title == "x y.json → " + path)
    }

    @Test("--name-status -z output: one item per file, rename and copy with their old path")
    func parseNameStatus() {
        let output = ["M", "m.swift", "A", "new file.txt", "D", "gone.c", "T", "link",
                      "R087", "old\tname.txt", "new\nname.txt", "C100", "src.c", "copy.c",
                      "R100", "same", "same", ""].joined(separator: "\0")
        #expect(GitFileListItem.parse(nameStatus: output) == [
            GitFileListItem(path: "m.swift", oldPath: nil, status: .modified),
            GitFileListItem(path: "new file.txt", oldPath: nil, status: .added),
            GitFileListItem(path: "gone.c", oldPath: nil, status: .deleted),
            GitFileListItem(path: "link", oldPath: nil, status: .modified),
            GitFileListItem(path: "new\nname.txt", oldPath: "old\tname.txt", status: .renamed),
            GitFileListItem(path: "copy.c", oldPath: "src.c", status: .copied),
            GitFileListItem(path: "same", oldPath: nil, status: .renamed)
        ])
    }

    @Test("--name-status -z output: empty is no files, and a truncated record is dropped")
    func parseNameStatusEdges() {
        #expect(GitFileListItem.parse(nameStatus: "").isEmpty)
        #expect(GitFileListItem.parse(nameStatus: "M\0a.txt\0R100\0only-old\0") == [
            GitFileListItem(path: "a.txt", oldPath: nil, status: .modified)
        ])
    }
}
