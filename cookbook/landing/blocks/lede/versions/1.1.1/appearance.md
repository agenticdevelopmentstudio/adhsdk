
- **Element**: Semantic `<p>` HTML element
- **Base class**: `lp-lede`
- **Color**: `var(--lp-ink-dim, #a0a0a0)`
- **Font**: weight 300, size `1.02rem`
- **Measure**: `max-width: 72ch` (see **constrain-paragraph-measure**) — wider than the 60ch a proportional face would want, because the site is set in one monospace face where a character is narrower than average
- **Spacing**: `margin-top: 1.15rem` by default; `0.9rem` between two consecutive ledes (`.lp-lede + .lp-lede`); `1.8rem` when a lede is the first child of `.lp-wrap`
- **Text wrapping**: `text-wrap: pretty`
- **Emphasis (`<em>`)**: rendered in `var(--lp-accent-bright, #d8d8d8)` with `font-style: normal` — color signals emphasis instead of italics
- **Additional styling**: Applied via optional `className` prop
- **Styling source**: `packages/web/packages/landing/src/css/blocks.css` (`.lp-lede` rule)

