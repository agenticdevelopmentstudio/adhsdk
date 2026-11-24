
- The ⇧-click range is computed over the **current visible order** of `rows`.
- Ids no longer present in `rows` are pruned by the caller, not the component.
- With `onSortChange` omitted, sortable headers are inert (no sorting offered).
- `loading` and an empty `rows` array each render their dedicated state; `loading` takes precedence.
- Column widths loaded from `localStorage` are parsed as JSON; a parse failure falls back to an empty width map (so all columns behave as freshly measured). The parsed value's shape — that each entry is actually a number — is not validated beyond that.
- If localStorage is full or access is blocked, widths still apply for the session but are not persisted.
- A column dragged narrower than 48px is clamped to that minimum.
- A drag-to-reorder gesture, picked up from the row's drag handle, does not also select the row — dragging and selecting are different acts. This is distinct from a plain click landing on an in-cell control, which moves the selection to that row only when at most one row was already selected, and otherwise leaves a multi-row selection untouched, per **cell-control-click-guards-selection**.
- Double-click activation (`onRowActivate`) fires in action-list mode as well as in a selectable table — it is gated only on `onRowActivate` being provided, not on `selectedIds`/`onSelectionChange`. Enter activation, by contrast, is reachable only when the grid is selectable, because only the selectable grid attaches a key handler at all.
- When the focused row's id is no longer present in `rows`, the component does not reset `aria-activedescendant` or internal focus tracking on its own; the caller is expected to keep `selectedIds` (and, indirectly, focus) in sync with `rows`.


- The sort cycle and the select-all toggle are specified in **sort-cycles-two-states** and **include-select-all**.
