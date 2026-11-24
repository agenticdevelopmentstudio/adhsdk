
- The ⇧-click range is computed over the **current visible order** of `rows`.
- Ids no longer present in `rows` are pruned by the caller, not the component.
- With `onSortChange` omitted, sortable headers are inert (no sorting offered).
- `loading` and an empty `rows` array each render their dedicated state; `loading` takes precedence.
- The "Select all" checkbox is a plain boolean toggle, not tri-state/indeterminate: it is checked only when every row in the current `rows` array is selected. Clicking it again in that state clears those rows rather than being a no-op, while selections outside the current `rows` array (other pages, filtered-out rows) are left untouched either way.
- Clicking a sortable header cycles between two states, not three: a header that is unsorted, sorted on a different column, or sorted descending on this column goes to ascending on the next click; a header already ascending on this column goes to descending. There is no click that returns a column to unsorted — the caller clears `sort` itself for that.
- Column widths loaded from `localStorage` are parsed as JSON; a parse failure falls back to an empty width map (so all columns behave as freshly measured). The parsed value's shape — that each entry is actually a number — is not validated beyond that.
- If localStorage is full or access is blocked, widths still apply for the session but are not persisted.
- A column dragged narrower than 48px is clamped to that minimum.
- A drag-to-reorder gesture, picked up from the row's drag handle, does not also select the row — dragging and selecting are different acts. This is distinct from a plain click landing on an in-cell control, which moves the selection to that row only when at most one row was already selected, and otherwise leaves a multi-row selection untouched, per **not-hijack-cell-controls**.
- Double-click activation (`onRowActivate`) fires in action-list mode as well as in a selectable table — it is gated only on `onRowActivate` being provided, not on `selectedIds`/`onSelectionChange`. Enter activation, by contrast, is reachable only when the grid is selectable, because only the selectable grid attaches a key handler at all.
- When the focused row's id is no longer present in `rows`, the component does not reset `aria-activedescendant` or internal focus tracking on its own; the caller is expected to keep `selectedIds` (and, indirectly, focus) in sync with `rows`.

