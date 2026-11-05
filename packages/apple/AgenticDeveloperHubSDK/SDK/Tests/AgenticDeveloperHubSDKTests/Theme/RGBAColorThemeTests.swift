import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

/// `composited(over:)` is load-bearing for `ChatRoleDerivationTests`'s
/// legibility guarantee — a translucent bubble fill's contrast is only
/// meaningful after it is resolved against its real backdrop. These pin the
/// compositing math itself, independent of any theme.
@Suite("RGBAColor compositing")
struct RGBAColorThemeTests {

    @Test("full alpha returns the source colour unchanged")
    func fullAlphaIsSourceUnchanged() {
        let source = RGBAColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
        let backdrop = RGBAColor(red: 1, green: 1, blue: 1, alpha: 1)
        let result = source.composited(over: backdrop)
        #expect(result == source)
    }

    @Test("zero alpha returns the backdrop unchanged")
    func zeroAlphaIsBackdropUnchanged() {
        let source = RGBAColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0)
        let backdrop = RGBAColor(red: 0.9, green: 0.1, blue: 0.5, alpha: 1)
        let result = source.composited(over: backdrop)
        #expect(result == backdrop)
    }

    @Test("50% grey over white lands midway")
    func halfAlphaGreyOverWhiteIsMidway() {
        let grey = RGBAColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        let white = RGBAColor.opaqueWhite
        let result = grey.composited(over: white)
        #expect(result.alpha == 1)
        #expect(abs(result.red - 0.5) < 0.001)
        #expect(abs(result.green - 0.5) < 0.001)
        #expect(abs(result.blue - 0.5) < 0.001)
    }

    @Test("compositing two translucent colours accumulates alpha correctly")
    func translucentOverTranslucent() {
        // 50%-alpha white over 50%-alpha black: out alpha = 0.5 + 0.5*0.5 = 0.75,
        // and the resulting channel sits at 0.5/0.75 = 2/3 toward white.
        let source = RGBAColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        let backdrop = RGBAColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        let result = source.composited(over: backdrop)
        #expect(abs(result.alpha - 0.75) < 0.001)
        #expect(abs(result.red - (2.0 / 3.0)) < 0.001)
    }
}
