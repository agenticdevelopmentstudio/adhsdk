---
id: fcd5062f-05c2-4877-adfb-9b77c75c6076
title: "Editable List"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Table-and-bar list with search, filters, sorting, selection, and optional details pane."
platforms:
  - typescript
  - web
tags:
  - list
  - table
  - data-grid
depends-on:
  - d04eef56-2dbf-4148-964b-c095f242227f
  - c21473ee-a075-4800-96db-ff3de0888515
  - 0f5b7167-b375-4f44-977b-566f720a453d
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
  - a56695f3-0205-4c9b-b724-53be608de2f0
  - 81db83fc-b30c-4ba3-b4d5-572dc8b4e335
  - 60a907a2-2cc8-4c0c-bb54-3b0516d280b6
related: []
references: []
approved-by: ""
approved-date: ""
---

# Editable List

## Overview

A configurable list/table component combining a button bar (with search, text filters, and facet menus), a data table (with sortable and resizable columns), row selection via checkboxes, and an optional details pane for viewing one selected row in full. Rows do not carry their own action buttons; actions operate on the selection and are supplied via the bar. The component never paginates; the full matching set is on screen and scrolls.

"Editable" names what the list is *for*, not a per-cell edit mode the component itself provides: the bar's actions mutate the underlying data by acting on the selection, and the underlying `DataTable` cells are built to stay usable as inline-editable controls (a column's own `render` can put an input, a select, or a button in a cell without that click stealing the row's selection — see `data-table.tsx`'s `fromCellControl` guard) if the caller's column wants one. No row carries a built-in edit control of its own.

## Behavioral Requirements

- **render-search**: The component MUST render a search input in the bar, its value bound to `list.search`. Filtering is the controller's job — `useEditableList` matches `list.search` against every searchable column's `value` — not the component's; the component only renders whatever rows `list.rows` currently contains.
- **update-search**: The component MUST call `list.setSearch()` with the input's new value on every keystroke; the controller applies the actual filtering.
- **render-text-filters**: The component MUST render text filter inputs (from `list.textFilters`) in the bar, with placeholders and widths from filter metadata.
- **update-text-filter-values**: The component MUST update filter values via `list.setTextFilterValue()` when the user types in a text filter input.
- **render-facet-menus**: The component MUST render facet dropdown menus (from `list.facets`) in the bar with options and selected state from controller.
- **update-facet-selection**: The component MUST update facet selection via `list.setFacetSelection()` when the user selects options in a facet menu.
- **render-table**: The component MUST render a data table with rows from `list.rows` and columns from `list.columns`.
- **render-column-headers**: Each column MUST render a header (from column metadata) and cell content (from `column.value` or `column.render`).
- **support-sorting**: The component MUST render sortable columns and call `list.setSort()` when the user clicks a sortable header.
- **preserve-sort-state**: The component MUST display the current sort state (from `list.sort`) on the active column header.
- **support-column-resizing**: The component MUST allow users to resize columns and persist widths under the key provided by `columnWidthsKey`.
- **render-selection-checkboxes**: When `selectable` is true, the component MUST render checkboxes for each row and a select-all header checkbox.
- **select-all-scope**: The select-all header checkbox MUST select or deselect only the rows currently in `list.rows` (the visible/filtered set). It MUST NOT alter the selection state of any row hidden by the active filter — "all" means "all that is on screen," not "all that was ever selected."
- **update-selection**: The component MUST update row selection via `list.setSelectedIds()` when the user checks or unchecks a row checkbox or the select-all header.
- **show-selection-count**: When rows are selected and `selectable` is true, the component MUST display a count button showing the number of selected rows.
- **show-hidden-selected-count**: When `selectable` is true and one or more selected rows are hidden by the active filter, the selection-count button MUST include the literal text "(N not shown)" naming how many. An accent color on that text is a supplementary visual cue, never the sole means of conveying it.
- **provide-clear-selection-button**: The count button MUST be clickable and MUST call `list.clearSelection()` to deselect all rows.
- **render-actions**: The component MUST render any action nodes passed via the `actions` prop in the bar to the right of filters.
- **support-row-activation**: When `onRowActivate` is provided, the component MUST call it with the row's ID when the user double-clicks a row or presses Enter on a focused row.
- **grid-role-and-focus**: When `selectable` is true, the table MUST use `role="grid"` on a single focusable container (`tabIndex=0`), track exactly one focused row in state rather than giving any row its own `tabIndex`, expose the focused row via `aria-activedescendant`, move it with ArrowUp/ArrowDown, toggle the focused row's selection with Space, and — only when `onRowActivate` is provided — activate the focused row on Enter. When `selectable` is false, the table MUST use `role="table"` instead and MUST claim none of those keys, so an in-cell control's own Space/Enter/Arrow handling is never intercepted.
- **render-empty-state**: When the list is empty (no rows) and no filter is active, the component MUST display the text from `emptyLabel`.
- **render-filtered-empty-state**: When the list is empty due to filtering, the component MUST display the text from `emptyFilteredLabel`.
- **render-loading-state**: When `loading` is true, the component MUST display a loading indicator in the table.
- **handle-error-no-rows**: When an error is present, no rows exist, and the list is not loading, the component MUST replace the entire list with an error alert (not render the bar or table).
- **loading-preempts-error-replacement**: When an error is present, no rows exist, but `loading` is true, the component MUST NOT replace the whole list with the error alert. It MUST instead render the bar, the error alert above the table (see **handle-error-with-rows**), and the table's own loading indicator.
- **handle-error-with-rows**: When an error is present but rows exist (e.g., a refetch failed) or the list is loading, the component MUST display an error alert above the table without removing the rows or the loading indicator.
- **error-with-rows-suffix**: The error-with-rows alert's description MUST append the literal text " — showing the last rows that loaded." after the error's own message.
- **default-error-title**: When `errorTitle` is omitted and `error` is present, the component MUST derive the alert title as "Couldn't load {ariaLabel}", with `ariaLabel` lowercased.
- **render-truncation-notice**: When `truncationNotice` is provided, the component MUST display it as an alert above the table.
- **render-details-pane**: When `details` is provided, the component MUST render a resizable split with the table on top and details pane on bottom.
- **show-single-row-details**: The details pane MUST render the details for exactly one row when one row is selected, calling `details.render()` with that row.
- **show-details-empty-message**: The details pane MUST display `details.emptyLabel` when no row is selected.
- **show-details-many-message**: The details pane MUST display `details.manyLabel` when more than one row is selected.
- **render-details-header**: The details pane's header bar MUST display, on its left side, the result of `describeRow(detailRow)` when exactly one row is selected and `describeRow` is provided and returns a non-empty value; otherwise it MUST fall back to `details.label` (default `"Details"`). Header actions (from `details.actions`) render on the right.
- **render-details-actions**: Header actions MUST be called with the single selected row when one row is selected, or with `null` when zero or multiple rows are selected.
- **render-footer**: When `footer` is provided, the component MUST render it below the table or details pane.
- **render-null-values**: For a column defined with `value`, the component MUST render an em dash (—) in place of a null, undefined, or empty-string result, to distinguish "this row has no value here" from a failed load. A column defined with neither `value` nor `render` is not covered by this requirement — see the "Column with no render and no value" edge case.
- **preserve-selection-across-filter-changes**: Row selection MUST persist when the filter changes, allowing the selection to contain rows not currently visible.
- **describe-rows-for-accessibility**: When `describeRow` is provided, the component MUST use it to name each row's checkbox. If omitted, the component SHOULD guess the row name from the first non-empty string field that is not the row's ID.

## Appearance

- **Container**: Flex column layout; accepts a caller-provided class for the root.
- **Button bar**: Dark surface background, rounded top corners, left and right borders; holds the search input, filter inputs, facet menus, action nodes, and the selection-count button.
- **Search input**: Height 2rem (32px), max-width 20rem, `search` input type, with an accessible label.
- **Text filter inputs**: Height 2rem (32px), width from filter metadata or 14rem default, `search` input type.
- **Facet menu buttons**: Dark/ghost variant, small size.
- **Table**: Rows are one line tall; columns are resizable and sortable. Nested inside the details pane, the table's top rounding and top border are removed so the bar, the rows, the divider, and the pane read as one continuous card; standalone, it caps at `maxHeightClass` (default 60% of the viewport height).
- **Selection count button**: Ghost variant, small size, height 1.75rem (28px), extra-small text; shows the selected count and, when any selected rows are hidden by a filter, an accent-colored "(N not shown)" suffix.
- **Error alerts**: Error/danger variant with a triangle-alert icon; positioned above the table when rows exist, or replacing the entire list when none do.
- **Truncation alert**: Accent variant with a triangle-alert icon, positioned above the table.
- **Details pane**: A resizable split whose divider doubles as the pane's header bar; the pane's height is fixed by `details.heightClass` or a 60%-of-viewport default (the split sizes its panes as percentages of that height, so a definite height is required rather than a cap). The header bar shows the row name or the pane label on the left and header actions on the right. The bottom half shows the row's rendered details, or the empty/many-selected message.
- **Cell values**: Rendered as plain text; a null or empty value from a `value`-based column renders as an em dash in a dim, de-emphasized text color rather than the normal text color.

## States

| State | Appearance change |
|-------|------------------|
| Default | Standard table layout with bar and rows visible |
| Loading | Loading indicator displayed in table |
| Error (no rows, not loading) | Entire list replaced with error alert |
| Error (with rows, or still loading) | Error alert rendered above table; rows and/or loading indicator remain visible |
| Empty (no filter) | Table displays empty message, bar and filters visible |
| Empty (filtered) | Table displays filtered-empty message, current filters visible |
| Rows selected | Selection count button appears in bar, highlighted row(s) in table |
| Hidden selected rows | Selection count button shows hidden count in gold next to main count |
| Details pane shown | Split view with table on top, details pane on bottom |
| Details pane - no selection | Details pane shows empty message |
| Details pane - many selected | Details pane shows many-selection message |
| Details pane - single row | Details pane shows row details and header actions enabled |

## Accessibility

- **Role**: `role="grid"` (with `row`/`gridcell`/`columnheader`/`aria-sort` on its children) for a selectable table, or plain `role="table"` (with `row`/`cell`/`columnheader`) for a non-selectable one — see **grid-role-and-focus**. The bar is `role="toolbar"`. The details-pane divider is `role="separator"` with `aria-orientation="horizontal"` and `aria-valuenow`/`aria-valuemin`/`aria-valuemax`.
- **Search input label**: `aria-label="Filter [ariaLabel]"`, with `ariaLabel` lowercased (e.g., "Filter users") — see the Localization note on the locale-sensitivity of that transform.
- **Text filter input labels**: `aria-label={filter.placeholder}` from filter metadata.
- **Facet menu labels**: Named from `facet.label`; each option is a native `<label>` wrapping its checkbox rather than a separate `aria-label`, so the name is announced once, not twice.
- **Selection count button**: `aria-live="polite"` to announce selection changes; includes a visually-hidden "Clear selection" label naming what the button (and its trailing icon) does.
- **Table aria-label**: Passed from component prop `ariaLabel` (required).
- **Row descriptions**: Checkboxes are named using `describeRow` callback or the table's own fallback guess (the row's first non-empty string field that isn't the id).
- **Details pane label**: Passed to `ResizableSplit` as `bottomLabel`, and also used as the disclosure chevron's `aria-label`.
- **Keyboard model**: See **grid-role-and-focus** for the grid's focus/Arrow/Space/Enter behavior. Column resizing (the drag handle on a header's trailing border) has no keyboard equivalent — it is pointer-only; see **keyboard-navigable** in Compliance.
- **Minimum touch target**: The selection-count button is 1.75rem (28px) tall; the search and filter inputs are 2rem (32px) tall — both under the 44×44pt / 48×48dp platform minimum; see **touch-target-size** in Compliance.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| editable-list-001 | render-search | Component rendered with list prop | Search input visible in bar with label "Filter [ariaLabel]" |
| editable-list-002 | update-search | User types "abc" in search input | `list.setSearch("abc")` called; controller (not the component) recomputes `list.rows` from the new term |
| editable-list-003 | render-text-filters | list.textFilters contains one filter with id="status", placeholder="Status" | Text input visible in bar with placeholder "Status" |
| editable-list-004 | update-text-filter-values | User types "active" in text filter input | `list.setTextFilterValue("status", "active")` called |
| editable-list-005 | render-facet-menus | list.facets contains one facet with id="role", label="Role", options ["Admin", "User"] | Dropdown menu visible with label "Role" and options shown on click |
| editable-list-006 | update-facet-selection | User selects "Admin" in role facet | `list.setFacetSelection("role", new Set(["Admin"]))` called |
| editable-list-007 | render-table | list.rows contains 3 rows; list.columns defined | Data table renders with 3 rows |
| editable-list-008 | render-column-headers | Column has header="Name" and value=(row) => row.name | Table header shows "Name"; cells show row.name values |
| editable-list-009 | support-sorting | Column key="name", sortable=true, list.sort=null; user clicks the "Name" header once | `list.setSort({ key: "name", dir: "asc" })` called |
| editable-list-010 | preserve-sort-state | list.sort = { key: "name", direction: "asc" } | Table header shows sort indicator on "Name" column pointing up |
| editable-list-011 | support-column-resizing | columnWidthsKey="users_table"; column key="email" dragged to 220px | Column resizes to (at least) the 48px minimum; `localStorage.setItem("data-table-cols:users_table", JSON.stringify({ email: 220 }))` called — widths are stored as a column-key-to-pixel-integer map under the `data-table-cols:<key>` prefix |
| editable-list-012 | render-selection-checkboxes | selectable=true; list.rows contains 2 rows | Checkbox in header and checkbox in each of 2 rows visible |
| editable-list-013 | update-selection | User checks checkbox on row 1 | `list.setSelectedIds(new Set([row1_id]))` called; row1 highlighted |
| editable-list-014 | show-selection-count | selectable=true; 2 rows selected | Count button shows "2 selected" |
| editable-list-015 | show-hidden-selected-count | selectable=true; 3 rows selected but filter hides 1 | Count button shows "3 selected (1 not shown)" with hidden count in gold |
| editable-list-016 | provide-clear-selection-button | Count button displayed with 2 rows selected; user clicks button | `list.clearSelection()` called; all rows deselected; count button hidden |
| editable-list-017 | render-actions | actions=`<button>Delete</button>` | Delete button visible in bar to right of filters |
| editable-list-018 | support-row-activation | onRowActivate=(id) => {...}; user double-clicks row with id="row123" | `onRowActivate("row123")` called |
| editable-list-019 | render-empty-state | list.rows is empty, no filter applied, emptyLabel="No data" | Table shows "No data" message; bar and filters still visible |
| editable-list-020 | render-filtered-empty-state | list.rows is empty due to filter, emptyFilteredLabel="No matches" | Table shows "No matches" message |
| editable-list-021 | render-loading-state | loading=true | Table shows loading indicator |
| editable-list-022 | handle-error-no-rows | error={new Error("API failed")}, list.allRows=[], loading=false | Entire list replaced with error alert; bar and table not shown |
| editable-list-023 | handle-error-with-rows | error={new Error("Refetch failed")}, list.allRows contains 3 rows | Error alert shown above table; table and all 3 rows still visible |
| editable-list-024 | render-truncation-notice | truncationNotice="Showing 500 of 1000+" | Alert with truncation message shown above table |
| editable-list-025 | render-details-pane | `details={render: (row) => <div>{row.name}</div>}` | Split view rendered with table on top, details pane on bottom |
| editable-list-026 | show-single-row-details | details provided; 1 row selected with data {id: "1", name: "Alice"} | Details pane calls `render({id: "1", name: "Alice"})`; output shown in bottom pane |
| editable-list-027 | show-details-empty-message | details provided with emptyLabel="Select a row"; 0 rows selected | Details pane shows "Select a row" |
| editable-list-028 | show-details-many-message | details provided with manyLabel="Select one"; 2 rows selected | Details pane shows "Select one" |
| editable-list-029 | render-details-header | details provided; 1 row selected; describeRow=(row) => row.name | Details header shows row's name; had describeRow been omitted or returned "", it would show details.label (default "Details") instead |
| editable-list-030 | render-details-actions | `details.actions=(row) => row ? <button>Edit</button> : null`; 1 row selected | Header shows Edit button; passed the selected row object |
| editable-list-031 | render-details-actions | `details.actions=(row) => row ? <button>Edit</button> : null`; 0 or 2+ rows selected | Header actions button not shown; passed null to actions() |
| editable-list-032 | render-footer | footer=`<div>Total: 100</div>` | Footer rendered below table |
| editable-list-033 | render-null-values | Column with value=(row) => row.optional (null value); row rendered | Cell displays em dash (—) in dim color |
| editable-list-034 | preserve-selection-across-filter-changes | 2 rows selected; search filter applied hiding 1 selected row | Selection still includes both row IDs; count shows "2 selected (1 not shown)" |
| editable-list-035 | describe-rows-for-accessibility | describeRow=(row) => row.email; row1 has email="alice@example.com" | Checkbox has aria-label containing "alice@example.com" |
| editable-list-036 | select-all-scope | list.rows contains 2 visible rows (of 3 total; the 3rd is hidden by a filter and already selected); user clicks the header checkbox | `list.setSelectedIds()` called with a set that adds/removes only the 2 visible rows' ids; the hidden, already-selected row's id is left untouched |
| editable-list-037 | grid-role-and-focus | selectable=true; table renders; user Tabs into the grid, then presses ArrowDown | The grid container (not any row) receives DOM focus (`role="grid"`, `tabIndex=0`); `aria-activedescendant` moves to the next row's id; no row carries its own `tabIndex` |
| editable-list-038 | loading-preempts-error-replacement | error={new Error("Failed")}, list.allRows=[], loading=true | List is NOT replaced: bar renders, an error alert renders above the table, and the table shows its loading indicator (not the empty message) |
| editable-list-039 | error-with-rows-suffix | error={new Error("Refetch failed")}, list.allRows contains 2 rows | Error alert text reads "Refetch failed — showing the last rows that loaded." |
| editable-list-040 | default-error-title | error={new Error("x")}, errorTitle omitted, ariaLabel="Users" | Alert title reads "Couldn't load users" (ariaLabel lowercased) |
| editable-list-041 | support-sorting | Column key="name", sortable=true, list.sort={key:"name",dir:"asc"}; user clicks the "Name" header again | `list.setSort({ key: "name", dir: "desc" })` called — the toggle is asc↔desc only; there is no third click that clears the sort |

## Edge Cases

- **Null or empty search**: Search input defaults to empty; component renders all rows until user types.
- **Empty list with no filter**: Component displays empty message; bar, search, and filters remain interactive.
- **Filter that matches zero rows**: Component displays filtered-empty message; selection survives the filter but hidden count is shown.
- **Selection survives filter**: Selected row IDs are not cleared when a filter is applied; selected row that becomes hidden shows in the hidden count.
- **Selection cleared by external change**: If `list.setSelectedIds()` is called externally (e.g., by parent component), the count updates and hidden count recalculates.
- **Row ID collision**: If a row's ID (from `list.getRowId(row)`) is duplicated, behavior is undefined in the table's selection logic.
- **Column with no render and no value**: `DataTable` receives `render: undefined` for that column and falls back to `String(row[col.key] ?? "")` — it reads the row object directly by the column's `key` and stringifies it, rendering an empty string (not an em dash) when the field is missing. This bypasses the em-dash treatment, which applies only to columns defined with `value` — see **render-null-values**.
- **Column value is empty string**: Renders as em dash (—) to distinguish from undefined/null (only for `value`-based columns; see above).
- **Multiple sorts attempted**: Only one sort is active; `list.sort` is a single sort state, not multi-column sort. Repeated clicks on the same header toggle between ascending and descending only — there is no third click that clears the sort.
- **Column resize persists across page reload**: Column widths are stored in browser storage as a JSON column-key-to-pixel-width map under the key `data-table-cols:${columnWidthsKey}`; if storage is cleared, columns return to default size.
- **Details pane selection changes**: If single-row selection changes (e.g., user clicks another row), pane immediately re-renders with new row's details. Selection that leaves the pane empty or multi-selected shows appropriate message.
- **Details pane divider position**: Divider position is persisted under `details.storageKey` if provided; otherwise position resets on remount.
- **Error state during loading**: See **loading-preempts-error-replacement** — the whole-list replacement is skipped while `loading` is true, so the bar, the error strip, and the table's own loading indicator all render together.
- **Error title missing**: See **default-error-title** — the title is derived from `ariaLabel`, lowercased.
- **Row activation with no details pane**: `onRowActivate` can be used independently of `details` pane; row double-click or Enter key calls the callback.
- **Facet with no options**: Facet menu renders with empty options list.
- **Text filter with no width**: Text filter input uses default width of 14rem.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `list` | `EditableListController<T>` | — | Required. Controller managing rows, selection, search, filters, sorting — see the sub-table below. |
| `ariaLabel` | string | — | Required. Name of the list for assistive tech (e.g., "Users", "Templates"). |
| `onRowActivate` | (id: string) => void | undefined | Optional. Callback when user double-clicks a row or presses Enter on focused row. |
| `actions` | ReactNode | undefined | Optional. Action button nodes to render in the bar. |
| `selectable` | boolean | true | Optional. Whether to show selection checkboxes and count. |
| `searchPlaceholder` | string | "Filter" | Optional. Placeholder text for search input. |
| `emptyLabel` | string | "Nothing here." | Optional. Message when list is empty with no filter. |
| `emptyFilteredLabel` | string | "Nothing matches these filters." | Optional. Message when list is empty due to filter. |
| `loading` | boolean | false | Optional. Whether to show loading indicator in table. |
| `columnWidthsKey` | string | — | Required. Storage key for persisting column widths. |
| `maxHeightClass` | string | "max-h-[60vh]" | Optional. Tailwind class for table max height (ignored if details pane present). |
| `details` | `EditableListDetails<T>` | undefined | Optional. Configuration for details pane showing single-row details — see the sub-table below. |
| `footer` | ReactNode | undefined | Optional. Content to render below table or details pane. |
| `describeRow` | (row: T) => string | undefined | Optional. Function to name each row for accessibility. If omitted, component guesses from first non-empty string field. |
| `error` | unknown | undefined | Optional. Error object; if present and no rows and not loading, list is replaced with error alert; otherwise an error alert is shown above the table. |
| `errorTitle` | string | undefined | Optional. Custom error title. Defaults to "Couldn't load {ariaLabel}" with `ariaLabel` lowercased. |
| `truncationNotice` | ReactNode | undefined | Optional. Message about list being capped (e.g., "Showing 500 of more"). |
| `className` | string | undefined | Optional. CSS class for root container. |

`list` is an `EditableListController<T>`, produced by the sibling `useEditableList()` hook:

### `EditableListController<T>`

| Member | Type | Default | Description |
|--------|------|---------|-------------|
| `columns` | `EditableListColumn<T>[]` | — | Echoes the `columns` the hook was given. |
| `getRowId` | `(row: T) => string` | — | Echoes the hook's `getRowId`. |
| `rows` | `T[]` | — | `allRows` after search, text filters, facets, and sort are applied — what the table renders. |
| `allRows` | `T[]` | — | Every row the hook was given, unfiltered. |
| `search` | `string` | `""` | The free-text search term. |
| `setSearch` | `(next: string) => void` | — | Updates `search`. |
| `sort` | `ListSort \| null` | `null` (or the hook's `initialSort`) | The active `{ key, dir }`, or `null` for arrival order. |
| `setSort` | `(next: ListSort) => void` | — | Replaces `sort`. |
| `selectedIds` | `Set<string>` | `new Set()` | The selected row ids. Pruned against `allRows` (not the filtered `rows`) whenever the row set changes. |
| `setSelectedIds` | `(ids: Set<string>) => void` | — | Replaces `selectedIds`. |
| `clearSelection` | `() => void` | — | Sets `selectedIds` to an empty set. |
| `selectedRows` | `T[]` | — | `allRows` filtered to the selected ids, in list order. |
| `facets` | `EditableListFacet<T>[]` | `[]` | Echoes the hook's `facets`. |
| `facetOptions` | `Record<string, string[]>` | — | Every value each facet's `valuesOf` finds across `allRows`, sorted. |
| `facetSelection` | `Record<string, Set<string>>` | `{}` | The ticked values per facet, pruned to values still present in `facetOptions`. |
| `setFacetSelection` | `(id: string, next: Set<string>) => void` | — | Replaces one facet's ticked set. |
| `textFilters` | `EditableListTextFilter<T>[]` | `[]` | Echoes the hook's `textFilters`. |
| `textFilterValues` | `Record<string, string>` | `{}` | The current text per filter id. |
| `setTextFilterValue` | `(id: string, next: string) => void` | — | Replaces one filter's text. |
| `filtered` | `boolean` | `false` | True while a search term, filter value, or facet selection is narrowing the list. |

### `EditableListDetails<T>`

| Member | Type | Default | Description |
|--------|------|---------|-------------|
| `render` | `(row: T) => ReactNode` | — | Required. The pane's body for the one selected row. |
| `label` | `string` | `"Details"` | The pane's name, shown on its header bar and used as the disclosure chevron's `aria-label`. |
| `actions` | `(row: T \| null) => ReactNode` | `undefined` | Right-aligned header-bar controls. Called with the single selected row, or `null` when zero or multiple rows are selected. |
| `storageKey` | `string` | `undefined` | Persists the divider's drag ratio under this key; omit and the ratio resets on remount. |
| `emptyLabel` | `string` | `"Select a row to see its details."` | Shown when no row is selected. |
| `manyLabel` | `string` | `"Select a single row to see its details."` | Shown when more than one row is selected. |
| `heightClass` | `string` | `"h-[60vh]"` (a 60%-of-viewport-height Tailwind class) | The fixed height of the table-plus-pane column; a definite height, not a cap, because the split sizes its panes as percentages of it. |

## Deep Linking

Not applicable: This component is not designed to participate in deep linking. Its rows and state (selection, filters, sort) are managed by the parent component and controller, which is responsible for routing and URL state management.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| search.placeholder | "Filter" | Placeholder for search input (from `searchPlaceholder` prop) |
| search.aria-label | "Filter [ariaLabel]" | Accessibility label for search input |
| empty.no-filter | "Nothing here." | Message when list is empty with no active filter |
| empty.filtered | "Nothing matches these filters." | Message when list is empty due to active filters |
| selection.count | "{count} selected" | Selection count button text |
| selection.hidden | "({count} not shown)" | Hidden selection count (appended in gold color) |
| selection.clear | "Clear selection" | Screen-reader label for clear-selection button |
| table.error | "Couldn't load {ariaLabel}" | Error alert title (default, overridable via `errorTitle` prop) |
| table.error.with-rows | "— showing the last rows that loaded." | Error alert description when rows exist |
| details.label | "Details" | Default label for details pane header |
| details.empty | "Select a row to see its details." | Message when details pane has no selection |
| details.many | "Select a single row to see its details." | Message when details pane has multiple selections |
| button-bar.aria-label | "{ariaLabel} actions" | Accessibility label for button bar |

All text defaults are passed as component props; externalization depends on the application's localization strategy.

The `ariaLabel.toLowerCase()` call used to build both `search.aria-label` and the default `table.error` title is a locale-sensitive casing transform: JavaScript's `String.prototype.toLowerCase()` applies the Unicode default case-folding, which is wrong for some locales (Turkish's dotted/dotless I is the standard example). A localization pass should give this a locale-aware lowercasing path rather than assume the default transform is correct everywhere — and it must not reach for an invariant-culture call either, since this text is user-facing, not an internal key.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The `ResizableSplit` divider's expand/collapse animation MUST be suppressed when the app's `data-reduce-motion` setting is `"on"` (read from `document.documentElement.dataset.reduceMotion`); a direct drag is never animated regardless of the setting. |
| Increase Contrast | The component references named design tokens (`apt-gold`, `apt-border`, `apt-text-dim`, …) rather than fixed color values. Resolving those tokens to higher-contrast values under the platform's Increase Contrast setting is the responsibility of the token/theme layer — this component does not read the setting itself. |
| Differentiate Without Color | The hidden-selection count is never color-only: it MUST render as literal text ("(N not shown)"), with an accent color as a supplementary cue — see **show-hidden-selected-count**. Sort indicators MUST use (and already do use) a directional chevron icon alongside the header's sort state, so sort order is never conveyed by color alone. |

## Feature Flags

Not applicable: This component does not implement feature flags. Feature flagging is the responsibility of the parent component or controller that conditionally renders or enables filtering and details features based on application-level flags.

## Analytics

This component does not emit analytics itself; instrumentation is the responsibility of a wrapping hook or the parent component, which has access to every state change the controller exposes (search, filter, facet, sort, and selection changes) plus the row-activation and error props. A wrapper instrumenting parity across admin lists might emit events named along the lines of `editable_list.loaded`, `.searched`, `.filtered`, `.sorted`, `.column_resized`, `.selection_changed`, `.row_activated`, and `.error_shown` — but none of these, nor their payload shapes, are part of this component's contract. A `.searched` event's payload should carry a query length (or a hash) rather than the raw search string, which can hold operator-typed PII such as an email address.

## Privacy

- **Data collected**: None by the component itself. The component does not collect, log, or transmit any user data beyond what the controller and parent application explicitly define (e.g., search queries, selected row IDs).
- **Storage**: Column widths and details pane divider position are persisted to browser storage (localStorage or equivalent) under keys provided by the parent (`columnWidthsKey`, `details.storageKey`). Selection state, search queries, and filter values are not persisted unless the controller or parent component explicitly implements persistence.
- **Transmission**: The component does not transmit data. Network requests (data fetching, filtering, sorting) are handled by the parent component and controller.
- **Retention**: Persisted storage (column widths, divider position) is retained until explicitly cleared by the application or user action (e.g., browser storage clear).

## Logging

Subsystem: `adhsdk.ui.blocks` | Category: `EditableList`

| Event | Level | Message |
|-------|-------|---------|
| Render | debug | `EditableList rendered: ${ariaLabel}, rows: ${list.rows.length}, filtered: ${list.filtered}, selected: ${list.selectedIds.size}` |
| Error | error | `EditableList error: ${errorMessage(error)}, ariaLabel: ${ariaLabel}, rows: ${list.allRows.length}` |
| Column resize | debug | `EditableList column resized: column=${column.key}, stored under key=${columnWidthsKey}` |
| Sort change | debug | `EditableList sort changed: key=${sort.key}, direction=${sort.direction}` |
| Selection change | debug | `EditableList selection changed: selected=${list.selectedIds.size}, hidden=${hiddenSelected}` |

`error` is typed `unknown`. `errorMessage()` is the same coercion the component's own render path uses (`err instanceof Error ? err.message : String(err)`) — an `Error`'s `.message` for a real error, `String(err)` for anything else thrown, never a raw property access that would fail on a non-Error value.

## Platform Notes

- **React/Web**: Source implementation in `packages/web/packages/ui/src/blocks/editable-list.tsx`, composed from `DataTable`, `ResizableSplit`, `Input`, `Button`, `Alert`/`AlertDescription`/`AlertTitle`, `ButtonBar`, and `FacetMenu` (all sibling ingredients). Uses React 18 `"use client"`, with `useState`/`useMemo`/`useCallback` inside the `useEditableList()` controller hook. The appearance details described generically above map to these Tailwind utilities: `h-8`/`max-w-xs` (search/filter inputs), `h-7` (selection-count button), `text-apt-text-dim` (em-dash cells), `text-apt-gold` (hidden-count suffix), `rounded-t-lg border-x` (bar), `rounded-t-none border-t-0` / `rounded-none border-0` (table nested in the details split), and `max-h-[60vh]` (default standalone cap). Column-width persistence uses `localStorage` under `data-table-cols:${columnWidthsKey}`; the details-pane divider ratio persists under `details.storageKey` the same way, inside `ResizableSplit`. Selection state survives filter changes by design — selected IDs are not cleared when filters update.
- **SwiftUI**: `Table` (macOS 13+ / iOS 16+) for the grid, with the `.searchable(text:)` modifier — not a `SearchField` view, which does not exist in SwiftUI — for the search box in a toolbar. `Table` supports sorting natively through a `sortOrder: Binding<[KeyPathComparator<T>]>` parameter, and its columns resize natively on macOS (not on iOS/iPadOS, where `Table` has no user-resizable columns). Selection uses `Table`'s own `selection: Binding<Set<ID>>`. Filter and facet inputs would be custom toolbar views. The details pane would be a `NavigationSplitView` or a manual `VStack`-based split.
- **Compose**: A `LazyColumn` for the rows, with a sticky header `Row` rendered above it (Compose has no built-in table/grid with a header and resizable columns), each cell sized via `Modifier.weight`/`width`. Search: an `OutlinedTextField` above the list. Selection: `selectedIds: Set<ID>` needs a custom `Saver` to survive process death in `rememberSaveable` — `Set` is not one of the types it can serialize out of the box; plain `remember` works for in-memory-only persistence. Facet menus: `DropdownMenu` with checkable items. Column resizing has no Compose primitive and would need custom pointer-drag/gesture handling.
- **AppKit / UIKit**: `NSTableView` (macOS) or `UITableViewController`/`UICollectionView` (iOS) with a search controller and text-field filters in a toolbar. Selection tracked via delegate methods. Details view: a split view controller (macOS) or a pushed/presented detail controller (iOS). `NSTableView` supports column resizing natively; UIKit tables have no column concept to resize.
- **WinUI 3**: WinUI 3 ships no built-in `DataGrid`; the Community Toolkit's `DataGrid` is archived/in Labs, raises a `Sorting` event without performing the sort itself, and has no native multi-column sort — any of that would have to be hand-rolled on top of it, so a plain `ListView` or `ItemsRepeater` with a manually built header row (for sort indicators and resize handles) is the safer default, with the Toolkit `DataGrid` remaining an option if its caveats are accepted. Filters and search would be `TextBox` controls in a `CommandBar`. The details split is a `Grid` with a horizontal `GridSplitter` between the table area and a details row — not `SplitView`, which is a side (left/right) pane, not a top/bottom one.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/editable-list.tsx` | unverified |

## Design Decisions

**Decision**: Row selection persists when filters change; the hidden count in the bar shows how many selected rows are currently off-screen rather than clearing them.
**Rationale**: Preserves operator intent — a bulk action targeting three rows remains valid even if a search temporarily hides one of them. The hidden count informs the operator, and the clear-selection button offers a one-press undo.
**Approved**: pending

**Decision**: The details pane always shows exactly one row's data, prompting the operator to select a single row when zero or several are selected.
**Rationale**: A pane is a view of a record, and there is no such thing as "the details of three rows." This avoids the ambiguity of "which row's details?" and keeps the pane's data source unambiguous.
**Approved**: pending

**Decision**: Rows carry no action buttons of their own; every action lives in the bar and operates on the selection, except for the rare per-row control (a role menu, a membership chip) supplied as a column by the parent.
**Rationale**: Per-row buttons duplicate the bar's actions and create confusion about whether an action applies to one row or the whole selection.
**Approved**: pending

**Decision**: The component never paginates; the full matching set stays on screen and scrolls.
**Rationale**: Pagination plus filtering creates two ways to not see a row — a filter that matches 40 items and a pager showing 25 hides 15 behind a control most operators never press.
**Approved**: pending

**Decision**: Whether the entire list is replaced by an error alert depends on whether any rows currently exist (and whether the list is still loading), not on loading state alone.
**Rationale**: If the list has never loaded, the empty state's "nothing here" claim has no standing coming from a failed request, so the whole UI is replaced — unless a load is still in flight, in which case replacing it would hide the very loading indicator that explains why there are no rows yet. If a refetch fails after an earlier success, the rows on screen are still real — just possibly stale — so they stay visible with an error strip above them; this prevents a transient network failure from blanking out rows the operator just acted on.
**Approved**: pending

**Decision**: Search persists independently of selection — the search input is a controlled input wired to the controller's `search`/`setSearch`, but typing in it, or changing a filter, never clears the current selection.
**Rationale**: The search term is an independent dimension of list state; conflating "what's visible" with "what's selected" would silently drop a selection made a keystroke before a filter narrowed the view.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | partial | Privacy and Data |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.plural-forms](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d24616b8-d1af-593d-ba01-f51ee4a91ea4) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | failed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

These statuses rest on: the ARIA roles/labels, `aria-live` region, and chevron sort icons in `editable-list.tsx`/`data-table.tsx` (the accessibility passes); the pointer-only column-resize handle with no keyboard fallback (`keyboard-navigable`: partial) and the 28–32px control heights against a 44px minimum (`touch-target-size`: failed); the component's own lack of network transmission (`data-minimization`: passed) set against log/error messages whose text content originates with the caller (`no-pii-in-logs`, `secure-log-output`: partial); and the literal English strings ("selected", "not shown", "Clear selection", "Select all", "No items.", "Resize column …") hardcoded into the component and its `DataTable`, with a single non-pluralized count template and physical (`right-0`) rather than logical resize-handle positioning (the internationalization failures). `separation-of-concerns` is partial because filtering/sorting/selection are delegated to the external `useEditableList` controller, but derivations like `hiddenSelected`, `detailRow`, and error branching remain inline in the component; `unit-test-coverage` passes because `editableListDetails.test.tsx` and `editableListSelectionCount.test.tsx` import `EditableList` directly and exercise its behavior with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed every requirement to subject-only kebab-case; added `EditableListController`/`EditableListDetails` configuration sub-tables; fixed the `h-8`/`h-7` appearance px values and moved Tailwind-class detail out of Appearance into the React/Web platform note; corrected the null-value/no-value-column contradiction, the hidden-count color-only contradiction, and the details-header fallback ambiguity; added `select-all-scope`, `grid-role-and-focus`, `loading-preempts-error-replacement`, `error-with-rows-suffix`, and `default-error-title` requirements with test vectors; made the sort-toggle (009/041) and column-width-storage (011) test vectors concrete; corrected the unknown-typed error logging to use `errorMessage()`; corrected the SwiftUI (`.searchable`, native `Table` sort/resize), Compose (`Saver`, header row), and WinUI 3 (no built-in `DataGrid`, `Grid`+`GridSplitter`) platform notes; converted Design Decisions to Decision/Rationale/Approved form and retitled the search-persistence one; filled in `depends-on` and a real Compliance table; noted the locale-sensitivity of the `ariaLabel.toLowerCase()` casing transform; and reframed Analytics as non-normative guidance to drop the raw-query PII exposure. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Wrapped generics/JSX in code spans (EditableListController<T>/EditableListDetails<T> headings and table cells, details.actions JSX examples) so GitHub stops stripping them. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
