import Testing
import AppKit
@testable import AgenticDeveloperHubSDKUI

/// The drop that puts a shell prompt's glyph on the middle of the line it
/// introduces.
@MainActor
@Suite("PromptGlyphAlignment")
struct PromptGlyphAlignmentTests {

    private let font = NSFont.systemFont(ofSize: 14)

    @Test("a glyph with no ink asks for no correction")
    func inklessGlyphsDropNothing() {
        #expect(PromptGlyphAlignment.baselineDrop(for: "", in: font, centeredOn: font) == 0)
        // A space has an advance but no ink; a baseline drop derived from an
        // empty bounding box would be a division by nothing dressed up as a
        // number.
        #expect(PromptGlyphAlignment.baselineDrop(for: " ", in: font, centeredOn: font) == 0)
    }

    /// A capital "X" is the case the arithmetic can be checked by hand: its
    /// ink runs from the baseline to the cap height, so its middle is
    /// `capHeight / 2`, and the text's middle is `(capHeight + descender) / 2`.
    /// The drop between them is therefore exactly `-descender / 2` — a real
    /// number this function has to produce, not a tautology.
    @Test("the drop is the arithmetic it claims to be")
    func dropMatchesTheMetrics() {
        let drop = PromptGlyphAlignment.baselineDrop(for: "X", in: font, centeredOn: font)
        // Loose because real faces overshoot the cap height by a fraction of a
        // point; tight enough to fail if the sign or the halving is wrong.
        #expect(abs(drop - (-font.descender / 2)) < 0.5)
        // Down, not up: descender is negative, so this is positive.
        #expect(drop > 0)
    }

    @Test("the drop scales with the type, so it survives the text-size slider")
    func dropScalesWithTheFont() {
        let small = NSFont.systemFont(ofSize: 12)
        let large = NSFont.systemFont(ofSize: 24)
        let atSmall = PromptGlyphAlignment.baselineDrop(for: "\u{276F}", in: small, centeredOn: small)
        let atLarge = PromptGlyphAlignment.baselineDrop(for: "\u{276F}", in: large, centeredOn: large)
        // Fails the moment anyone replaces this with a constant nudge, which
        // is the whole reason it is derived.
        #expect(abs(atLarge - atSmall * 2) < 0.5)
    }

    /// The premise of the whole exercise: the composer's face does not have
    /// the prompt, so its own metrics are the wrong ones to measure against.
    @Test("the glyph is measured in the face that really draws it")
    func measuresTheSubstitutedFace() throws {
        ToolkitFonts.registerBundledFonts()
        let vt323 = try #require(NSFont(name: "VT323", size: 15))
        let center = try #require(
            PromptGlyphAlignment.inkCenterAboveBaseline(of: "\u{276F}", in: vt323))

        // VT323 carries 568 glyphs and `\u{276F}` is not among them. Asking
        // VT323 for a bounding box it has nothing for answers the empty rect;
        // a real measurement means the substitution was resolved.
        #expect(center > 0)
        #expect(center < vt323.pointSize)
    }
}
