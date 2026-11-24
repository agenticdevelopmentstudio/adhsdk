import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("RGBAColor conformance")
struct RGBAColorConformanceTests {

    private static let tolerance = 1e-12

    private func decode(_ json: String) throws -> RGBAColor {
        let colors = try JSONDecoder().decode([RGBAColor].self, from: Data(json.utf8))
        return try #require(colors.first)
    }

    @Test("rgbacolor-001: components clamp into 0...1")
    func v001_clampRange() {
        let color = RGBAColor(red: -0.5, green: 1.5, blue: 0.25, alpha: 2)
        #expect(color.red == 0)
        #expect(color.green == 1)
        #expect(color.blue == 0.25)
        #expect(color.alpha == 1)
    }

    @Test("rgbacolor-002: NaN clamps to 0 without trapping")
    func v002_clampNaN() {
        let color = RGBAColor(red: .nan, green: 0.5, blue: 0.5, alpha: 1)
        #expect(color.red == 0)
    }

    @Test("rgbacolor-003: infinities clamp to the range ends")
    func v003_clampInfinity() {
        let color = RGBAColor(red: .infinity, green: -.infinity, blue: 0, alpha: 1)
        #expect(color.red == 1)
        #expect(color.green == 0)
    }

    @Test("rgbacolor-004: hex channel order and normalisation")
    func v004_hexChannelOrder() throws {
        let color = try #require(RGBAColor(hexString: "#FF000080"))
        #expect(color.red == 1)
        #expect(color.green == 0)
        #expect(color.blue == 0)
        #expect(abs(color.alpha - 128.0 / 255.0) < Self.tolerance)
    }

    @Test("rgbacolor-005: the leading hash is optional")
    func v005_optionalHash() throws {
        let bare = try #require(RGBAColor(hexString: "00ff41ff"))
        let hashed = try #require(RGBAColor(hexString: "#00ff41ff"))
        #expect(bare == hashed)
    }

    @Test("rgbacolor-006: hex parsing is case-insensitive")
    func v006_caseInsensitive() throws {
        let mixed = try #require(RGBAColor(hexString: "#aBcDeF12"))
        let upper = try #require(RGBAColor(hexString: "#ABCDEF12"))
        #expect(mixed == upper)
    }

    @Test("rgbacolor-007: wrong lengths and shorthand return nil")
    func v007_wrongLengthNil() {
        for text in ["#FFF", "#FF0000", "", "#"] {
            #expect(RGBAColor(hexString: text) == nil, "\(text) should be rejected")
        }
    }

    @Test("rgbacolor-008: a doubled hash returns nil")
    func v008_doubleHashNil() {
        #expect(RGBAColor(hexString: "##FF000080") == nil)
    }

    @Test("rgbacolor-009: non-hex digits return nil")
    func v009_nonHexNil() {
        #expect(RGBAColor(hexString: "#GG000080") == nil)
    }

    @Test("rgbacolor-010: a leading plus sign is accepted by this implementation")
    func v010_plusSignLeniency() throws {
        let color = try #require(RGBAColor(hexString: "+FFFFFFF"))
        #expect(abs(color.red - 15.0 / 255.0) < Self.tolerance)
    }

    @Test("rgbacolor-011: hexString rounds to the nearest byte")
    func v011_hexRounding() {
        #expect(RGBAColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1).hexString == "#336699FF")
    }

    @Test("rgbacolor-012: clear serialises to all zeros")
    func v012_clearHex() {
        #expect(RGBAColor.clear.hexString == "#00000000")
    }

    @Test("rgbacolor-013: out-of-range components serialise clamped")
    func v013_clampedHex() {
        #expect(RGBAColor(red: 9, green: -9, blue: 0, alpha: 1).hexString == "#FF0000FF")
    }

    @Test("rgbacolor-014: encodes as a single hex string")
    func v014_encodeSingleString() throws {
        let data = try JSONEncoder().encode([RGBAColor.white])
        #expect(String(decoding: data, as: UTF8.self) == "[\"#FFFFFFFF\"]")
    }

    @Test("rgbacolor-015: decodes a single hex string byte-exactly")
    func v015_decodeRoundTrip() throws {
        let color = try decode("[\"#336699FF\"]")
        #expect(color.hexString == "#336699FF")
    }

    @Test("rgbacolor-016: a non-hex string is a data-corrupted error")
    func v016_decodeBadStringThrows() {
        do {
            _ = try decode("[\"red\"]")
            Issue.record("Decoding should have thrown")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Expected #RRGGBBAA hex color string.")
        } catch {
            Issue.record("Expected a data-corrupted error, got \(error)")
        }
    }

    @Test("rgbacolor-017: a number is a decoding error")
    func v017_decodeNumberThrows() {
        #expect(throws: DecodingError.self) {
            try decode("[12]")
        }
    }

    @Test("rgbacolor-018: the constants")
    func v018_constants() {
        #expect(RGBAColor.black == RGBAColor(red: 0, green: 0, blue: 0, alpha: 1))
        #expect(RGBAColor.white == RGBAColor(red: 1, green: 1, blue: 1, alpha: 1))
        #expect(RGBAColor.clear == RGBAColor(red: 0, green: 0, blue: 0, alpha: 0))
    }

    @Test("rgbacolor-019: equal components compare equal")
    func v019_valueSemantics() {
        let first = RGBAColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.4)
        let second = RGBAColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.4)
        #expect(first == second)
    }

    @Test("rgbacolor-020: surrounding whitespace is rejected")
    func v020_noWhitespace() {
        #expect(RGBAColor(hexString: " #FF000080") == nil)
        #expect(RGBAColor(hexString: "FF00008 ") == nil)
    }

    @Test("rgbacolor-021: four and seven digits are rejected")
    func v021_shorthandRejected() {
        #expect(RGBAColor(hexString: "#FFFF") == nil)
        #expect(RGBAColor(hexString: "#FF00008") == nil)
    }

    @Test("rgbacolor-022: a leading minus sign on zero is accepted by this implementation")
    func v022_minusSignLeniency() throws {
        let color = try #require(RGBAColor(hexString: "-0000000"))
        #expect(color.red == 0)
        #expect(color.green == 0)
        #expect(color.blue == 0)
        #expect(color.alpha == 0)
    }

    @Test("rgbacolor-023: a half-grey is quantised to the 8-bit grid")
    func v023_roundTripQuantises() throws {
        let hex = RGBAColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).hexString
        #expect(hex == "#808080FF")
        let decoded = try #require(RGBAColor(hexString: hex))
        #expect(abs(decoded.red - 128.0 / 255.0) < Self.tolerance)
        #expect(decoded.red != 0.5)
    }
}
