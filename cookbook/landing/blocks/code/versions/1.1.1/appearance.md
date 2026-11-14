
- **Font**: Monospace, `var(--lp-font-mono, ui-monospace, "SF Mono", monospace)`, at `font-size: 0.8rem` and `line-height: 1.85`.
- **Background**: `var(--lp-card, rgba(255, 255, 255, 0.04))`.
- **Foreground/Text**: `var(--lp-ink, #ededed)`.
- **Padding**: `1.1rem` vertical × `1.25rem` horizontal.
- **Corner radius**: `var(--lp-radius, 14px)`.
- **Border**: `1px solid var(--lp-hairline, rgba(216, 216, 216, 0.18))`.
- **Shadow**: None. No shadow is applied by the source.
- **Min/Max size**: No enforced constraints; width grows with content (horizontal scroll as needed); height determined by line count and line-height.
- **Overflow**: Horizontal overflow MUST scroll (`overflow-x: auto`); vertical overflow MUST be visible or scroll as needed.

These are CSS custom properties supplied by the host page/theme, each with the literal fallback value shown; `lp-code` does not resolve them itself.

