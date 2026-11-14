
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | click-selects-row | click row Ada | selection = `{Ada}`, anchor = Ada |
| T2 | shift-click-extends-range | click Ada, ⇧-click Grace | selection = contiguous Ada…Grace |
| T3 | alt-click-adds-to-selection | ⌥-click an unselected row | row added to selection, anchor set to it |
| T3b | alt-click-adds-to-selection | ⌥-click an already-selected row | selection unchanged |
| T4 | arrow-key-moves-selection | focus grid, press ↓ | selection moves to next row, clamps at end |
| T5 | shift-arrow-extends-range | rows Ada, Bob, Cy; click Ada (anchor), press ⇧+↓ twice | selection = `{Ada, Bob, Cy}`, anchor still Ada |
| T6 | space-toggles-focused-row | focus row, press Space | focused row toggles |
| T7 | no-internal-sort | click sortable header | `onSortChange` fires with toggled dir; `rows` unchanged by component |
| T8 | selection-by-id | reorder `rows` after selecting | selection preserved across reorder |
| T9 | inert-sort-when-no-handler | render without `onSortChange`, click a sortable header | no sort affordance fires; `onSortChange` is never called |
| T10 | action-list-mode-when-unselectable | render without `selectedIds`/`onSelectionChange`; click a row | rows carry no `aria-selected`/`data-selected`, no pointer cursor; the click selects nothing; in-cell buttons remain operable |
| T11 | double-click-activates-row | double-click row with `onRowActivate` | `onRowActivate(id)` fires |
| T11b | double-click-activates-row | double-click an in-cell control (e.g. a button) with `onRowActivate` provided | `onRowActivate` does not fire; the control's own double-click behavior is unaffected |
| T12 | enter-activates-focused-row | focus row, press Enter with `onRowActivate` | `onRowActivate(id)` fires |
| T13 | size-columns-to-widest-cell | render with `autoSizeColumns: true` | header and body cells align; column is as wide as widest cell |
| T14 | resize-columns-by-drag | with `autoSizeColumns`, drag a column header's trailing border to 200px from the header's left edge | the column's track is `200px` |
| T15 | truncate-when-dragged-narrow | drag column narrower than content | cell text ellipsises; row heights remain aligned |
| T16 | enable-row-drag-to-reorder | drag row with `reorder` prop | `reorder.onDrop` fires with new position |
| T17 | respect-candrag-check | drag row where `canDrag(id)` = false | row does not enter dragged state; `onDrop` does not fire |
| T18 | add-leading-checkbox-column | render with `showSelectionCheckboxes: true` | leading column added with checkbox per row |
| T19 | include-select-all | click "Select all" checkbox | all visible rows selected |
| T20 | checkbox-click-not-select-row | click row checkbox | checkbox toggles; `onSelectionChange` fires; the row's own click-selection handling does not fire |
| T21 | onselectionchange-new-set | click row Ada, capture the `Set` passed to `onSelectionChange`, then click row Grace | the second call receives a new `Set` instance, distinct from the first |
| T22 | pointer-no-focus-steal | focus an in-cell editor elsewhere on the page, then mousedown a row (not on an in-cell control) | the editor keeps focus; the grid does not receive it |
| T23 | persist-column-widths | drag a column with `columnWidthsKey` set, then remount the table with the same key | the dragged width is read back from `localStorage` and applied |
| T24 | fill-slack-not-stretch | render with `autoSizeColumns: true` and columns narrower than the container | a trailing filler track absorbs the slack; content-sized columns stay left-packed |
| T25 | ignore-cell-control-events | focus an in-cell `<input>`, press Space | the grid's Space handler does not fire; the input receives the space character |
| T26 | announce-drag-state | pick up a row via `reorder` | an accessible announcement naming the row and drop zone is emitted |
| T27 | label-checkboxes | render a row checkbox with no `describeRow` prop and no other non-empty string field on the row | checkbox `aria-label` falls back to `row {id}` |
| T28 | renders-empty-state | render with `rows: []`, `loading: false` | `emptyLabel` is shown in place of rows |
| T29 | renders-loading-state | render with `loading: true` and non-empty `rows` | the `role="status"` loading affordance is shown instead of rows |
| T30 | cell-control-click-guards-selection | at most one row selected; click (not on the checkbox) an in-cell control in an unselected row | that row becomes the selection (single-row select fires), and the control's own click still fires |
| T31 | cell-control-click-guards-selection | more than one row selected; click (not on the checkbox) an in-cell control in any row | the selection is unchanged (no row is added or removed), and the control's own click still fires |
| T32 | sort-cycles-two-states | sorted `desc` on a column; click its header | `onSortChange` fires with `{ key, dir: "asc" }` |
| T33 | sort-cycles-two-states | sorted `asc` on a column; click its header | `onSortChange` fires with `{ key, dir: "desc" }`; no click ever reports unsorted |
| T34 | include-select-all | every row selected plus one id outside `rows`; click "Select all" | every row is deselected; the outside id stays selected |
| T35 | resize-columns-by-drag | with `autoSizeColumns`, drag a column to 200px, then double-click its resize handle | the dragged width is cleared and the column returns to its measured content width |
| T36 | resize-columns-by-drag | with `autoSizeColumns`, drag a column to 20px | the column's track is `48px` |
| T37 | size-columns-to-widest-cell | with `autoSizeColumns`, render, then replace `rows` with rows whose widest cell is wider | the column is re-measured and its track grows to the new widest cell |
| T38 | shift-click-extends-range | click Ada (anchor), ⇧-click Cy, then ⇧-click Bob | selection = `{Ada, Bob}`; the anchor is still Ada |
| T39 | focused-row-tracking | focus the grid with no row focused | the first row is focused (`aria-activedescendant`) and the selection is unchanged |
