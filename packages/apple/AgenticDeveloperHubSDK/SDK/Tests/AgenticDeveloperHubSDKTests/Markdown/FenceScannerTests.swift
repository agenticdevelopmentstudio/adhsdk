import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("FenceScanner")
struct FenceScannerTests {

    private func roles(_ source: String) -> [MarkdownLineRole] {
        FenceScanner.classify(source).map(\.role)
    }

    @Test("a document with no fence is all text")
    func plainTextHasNoFences() {
        #expect(roles("a\nb\n") == [.text, .text, .text])
        #expect(FenceScanner.fencedBlockContents(in: "a\nb\n").isEmpty)
    }

    @Test("both fence markers open and close a block")
    func bothMarkersAreRecognised() {
        #expect(roles("```\ncode\n```") == [.openingFence, .insideFence, .closingFence])
        #expect(roles("~~~\ncode\n~~~") == [.openingFence, .insideFence, .closingFence])
        #expect(FenceScanner.fencedBlockContents(in: "~~~\ncode\n~~~") == ["code"])
    }

    @Test("a fence is closed only by its own marker")
    func markersDoNotCloseEachOther() {
        // The `~~~` is content inside the backtick block, not its close.
        #expect(roles("```\n~~~\n```")
                == [.openingFence, .insideFence, .closingFence])
        #expect(FenceScanner.fencedBlockContents(in: "```\n~~~\n```") == ["~~~"])
    }

    @Test("a closing fence must be at least as long as the opener")
    func closingFenceMustMatchOpenerLength() {
        #expect(roles("````\n```\ncode\n````")
                == [.openingFence, .insideFence, .insideFence, .closingFence])
        // Longer than the opener is fine.
        #expect(roles("```\ncode\n`````") == [.openingFence, .insideFence, .closingFence])
    }

    @Test("a closing fence carries no info string")
    func closingFenceHasNoInfoString() {
        #expect(roles("```\ncode\n```swift\n```")
                == [.openingFence, .insideFence, .insideFence, .closingFence])
    }

    @Test("an opener's info string is allowed, and a backtick in it is not a fence at all")
    func openerInfoStrings() {
        #expect(FenceScanner.fence(in: "```swift")?.hasInfoString == true)
        #expect(FenceScanner.fence(in: "~~~ swift")?.hasInfoString == true)
        #expect(FenceScanner.fence(in: "``` a `b` c") == nil)
        #expect(FenceScanner.fence(in: "~~~ a `b` c") != nil)
    }

    @Test("fewer than three markers is not a fence")
    func shortRunsAreNotFences() {
        #expect(FenceScanner.fence(in: "``code``") == nil)
        #expect(FenceScanner.fence(in: "~~struck~~") == nil)
    }

    @Test("an unterminated fence runs to the end of the document and yields no block")
    func unterminatedFenceRunsToEndOfFile() {
        #expect(roles("text\n```\ncode\nmore\n") == [.text, .openingFence, .insideFence, .insideFence, .insideFence])
        #expect(FenceScanner.fencedBlockContents(in: "text\n```\ncode\n").isEmpty)
    }

    @Test("a CRLF document is split into its lines, not read as one")
    func crlfLinesAreSplit() {
        #expect(roles("a\r\n```\r\ncode\r\n```\r\n")
                == [.text, .openingFence, .insideFence, .closingFence, .text])
    }

    @Test("two blocks come back separately, in document order")
    func multipleBlocks() {
        let source = "```\none\n```\n\n~~~\ntwo\n~~~\n"
        #expect(FenceScanner.fencedBlockContents(in: source) == ["one", "two"])
    }
}
