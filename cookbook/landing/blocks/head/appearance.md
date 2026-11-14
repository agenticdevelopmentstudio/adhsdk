
Styling is applied via external CSS classes (`lp-head`, `lp-eyebrow`). The source sets no inline styles; every value comes from `blocks.css`. The rules live in `packages/web/packages/landing/src/css/blocks.css` (`.lp-head`, `.lp-eyebrow`, `.lp-eyebrow::before`, `.lp-head h2`, `.lp-head h2 b`).

Key values, taken from `blocks.css`:

- **Container (`.lp-head`)**: `max-width: 48rem`; `margin-bottom: var(--lp-head-gap, 2.6rem)`.
- **Eyebrow (`.lp-eyebrow`)**: a flex row, `gap: 0.85rem`, `width: fit-content`, `font-size: 0.82rem`, `font-weight: 500`, `letter-spacing: 0.28em`, uppercase, `color: var(--lp-accent-bright, #d8d8d8)`, `margin-bottom: var(--lp-eyebrow-gap, 1.2rem)`.
- **Eyebrow rule (`.lp-eyebrow::before`)**: a leading bar `2.2rem` wide and `2px` tall, `background: var(--lp-accent, #9a9a9a)`.
- **Title (`.lp-head h2`)**: `font-size: clamp(1.5rem, 3.6vw, 2.3rem)`, `font-weight: 200`, `line-height: 1.25`, `letter-spacing: 0.01em`, `text-wrap: balance`.
- **Title emphasis (`.lp-head h2 b`)**: `font-weight: 400` and `color: var(--lp-accent-bright, #d8d8d8)`.
