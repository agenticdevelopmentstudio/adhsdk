
- **Missing `href`.** `href` is a forwarded native prop, not required by the
  component; omitting it yields an anchor with no destination (the caller's
  responsibility), while `target`/`rel` are still applied.
- **Icon-plus-text without glyph.** With `glyph={false}` and both a leading icon
  and text as children, only the text contributes the accessible name (the icon
  is `aria-hidden` at the call site).
- **Long labels.** `whitespace-nowrap` keeps the "{label} ↗" pair on one line; a
  consumer that needs wrapping overrides it through `className`.
- **Internal links.** This is for *external* jump-outs; in-app navigation SHOULD
  use the app router link, not a new-tab anchor.
- **Overriding `target`/`rel`.** The safe defaults are set *after* `...props`
  spreads, so the safe contract is guaranteed — a caller-supplied `target`/`rel`
  in props cannot accidentally drop the safe new-tab behavior.

