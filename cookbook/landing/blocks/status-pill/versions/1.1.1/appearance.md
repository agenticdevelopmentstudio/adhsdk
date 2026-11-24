
- **Corner radius**: `border-radius: 99px` (fully rounded pill).
- **Padding**: `0.32rem` vertical × `0.6rem` horizontal.
- **Font**: weight 600, size `0.62rem`, line-height 1, `var(--lp-font-mono, ui-monospace, "SF Mono", monospace)`; `letter-spacing: 0.16em`; `text-transform: uppercase` (locale-sensitive — see **Localization**).
- **Background**: transparent by default; `var(--lp-accent-dim, rgba(216, 216, 216, 0.14))` when `free={true}`.
- **Border**: `1px solid var(--lp-hairline, rgba(216, 216, 216, 0.18))` by default; border color becomes `var(--lp-status-free-border, rgba(216, 216, 216, 0.5))` when `free={true}`.
- **Foreground/Text**: `var(--lp-accent, #9a9a9a)` by default; `var(--lp-accent-bright, #d8d8d8)` when `free={true}`.
- **Shadow**: None.
- **Min/Max size**: No explicit min/max; `white-space: nowrap` prevents children from wrapping (see the long-text edge case below), so width grows with content and height follows the font's line box plus padding.

