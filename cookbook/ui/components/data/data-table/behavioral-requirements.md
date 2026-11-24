
### Selection and Focus

- **click-selects-row**: On a plain click of a row, the component MUST set the selection to exactly `{id}` and set the internal anchor to that id.
- **shift-click-extends-range**: On ⇧-click of a row, the component MUST set the selection to the contiguous range from the anchor to the clicked id (in the current `rows` order) and MUST leave the anchor unchanged.
- **alt-click-adds-to-selection**: On ⌥/Alt-click of a row, the component MUST add that id to the selection (leaving the selection unchanged if it is already present) and MUST set the anchor to that id. There is no ⌘/Ctrl-click binding on the pointer path; ⌘/Ctrl is not read by the click handler.
- **arrow-key-moves-selection**: When the grid is focused, ↑/↓ MUST set the selection to the previous/next row's id, set the anchor to it, and clamp at the first/last row.
- **shift-arrow-extends-range**: ⇧+↑/⇧+↓ MUST extend the selection one row from the focused row: the selection becomes the contiguous range from the anchor to the newly focused row, and the anchor stays where it was.
- **space-toggles-focused-row**: Space MUST toggle the focused row in or out of the selection.
- **focused-row-tracking**: The focused row is the row last acted on — set by a click, an arrow key or Space — and is kept apart from the selection. When the grid first receives focus with no focused row, the first row becomes focused without being selected; ↑/↓ then move from the focused row, falling back to the anchor and then to the first selected row.
- **selection-by-id**: The component MUST track selection by id (not row position) so it survives re-sorts and filters.
- **onselectionchange-new-set**: Every selection edit MUST be reported via `onSelectionChange` with a new `Set` instance (the set is owned by the caller).
- **pointer-no-focus-steal**: Pointer selection MUST NOT steal focus from an open editor elsewhere on the page.

### Sorting

- **no-internal-sort**: The component MUST NOT sort `rows` internally; it MUST report sort intent via `onSortChange` and render `rows` in the given order.
- **inert-sort-when-no-handler**: When `onSortChange` is omitted, sortable headers MUST render inert (no sort affordance fires).
- **sort-cycles-two-states**: Clicking a sortable header MUST report `asc` when the table is unsorted, sorted on a different column, or sorted `desc` on this column, and `desc` when it is already `asc` on this column. No click returns a column to unsorted; the caller clears `sort` itself.

### Row Activation

- **double-click-activates-row**: When `onRowActivate` is provided, double-clicking a row MUST invoke `onRowActivate` with that row's id, unless the click originated from an in-cell control.
- **enter-activates-focused-row**: When `onRowActivate` is provided and the table is selectable, pressing Enter MUST invoke `onRowActivate` with the currently focused row's id.

### Column Sizing (`autoSizeColumns`, opt-in)

- **size-columns-to-widest-cell**: With `autoSizeColumns`, a column with no declared `width` MUST be as wide as its WIDEST cell, measured across the header and every row, so all rows share one track and the columns LINE UP. The measuring MUST finish before paint (no misaligned frame is ever shown) and MUST repeat when the rows or columns change. See Design Decisions for why a bare `max-content` track is not enough.
- **resize-columns-by-drag**: With `autoSizeColumns`, each column (except one marked `resizable: false`) MUST offer a drag handle on its TRAILING border that sets an explicit width; DOUBLE-CLICKING the handle MUST clear it, springing the column back to fitting its content. A dragged width MUST win over the measured one, and MUST NOT go below a legible minimum (48px).
- **persist-column-widths**: Given `columnWidthsKey`, the dragged widths MUST persist (localStorage under key `data-table-cols:{columnWidthsKey}`) so a table remembers its layout across visits.
- **fill-slack-not-stretch**: Content-sized columns MUST pack to the leading edge — a trailing filler track absorbs any leftover width — rather than stretching to fill the table.
- **truncate-when-dragged-narrow**: A column dragged NARROWER than its content MUST ellipsise, never reflow (which would knock every row out of vertical alignment).

### Reordering (`reorder`, opt-in)

- **enable-row-drag-to-reorder**: When `reorder` is provided, rows MUST be draggable; releasing a row over the table MUST invoke `reorder.onDrop` with a `SortableDrop` object describing the new position.
- **respect-candrag-check**: When `reorder.canDrag` is provided, a row MUST NOT be draggable if `canDrag(id)` returns false.
- **announce-drag-state**: When a row is picked up, dragged, or dropped, the component MUST emit accessible announcements naming the row and the drop zone. The row's name is `reorder.describeRow(id)` if provided, else the table's `describeRow(row)`, else the row's id; the zone's name is the table's `ariaLabel`. See Localization for the announcement strings.

Whether reordering should be disabled while a sort or filter is in force is a caller obligation, not a component behavior — see **Design Decisions**.

### Selection Checkboxes (`showSelectionCheckboxes`, opt-in)

- **add-leading-checkbox-column**: When `showSelectionCheckboxes` is true and the table is selectable, the component MUST add a leading checkbox column that displays one checkbox per row.
- **include-select-all**: The selection checkbox column header MUST include a "Select all" checkbox that toggles the selection state of every visible row (not other pages or filters). It is a plain boolean toggle, not tri-state: it is checked only when every row in the current `rows` array is selected, and clicking it in that state clears those rows and leaves selections outside the current `rows` untouched.
- **label-checkboxes**: Each row's checkbox MUST have the accessible label `Select {name}`, where `{name}` comes from `describeRow(row)` if provided, otherwise from the row's first non-empty string field that is not the id, otherwise `row {id}`. Pass `describeRow` wherever a row has an obvious label; the field guess depends on object key order.
- **checkbox-click-not-select-row**: Clicking a selection checkbox MUST NOT trigger the row's own selection handling; it MUST only toggle that row's checkbox.

### Inline-Editable Cells

- **ignore-cell-control-events**: The selectable grid's keyboard and pointer handling MUST ignore events that originate from a control INSIDE a cell (input / textarea / select / button / link / contenteditable / `[role='button']`), so selection and inline editing can coexist. The reasoning is in Design Decisions.
- **cell-control-click-guards-selection**: A click on an in-cell control MUST still move the selection to its row, but only as a guard, never a shrink: when at most one row is already selected, the click MUST call the single-row selection handler for its row (so a details pane follows the row being edited); when more than one row is already selected, the click MUST leave the selection unchanged. Either way the control's own click is left intact.

### Empty and Loading States

- **renders-empty-state**: When `rows` is empty and `loading` is false, the component MUST render `emptyLabel` in place of rows.
- **renders-loading-state**: When `loading` is true, the component MUST render a loading affordance (`role="status"`) instead of rows, taking precedence over the empty state.

### Action-List Mode (Unselectable)

- **action-list-mode-when-unselectable**: When BOTH `selectedIds` and `onSelectionChange` are omitted, the component MUST render rows with no selection affordance — no `aria-selected`, no `data-selected`, no pointer cursor, and clicking a row MUST NOT select it — so in-cell controls (buttons, menus) own the interaction.

