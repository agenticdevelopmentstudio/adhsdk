import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitCommit.parse")
struct GitCommitParserTests {
    private static let unit = "\u{1F}"
    private static let record = "\u{1E}"

    /// One record as `git log --format=GitCommit.logFormat` writes it, before the
    /// newline git appends after each record.
    private static func record(
        sha: String, parents: String, subject: String, body: String,
        authorEpoch: String = "1700000000", committerEpoch: String = "1700000100"
    ) -> String {
        [sha, parents, "Ada", "ada@example.com", authorEpoch,
         "Grace", "grace@example.com", committerEpoch, subject, body]
            .joined(separator: unit) + record
    }

    @Test("the format string is the documented one")
    func logFormat() {
        #expect(GitCommit.logFormat == "%H%x1f%P%x1f%an%x1f%ae%x1f%at%x1f%cn%x1f%ce%x1f%ct%x1f%s%x1f%b%x1e")
    }

    @Test("a merge keeps every parent in order; a root has none")
    func parsesMergeCommitParents() {
        let output = Self.record(sha: "m1", parents: "a b c", subject: "Merge", body: "") + "\n"
            + Self.record(sha: "r1", parents: "", subject: "Root", body: "") + "\n"
        let commits = GitCommit.parse(log: output)
        #expect(commits.map(\.id) == ["m1", "r1"])
        #expect(commits.first?.parents == ["a", "b", "c"])
        #expect(commits.last?.parents == [])
    }

    @Test("a multi-line body survives, a unit separator in the subject survives, dates are epoch seconds")
    func parsesMultilineBodyAndUnitSeparatorsInSubject() throws {
        let subject = "odd\(Self.unit)subject"
        let output = Self.record(
            sha: "0123456789abcdef0123456789abcdef01234567", parents: "p",
            subject: subject, body: "line1\nline2\n"
        ) + "\n"
        let commit = try #require(GitCommit.parse(log: output).first)
        #expect(commit.subject == subject)
        #expect(commit.body == "line1\nline2")
        #expect(commit.author == GitPerson(
            name: "Ada", email: "ada@example.com", date: Date(timeIntervalSince1970: 1_700_000_000)
        ))
        #expect(commit.committer == GitPerson(
            name: "Grace", email: "grace@example.com", date: Date(timeIntervalSince1970: 1_700_000_100)
        ))
        #expect(commit.shortID == "01234567")
    }

    @Test("malformed records are dropped, the rest survive")
    func dropsMalformedRecords() {
        let output = "short\(Self.unit)record\(Self.record)\n"
            + Self.record(sha: "bad", parents: "", subject: "s", body: "", authorEpoch: "x") + "\n"
            + Self.record(sha: "ok", parents: "", subject: "s", body: "") + "\n"
        #expect(GitCommit.parse(log: output).map(\.id) == ["ok"])
    }

    @Test("empty output is no commits")
    func emptyOutput() {
        #expect(GitCommit.parse(log: "").isEmpty)
        #expect(GitCommit.parse(log: "\n").isEmpty)
    }
}
