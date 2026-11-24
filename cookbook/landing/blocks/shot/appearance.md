
- **Frame background**: Dark, `var(--lp-raise, #1c1c1c)` — the same macOS-style chrome on every platform (see **WinUI 3** in Platform Notes).
- **Title bar**: `.lp-shot__bar`, a flex row (0.45rem gap, 0.55rem/0.75rem padding) with a bottom hairline border and a `linear-gradient(var(--lp-raise), var(--lp-shot-bar-shade))` background.
- **Dots**: Three `.lp-shot__dot` circles, 10×10px, all colored with the same `var(--lp-shot-dot, rgba(237, 237, 237, 0.22))` — decorative traffic-light styling; the three dots are not functionally distinct red/yellow/green.
- **Title text**: `.lp-shot__name`, left-aligned immediately after the dots in the flex row (`margin-left: 0.4rem`), 0.7rem, letter-spaced, `var(--lp-ink-dim, #a0a0a0)`.
- **Placeholder**: `.lp-shot__placeholder`, a 45° repeating diagonal hatch (`var(--lp-shot-hatch, rgba(216, 216, 216, 0.05))`) to signal incompleteness.
- **Placeholder text**: The caption is wrapped in a `<b>` element, but CSS overrides it to normal weight (`font-weight: 400`), lowercase, `var(--lp-ink-dim, #a0a0a0)` — visually normal weight despite the `<b>` tag.
- **Pending label**: Rendered as plain text directly inside `.lp-shot__placeholder`, above the caption; it has no dedicated style rule, so it inherits the placeholder's own base text (0.78rem, uppercase, 0.14em letter-spacing, `var(--lp-accent, #9a9a9a)`) rather than a distinct smaller font weight.

