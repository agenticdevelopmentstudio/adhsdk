
- Trigger: `<button>` with `aria-haspopup="listbox"`, `aria-expanded`, `aria-label={ariaLabel}`.
- Surface: the `role="listbox"` container itself (not a row) owns `aria-activedescendant`, pointing at the currently highlighted option's `id`; rows are `role="option"` with `aria-selected` on the committed row and `data-highlighted` on the selection.
- Other row: also `role="option"`, `aria-selected` mirroring whether Other is committed; it additionally contains a labeled `<input>` (`aria-label` from `otherLabel`) and the OK `<button>` (native `disabled` while the input is empty; a disabled button leaves the tab order, so it is skipped by Tab and not clickable) — an option row with focusable descendants, which departs from a plain listbox/option tree (see **screen-reader-support** in Compliance).
- Focus returns to the trigger on close.

