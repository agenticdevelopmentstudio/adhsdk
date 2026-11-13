import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitOutputDecoding")
struct GitOutputDecodingTests {
    @Test("UTF-8 decodes as UTF-8")
    func utf8() {
        #expect(GitOutputDecoding.string(Data("café".utf8)) == "café")
    }

    @Test("invalid UTF-8 falls back to ISO Latin-1")
    func latin1Fallback() {
        #expect(GitOutputDecoding.string(Data([0x63, 0x61, 0x66, 0xE9])) == "café")
    }

    @Test("a Latin-1 record does not turn a UTF-8 record into mojibake")
    func mixedEncodingsDecodePerSegment() {
        // Record 1: UTF-8 "José" in its author field; record 2: Latin-1 "café" (0xE9) in its subject.
        var data = Data("a1\u{1F}José\u{1F}subject one\u{1E}\n".utf8)
        data += Data("a2\u{1F}Ann\u{1F}".utf8) + Data([0x63, 0x61, 0x66, 0xE9]) + Data("\u{1E}\n".utf8)
        #expect(GitOutputDecoding.string(data)
            == "a1\u{1F}José\u{1F}subject one\u{1E}\na2\u{1F}Ann\u{1F}café\u{1E}\n")
    }

    @Test("newline-separated lines decode independently")
    func newlineSeparatedLinesDecodeIndependently() {
        let data = Data("refs/heads/José\n".utf8) + Data([0x63, 0x61, 0x66, 0xE9, 0x0A])
            + Data("ünïcode\0end".utf8)
        #expect(GitOutputDecoding.string(data) == "refs/heads/José\ncafé\nünïcode\0end")
    }
}
