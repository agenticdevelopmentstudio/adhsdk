
All values come from the `.lp-hero-nav` rules in `flow.css`.

- **Layout**: A wrapping flex row (`display: flex`, `flex-wrap: wrap`) with `align-items: center` and `justify-content: center`.
- **Font**: `var(--lp-font-mono, ui-monospace, "SF Mono", monospace)`, 0.8rem, `letter-spacing: 0.12em`, `text-transform: uppercase`.
- **Link**: `display: inline-block`, `position: relative`, padding `8px 0`, no underline (`text-decoration: none`), `cursor: pointer`, colour `var(--lp-ink-dim, #a0a0a0)`, with `transition: color 0.3s`.
- **Link hover and focus-visible**: Colour `var(--lp-accent-bright, #d8d8d8)`.
- **Link focus ring**: `outline: 2px solid var(--lp-accent, #9a9a9a)` with `outline-offset: 3px`, on `:focus-visible` only.
- **Separator**: Colour is `--lp-ink-dim` (fallback `#a0a0a0`) mixed 60% with transparent via `color-mix`, padding `0 0.75rem`, `user-select: none`.
- **Phone width (max 640px)**: Separators are `display: none`; the nav gets `column-gap: 1.2rem`.
- **Background, border, shadow, corner radius**: None; the nav draws none of these.
- **Min/Max size**: None set; the row is as wide as its links and wraps at its container's width.

