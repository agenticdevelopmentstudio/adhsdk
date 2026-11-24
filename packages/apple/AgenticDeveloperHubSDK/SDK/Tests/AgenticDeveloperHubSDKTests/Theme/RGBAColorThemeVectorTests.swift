import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

/// Conformance vectors for the `RGBAColor` theme extension that have no direct
/// assertion in `RGBAColorThemeTests` (compositing) or `IdleStatusInkTests`.
@Suite("RGBAColor theme extension vectors")
struct RGBAColorThemeVectorTests {

    private func grey(_ level: Double, alpha: Double = 1) -> RGBAColor {
        RGBAColor(red: level, green: level, blue: level, alpha: alpha)
    }

    @Test("rgbacolor-theme-001: black and white luminance are 0 and 1")
    func v001LuminanceExtremes() {
        #expect(RGBAColor.opaqueBlack.relativeLuminance == 0)
        #expect(abs(RGBAColor.opaqueWhite.relativeLuminance - 1) < 0.0001)
    }

    @Test("rgbacolor-theme-002: mid grey luminance is linearized")
    func v002Linearization() {
        #expect(abs(grey(0.5).relativeLuminance - 0.214) < 0.001)
    }

    @Test("rgbacolor-theme-003: luminance ignores alpha")
    func v003LuminanceIgnoresAlpha() {
        #expect(grey(0.5, alpha: 0.1).relativeLuminance == grey(0.5).relativeLuminance)
    }

    @Test("rgbacolor-theme-004: black is dark, white is not")
    func v004IsDark() {
        #expect(RGBAColor.opaqueBlack.isDark)
        #expect(!RGBAColor.opaqueWhite.isDark)
    }

    @Test("rgbacolor-theme-005: mid grey is dark and takes black text (provisional)")
    func v005MidGreyProvisional() {
        let mid = grey(0.5)
        #expect(mid.isDark)
        #expect(mid.bestTextColor() == RGBAColor.opaqueBlack)
    }

    @Test("rgbacolor-theme-006: hex string for 0.2, 0.4, 0.6")
    func v006HexString() {
        #expect(RGBAColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1).hexStringRGB == "#336699")
    }

    @Test("rgbacolor-theme-007: hex string rounds half up")
    func v007HexRounding() {
        #expect(RGBAColor(red: 1, green: 0.5, blue: 0.25, alpha: 1).hexStringRGB == "#ff8040")
    }

    @Test("rgbacolor-theme-008: hex string drops alpha")
    func v008HexNoAlpha() {
        #expect(RGBAColor(red: 1, green: 0, blue: 0, alpha: 0.2).hexStringRGB == "#ff0000")
        #expect(RGBAColor(red: 1, green: 0, blue: 0, alpha: 1).hexStringRGB == "#ff0000")
    }

    @Test("rgbacolor-theme-009: blend formula and endpoints")
    func v009BlendFormula() {
        let black = RGBAColor.opaqueBlack
        let white = RGBAColor.opaqueWhite
        let quarter = black.blended(withFraction: 0.25, of: white)
        #expect(abs(quarter.red - 0.25) < 0.0001)
        #expect(abs(quarter.green - 0.25) < 0.0001)
        #expect(abs(quarter.blue - 0.25) < 0.0001)
        #expect(abs(quarter.alpha - 1) < 0.0001)
        #expect(black.blended(withFraction: 0, of: white) == black)
        #expect(black.blended(withFraction: 1, of: white) == white)
    }

    @Test("rgbacolor-theme-010: blend clamps the fraction")
    func v010BlendClamp() {
        let black = RGBAColor.opaqueBlack
        let white = RGBAColor.opaqueWhite
        #expect(black.blended(withFraction: 2, of: white) == black.blended(withFraction: 1, of: white))
        #expect(black.blended(withFraction: -1, of: white) == black.blended(withFraction: 0, of: white))
    }

    @Test("rgbacolor-theme-011: blend mixes alpha")
    func v011BlendAlpha() {
        let result = RGBAColor.clear.blended(withFraction: 0.5, of: RGBAColor.opaqueWhite)
        #expect(abs(result.red - 0.5) < 0.0001)
        #expect(abs(result.green - 0.5) < 0.0001)
        #expect(abs(result.blue - 0.5) < 0.0001)
        #expect(abs(result.alpha - 0.5) < 0.0001)
    }

    @Test("rgbacolor-theme-016: clear over clear is clear, no division by zero")
    func v016CompositeClear() {
        let result = RGBAColor.clear.composited(over: RGBAColor.clear)
        #expect(result == RGBAColor.clear)
    }

    @Test("rgbacolor-theme-018: a colour against itself is 1")
    func v018ContrastSelf() {
        #expect(abs(RGBAColor.opaqueWhite.contrastRatio(against: RGBAColor.opaqueWhite) - 1) < 0.0001)
    }

    @Test("rgbacolor-theme-019: contrast is symmetric")
    func v019ContrastSymmetric() {
        let first = RGBAColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
        let second = RGBAColor(red: 0.9, green: 0.9, blue: 0.1, alpha: 1)
        #expect(first.contrastRatio(against: second) == second.contrastRatio(against: first))
    }

    @Test("rgbacolor-theme-020: best text on black is white and on white is black")
    func v020BestTextExtremes() {
        #expect(RGBAColor.opaqueBlack.bestTextColor() == RGBAColor.opaqueWhite)
        #expect(RGBAColor.opaqueWhite.bestTextColor() == RGBAColor.opaqueBlack)
    }

    @Test("rgbacolor-theme-021: best text on dark and light greys")
    func v021BestTextGreys() {
        #expect(grey(0.4).bestTextColor() == RGBAColor.opaqueWhite)
        #expect(grey(0.6).bestTextColor() == RGBAColor.opaqueBlack)
    }

    @Test("rgbacolor-theme-022: best text returns the supplied argument unchanged")
    func v022BestTextArgument() {
        let darkInk = grey(0.1)
        let lightInk = grey(0.9)
        #expect(RGBAColor.opaqueBlack.bestTextColor(black: darkInk, white: lightInk) == lightInk)
    }

    @Test("rgbacolor-theme-023: dimmed accepts the first attempt")
    func v023DimmedAccept() {
        let result = RGBAColor.opaqueWhite.dimmed(towards: .opaqueBlack, by: 0.5, minContrast: 1)
        #expect(abs(result.red - 0.5) < 0.0001)
        #expect(abs(result.green - 0.5) < 0.0001)
        #expect(abs(result.blue - 0.5) < 0.0001)
        #expect(result.alpha == 1)
    }

    @Test("rgbacolor-theme-024: dimmed steps back until contrast is met")
    func v024DimmedSearch() {
        let result = RGBAColor.opaqueWhite.dimmed(towards: .opaqueBlack, by: 0.5, minContrast: 11)
        #expect(abs(result.red - 0.75) < 0.001)
        #expect(abs(result.green - 0.75) < 0.001)
        #expect(abs(result.blue - 0.75) < 0.001)
    }

    @Test("rgbacolor-theme-025: dimmed by zero returns self")
    func v025DimmedZero() {
        let color = RGBAColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
        #expect(color.dimmed(towards: .opaqueBlack, by: 0, minContrast: 1) == color)
    }

    @Test("rgbacolor-theme-026: unreachable contrast falls back to self")
    func v026DimmedUnreachable() {
        let result = RGBAColor.opaqueWhite.dimmed(towards: .opaqueBlack, by: 0.5, minContrast: 30)
        #expect(result == RGBAColor.opaqueWhite)
    }

    @Test("rgbacolor-theme-029: desaturated grey keeps apparent lightness above linear luminance")
    func v029DesaturateLuma() throws {
        let red = try #require(RGBAColor(hexString: "#c04040ff"))
        let result = red.desaturated()
        #expect(result.red > red.relativeLuminance + 0.2)
    }

    @Test("rgbacolor-theme-030: desaturate by zero is identity and keeps alpha")
    func v030DesaturateDefaults() {
        let color = RGBAColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 0.5)
        #expect(color.desaturated(by: 0) == color)
        #expect(abs(color.desaturated().alpha - 0.5) < 0.0001)
    }

    @Test("rgbacolor-theme-031: desaturate amount is clamped")
    func v031DesaturateClamp() throws {
        let green = try #require(RGBAColor(hexString: "#33ff66ff"))
        #expect(green.desaturated(by: 4) == green.desaturated(by: 1))
        #expect(green.desaturated(by: -2) == green)
    }

    @Test("rgbacolor-theme-032: desaturating a grey leaves it alone")
    func v032DesaturateIdempotent() {
        let result = grey(0.4).desaturated()
        #expect(abs(result.red - 0.4) < 0.0001)
        #expect(abs(result.green - 0.4) < 0.0001)
        #expect(abs(result.blue - 0.4) < 0.0001)
    }

    @Test("rgbacolor-theme-033: opaque constants")
    func v033OpaqueConstants() {
        #expect(RGBAColor.opaqueBlack == RGBAColor(red: 0, green: 0, blue: 0, alpha: 1))
        #expect(RGBAColor.opaqueWhite == RGBAColor(red: 1, green: 1, blue: 1, alpha: 1))
    }

    @Test("rgbacolor-theme-034: contrast ignores alpha")
    func v034ContrastIgnoresAlpha() {
        let faint = RGBAColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        #expect(abs(faint.contrastRatio(against: .opaqueWhite) - 21) < 0.0001)
    }
}
