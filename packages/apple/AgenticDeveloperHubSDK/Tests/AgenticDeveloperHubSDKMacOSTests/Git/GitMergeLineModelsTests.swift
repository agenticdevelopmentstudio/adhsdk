import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKLanguage
@testable import AgenticDeveloperHubSDKMacOS

/// Two conflicts: the first two ours lines against one theirs line, the second with a base.
let gitMergeFixtureText = """
top
<<<<<<< HEAD
ours one
ours two
=======
theirs one
>>>>>>> side
middle
<<<<<<< HEAD
x
||||||| base
y
=======
z
>>>>>>> side
bottom

"""

/// The number of lines `text` holds, a final newline ending the last one.
func gitMergeLineCount(_ text: String) -> Int {
    guard !text.isEmpty else { return 0 }
    return text.components(separatedBy: "\n").count - (text.hasSuffix("\n") ? 1 : 0)
}

/// The merge view's rows (recipe `workspace/git/git-merge-view`, "Rows").
@Suite("GitMergeLineModels")
@MainActor
struct GitMergeLineModelsTests {

    private func document() throws -> GitConflictDocument {
        try #require(GitConflictDocument.parse(gitMergeFixtureText))
    }

    @Test("ours and theirs are aligned: common rows on both, the shorter side padded with fillers")
    func alignedRows() throws {
        let layout = GitMergeLayout.make(document: try document(), choices: [:], colours: nil)

        #expect(layout.ours.rows.map(\.text) == ["top", "ours one", "ours two", "middle", "x", "bottom"])
        #expect(layout.theirs.rows.map(\.text) == ["top", "theirs one", "", "middle", "z", "bottom"])
        try #require(layout.theirs.rowCount == 6)
        #expect(layout.theirs.rows[2].background == .filler)
        #expect(layout.theirs.rows[2].gutter == [nil])
        #expect(layout.ours.rows.map(\.gutter) == [["1"], ["2"], ["3"], ["4"], ["5"], ["6"]])
        #expect(layout.theirs.rows.map(\.gutter) == [["1"], ["2"], [nil], ["3"], ["4"], ["5"]])
        #expect(layout.sideStarts == [1, 4])
        #expect(layout.ours.gutterColumnCount == 1)
        #expect(layout.ours.gutterColumnWidth(0) == 3)
    }

    @Test("an unchosen conflict is emphasis on both sides and one emphasis row in the result; common is plain")
    func unchosenBackgrounds() throws {
        let layout = GitMergeLayout.make(document: try document(), choices: [:], colours: nil)

        #expect(layout.ours.rows.map(\.background) == [.none, .emphasis, .emphasis, .none, .emphasis, .none])
        #expect(layout.theirs.rows.map(\.background) == [.none, .emphasis, .filler, .none, .emphasis, .none])
        #expect(layout.result.rows.map(\.text) == ["top", "", "middle", "", "bottom"])
        #expect(layout.result.rows.map(\.background) == [.none, .emphasis, .none, .emphasis, .none])
        #expect(layout.resultStarts == [1, 3])
    }

    @Test("a chosen conflict is added on the chosen side and plain on the other, and fills the result")
    func chosenBackgrounds() throws {
        let layout = GitMergeLayout.make(document: try document(), choices: [0: .theirs, 1: .ours], colours: nil)

        #expect(layout.ours.rows.map(\.background) == [.none, .none, .none, .none, .added, .none])
        #expect(layout.theirs.rows.map(\.background) == [.none, .added, .filler, .none, .none, .none])
        #expect(layout.result.rows.map(\.text) == ["top", "theirs one", "middle", "x", "bottom"])
        #expect(layout.result.rows.map(\.background) == [.none, .added, .none, .added, .none])
        #expect(layout.result.rows.map(\.gutter) == [["1"], ["2"], ["3"], ["4"], ["5"]])
    }

    @Test("Both marks both sides added; Base marks neither and puts the base in the result")
    func bothAndBase() throws {
        let layout = GitMergeLayout.make(document: try document(), choices: [0: .oursThenTheirs, 1: .base],
                                         colours: nil)
        try #require(layout.ours.rowCount == 6 && layout.theirs.rowCount == 6)

        #expect(layout.ours.rows[1...2].map(\.background) == [.added, .added])
        #expect(layout.theirs.rows[1].background == .added)
        #expect(layout.ours.rows[4].background == .none)
        #expect(layout.theirs.rows[4].background == .none)
        #expect(layout.result.rows.map(\.text) == ["top", "ours one", "ours two", "theirs one", "middle", "y",
                                                   "bottom"])
    }

    @Test("with every conflict chosen, the result has one row per line of the resolved text", arguments: [
        [0: GitConflictDocument.Choice.ours, 1: .ours],
        [0: .theirs, 1: .theirs],
        [0: .oursThenTheirs, 1: .theirsThenOurs],
        [0: .theirsThenOurs, 1: .base]
    ])
    func resultMatchesResolved(_ choices: [Int: GitConflictDocument.Choice]) throws {
        let document = try document()
        let layout = GitMergeLayout.make(document: document, choices: choices, colours: nil)
        let resolved = try #require(document.resolved(choices))

        #expect(layout.result.rowCount == gitMergeLineCount(resolved))
        #expect(layout.result.rows.map(\.text) == Array(resolved.components(separatedBy: "\n").dropLast()))
    }

    @Test("the texts to colour are the common lines with each side's conflict lines")
    func texts() throws {
        let texts = GitMergeLayout.texts(of: try document())
        #expect(texts.ours == "top\nours one\nours two\nmiddle\nx\nbottom")
        #expect(texts.theirs == "top\ntheirs one\nmiddle\nz\nbottom")
        #expect(texts.base == "top\nmiddle\ny\nbottom")
    }

    @Test("each row takes the syntax runs of its own line in its side's text")
    func colours() throws {
        let red = try #require(RGBAColor(hexString: "#FF0000FF"))
        let green = try #require(RGBAColor(hexString: "#00FF00FF"))
        let blue = try #require(RGBAColor(hexString: "#0000FFFF"))
        func styled(_ count: Int, _ colour: RGBAColor) -> [StyledLine] {
            (0..<count).map { _ in
                StyledLine(runs: [SyntaxRun(range: NSRange(location: 0, length: 1), foreground: colour, fontStyle: [])])
            }
        }
        let colours = GitMergeColours(ours: styled(6, red), theirs: styled(5, green), base: styled(4, blue))
        let layout = GitMergeLayout.make(document: try document(), choices: [0: .theirs, 1: .base], colours: colours)
        try #require(layout.ours.rowCount == 6 && layout.theirs.rowCount == 6 && layout.result.rowCount == 5)

        #expect(layout.ours.rows[1].runs.first?.foreground == red)
        #expect(layout.theirs.rows[1].runs.first?.foreground == green)
        #expect(layout.theirs.rows[2].runs.isEmpty, "a filler has no runs")
        #expect(layout.result.rows[1].runs.first?.foreground == green)
        #expect(layout.result.rows[3].runs.first?.foreground == blue)
    }
}
