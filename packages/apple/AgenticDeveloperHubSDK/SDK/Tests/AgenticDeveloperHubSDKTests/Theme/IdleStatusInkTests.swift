import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

/// The grey the status line wears while nothing is happening, and the colour
/// operation it is built from.
///
/// Two roles render the same shape of line — a glyph, then a phrase — and mean
/// opposite things: `.thinkingDoneText` is a report ("thought for 8s"),
/// `.thinkingIdleText` is a shrug ("waiting to zeeble…"). Nothing in the
/// layout distinguishes them, so the colour has to, and these tests are what
/// keep them from collapsing back into one value.
@Suite("Idle status ink")
struct IdleStatusInkTests {

    private func theme(background: String, foreground: String) -> ColorTheme {
        let ansi = (0..<16).map { _ in RGBAColor(hexString: "#808080ff")! }
        return ColorTheme(
            name: "T", appearance: .dark,
            foreground: RGBAColor(hexString: foreground + "ff")!,
            background: RGBAColor(hexString: background + "ff")!,
            cursor: RGBAColor(hexString: foreground + "ff")!,
            selection: RGBAColor(hexString: "#445566ff")!,
            ansi: ansi
        )
    }

    private func spread(_ color: RGBAColor) -> Double {
        Swift.max(color.red, color.green, color.blue) - Swift.min(color.red, color.green, color.blue)
    }

    // MARK: desaturated(by:)

    @Test("a full desaturation leaves the three channels equal")
    func fullDesaturationIsNeutral() {
        let green = RGBAColor(hexString: "#33ff66ff")!
        let grey = green.desaturated()
        #expect(abs(grey.red - grey.green) < 0.0001)
        #expect(abs(grey.green - grey.blue) < 0.0001)
    }

    /// The reason this uses luma over the encoded components rather than
    /// `relativeLuminance`: the two are different quantities, and a
    /// linear-light value written back into a display-encoded channel is a
    /// category error. The grey has to look like the same ink with the colour
    /// drained out, not like a different one.
    @Test("the grey keeps roughly the apparent lightness it replaced")
    func desaturationPreservesApparentLightness() {
        let luma = { (c: RGBAColor) in 0.299 * c.red + 0.587 * c.green + 0.114 * c.blue }

        let green = RGBAColor(hexString: "#33ff66ff")!
        #expect(abs(luma(green.desaturated()) - luma(green)) < 0.0001)

        // The bug this guards against, shown where it bites hardest: a mid red
        // whose linear-light luminance is barely a third of its apparent
        // lightness. Substituting it would drop the idle line to near-black.
        let red = RGBAColor(hexString: "#c04040ff")!
        let grey = red.desaturated()
        #expect(abs(luma(grey) - luma(red)) < 0.0001)
        #expect(grey.red > red.relativeLuminance + 0.2)
    }

    @Test("an amount of zero is the identity, and alpha always survives")
    func desaturationEndpoints() {
        let translucent = RGBAColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 0.5)
        #expect(translucent.desaturated(by: 0) == translucent)
        #expect(translucent.desaturated().alpha == 0.5)
    }

    @Test("out-of-range amounts clamp instead of overshooting")
    func desaturationClamps() {
        let green = RGBAColor(hexString: "#33ff66ff")!
        #expect(green.desaturated(by: 4) == green.desaturated(by: 1))
        #expect(green.desaturated(by: -2) == green)
    }

    @Test("a grey stays exactly itself")
    func desaturatingAGreyIsIdempotent() {
        let grey = RGBAColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        let again = grey.desaturated()
        #expect(abs(again.red - 0.4) < 0.0001)
        #expect(abs(again.green - 0.4) < 0.0001)
        #expect(abs(again.blue - 0.4) < 0.0001)
    }

    // MARK: thinkingIdleText

    @Test("the idle ink is greyer than the theme's own foreground")
    func idleInkIsGreyer() {
        // A phosphor-green terminal: the foreground is as saturated as a
        // theme's ink gets, so the drain is unmistakable.
        let palette = SemanticPalette(theme: theme(background: "#050805", foreground: "#33ff66"))
        #expect(spread(palette.thinkingIdleText) < spread(palette.theme.foreground))
    }

    @Test("the idle ink and the settled ink are different colours")
    func idleDiffersFromDone() {
        for (background, foreground) in [("#050805", "#33ff66"), ("#1e1e2e", "#cdd6f4")] {
            let palette = SemanticPalette(theme: theme(background: background, foreground: foreground))
            // The whole point of the role: two lines of identical shape that
            // mean opposite things must not paint identically.
            #expect(palette.thinkingIdleText != palette.color(.thinkingDoneText))
        }
    }

    @Test("dimmed, but never below the 3:1 the derivation promises")
    func idleInkStaysLegible() {
        for (background, foreground) in [("#050805", "#33ff66"), ("#1e1e2e", "#cdd6f4"),
                                         ("#fdf6e3", "#657b83")] {
            let palette = SemanticPalette(theme: theme(background: background, foreground: foreground))
            let contrast = palette.thinkingIdleText.contrastRatio(against: palette.theme.background)
            #expect(contrast >= 2.99)
        }
    }

    @Test("a theme that declares the role wins over the derivation")
    func declaredIdleInkWins() {
        var custom = theme(background: "#050805", foreground: "#33ff66")
        let red = RGBAColor(hexString: "#ff0000ff")!
        custom.roleOverrides[ThemeRole.thinkingIdleText.rawValue] = red
        #expect(SemanticPalette(theme: custom).thinkingIdleText == red)
    }

    /// How far apart a colour's channels are: 0 is a pure neutral, 1 a fully
    /// saturated primary.
    private func spread(of color: RGBAColor) -> Double {
        max(color.red, color.green, color.blue) - min(color.red, color.green, color.blue)
    }

    /// The bug the operator saw: a turn that had run and settled went on
    /// looking live, because dimming a phosphor-green ink without draining it
    /// leaves a phosphor-green ink. Web's `.pc-thinking--done` default is the
    /// literal grey `#8a8a8a`; what has to survive the derivation is the grey,
    /// not the hex.
    @Test("a saturated ink settles to a line with none of its colour left")
    func doneInkDrainsASaturatedInk() {
        let custom = theme(background: "#050805", foreground: "#33ff66")
        let palette = SemanticPalette(theme: custom)
        let drained = spread(of: palette.color(.thinkingDoneText))
        #expect(drained < spread(of: custom.foreground) / 10)
    }

    @Test("the settled line carries no more colour than the paper it sits on")
    func doneInkIsNeutral() {
        for (background, foreground) in [("#050805", "#33ff66"), ("#1e1e2e", "#cdd6f4"),
                                         ("#fdf6e3", "#657b83")] {
            let custom = theme(background: background, foreground: foreground)
            let done = SemanticPalette(theme: custom).color(.thinkingDoneText)
            // The derivation ends by blending toward the background, so a
            // tinted paper tints everything laid on it. What must not survive
            // is the *ink's* own hue.
            #expect(spread(of: done) <= Swift.max(spread(of: custom.background), 0.02),
                    "\(foreground) settles to a tinted line")
        }
    }

    /// `crt-monitor` and `handheld-communicator` do exactly this in their CSS:
    /// a phosphor screen writes in one ink, and they would rather the settled
    /// line stayed green than went grey. `old-school-terminal` does not, which
    /// is why olylo's chat settles to grey.
    @Test("a theme that declares the settled ink wins over the derivation")
    func declaredDoneInkWins() {
        var custom = theme(background: "#050805", foreground: "#33ff66")
        let green = RGBAColor(hexString: "#00ff41ff")!
        custom.roleOverrides[ThemeRole.thinkingDoneText.rawValue] = green
        #expect(SemanticPalette(theme: custom).color(.thinkingDoneText) == green)
    }
}
