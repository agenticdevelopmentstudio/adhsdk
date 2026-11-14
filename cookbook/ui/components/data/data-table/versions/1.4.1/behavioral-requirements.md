
### Selection and Focus

- **click-selects-row**: On a plain click of a row, the component MUST set the selection to exactly `{id}` and set the internal anchor to that id.
- **shift-click-extends-range**: On ⇧-click of a row, the component MUST set the selection to the contiguous range from the anchor to the clicked id (in the current `rows` order) and MUST leave the anchor unchanged.
- **alt-click-adds-to-selection**: On ⌥/Alt-click of a row, the component MUST add that id to the selection (leaving the selection unchanged if it is already present) and MUST set the anchor to that id. There is no ⌘/Ctrl-click binding on the pointer path; ⌘/Ctrl is not read by the click handler.
- **arrow-key-moves-selection**: When the grid is focused, ↑/↓ MUST set the selection to the previous/next row's id, set the anchor to it, and clamp at the first/last row.
- **shift-arrow-extends-range**: ⇧+↑/⇧+↓ MUST extend the selection one row from the anchor.
- **space-toggles-focused-row**: Space MUST toggle the focused row in or out of the selection.
- **selection-by-id**: The component MUST track selection by id (not row position) so it survives re-sorts and filters.
- **onselectionchange-new-set**: Every selection edit MUST be reported via `onSelectionChange` with a new `Set` instance (the set is owned by the caller).
- **pointer-no-focus-steal**: Pointer selection MUST NOT steal focus from an open editor elsewhere on the page.

### Sorting

- **no-internal-sort**: The component MUST NOT sort `rows` internally; it MUST report sort intent via `onSortChange` and render `rows` in the given order.
- **inert-sort-when-no-handler**: When `onSortChange` is omitted, sortable headers MUST render inert (no sort affordance fires).

### Row Activation

- **double-click-activates-row**: When `onRowActivate` is provided, double-clicking a row MUST invoke `onRowActivate` with that row's id, unless the click originated from an in-cell control.
- **enter-activates-focused-row**: When `onRowActivate` is provided and the table is selectable, pressing Enter MUST invoke `onRowActivate` with the currently focused row's id.

### Column Sizing (`autoSizeColumns`, opt-in)

- **size-columns-to-widest-cell**: With `autoSizeColumns`, a column with no declared `width` MUST be as wide as its WIDEST cell — measured across the header and every row, so all rows share one track and the columns LINE UP. A `max-content` track alone does NOT satisfy this: each row is its own grid (it must be, to carry the row's background/selection), so `max-content` would size every row independently and the header would not align with the body. The component therefore renders one pass at `max-content` (each cell at its natural width), measures the widest cell per column, and locks that in as an explicit px track — both passes BEFORE paint, so no misaligned frame is ever shown. It MUST re-measure when the rows or columns change.
- **resize-columns-by-drag**: With `autoSizeColumns`, each column (except one marked `resizable: false`) MUST offer a drag handle on its TRAILING border that sets an explicit width; DOUBLE-CLICKING the handle MUST clear it, springing the column back to fitting its content. A dragged width MUST win over the measured one, and MUST NOT go below a legible minimum (48px).
- **persist-column-widths**: Given `columnWidthsKey`, the dragged widths MUST persist (localStorage under key `data-table-cols:{columnWidthsKey}`) so a table remembers its layout across visits.
- **fill-slack-not-stretch**: Content-sized columns MUST pack to the leading edge — a trailing filler track absorbs any leftover width — rather than stretching to fill the table.
- **truncate-when-dragged-narrow**: A column dragged NARROWER than its content MUST ellipsise, never reflow (which would knock every row out of vertical alignment).

### Reordering (`reorder`, opt-in)

- **enable-row-drag-to-reorder**: When `reorder` is provided, rows MUST be draggable; releasing a row over the table MUST invoke `reorder.onDrop` with a `SortableDrop` object describing the new position.
- **respect-candrag-check**: When `reorder.canDrag` is provided, a row MUST NOT be draggable if `canDrag(id)` returns false.
- **announce-drag-state**: When a row is picked up, dragged, or dropped, the component MUST emit accessible announcements describing the row and the drop zone using `reorder.describeRow` (or the row's `describeRow` function, or a fallback description).

Whether reordering should be disabled while a sort or filter is in force is a caller obligation, not a component behavior — see **Design Decisions**.

### Selection Checkboxes (`showSelectionCheckboxes`, opt-in)

- **add-leading-checkbox-column**: When `showSelectionCheckboxes` is true and the table is selectable, the component MUST add a leading checkbox column that displays one checkbox per row.
- **include-select-all**: The selection checkbox column header MUST include a "Select all" checkbox that toggles the selection state of every visible row (not other pages or filters).
- **label-checkboxes**: Each row's checkbox MUST have an accessible label derived from `describeRow(row)` if provided, or by looking for the first non-empty string field in the row that is not the id, or falling back to `row {id}`.
- **checkbox-click-not-select-row**: Clicking a selection checkbox MUST NOT trigger the row's own selection handling; it MUST only toggle that row's checkbox.

### Inline-Editable Cells

- **not-hijack-cell-controls**: The selectable grid's keyboard/pointer machinery MUST ignore events that originate from a control INSIDE a cell (input / textarea / select / button / link / contenteditable / `[role='button']`). Its Arrow/Space handlers call `preventDefault`, which would swallow a space typed into an inline editor or a native select's keyboard use; and its mousedown-`preventDefault` would stop the control taking focus at all. Without this, selection and inline editing are mutually exclusive — a selectable table could not host an editable cell. A click on an in-cell control MUST still move the selection to its row, but only as a guard, never a shrink: when at most one row is already selected, the click MUST call the single-row selection handler for its row (so a details pane follows the row being edited); when more than one row is already selected, the click MUST leave the selection unchanged (a bulk selection is never collapsed to one row by an in-cell control click). Either way the control's own click is left intact.

### Empty and Loading States

- **renders-empty-state**: When `rows` is empty and `loading` is false, the component MUST render `emptyLabel` in place of rows.
- **renders-loading-state**: When `loading` is true, the component MUST render a loading affordance (`role="status"`) instead of rows, taking precedence over the empty state.

### Action-List Mode (Unselectable)

- **action-list-mode-when-unselectable**: When BOTH `selectedIds` and `onSelectionChange` are omitted, the component MUST render rows with no selection affordance — no `aria-selected`, no `data-selected`, no pointer cursor, and clicking a row MUST NOT select it — so in-cell controls (buttons, menus) own the interaction.

