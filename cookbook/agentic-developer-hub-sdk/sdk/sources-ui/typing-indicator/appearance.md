
- **Dot pulse (fallback path)**:
  - Dots: Three circular shapes, 7×7 points/pixels each
  - Dot spacing: 4 points/pixels horizontal
  - Dot corners: Rounded (50% border radius = 3.5 radius)
  - Dot color: Semantic palette `.secondaryText`
  - Dot opacity: 30% (idle), 100% (active)
  - Animation: Sequential fade, 0.2s transition time per dot, 0.35s cycle interval
  - Minimum component size: 48 × 28 points/pixels

- **Phase-driven line (words-enabled path)**:
  - Font: Semantic palette caption font
  - Text color (active/thinking): `.personaName`
  - Text color (done): `.thinkingDoneText`
  - Text color (idle): `.thinkingIdleText`
  - Glyph box width (macOS/AppKit): Calculated as the maximum of (`1.6ch` where `ch` is the width of the `0` character in the caption font) and the widest glyph character in the configured frames and done glyph. Box is centered.
  - Gap between glyph and words (macOS/AppKit): `0.45em` (45% of caption font point size, rounded)
  - Baseline alignment (macOS/AppKit): Both glyph and word text align to first baseline
  - Line wrapping: Words may truncate at tail if space is constrained
  - Minimum component size: 48 × 28 points/pixels
  - Horizontal padding: 4 points/pixels leading and trailing
  - No background fill or border

- **Colorful mode**:
  - When active, glyph and word colors shift to the randomly generated non-green HSL hue
  - Color cycle interval: 1000ms during thinking or utterance phases (web only)
  - macOS: a new hue is drawn only when a fresh think begins or `say()` is called; it is held for the rest of that phase rather than recycled every second
  - Color does NOT apply to settled/done line

- **Tint mode**:
  - Tint color and apply scope (icons/words/both) MUST NOT apply to settled/done line

