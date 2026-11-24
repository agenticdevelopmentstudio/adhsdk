import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitBlame.parse")
struct GitBlameParserTests {
    private static let first = String(repeating: "a", count: 40)
    private static let second = String(repeating: "b", count: 40)

    private static let porcelain = [
        "\(first) 1 1 2",
        "author Alice Example",
        "author-mail <alice@example.com>",
        "author-time 1700000000",
        "author-tz +0000",
        "committer Alice Example",
        "committer-mail <alice@example.com>",
        "committer-time 1700000000",
        "committer-tz +0000",
        "summary First commit",
        "boundary",
        "filename f.txt",
        "\tline one",
        "\(first) 2 2",
        "\tline two",
        "\(second) 5 3 1",
        "author Bob",
        "author-mail <bob@example.com>",
        "author-time 1700000100",
        "author-tz +0100",
        "committer Bob",
        "committer-mail <bob@example.com>",
        "committer-time 1700000100",
        "committer-tz +0100",
        "summary Second commit",
        "previous \(first) old name.txt",
        "filename f.txt",
        "\tline three",
        ""
    ].joined(separator: "\n")

    @Test("lines map to commits, repeated headers reuse metadata, runs group consecutive lines")
    func parsesPorcelain() throws {
        let blame = GitBlame.parse(porcelain: Self.porcelain)
        #expect(blame.lines == [
            GitBlame.Line(commitID: Self.first, originalLine: 1, finalLine: 1, text: "line one"),
            GitBlame.Line(commitID: Self.first, originalLine: 2, finalLine: 2, text: "line two"),
            GitBlame.Line(commitID: Self.second, originalLine: 5, finalLine: 3, text: "line three")
        ])
        #expect(blame.commits.count == 2)
        let one = try #require(blame.commits[Self.first])
        #expect(one.id == Self.first)
        #expect(one.author == GitPerson(name: "Alice Example", email: "alice@example.com",
                                        date: Date(timeIntervalSince1970: 1_700_000_000)))
        #expect(one.summary == "First commit")
        #expect(one.previous == nil)
        let two = try #require(blame.commits[Self.second])
        #expect(two.author.name == "Bob")
        #expect(two.summary == "Second commit")
        #expect(two.previous == GitBlame.Commit.Previous(id: Self.first, path: "old name.txt"))
        #expect(blame.runs == [
            GitBlame.Run(commitID: Self.first, finalLines: 1...2),
            GitBlame.Run(commitID: Self.second, finalLines: 3...3)
        ])
    }

    @Test("empty input is an empty blame")
    func parsesEmpty() {
        let blame = GitBlame.parse(porcelain: "")
        #expect(blame.lines.isEmpty)
        #expect(blame.commits.isEmpty)
        #expect(blame.runs.isEmpty)
    }
}
