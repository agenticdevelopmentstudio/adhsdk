
- The button always carries an accessible name: `aria-label={label}`. Because the
  glyph is `aria-hidden`, the name comes solely from `label` and never leaks the icon.
- It renders a real `<button type="button">` (through `Button`), so it is focusable
  and operable by Enter/Space, with the family focus-visible ring.
- `title` mirrors `label` at idle and becomes `"Copied!"` on success — a supplemental
  hover tooltip, not the accessible name (which stays `label` throughout).
- Success is signalled by more than color for sighted users: the glyph changes
  (`Copy` → `Check`) and the `title` changes to `"Copied!"`, so the affirmation is not
  conveyed by the green tint alone.
- The success state change is not actively announced to screen reader users: there is
  no `aria-live` region, and the accessible name (`aria-label`) never changes — it
  stays `label` throughout, including during the success flash. A screen reader user
  who clicks the button does not receive an equivalent affirmation to the glyph swap
  a sighted user sees.

