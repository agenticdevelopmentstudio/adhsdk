import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitConflictKind and GitConflictDocument")
struct GitConflictTests {
    private let twoConflicts = """
        top
        <<<<<<< HEAD
        ours one
        =======
        theirs one
        >>>>>>> topic
        middle
        <<<<<<< HEAD
        ours two
        =======
        theirs two
        >>>>>>> topic
        bottom

        """

    @Test("which sides each kind has, and which kinds carry markers")
    func kinds() {
        #expect(GitConflictKind.allCases.filter(\.hasOurs) == [.bothModified, .bothAdded, .deletedByThem, .addedByUs])
        #expect(GitConflictKind.allCases.filter(\.hasTheirs)
            == [.bothModified, .bothAdded, .deletedByUs, .addedByThem])
        #expect(GitConflictKind.allCases.filter(\.hasMarkers) == [.bothModified, .bothAdded])
        #expect(GitConflictKind(rawValue: "DU") == .deletedByUs)
        #expect(GitConflictKind(rawValue: "MM") == nil)
    }

    @Test("two conflicts with common text between them")
    func twoConflictsWithCommonText() throws {
        let document = try #require(GitConflictDocument.parse(twoConflicts))
        #expect(document.conflictCount == 2)
        #expect(document.endsWithNewline)
        #expect(document.segments == [
            .common(["top"]),
            .conflict(ours: ["ours one"], base: nil, theirs: ["theirs one"], oursLabel: "HEAD", theirsLabel: "topic"),
            .common(["middle"]),
            .conflict(ours: ["ours two"], base: nil, theirs: ["theirs two"], oursLabel: "HEAD", theirsLabel: "topic"),
            .common(["bottom"])
        ])
    }

    @Test("a diff3 base section, and labels with spaces kept")
    func diff3Base() throws {
        let text = "<<<<<<< HEAD:a.txt\nours\n||||||| merged common ancestors\nbase 1\nbase 2\n=======\n"
            + "theirs\n>>>>>>> feature branch\n"
        let document = try #require(GitConflictDocument.parse(text))
        #expect(document.segments == [
            .conflict(ours: ["ours"], base: ["base 1", "base 2"], theirs: ["theirs"], oursLabel: "HEAD:a.txt",
                      theirsLabel: "feature branch")
        ])
        #expect(document.resolved([0: .base]) == "base 1\nbase 2\n")
    }

    @Test("an empty ours side, and markers with no label")
    func emptyOurs() throws {
        let document = try #require(GitConflictDocument.parse("<<<<<<<\n=======\ntheirs\n>>>>>>>\n"))
        #expect(document.segments == [.conflict(ours: [], base: nil, theirs: ["theirs"], oursLabel: "",
                                                theirsLabel: "")])
        #expect(document.resolved([0: .ours]) == "")
        #expect(document.resolved([0: .theirs]) == "theirs\n")
    }

    @Test("no trailing newline is preserved")
    func noTrailingNewline() throws {
        let document = try #require(GitConflictDocument.parse("a\n<<<<<<< x\no\n=======\nt\n>>>>>>> y\nz"))
        #expect(!document.endsWithNewline)
        #expect(document.resolved([0: .theirs]) == "a\nt\nz")
    }

    @Test("an unterminated conflict, or none at all, is no document")
    func unterminated() {
        #expect(GitConflictDocument.parse("a\n<<<<<<< HEAD\nours\n=======\ntheirs\n") == nil)
        #expect(GitConflictDocument.parse("a\n<<<<<<< HEAD\nours\n") == nil)
        #expect(GitConflictDocument.parse("plain\ntext\n") == nil)
        #expect(GitConflictDocument.parse("") == nil)
    }

    @Test("marker-like text outside its place is ordinary text")
    func markerLookalikes() throws {
        let text = "=======\n<<<<<<<< eight\n<<<<<<< HEAD\n<<<<<<< inner\n=======\nt\n>>>>>>> x\n>>>>>>> after\n"
        let document = try #require(GitConflictDocument.parse(text))
        #expect(document.segments == [
            .common(["=======", "<<<<<<<< eight"]),
            .conflict(ours: ["<<<<<<< inner"], base: nil, theirs: ["t"], oursLabel: "HEAD", theirsLabel: "x"),
            .common([">>>>>>> after"])
        ])
    }

    @Test("CRLF lines keep their carriage return and still read as markers")
    func crlf() throws {
        let document = try #require(GitConflictDocument.parse("a\r\n<<<<<<< o\r\nx\r\n=======\r\ny\r\n>>>>>>> t\r\n"))
        #expect(document.endsWithNewline)
        #expect(document.resolved([0: .ours]) == "a\r\nx\r\n")
    }

    @Test("resolved for each choice")
    func resolvedForEachChoice() throws {
        let document = try #require(GitConflictDocument.parse(twoConflicts))
        let expected: [GitConflictDocument.Choice: String] = [
            .ours: "top\nours one\nmiddle\nours two\nbottom\n",
            .theirs: "top\ntheirs one\nmiddle\ntheirs two\nbottom\n",
            .oursThenTheirs: "top\nours one\ntheirs one\nmiddle\nours two\ntheirs two\nbottom\n",
            .theirsThenOurs: "top\ntheirs one\nours one\nmiddle\ntheirs two\nours two\nbottom\n"
        ]
        for (choice, text) in expected {
            #expect(document.resolved([0: choice, 1: choice]) == text, "\(choice)")
        }
        #expect(document.resolved([0: .ours, 1: .theirs]) == "top\nours one\nmiddle\ntheirs two\nbottom\n")
    }

    @Test("a missing choice, or base without a base section, resolves to nil")
    func unresolvable() throws {
        let document = try #require(GitConflictDocument.parse(twoConflicts))
        #expect(document.resolved([0: .ours]) == nil)
        #expect(document.resolved([:]) == nil)
        #expect(document.resolved([0: .ours, 1: .base]) == nil)
    }

    @Test("a real conflict resolved to ours is stage 2's content", .timeLimit(.minutes(1)))
    func roundTripAgainstStageTwo() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-conflict-document")
        defer { repository.tearDown() }
        let base = (1...12).map { "line \($0)" }
        func text(_ lines: [String]) -> String { lines.joined(separator: "\n") + "\n" }
        try repository.write(text(base), to: "a.txt")
        try await repository.run(["add", "a.txt"])
        try await repository.run(["commit", "-q", "-m", "base"])
        try await repository.run(["branch", "topic"])
        var ours = base
        ours[1] = "main 2"
        ours[9] = "main 10"
        try repository.write(text(ours), to: "a.txt")
        try await repository.run(["commit", "-q", "-a", "-m", "main"])
        try await repository.run(["switch", "-q", "topic"])
        var theirs = base
        theirs[1] = "topic 2"
        theirs[9] = "topic 10"
        try repository.write(text(theirs), to: "a.txt")
        try await repository.run(["commit", "-q", "-a", "-m", "topic"])
        try await repository.run(["switch", "-q", "main"])
        await #expect(throws: GitTestRepository.CommandFailed.self) {
            try await repository.run(["merge", "topic"])
        }

        let working = try String(contentsOf: repository.url("a.txt"), encoding: .utf8)
        let document = try #require(GitConflictDocument.parse(working))
        #expect(document.conflictCount == 2)
        var choices: [Int: GitConflictDocument.Choice] = [:]
        for index in 0..<document.conflictCount { choices[index] = .ours }
        let stageTwo = try await repository.run(["show", ":2:a.txt"])
        #expect(document.resolved(choices) == stageTwo)
        #expect(stageTwo == text(ours))
    }
}
