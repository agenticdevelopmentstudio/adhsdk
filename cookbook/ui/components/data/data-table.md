---
id: d04eef56-2dbf-4148-964b-c095f242227f
title: "DataTable"
type: ingredient
version: 1.4.2
status: review
language: en
created: 2026-06-26
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Controlled, selectable, optionally-sortable, optionally-reorderable generic table primitive with multi-row selection, inline editing, and column resizing."
platforms:
  - typescript
  - web
tags:
  - component
  - data-table
  - table
  - ui
depends-on:
  - a105b6cf-307d-4156-8b73-468f627f3c9b
  - d8f2a1c3-9e4b-4a7b-8c6d-2f9a1e5b3c7d
  - 26df832c-a7f7-4cf6-b3f5-240c61e8bd68
related:
  - 6acd3c5f-7bb5-4d6d-8c8d-141e1909cf73
  - e1859aa2-d0c4-4d9a-b926-203dd5fbbca3
references: []
approved-by: ""
approved-date: ""
---

# DataTable

## Overview

A generic, selectable, optionally-sortable, optionally-reorderable table primitive in `@adh-sdk/ui`.
It is a **controlled** table: the caller owns `rows`, the `selectedIds` set, and
the optional `sort`. The component renders columns, handles pointer + keyboard
selection, and reports changes up. It is generic over the row type `T` and owns
the multi-row selection model (click / ⇧-click / ⌥-click / keyboard). It is the
foundation for details-pane lists and member-picking dialogs.

## Behavioral Requirements

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

## Appearance

```
┌───────────────────────────────────────────────────┐
│ ☐ │ Name ▲     │ Email          │ Phone           │  ← sticky header (sortable = button + caret; ☐ = select-all)
├────┼────────────┼────────────────┼─────────────────┤
│ ☐  │ Ada        │ ada@x.io       │ +1 555 0100     │  ← row (aria-selected)
│ ☑  │ Grace      │ grace@x.io     │ +1 555 0101     │  ← selected row (bg-apt-gold/15)
└────┴────────────┴────────────────┴─────────────────┘
```

- Container: `border border-apt-border rounded-lg overflow-auto`.
- Header: `bg-apt-surface-2`, sticky (`position: sticky; top: 0`), `text-apt-text-muted`, mono caption style; a sortable header is a `<button>` with a `ChevronUp`/`ChevronDown` caret in `apt-text-muted`.
- Row: `text-apt-text`, hover `bg-apt-surface-2`, selected `bg-apt-gold/15`; divider `border-t border-apt-border`.
- Selection checkbox column: width `2.75rem`, not resizable.
- Column widths come from a CSS grid template built from each column's `width` — or, with `autoSizeColumns`, from the measured width of each column's widest cell, which the user may override by dragging the column's trailing border (`cursor-col-resize`, `hover:bg-apt-gold/40`, matching the topic list's rail handle).
- Resize handle: `absolute top-0 right-0 h-full w-1.5 translate-x-1/2` on the trailing border of each resizable column header.
- No raw hex; no `!important`.

## States

| State | Appearance change |
|---|---|
| Default row | `text-apt-text`, transparent background |
| Hover row | `bg-apt-surface-2` |
| Selected row | `bg-apt-gold/15`, `aria-selected="true"`, `data-selected` |
| Keyboard-focused row | roving `data-focused="true"`; `aria-activedescendant` points at it |
| Dragging row | row's transform reflects pointer position (dnd-kit) |
| Sortable header (active) | `aria-sort` set to "ascending" or "descending"; caret reflects direction |
| Loading | loading affordance shown in place of rows (status message) |
| Empty | `emptyLabel` (default "No items.") shown |

## Accessibility

- `role="grid"` (selectable) or `role="table"` (action-list) with `aria-label`; header is `role="row"` / `role="columnheader"` (sortable headers set `aria-sort` to "ascending" or "descending"); body rows are `role="row"` with `aria-selected` (selectable only); cells are `role="gridcell"` (selectable) or `role="cell"` (action-list).
- The grid is focusable (`tabIndex=0`) when selectable; a roving `data-focused` attribute tracks keyboard focus; `aria-activedescendant` points at it.
- Pointer selection does not steal focus from an open editor elsewhere.
- Selection checkboxes have accessible labels derived from row content (`Select Ada`, `Select Grace`).
- Sortable headers are buttons with `aria-sort` attributes.
- Column resize handles are separators with `aria-orientation="vertical"` and `aria-label="Resize column {key}"`.
- Drag operations emit accessible announcements via the dnd system (row name, drop zone name).
- Loading state uses `role="status"` for the affordance message.

## Conformance Test Vectors

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
## Edge Cases

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
## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `columns` | `DataTableColumn<T>[]` | — | Column definitions. |
| `rows` | `T[]` | — | Rows already in display order. |
| `getRowId` | `(row: T) => string` | — | Stable id for a row. |
| `selectedIds` | `Set<string>?` | — | Caller-owned selection set. Omit (with `onSelectionChange`) for action-list mode. |
| `onSelectionChange` | `((ids: Set<string>) => void)?` | — | Fired with a new `Set` on every selection edit. Omitting it disables selection entirely (action-list mode). |
| `onRowActivate` | `((id: string) => void)?` | — | Fired when a row is double-clicked or Enter is pressed on the focused row (only when table is selectable). |
| `sort` | `{ key: string; dir: "asc" \| "desc" }`? | — | Current sort (caller reorders `rows`). |
| `onSortChange` | `(sort) => void`? | — | Sort intent; if omitted, headers are inert. |
| `emptyLabel` | `string` | `"No items."` | Shown when `rows` is empty. |
| `loading` | `boolean` | `false` | Renders the loading state. |
| `ariaLabel` | `string` | — | Required grid label. |
| `className` | `string` | — | Extra classes on the container. |
| `autoSizeColumns` | `boolean` | `false` | Size columns to widest cell and allow user resizing. |
| `columnWidthsKey` | `string?` | — | Persist dragged column widths under this localStorage key. |
| `reorder` | `DataTableReorder?` | — | Enable row reordering via drag-and-drop. |
| `showSelectionCheckboxes` | `boolean` | `false` | Show a leading checkbox column (only if selectable). |
| `describeRow` | `(row: T) => string`? | — | Accessible label for a row (used in checkboxes and drag announcements). |

Column fields: `key: string`, `header: React.ReactNode`, `render?: (row: T, ctx: DataTableRowContext) => React.ReactNode` (default `String(row[key])`), `sortable?: boolean`, `width?: string` (e.g. `"12rem"` / `"1fr"`), `align?: "start" | "end"`, `resizable?: boolean`.

`DataTableReorder` fields:

| Field | Type | Required | Description |
|---|---|---|---|
| `onDrop` | `(drop: SortableDrop) => void` | yes | Called with where the row landed, as neighbours rather than an index. |
| `describeRow` | `(id: string) => string` | no | The row's name for the drag announcements. |
| `canDrag` | `(id: string) => boolean` | no | False for a row that must not move right now. |

`SortableDrop` is `{ itemId: string; fromZoneId: string; toZoneId: string; afterId: string | null; beforeId: string | null }`: the dragged id, its source and destination zones (the same single zone here), the id it landed below (null at the top) and the id it landed above (null at the bottom). The table is one zone, so `fromZoneId` equals `toZoneId`.

`DataTableRowContext` is `{ dragHandleProps: React.HTMLAttributes<HTMLElement>; dragging: boolean }`: the props to spread on the element that picks the row up (empty when `reorder` is off) and whether this row is the one being dragged.
## Deep Linking

Not applicable: DataTable is a presentational primitive with no routing or URL-based state.

## Localization

Most user-facing text is caller-supplied (`ariaLabel`, `emptyLabel`, column `header`, `describeRow`), and localization of those is the caller's responsibility. The component itself also owns a small set of hardcoded English strings that have no override besides `emptyLabel`:

| String | Context |
|---|---|
| `"Select all"` | Select-all checkbox `aria-label`, shown when `showSelectionCheckboxes` is true |
| `"No items."` | Default `emptyLabel`; overridable via that prop |
| `` `row {id}` `` | Fallback row-checkbox `aria-label` when no `describeRow` is given and the row has no other non-empty string field |
| `` `Select {name}` `` | Row-checkbox `aria-label` template, `{name}` from `describeRow(row)` or the fallback above |
| `` `Resize column {key}` `` | Column resize-handle `aria-label`, built from the column `key` rather than its header text |

These literals are not routed through any localization layer; a non-English caller sees them in English regardless of locale.

The drag announcements, emitted when `reorder` is set, are also hardcoded English: `Picked up {name}.`, `{name} is over {target}.` (or `{name} is over no drop target.`), `{name} was dropped.` (or `{name} was returned to where it started.`), and `Dragging {name} was cancelled.` Here `{name}` follows **announce-drag-state** and `{target}` is the table's `ariaLabel` or another row's name.
## Accessibility Options

| Option | Behavior |
|---|---|
| Reduce Motion | Not honored: a dragged row's transform (`drag?.style`) is applied unconditionally, with no `prefers-reduced-motion` check. |
| Increase Contrast | Not verified: DataTable picks design tokens (`apt-*`) for its text, header, hover and selected backgrounds, so contrast depends on the theme's token values, which the source does not check. |
| Differentiate Without Color | Partially addressed: selection is conveyed through `aria-selected`/`data-selected` plus a background tint together, not color alone, but no additional non-color marker (e.g. an icon) is added. |

## Feature Flags

Not applicable: DataTable is a foundational primitive with no feature-gated behavior; feature gates on features using the table belong in the consuming application.

## Analytics

Not applicable: DataTable is a presentational primitive; it emits no structured log events or analytics. Consumer applications instrument their own models when a row is activated or the selection changes.

## Privacy

Not applicable: DataTable does not collect, store, or transmit user data. Row content is entirely caller-owned and may be sanitized by the caller before rendering.

## Logging

Not applicable: DataTable is a presentational primitive; it emits no structured log events. Consumers log events of interest (row activation, selection changes) in their own handlers.

## Platform Notes

- **React/Web**: Source file is `packages/web/packages/ui/src/components/data-table.tsx` (exported via the `./components/*` wildcard). Uses CSS Grid for layout, dnd-kit for drag-and-drop (via `SortableItem`, `SortableSurface`, `SortableZone`), and lucide-react for sort carets (`ChevronUp`, `ChevronDown`). Checkbox cells use a separate `Checkbox` component from the same UI package. Storage is via localStorage for column widths.
- **SwiftUI**: `Table` is available from iOS 16 / macOS 12 and resizes its columns natively on macOS. For earlier OS versions, use a `List` with `.listStyle(.insetGrouped)` (there is no `.inset(grouped)` modifier). Selection maps to a SwiftUI `@State` binding tracking `Set<ID>`. Sorting maps to a data-binding holding the current sort column and direction; the table does not reorder rows itself. Row reorder maps to `.onMove` on the `ForEach` inside a `List` (or `draggable`/`dropDestination` for a custom drop), reporting the neighbours the row landed between.
- **Compose**: Start from a `LazyColumn` or `Column` with a custom row layout per column definition. Selection uses a mutable state `Set<ID>` held at the caller level. Sorting is caller-driven via a state binding; the component renders `rows` as given. Column resize and reorder require custom Modifier-based drag-and-drop handlers — dnd-kit is web-only and has no Compose equivalent; use Compose's pointer-input APIs or a Compose-native drag-and-drop library instead.
- **AppKit / UIKit**: macOS (AppKit): start from `NSTableView` with `NSTableColumn` per column; selection maps to `selectedRowIndexes`, with indexes mapped to ids on every change and remapped after `reloadData`, so selection stays by id. iOS (UIKit): `UITableView` is single-column, so use `UICollectionView` with a custom `UICollectionViewCompositionalLayout` for multi-column grids. Selection uses `UICollectionViewDelegate.didSelectItemAt` and an index-to-id mapping; sorting is caller-driven. Column resize and reorder (iOS) are limited; macOS `NSTableView` offers native resize.
- **WinUI 3**: Start from `DataGrid` (`CommunityToolkit.WinUI.Controls`, not `Microsoft.UI.Xaml.Controls`) or `ItemsView` with `ItemsRepeater` rows. Selection: use `DataGrid.SelectionMode = "Extended"` (the values are `Single` and `Extended`) or bind `SelectedItems` to a collection; track by id via a data object. Sorting: use `DataGrid` built-in sorting or manage `SortDescription` in a `CollectionViewSource` wrapping `rows`. Column resize: `DataGrid` columns are natively resizable; set `CanUserResizeColumns="True"`. Reorder: `DataGrid` does not natively reorder rows; use a `ListView` with `CanReorderItems` and its `DragItemsStarting` / `DragItemsCompleted` events (`ItemsRepeater` has no drag events), or wire an external reordering gesture handler.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/data-table.tsx` | confirmed (1.4.2) |

## Design Decisions

**Decision**: The component reports `onSortChange` and renders `rows` as given, rather than sorting internally.
**Rationale**: Keeps sorting policy with the data owner rather than duplicating it inside the table.
**Approved**: pending

**Decision**: Selection is a capability, not a mandate — omitting `selectedIds`/`onSelectionChange` turns the same grid into an action-list table.
**Rationale**: Sites never fork a second table for rows whose interaction lives entirely in per-cell controls, such as lists of users, flags or tokens.
**Approved**: pending

**Decision**: The anchor id used for range selection is internal state, not part of the public API.
**Rationale**: It is only ever used to compute shift-click ranges and has no meaning to a caller.
**Approved**: pending

**Decision**: Row activation is a separate act from selection — click selects, double-click (or Enter) activates.
**Rationale**: Lets one table support multi-select (bulk actions) and row opening (a details view) without the two conflicting.
**Approved**: pending

**Decision**: Reordering is opt-in (`reorder`) and independent of sorting; the component does not itself disable reordering when a sort or filter is active.
**Rationale**: A dragged row's new position would describe the filtered/sorted view rather than the underlying list, so reordering while sorted is misleading — but enforcing that is a caller obligation the component leaves to the caller, who simply omits `reorder` when a sort or filter is in force.
**Approved**: pending

**Decision**: The table does not hijack keyboard or pointer events from in-cell controls (inputs, selects, buttons, contenteditable), and a click on such a control moves a single-row selection to that row but leaves a multi-row selection alone.
**Rationale**: The grid's Arrow and Space handlers call `preventDefault`, which would swallow a space typed into an inline editor or a native select's keyboard use, and its mousedown `preventDefault` would stop a control taking focus at all; without the guard, selection and inline editing would be mutually exclusive. A details-pane list (at most one row selected) needs "click into a cell moves the pane to that row" so the row stays inline-editable without losing selection sync; a bulk-action table (many rows selected) needs the opposite — moving the selection to one row on an incidental control click would silently turn a 30-row bulk action into a 1-row one. Guarding on `selectedIds.size > 1` serves both without either use case losing anything.
**Approved**: pending

**Decision**: With `autoSizeColumns: true`, the component renders once at `max-content` (measuring each cell), then locks in explicit widths for a second pass.
**Rationale**: Each row is its own grid, so a single `max-content` pass would size every row independently and the header would not align with the body. Both passes complete before paint, so no misaligned frame is ever visible.
**Approved**: pending

**Decision**: Column auto-sizing, drag-resize, persistence, and row reorder are kept as internal behavior of `DataTable` rather than split into separate hooks or wrapper components.
**Rationale**: Both features build on state the table already computes once per render — `ids` and `renderedColumns` — that reorder's `SortableZone`/`SortableSurface` and the auto-size measuring pass both read directly. Extracting either into a standalone hook or wrapper would mean re-threading that same state across a new boundary for every consumer, in exchange for splitting up a table that, as built, has one render pass and one set of derived ids to keep in sync.
**Approved**: pending

**Decision**: Accept that drag transforms ignore `prefers-reduced-motion`, as known debt.
**Rationale**: The dragged row's transform is applied unconditionally, so the `reduced-motion` check fails. The remedy is to skip the transform and transition under `prefers-reduced-motion`; nothing about the current API blocks adding it later.
**Approved**: pending

**Decision**: Accept the component's hardcoded English strings, as known debt.
**Rationale**: The strings listed under Localization have no override besides `emptyLabel`, so the `string-externalization` and `no-hardcoded-strings` checks fail. The remedy is a `labels` prop (or a locale provider) defaulting to today's English, which would not be a breaking change.
**Approved**: pending
## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | failed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | User Safety |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`screen-reader-support`, `focus-management`, and `semantic-markup` rest on the `role`/`aria-*` attributes the source sets on the grid, rows, cells, headers, and resize handles. `keyboard-navigable` is partial because selection, activation, and sorting are fully keyboard-operable but column resize and row reorder have no keyboard path in this source. `dynamic-type-support` and `contrast-ratio` are partial because the source uses relative Tailwind sizing and design tokens without verifying either against a scaling or contrast requirement. `touch-target-size` is partial because the resize handle (`w-1.5`, 6px) is well under a legible target and checkbox sizing is delegated to the `Checkbox` component. `reduced-motion` fails because the drag transform (`drag?.style`) is applied unconditionally with no `prefers-reduced-motion` check. `string-externalization` and `no-hardcoded-strings` fail because of the literal strings listed under Localization. `text-expansion-tolerance` fails because cells `truncate` rather than reflow. `rtl-layout-support` is partial because the resize handle is positioned with physical `right-0`/`translate-x-1/2` rather than a logical (start/end) property. `unicode-support` passes because row content renders through ordinary React string interpolation with no charset restriction. `safe-defaults` passes because every added-surface prop (`autoSizeColumns`, `reorder`, `showSelectionCheckboxes`) defaults to off/undefined. `separation-of-concerns` is partial because selection, keyboard navigation, column-resize dragging, and auto-sizing are all implemented as state and handlers inline inside `DataTable` itself rather than extracted into a hook; `unit-test-coverage` passes because `dataTable.test.tsx` imports `DataTable` directly and exercises its behavior with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial conversion from legacy UI spec. |
| 1.1.0 | 2026-07-03 | Mike Fullerton | Selection made optional: omitting selectedIds/onSelectionChange yields action-list mode (no aria-selected, inert rows, in-cell controls own interaction). |
| 1.2.0 | 2026-07-11 | Mike Fullerton | **Content-sized + user-resizable columns** (`autoSizeColumns`, `columnWidthsKey`, per-column `resizable`), and **selectable tables can now host inline editors**. Sizing: a `max-content` track cannot do this on its own, because each row is its own grid — it would size every row independently and the header would not line up with the body. So the table renders one pass at `max-content`, measures the widest cell per column, and locks that in as an explicit px track shared by every row (both passes pre-paint, so no misaligned frame is shown), re-measuring when rows/columns change. A drag handle on each column's trailing border overrides the measured width; double-click springs it back; widths optionally persist. Editing: the selectable grid's Arrow/Space handlers `preventDefault` and its row `mousedown` handler `preventDefault`s to avoid focus-stealing — which swallowed spaces typed into an in-cell editor and stopped in-cell controls taking focus at all, making selection and inline editing mutually exclusive. Both now ignore events originating inside a cell control, so a row can be selected (driving a details pane) AND edited in place. New requirements `must-size-columns-to-widest-cell`, `must-resize-columns-by-drag`, `may-persist-column-widths`, `must-fill-slack-not-stretch`, `must-truncate-when-dragged-narrow`, `must-not-hijack-cell-controls`. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | **Row activation, reordering, and selection checkboxes** (`onRowActivate`, `reorder`, `showSelectionCheckboxes`). Activation: double-click and Enter open a row when handler is provided; reaches keyboard-only users. Reordering: `reorder` prop enables drag-and-drop row reordering with accessible announcements and `canDrag` guards; omit when sorted/filtered. Checkboxes: `showSelectionCheckboxes` adds a leading column with per-row and select-all checkboxes; row labels derive from `describeRow` or row content. New requirements `double-click-activates-row`, `enter-activates-focused-row`, `must-enable-row-drag-to-reorder`, `must-respect-candrag-check`, `must-announce-drag-state`, `must-not-reorder-while-sorted`, `must-add-leading-checkbox-column`, `must-include-select-all`, `must-label-checkboxes`, `checkbox-click-not-select-row`. Platform Notes section added. Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy, Logging sections added with not-applicable explanations. |
| 1.3.1 | 2026-09-22 | Mike Fullerton | Platform Notes expanded to five separate bullets (SwiftUI, Compose, AppKit/UIKit, WinUI 3) with concrete guidance on control selection, property mapping, and platform-specific constraints. WinUI 3 bullet specifies DataGrid vs. ItemsRepeater, SelectionMode binding, sorting via SortDescription or built-in, column resize handling, and row reorder patterns. |
| 1.4.0 | 2026-09-22 | Mike Fullerton | Lint pass: corrected the ⌥/Alt-click requirement and its test vector to additive-only selection (source has no ⌘/Ctrl handling); renamed all keyword-prefixed requirements to subject-only kebab-case; added depends-on/related cross-references; added Empty and Loading States requirements; moved the sorted/filtered reorder constraint out of Behavioral Requirements into Design Decisions; reformatted Design Decisions into Decision/Rationale/Approved form and added an SRP-scope decision; rewrote Conformance Test Vectors for full requirement/edge-case coverage and split multi-outcome rows; resolved the in-cell-control contradiction between the last edge case and not-hijack-cell-controls; reworded checkbox-click-not-select-row off the undefined onRowClick API; specified the sort cycle, select-all indeterminate/clear behavior, stale-focused-id, and action-list double-click behaviors; corrected Localization, Accessibility Options, and Platform Notes (React/Web label, SwiftUI Table availability and .insetGrouped, Compose has no dnd-kit equivalent, WinUI 3 DataGrid namespace); added the Compliance table. |
| 1.4.1 | 2026-09-25 | Mike Fullerton | not-hijack-cell-controls corrected to describe the size>1 guard (control click moves selection only when <=1 row selected, else leaves multi-selection unchanged); added T30/T31 vectors and updated Design Decision/Edge Case. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.4.2 | 2026-11-14 | Mike Fullerton | Split not-hijack-cell-controls in two, promoted the two-state sort cycle, select-all toggle and focused-row rule to named requirements, defined DataTableReorder, SortableDrop and DataTableRowContext, added vectors T32 to T39 with concrete values, recorded reduced-motion and English-only strings as Design Decisions, and corrected the SwiftUI, AppKit and WinUI 3 notes. |
