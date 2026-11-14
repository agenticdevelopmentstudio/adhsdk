
- **Structure**: Block-level container rendered as a `<div>`. The component applies no inline styles itself; all visual treatment comes from the `lp-closer` CSS class in `packages/web/packages/landing/src/css/blocks.css`.
- **Background**: Transparent — no background rule is set on `.lp-closer` or `.lp-closer h2`.
- **Padding**: `.lp-closer` sets `padding-top: var(--lp-gap, clamp(3.75rem, 8vw, 6.5rem))`; no other padding is applied.
- **Border**: `.lp-closer` sets `border-top: 1px solid var(--lp-hairline, rgba(216, 216, 216, 0.18))`; there is no border on any other edge.
- **Text alignment**: `.lp-closer` sets `text-align: center`. The title's `h2` additionally sets `text-wrap: balance` and a responsive `font-size: clamp(1.5rem, 4vw, 2.4rem)` with `font-weight: 200`.
- **Positioning**: `.lp-closer` sets `position: relative`.
- **Title line height**: `.lp-closer h2` sets `line-height: 1.25`.
- **Title emphasis**: A `<b>` inside the title (`.lp-closer h2 b`) renders at `font-weight: 400` in the accent colour `var(--lp-accent-bright, #d8d8d8)`.
- **Child paragraphs**: `.lp-closer p` sets `margin: 1.1rem auto 2rem`, `max-width: 48ch` (centred), `color: var(--lp-ink-dim, #a0a0a0)` and `font-weight: 300`.
- **Width**: 100% of container — default block-level `<div>` behavior; `.lp-closer` sets no explicit width.

