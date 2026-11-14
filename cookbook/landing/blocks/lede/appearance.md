
- **Element**: Semantic `<p>` HTML element
- **Base class**: `lp-lede`
- **Color**: `var(--lp-ink-dim, #a0a0a0)`
- **Font**: weight 300, size `1.02rem`
- **Measure**: `max-width: 72ch` (see **constrain-paragraph-measure** and the 72ch Design Decision); `ch` is the width of the `0` glyph of the paragraph's font, which the host chooses (the shipped site sets one monospace font-family token)
- **Spacing**: `margin-top: 1.15rem` by default; `0.9rem` between two consecutive ledes (`.lp-lede + .lp-lede`); `1.8rem` when a lede is the first child of `.lp-wrap`
- **Text wrapping**: `text-wrap: pretty`
- **Emphasis (`<em>`)**: rendered in `var(--lp-accent-bright, #d8d8d8)` with `font-style: normal` — color signals emphasis instead of italics. This styling is informative only; the component has no requirement for it and no test vector covers it.
- **Additional styling**: Applied via optional `className` prop

