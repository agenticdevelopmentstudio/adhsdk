import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("StreamingTextSubstitution conformance")
struct StreamingTextSubstitutionTests {

    private typealias Stream = StreamingTextSubstitution

    private func makeStream(
        _ pairs: [(alias: String, real: String)] = [("robin", "mike")],
        direction: Stream.Direction = .concealing
    ) -> Stream {
        let filter = TextSubstitutionFilter(pairs: pairs.map { .init(alias: $0.alias, real: $0.real) })
        return Stream(filter: filter, direction: direction)
    }

    private func longestPairs() -> [(alias: String, real: String)] {
        [("rob", "mike"), ("robert", "mike fullerton")]
    }

    private func text(_ bytes: [UInt8]) -> String {
        String(bytes: bytes, encoding: .utf8) ?? ""
    }

    private func feed(_ stream: inout Stream, _ string: String) -> String {
        text(stream.feed(Array(string.utf8)))
    }

    @Test("V1: a complete match is replaced at once")
    func testV1_completeMatchEmitted() {
        var stream = makeStream()
        #expect(feed(&stream, "hello mike") == "hello robin")
        #expect(!stream.isHolding)
    }

    @Test("V2: a split word is held then replaced")
    func testV2_splitWordHeldThenReplaced() {
        var stream = makeStream()
        #expect(feed(&stream, "hello mi") == "hello ")
        #expect(stream.isHolding)
        #expect(feed(&stream, "ke!") == "robin!")
        #expect(!stream.isHolding)
    }

    @Test("V3: a diverging stream releases the held bytes")
    func testV3_divergingStreamReleasesHeld() {
        var stream = makeStream()
        #expect(feed(&stream, "mi").isEmpty)
        #expect(feed(&stream, "x") == "mix")
    }

    @Test("V4: flush emits a held partial match unchanged")
    func testV4_flushEmitsPartial() {
        var stream = makeStream()
        #expect(feed(&stream, "mik").isEmpty)
        #expect(stream.isHolding)
        #expect(text(stream.flush()) == "mik")
        #expect(!stream.isHolding)
    }

    @Test("V5: ASCII case folds and the replacement is as given")
    func testV5_caseFoldReplacementAsGiven() {
        var stream = makeStream()
        #expect(feed(&stream, "MIKE Mike") == "robin robin")
    }

    @Test("V6: revealing replaces the alias with the real text")
    func testV6_revealing() {
        var stream = makeStream(direction: .revealing)
        #expect(feed(&stream, "robin") == "mike")
    }

    @Test("V7: the longest pattern wins")
    func testV7_longestFirst() {
        var stream = makeStream(longestPairs())
        #expect(feed(&stream, "mike fullerton") == "robert")
    }

    @Test("V8: a shorter match is held while a longer one may complete")
    func testV8_holdOverShorterMatch() {
        var stream = makeStream(longestPairs())
        #expect(feed(&stream, "mike").isEmpty)
        #expect(stream.isHolding)
        #expect(text(stream.flush()) == "rob")
    }

    @Test("V9: a replacement is not scanned again")
    func testV9_singlePass() {
        var stream = makeStream([("b", "a"), ("c", "b")])
        #expect(feed(&stream, "ab") == "bc")
    }

    @Test("V10: non-ASCII letters are not case-folded")
    func testV10_nonASCIINotFolded() {
        var stream = makeStream([("x", "\u{C9}")])
        #expect(stream.feed([0xC3, 0xA9]) == [0xC3, 0xA9])
        #expect(text(stream.feed([0xC3, 0x89])) == "x")
    }

    @Test("V11: binary bytes pass through an identity filter")
    func testV11_binarySafeIdentity() {
        var stream = Stream(filter: .identity, direction: .concealing)
        #expect(stream.feed([0xFF, 0x6D]) == [0xFF, 0x6D])
        #expect(!stream.isHolding)
    }

    @Test("V12: a binary byte is emitted and a pattern prefix held")
    func testV12_binarySafeHoldsPrefix() {
        var stream = makeStream()
        #expect(stream.feed([0xFF, 0x6D]) == [0xFF])
        #expect(stream.isHolding)
    }

    @Test("V13: a match needs no word boundary")
    func testV13_noWordBoundary() {
        var stream = makeStream()
        #expect(feed(&stream, "mimike") == "mirobin")
    }

    @Test("V14: flush with nothing held is empty")
    func testV14_flushEmpty() {
        var stream = makeStream()
        #expect(stream.flush().isEmpty)
    }

    @Test("V15: output keeps input order")
    func testV15_orderPreserved() {
        var stream = makeStream()
        #expect(feed(&stream, "a mike b") == "a robin b")
    }

    @Test("V16: an identity filter passes bytes and holds nothing")
    func testV16_noPatterns() {
        var stream = Stream(filter: .identity, direction: .concealing)
        #expect(feed(&stream, "abc") == "abc")
        #expect(!stream.isHolding)
    }

    @Test("V17: feed accepts an array and an array slice")
    func testV17_genericInput() {
        var stream = makeStream()
        let array: [UInt8] = Array("mi".utf8)
        #expect(stream.feed(array).isEmpty)
        let slice: ArraySlice<UInt8> = Array("ke".utf8)[...]
        #expect(text(stream.feed(slice)) == "robin")
    }

    @Test("V18: the held run is shorter than the longest pattern")
    func testV18_holdBound() {
        var stream = makeStream([("robert", "mike fullerton")])
        #expect(feed(&stream, "mike fullert").isEmpty)
        #expect(stream.isHolding)
        let flushed = stream.flush()
        #expect(flushed.count == 12)
        #expect(flushed.count < "mike fullerton".utf8.count)
    }

    @Test("V19: bytes that start no pattern are not held")
    func testV19_passThroughBytes() {
        var stream = makeStream()
        #expect(feed(&stream, "hello world") == "hello world")
        #expect(!stream.isHolding)
    }

    @Test("V20: a diverging stream releases the shorter match")
    func testV20_holdReleasedShorterMatch() {
        var stream = makeStream(longestPairs())
        #expect(feed(&stream, "mike x") == "rob x")
        #expect(!stream.isHolding)
    }

    @Test("V21: flush replaces the shorter match and passes the rest")
    func testV21_flushShorterMatchThenPartial() {
        var stream = makeStream(longestPairs())
        #expect(feed(&stream, "mike fu").isEmpty)
        #expect(stream.isHolding)
        #expect(text(stream.flush()) == "rob fu")
    }
}
