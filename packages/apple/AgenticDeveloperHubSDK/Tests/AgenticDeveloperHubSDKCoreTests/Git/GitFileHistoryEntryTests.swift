import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitFileHistoryEntry.parse")
struct GitFileHistoryEntryTests {
    private static let unit = "\u{1F}"

    /// One record as `git log --format=GitCommit.logFormat --name-status` writes it: the
    /// record, git's newline, then a blank line and the commit's status lines, if any.
    private static func record(_ sha: String, _ subject: String, status: [String] = []) -> String {
        let fields = [sha, "", "Ada", "ada@example.com", "1700000000", "Ada", "ada@example.com", "1700000000",
                      subject, "body line\nsecond line"]
        let record = fields.joined(separator: unit) + "\u{1E}\n"
        return status.isEmpty ? record : record + "\n" + status.joined(separator: "\n") + "\n"
    }

    @Test("each commit carries the file's path then, and a rename carries both paths")
    func renameChain() {
        let output = Self.record("c4", "Edit", status: ["M\tnew name.txt"])
            + Self.record("c3", "Merge")
            + Self.record("c2", "Rename", status: ["R087\tmid.txt\tnew name.txt"])
            + Self.record("c1", "Copy", status: ["C100\told.txt\tmid.txt"])
            + Self.record("c0", "Add", status: ["A\told.txt"])
        let entries = GitFileHistoryEntry.parse(log: output, path: "new name.txt")
        #expect(entries.map(\.commit.id) == ["c4", "c3", "c2", "c1", "c0"])
        #expect(entries.map(\.commit.body) == Array(repeating: "body line\nsecond line", count: 5))
        #expect(entries.map(\.path) == ["new name.txt", "new name.txt", "new name.txt", "mid.txt", "old.txt"])
        #expect(entries.map(\.oldPath) == [nil, nil, "mid.txt", "old.txt", nil])
        #expect(entries[2].paths == ["mid.txt", "new name.txt"])
        #expect(entries[4].paths == ["old.txt"])
    }

    @Test("quoted status paths are unquoted")
    func quotedPaths() {
        let output = Self.record("c1", "Rename", status: ["R100\t\"caf\\303\\251.txt\"\t\"tab\\there.txt\""])
        let entries = GitFileHistoryEntry.parse(log: output, path: "tab\there.txt")
        #expect(entries.first?.path == "tab\there.txt")
        #expect(entries.first?.oldPath == "café.txt")
    }

    @Test("empty output is an empty history")
    func empty() {
        #expect(GitFileHistoryEntry.parse(log: "", path: "a").isEmpty)
    }
}
