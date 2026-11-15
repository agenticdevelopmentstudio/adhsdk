import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("ThemeOptions")
struct ThemeOptionsTests {

    private func json(_ text: String) -> Data { Data(text.utf8) }

    private func terminalVariants() -> [ThemeTerminalOptions] {
        [
            ThemeTerminalOptions(paddingTop: 1),
            ThemeTerminalOptions(paddingLeading: 1),
            ThemeTerminalOptions(paddingBottom: 1),
            ThemeTerminalOptions(paddingTrailing: 1),
            ThemeTerminalOptions(fontName: "Menlo"),
            ThemeTerminalOptions(fontSize: 1),
            ThemeTerminalOptions(cursorShape: .block),
            ThemeTerminalOptions(cursorBlinks: false)
        ]
    }

    @Test("themeoptions-001: empty terminal options")
    func v001TerminalDefaults() {
        let options = ThemeTerminalOptions()
        #expect(options.paddingTop == nil)
        #expect(options.paddingLeading == nil)
        #expect(options.paddingBottom == nil)
        #expect(options.paddingTrailing == nil)
        #expect(options.fontName == nil)
        #expect(options.fontSize == nil)
        #expect(options.cursorShape == nil)
        #expect(options.cursorBlinks == nil)
        #expect(options.isEmpty)
    }

    @Test("themeoptions-002: zero is a value, not nil")
    func v002ZeroIsValue() {
        #expect(!ThemeTerminalOptions(paddingTop: 0).isEmpty)
    }

    @Test("themeoptions-003: each field alone makes the options non-empty")
    func v003EachFieldAlone() {
        let variants = terminalVariants()
        #expect(variants.count == 8)
        for variant in variants {
            #expect(!variant.isEmpty)
        }
    }

    @Test("themeoptions-004: font size alone leaves the rest nil")
    func v004FontSizeOnly() {
        let options = ThemeTerminalOptions(fontSize: 13)
        #expect(options.fontSize == 13)
        #expect(options.paddingTop == nil)
        #expect(options.paddingLeading == nil)
        #expect(options.paddingBottom == nil)
        #expect(options.paddingTrailing == nil)
        #expect(options.fontName == nil)
        #expect(options.cursorShape == nil)
        #expect(options.cursorBlinks == nil)
    }

    @Test("themeoptions-005: empty project options")
    func v005ProjectDefaults() {
        let options = ThemeProjectOptions()
        #expect(options.highlightActivePane == nil)
        #expect(options.paneOutline == nil)
        #expect(options.paneBackdrop == nil)
        #expect(options.isEmpty)
    }

    @Test("themeoptions-006: false is a value, not nil")
    func v006FalseIsValue() {
        #expect(!ThemeProjectOptions(highlightActivePane: false).isEmpty)
    }

    @Test("themeoptions-007: encoding omits nil fields")
    func v007EncodeOnlySetKeys() throws {
        let data = try JSONEncoder().encode(ThemeTerminalOptions(paddingTop: 4))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object.count == 1)
        #expect(object["paddingTop"] as? Int == 4)
    }

    @Test("themeoptions-008: an empty object decodes to empty options")
    func v008DecodeEmptyObject() throws {
        let terminal = try JSONDecoder().decode(ThemeTerminalOptions.self, from: json("{}"))
        let project = try JSONDecoder().decode(ThemeProjectOptions.self, from: json("{}"))
        #expect(terminal.isEmpty)
        #expect(project.isEmpty)
    }

    @Test("themeoptions-009: cursor shape encodes as its raw value")
    func v009CursorShapeEncode() throws {
        let data = try JSONEncoder().encode([TerminalCursorShape.hollowBlock])
        #expect(String(decoding: data, as: UTF8.self) == "[\"hollowBlock\"]")
    }

    @Test("themeoptions-010: an unknown cursor shape fails to decode")
    func v010CursorShapeUnknown() {
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode([TerminalCursorShape].self, from: json("[\"triangle\"]"))
        }
    }

    @Test("themeoptions-011: cursor shape cases in declaration order")
    func v011CursorShapeCases() {
        #expect(TerminalCursorShape.allCases == [.block, .hollowBlock, .underline, .bar])
    }

    @Test("themeoptions-012: cursor shape labels")
    func v012CursorShapeLabels() {
        #expect(TerminalCursorShape.block.label == "Block  ▉")
        #expect(TerminalCursorShape.hollowBlock.label == "Hollow Block  ▢")
        #expect(TerminalCursorShape.underline.label == "Underline  _")
        #expect(TerminalCursorShape.bar.label == "Bar  |")
    }

    @Test("themeoptions-013: shape and blink are separate fields")
    func v013ShapeAndBlink() {
        let options = ThemeTerminalOptions(cursorShape: .bar, cursorBlinks: true)
        #expect(options.cursorShape == .bar)
        #expect(options.cursorBlinks == true)
    }

    @Test("themeoptions-014: pane outline encodes as a hex string")
    func v014ProjectColorEncoding() throws {
        let color = try #require(RGBAColor(hexString: "#336699FF"))
        let data = try JSONEncoder().encode(ThemeProjectOptions(paneOutline: color))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["paneOutline"] as? String == "#336699FF")
        #expect(object["paneBackdrop"] == nil)
        #expect(object["highlightActivePane"] == nil)
        #expect(object.count == 1)
    }

    @Test("themeoptions-015: a malformed colour string fails to decode")
    func v015MalformedColor() {
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(ThemeProjectOptions.self, from: json("{\"paneBackdrop\":\"red\"}"))
        }
    }

    @Test("themeoptions-016: a wrong JSON type fails to decode")
    func v016TypeMismatch() {
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(ThemeTerminalOptions.self, from: json("{\"paddingTop\":\"4\"}"))
        }
    }

    @Test("themeoptions-017: equality follows the fields")
    func v017Equality() {
        let first = ThemeTerminalOptions(paddingTop: 2, fontName: "Menlo")
        var second = ThemeTerminalOptions(paddingTop: 2, fontName: "Menlo")
        #expect(first == second)
        second.fontSize = 12
        #expect(first != second)
        let project = ThemeProjectOptions(highlightActivePane: true)
        var other = ThemeProjectOptions(highlightActivePane: true)
        #expect(project == other)
        other.highlightActivePane = false
        #expect(project != other)
    }

    @Test("themeoptions-018: terminal options round trip")
    func v018RoundTrip() throws {
        let original = ThemeTerminalOptions(
            paddingTop: 2, paddingLeading: 3, paddingBottom: 4, paddingTrailing: 5,
            fontName: "FiraCodeNFM-Reg", fontSize: 12.5,
            cursorShape: .underline, cursorBlinks: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeTerminalOptions.self, from: data)
        #expect(decoded == original)
    }
}
