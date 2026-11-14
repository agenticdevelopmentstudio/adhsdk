import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKLanguage
@testable import AgenticDeveloperHubSDKMacOS

@Suite("GitSyntaxColoring")
@MainActor
struct GitSyntaxColoringTests {

    // MARK: - lines(for:path:)

    @Test("a known language is coloured line by line")
    func colorsKnownLanguage() async throws {
        let coloring = try GitTextMateFixture.coloring()
        let lines = try #require(await coloring.lines(for: Data("let x = 1".utf8), path: "a.swift"))
        #expect(lines.count == 1)
        #expect(lines.first?.runs.first?.range == NSRange(location: 0, length: 3))
    }

    @Test("an unknown language gives nil")
    func unknownLanguage() async throws {
        let coloring = try GitTextMateFixture.coloring()
        #expect(await coloring.lines(for: Data("let x = 1".utf8), path: "a.unknownext") == nil)
    }

    @Test("nil data gives nil")
    func nilData() async throws {
        let coloring = try GitTextMateFixture.coloring()
        #expect(await coloring.lines(for: nil, path: "a.swift") == nil)
    }

    @Test("data over the byte limit gives nil")
    func overByteLimit() async throws {
        let coloring = try GitTextMateFixture.coloring()
        let data = Data(repeating: UInt8(ascii: "a"), count: SyntaxHighlighter.maximumBytes + 1)
        #expect(await coloring.lines(for: data, path: "a.swift") == nil)
    }

    @Test("a line over the length limit gives nil")
    func overLineLimit() async throws {
        let coloring = try GitTextMateFixture.coloring()
        let data = Data(String(repeating: "a", count: SyntaxHighlighter.maximumLineLength + 1).utf8)
        #expect(await coloring.lines(for: data, path: "a.swift") == nil)
    }

    @Test("non-UTF-8 content is decoded as Latin-1 and still coloured")
    func latin1() async throws {
        let coloring = try GitTextMateFixture.coloring()
        let data = try #require("let é = 1".data(using: .isoLatin1))
        #expect(String(data: data, encoding: .utf8) == nil)
        let lines = try #require(await coloring.lines(for: data, path: "a.swift"))
        #expect(lines.count == 1)
        #expect(!(lines.first?.runs.isEmpty ?? true))
    }

    // MARK: - Revisions

    @Test("each diff target reads its old and new sides from the right revisions")
    func revisions() {
        typealias Rev = GitSyntaxColoring.Revision
        #expect(GitSyntaxColoring.revisions(for: .unstaged(paths: [])) == (old: Rev.at(":0"), new: Rev.workingFile))
        #expect(GitSyntaxColoring.revisions(for: .staged(paths: [])) == (old: Rev.at("HEAD"), new: Rev.at(":0")))
        #expect(GitSyntaxColoring.revisions(for: .untracked(path: "a")) == (old: Rev.absent, new: Rev.workingFile))
        #expect(GitSyntaxColoring.revisions(for: .commit("c1", paths: [])) == (old: Rev.at("c1^1"), new: Rev.at("c1")))
        #expect(GitSyntaxColoring.revisions(for: .range(from: "a1", to: "b2", paths: []))
                == (old: Rev.at("a1"), new: Rev.at("b2")))
    }

    @Test("a rename reads the old path at the parent and the new path at the commit")
    func sidesOfRename() async throws {
        let coloring = try GitTextMateFixture.coloring()
        let source = GitViewsFakeContentSource()
        source.files = ["old.swift@c1^1": Data("let a = 1".utf8), "new.swift@c1": Data("let b = 2\nlet c = 3".utf8)]
        let diff = GitFileDiff(oldPath: "old.swift", newPath: "new.swift", change: .renamed(similarity: 90),
                               isBinary: false, hunks: [])
        let sides = await coloring.sides(of: diff, target: .commit("c1", paths: []), source: source)

        #expect(source.contentsRequests == ["old.swift@c1^1", "new.swift@c1"])
        #expect(sides.old?.count == 1)
        #expect(sides.new?.count == 2)
    }

    @Test("an added file reads only its new side, and a working file reads with no revision")
    func sidesOfAddedAndWorking() async throws {
        let coloring = try GitTextMateFixture.coloring()
        let source = GitViewsFakeContentSource()
        let added = GitFileDiff(oldPath: nil, newPath: "a.swift", change: .added, isBinary: false, hunks: [])
        _ = await coloring.sides(of: added, target: .commit("c1", paths: []), source: source)
        #expect(source.contentsRequests == ["a.swift@c1"])

        let modified = GitFileDiff(oldPath: "a.swift", newPath: "a.swift", change: .modified, isBinary: false,
                                   hunks: [])
        _ = await coloring.sides(of: modified, target: .unstaged(paths: []), source: source)
        #expect(source.contentsRequests == ["a.swift@c1", "a.swift@:0", "a.swift@"])
    }

    @Test("a side whose contents fail is nil, the other still coloured")
    func sidesWithFailure() async throws {
        let coloring = try GitTextMateFixture.coloring()
        let source = GitViewsFakeContentSource()
        source.failing = ["contents:a.swift@c1^1"]
        source.files = ["a.swift@c1": Data("let a = 1".utf8)]
        let diff = GitFileDiff(oldPath: "a.swift", newPath: "a.swift", change: .modified, isBinary: false, hunks: [])
        let sides = await coloring.sides(of: diff, target: .commit("c1", paths: []), source: source)
        #expect(sides.old == nil)
        #expect(sides.new?.count == 1)
    }
}
