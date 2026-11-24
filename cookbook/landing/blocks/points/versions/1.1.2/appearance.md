
- **Marker appearance**: Each `<li>`'s `::before` pseudo-element supplies the marker: `content: var(--lp-points-mark, "\2192")` for unordered lists, or `counter(lp-point) var(--lp-points-ordinal-suffix, ".")` for ordered lists. Both the glyph and the ordinal suffix are CSS custom-property tokens the host can override.
- **Item spacing**: The root `.lp-points` is a single-column CSS Grid with `gap: 0.75rem` between `<li>` rows, and sets `list-style: none` so the browser's default marker is suppressed in favor of the `::before` token.
- **Typography**: Text within the `<span>` inherits `.lp-points li`'s `font-size: 0.94rem`, `font-weight: 300`, and `line-height: 1.7`; no inline typography overrides.
- **Grid layout**: The two-column structure (marker column, content column) is CSS Grid on each `<li>` (`grid-template-columns: 1.4rem 1fr`, widened to `1.9rem 1fr` when ordered) — not on the root, which is a single-column grid used only for row spacing.
- **Bold text**: Term text rendered with `<b>` element; CSS raises it to `font-weight: 500` and a brighter `--lp-ink` color token for visual weight.

