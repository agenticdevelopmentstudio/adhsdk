
- `role="grid"` (selectable) or `role="table"` (action-list) with `aria-label`; header is `role="row"` / `role="columnheader"` (sortable headers set `aria-sort` to "ascending" or "descending"); body rows are `role="row"` with `aria-selected` (selectable only); cells are `role="gridcell"` (selectable) or `role="cell"` (action-list).
- The grid is focusable (`tabIndex=0`) when selectable; a roving `data-focused` attribute tracks keyboard focus; `aria-activedescendant` points at it.
- Pointer selection does not steal focus from an open editor elsewhere.
- Selection checkboxes have accessible labels derived from row content (`Select Ada`, `Select Grace`).
- Sortable headers are buttons with `aria-sort` attributes.
- Column resize handles are separators with `aria-orientation="vertical"` and `aria-label="Resize column {key}"`.
- Drag operations emit accessible announcements via the dnd system (row name, drop zone name).
- Loading state uses `role="status"` for the affordance message.

