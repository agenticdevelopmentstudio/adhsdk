import AppKit
import CoreText

/// Where a prompt glyph's baseline has to sit for the glyph to look centred on
/// the line of text it introduces.
///
/// Sharing a baseline is not the same as looking aligned once the two runs are
/// in different faces, and here they always are: a terminal theme's face is
/// missing the glyph. VT323 carries 568 glyphs and none of them is `❯` (nor
/// `↵`, `✱` or `⊙`), so the prompt is drawn by whatever face the system
/// substitutes — one with its own ascent, descent and ink height — and on the
/// composer's shared baseline it rode about two points high.
///
/// Both halves of the correction are read from the fonts, never nudged by a
/// constant, so it holds at every text scale and on a theme with a different
/// face.
public enum PromptGlyphAlignment {

    /// How far *below* the text's baseline to put the prompt's, so that the
    /// middle of the glyph's ink lands on the middle of the text.
    ///
    /// The text's middle comes from the font rather than from whatever is
    /// currently typed — the band between the cap height and the descender,
    /// which is what mixed-case text occupies. Measuring the live string
    /// instead would make the prompt hop every time someone typed a "g".
    ///
    /// Answers `0` for a glyph with no ink (an empty prompt, or a character
    /// the substituted face has nothing for), which is also the right answer:
    /// nothing to centre.
    public static func baselineDrop(
        for glyph: String, in promptFont: NSFont, centeredOn textFont: NSFont
    ) -> CGFloat {
        guard let inkCenter = inkCenterAboveBaseline(of: glyph, in: promptFont) else { return 0 }
        let textCenter = (textFont.capHeight + textFont.descender) / 2
        return inkCenter - textCenter
    }

    /// The middle of `glyph`'s ink measured up from the baseline, in the face
    /// that really draws it. `CTFontCreateForString` resolves the substitution
    /// `promptFont` would otherwise make silently — asking `promptFont` itself
    /// for metrics it has no glyph for is what made the naive version wrong.
    static func inkCenterAboveBaseline(of glyph: String, in promptFont: NSFont) -> CGFloat? {
        let utf16 = Array(glyph.utf16)
        guard !utf16.isEmpty else { return nil }
        let resolved = CTFontCreateForString(
            promptFont, glyph as CFString, CFRange(location: 0, length: utf16.count))

        var characters = utf16
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        guard CTFontGetGlyphsForCharacters(resolved, &characters, &glyphs, characters.count) else {
            return nil
        }
        let ink = CTFontGetBoundingRectsForGlyphs(resolved, .default, glyphs, nil, glyphs.count)
        guard ink.height > 0 else { return nil }
        return ink.midY
    }
}
