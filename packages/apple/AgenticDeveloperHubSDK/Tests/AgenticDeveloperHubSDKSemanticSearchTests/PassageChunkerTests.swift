import Foundation
import Testing
@testable import AgenticDeveloperHubSDKSemanticSearch

struct PassageChunkerTests {

    private let chunker = PassageChunker()

    @Test func emptyAndBlankTextGiveNoPassages() {
        #expect(chunker.chunk("").isEmpty)
        #expect(chunker.chunk("  \n\n \t \n").isEmpty)
    }

    @Test func shortTextIsOnePassage() {
        #expect(chunker.chunk("Hello world.") == [PassageChunk(index: 0, content: "Hello world.")])
    }

    @Test func blocksArePackedAndJoinedByABlankLine() {
        let chunks = chunker.chunk("one\n\n\n  two  \n \t\nthree")
        #expect(chunks.map(\.content) == ["one\n\ntwo\n\nthree"])
    }

    @Test func crlfReadsAsLF() {
        #expect(chunker.chunk("a\r\n\r\nb").map(\.content) == ["a\n\nb"])
    }

    @Test func topHeadingsStartAPassage() {
        let chunks = chunker.chunk("intro\n\n# One\n\nbody one\n\n## Two\n\nbody two\n\n### Three\n\nbody three")
        #expect(chunks.map(\.content) == [
            "intro",
            "# One\n\nbody one",
            "## Two\n\nbody two\n\n### Three\n\nbody three"
        ])
        #expect(chunks.map(\.index) == [0, 1, 2])
    }

    @Test func aHeadingFirstDoesNotMakeAnEmptyPassage() {
        #expect(chunker.chunk("# Title\n\ntext").map(\.content) == ["# Title\n\ntext"])
    }

    @Test func hashWithoutSpaceIsNotAHeading() {
        #expect(!PassageChunker.isTopHeading("#tag"))
        #expect(!PassageChunker.isTopHeading("### deep"))
        #expect(PassageChunker.isTopHeading("# a"))
        #expect(PassageChunker.isTopHeading("##\tb"))
    }

    @Test func blocksPackUpToTheTarget() {
        let small = PassageChunker(targetCharacters: 10, maxCharacters: 100)
        // "aaaa" + 2 + "bbbb" = 10 fits; "cccc" would make 16.
        #expect(small.chunk("aaaa\n\nbbbb\n\ncccc").map(\.content) == ["aaaa\n\nbbbb", "cccc"])
    }

    @Test func aLongBlockIsCutAtWhitespace() {
        // The window "alpha beta g" ends mid-word, so the cut is at the space before "gamma".
        let small = PassageChunker(targetCharacters: 12, maxCharacters: 12)
        #expect(small.chunk("alpha beta gamma delta").map(\.content) == ["alpha beta", "gamma delta"])
        // A window that ends exactly at a word's end still cuts at its last space, as the server does.
        #expect(PassageChunker.hardSplit("alpha beta gamma", maxCharacters: 10) == ["alpha", "beta", "gamma"])
    }

    @Test func aBlockWithNoWhitespaceIsCutAtTheLimit() {
        #expect(PassageChunker.hardSplit("abcdefghij", maxCharacters: 4) == ["abcd", "efgh", "ij"])
    }

    @Test func everyPieceRespectsTheMaximum() {
        let text = String(repeating: "word ", count: 3000)
        for chunk in chunker.chunk(text) {
            #expect(chunk.content.count <= PassageChunker.defaultMaxCharacters)
        }
    }

    @Test func fitsHalvesAPassageAtTheSpaceNearestTheMiddle() {
        let chunks = chunker.chunk("one two three four five six", fits: { $0.count <= 14 })
        #expect(chunks.map(\.content) == ["one two three", "four five six"])
    }

    @Test func fitsKeepsHalvingUntilEveryPieceFits() {
        let text = (1...40).map { "w\($0)" }.joined(separator: " ")
        let chunks = chunker.chunk(text, fits: { $0.count <= 20 })
        #expect(chunks.allSatisfy { $0.content.count <= 20 })
        #expect(chunks.map(\.content).joined(separator: " ") == text)
        #expect(chunks.map(\.index) == Array(0..<chunks.count))
    }

    @Test func chunkingIsDeterministic() {
        let text = (1...500).map { "Sentence number \($0)." }.joined(separator: "\n\n")
        #expect(chunker.chunk(text) == chunker.chunk(text))
    }

    @Test func tokenBudgetUsesTheEmbedderCount() {
        let embedder = CountingEmbedder(tokensPerCharacter: 1)
        let fits = SemanticTokenBudget.fits(embedder: embedder, title: nil)
        #expect(fits(String(repeating: "a", count: 1024)))
        #expect(!fits(String(repeating: "a", count: 1025)))
    }

    @Test func tokenBudgetTreatsAnUnmeasurablePassageAsTooLong() {
        let fits = SemanticTokenBudget.fits(embedder: FailingEmbedder(), title: "t")
        #expect(!fits("short"))
    }

    // MARK: - Source hash

    /// The spec's conformance vectors, computed independently in Python as
    /// `sha256(((title or '') + '\n\n' + content).encode())`.
    @Test func sourceHashMatchesTheBackend() {
        #expect(PassageSourceHash.of(title: "Notes", content: "Hello")
                == "240940d96ae57f5f7d8803b87cdd38180d2665d5420088488264957d06d4378e")
        #expect(PassageSourceHash.of(title: nil, content: "Hello")
                == "b9662bd8128a983445b3eef232acfb6fee5b9927c4e4672b71c1b60659652813")
        #expect(PassageSourceHash.of(title: "", content: "Hello")
                == "b9662bd8128a983445b3eef232acfb6fee5b9927c4e4672b71c1b60659652813")
        #expect(PassageSourceHash.of(title: "Café", content: "naïve\r\ntext")
                == "6419bfd95317913d875de8ded8a47de0e89e3d2f16adf999b80eb4cd480b49f3")
    }
}

/// Counts one token per character (times a factor), prefix excluded.
struct CountingEmbedder: TextEmbedder {
    let tokensPerCharacter: Int
    var stamp: String { "counting:000000000000:000000000000:2" }
    var dimensions: Int { 2 }
    func tokenCount(_ text: String, task: EmbeddingTask) throws -> Int { text.count * tokensPerCharacter }
    func embed(_ text: String, task: EmbeddingTask) async throws -> [Float] { [1, 0] }
}

struct FailingEmbedder: TextEmbedder {
    struct Failure: Error {}
    var stamp: String { "failing:000000000000:000000000000:2" }
    var dimensions: Int { 2 }
    func tokenCount(_ text: String, task: EmbeddingTask) throws -> Int { throw Failure() }
    func embed(_ text: String, task: EmbeddingTask) async throws -> [Float] { throw Failure() }
}
