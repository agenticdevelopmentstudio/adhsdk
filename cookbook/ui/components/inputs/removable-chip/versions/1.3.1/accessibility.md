
- The ✕ is a **real `<button type="button">`**, so it is focusable and keyboard-operable
  (Enter/Space) natively — removal is not pointer-only.
- The button's accessible name is `removeLabel` (`aria-label`), which callers typically
  set to a value-specific label such as `` `Remove ${value}` ``. Combined with the badge
  body, each chip reads as "`<value>`, Remove `<value>`" to AT.
- The ✕ glyph is `aria-hidden`, so the icon does not add a second, redundant label —
  the button's `aria-label` is the single accessible name.
- The chip body is a `Badge` (`<span>`); it is not itself interactive, keeping one
  clear action (remove) per chip.

