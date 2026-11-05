import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

/// `SemanticPalette.scaled(by:)` — the reader's own type multiplier, kept
/// separate from the designer's `sizeScale` so a "Text Size" control survives a
/// change of theme.
@Suite("SemanticPalette.scaled(by:)")
struct SemanticPaletteScaleTests {

    private func theme(sizeScale: Double = 1) -> ColorTheme {
        let ansi = (0..<16).map { _ in RGBAColor(hexString: "#808080ff")! }
        var theme = ColorTheme(
            name: "T", appearance: .dark,
            foreground: RGBAColor(hexString: "#cdd6f4ff")!,
            background: RGBAColor(hexString: "#1e1e2eff")!,
            cursor: RGBAColor(hexString: "#cdd6f4ff")!,
            selection: RGBAColor(hexString: "#445566ff")!,
            ansi: ansi
        )
        theme.typography.sizeScale = sizeScale
        return theme
    }

    private func size(_ palette: SemanticPalette, _ role: TextRole) -> Double {
        palette.size(role)
    }

    @Test("a factor of one is the palette itself")
    func identity() {
        let palette = SemanticPalette(theme: theme())
        #expect(size(palette.scaled(by: 1), .body) == size(palette, .body))
    }

    @Test("every role grows by the factor, not just the one a view asked for")
    func scalesEveryRole() {
        let palette = SemanticPalette(theme: theme())
        let scaled = palette.scaled(by: 1.5)
        // A bubble, a timestamp and a status line each resolve their own size;
        // a scale that reached only `.body` would leave the chat mismatched.
        for role in TextRole.allCases {
            #expect(abs(size(scaled, role) - size(palette, role) * 1.5) < 0.0001)
        }
    }

    /// The two scales answer to different people and must compose rather than
    /// replace: `old-school-terminal` sets 1.0667 because VT323 draws small for
    /// its point size, which is a fact about the typeface, not a preference.
    @Test("the reader's factor multiplies the theme's own scale rather than replacing it")
    func composesWithTheThemesOwnScale() {
        let designed = SemanticPalette(theme: theme(sizeScale: 1.0667))
        let plain = SemanticPalette(theme: theme(sizeScale: 1))
        let scaled = designed.scaled(by: 1.5)
        #expect(abs(size(scaled, .body) - size(plain, .body) * 1.0667 * 1.5) < 0.001)
    }

    @Test("a factor arriving from a slider is clamped at both ends")
    func clampsAbsurdFactors() {
        let palette = SemanticPalette(theme: theme())
        // Zero would lay every intrinsic-size-driven constraint out at no
        // height, taking the window with it.
        #expect(size(palette.scaled(by: 0), .body) == size(palette.scaled(by: 0.5), .body))
        #expect(size(palette.scaled(by: 100), .body) == size(palette.scaled(by: 4), .body))
    }

    @Test("scaling changes type only, never colour")
    func leavesColoursAlone() {
        let palette = SemanticPalette(theme: theme())
        let scaled = palette.scaled(by: 1.75)
        for role in ThemeRole.allCases {
            #expect(scaled.color(role) == palette.color(role))
        }
    }
}
