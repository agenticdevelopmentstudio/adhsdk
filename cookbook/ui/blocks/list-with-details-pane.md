---
id: 6acd3c5f-7bb5-4d6d-8c8d-141e1909cf73
title: "ListWithDetailsPane"
type: recipe
version: 2.2.1
status: review
language: en
created: 2026-06-26
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A master/detail block: ListHeader over a multi-select DataTable and details pane, divided by an always-visible header-bar splitter; list and details are peers."
platforms:
  - typescript
  - web
tags:
  - master-detail
  - table
  - layout
  - selection
ingredients:
  - a8f66760-7db0-4a10-927e-856c2170dd4f
  - d04eef56-2dbf-4148-964b-c095f242227f
  - c21473ee-a075-4800-96db-ff3de0888515
  - 550f00f7-bfb2-415e-9b15-bd5dce015500
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# ListWithDetailsPane

## Overview

A master/detail block in `@adh-sdk/ui`: the shared `ListHeader`
(filter + actions + delete) over a `DataTable`, over a details pane. The list
and the details pane are PEERS in the column — the details never overlays the
list — and the divider between them renders as the details pane's always-visible
header bar (`ResizableSplit`'s header-bar variant, titled by `detailsLabel`). It
composes `ListHeader` + `DataTable` + `ResizableSplit` + `AlertModal` + `Button`.

It owns the selection state and filter; it renders rows in a `DataTable`
(clicking a row selects it; ↑/↓ move the selection — DataTable's keyboard nav),
and a bottom details pane that reflects the single selected row. It is generic
over row type `T`. Selection can be driven internally or mirrored to a URL
parameter for deep-linking (when `paramKey` is provided).

## Ingredients

| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| DataTable | [adhsdk.ingredient.ui.components.data.data-table](cookbook:d04eef56-2dbf-4148-964b-c095f242227f) | Renders filtered, multi-select rows | yes | `columns`, `rows`, `getRowId`, selection, `loading`, `emptyLabel`, `autoSizeColumns`, `columnWidthsKey`, `reorder` |
| ListHeader | [adhsdk.ingredient.ui.blocks.list-header](cookbook:a8f66760-7db0-4a10-927e-856c2170dd4f) | The filter + actions bar above the table | yes | `search` from `filterText`/`onFilterTextChange`; `actions` from `actions` + Delete |
| ResizableSplit | [adhsdk.ingredient.ui.components.layout.resizable-split](cookbook:c21473ee-a075-4800-96db-ff3de0888515) | Top/bottom split: table on top, details below its header-bar divider (`header={detailsLabel}`) | yes | `storageKey` forwarded from props; persists split bar position |
| AlertAndDialog | [adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500) | Destructive confirm shown before delete | yes | `destructive` tone; copy from `deleteConfirm` |

Composed shared primitives without their own recipe domains: `Button` (toolbar
actions + Delete), `Input` (filter box), and `Separator` (`dividerBefore`).

The `ingredients` domains above point at other `recipes/*`, not at
`ingredients/*`, and that is intentional here: `ListWithDetailsPane` is a
block composed from other blocks/recipes (`ListHeader`, `DataTable`,
`ResizableSplit`, `AlertAndDialog`) rather than from primitive ingredients
directly, so its Ingredients table names the recipes it wires together.

## Integration Requirements

- **own-selection**: The ListWithDetailsPane MUST own the selection state as
  a `Set<string>` and pass it to `DataTable`; selection MUST survive filter
  changes. Ids removed other than through the component's own Delete flow
  (see **confirm-delete**) are pruned from the rendered selection only when
  they leave the `rows` prop.
- **filter-rows**: The ListWithDetailsPane MUST filter rows by `filterRow`
  before the table, using the controlled `filterText`/`onFilterTextChange` when
  provided and internal state otherwise. The default `filterRow` is the single
  definition of "default filter" for this component: for each column in
  `columns`, stringify the row's raw value at that column's `key`
  (`row[column.key]`) and test a case-insensitive substring match against the
  query; a row matches if any column does.
- **disable-selection-actions**: Action buttons with `requiresSelection` and
  the Delete button MUST be `disabled` whenever the selection is empty.
- **confirm-delete**: When Delete is activated and `onDelete` is set, the
  ListWithDetailsPane MUST open an `AlertModal` (`destructive`, copy from
  `deleteConfirm`) before calling `onDelete(selectedIds)`, and on confirm MUST
  clear the entire selection immediately and synchronously in the confirm
  handler — it does not wait for the caller's `rows` prop to update first.
- **render-detail-states**: The details pane (the `ResizableSplit` bottom)
  MUST render `emptyDetail` (default "Select a row to see details.") when 0 rows
  are selected, `renderDetail(row)` when exactly 1 row is selected, and the hint
  "Select a single row to see details." when more than 1 row is selected.
- **render-divider-before-action**: A `ListAction` with `dividerBefore: true`
  MUST render a `Separator` immediately before its button in the toolbar.
- **use-list-header**: The toolbar MUST be the shared `ListHeader` (filter
  field left, actions right) so every list header on the platform matches.
- **render-details-header-bar**: The split's divider MUST render as the
  details pane's header bar (`ResizableSplit` `header={detailsLabel}`, default
  `"Details"`): always visible, drag anywhere on it, disclosure chevron far
  right, animated collapse, reveal-to-fit on expand.
- **move-selection-by-keyboard**: With the table focused, ↑/↓ MUST move the
  selection (DataTable's keyboard navigation).
- **support-url-driven-selection**: When `paramKey` is provided, the
  component MUST mirror the single selected row's id into `?<paramKey>=<id>` via
  `history.replaceState` (selecting a row neither remounts the route nor spams
  the history stack) and MUST seed initial selection from the URL parameter on
  mount; a 0-or-many selection clears the URL parameter.
- **persist-column-widths**: When `columnWidthsKey` is provided, the
  component MUST persist the user's dragged column widths under that key (via
  `DataTable`); this is distinct from `storageKey` which persists only the
  split-bar position.
- **support-column-reordering**: When `reorder` is provided (a
  `DataTableReorder` config), the component MUST forward it to `DataTable` to
  allow rows to be dragged into a new order. The component forwards `reorder`
  as given and does not itself gate on the filter; callers SHOULD NOT enable
  `reorder` while their filter is non-empty (filtered rows are a selection,
  not a position in the list).
- **clear-stale-deep-link**: When a URL-seeded selection points to a row
  id that no longer exists in `rows` (deleted/renamed), the component MUST clear
  that id from both state and the URL, so a stale link fails safe to "nothing
  open" rather than blank screen. This pruning MUST NOT run while `loading` is
  true, and it MUST NOT run whenever `rows` is empty — whether that emptiness is
  a load still in flight or a genuinely empty list — since an asynchronous row
  load's first render also has an empty `rows` before the data arrives, and
  running the check then would clear a valid `?<paramKey>=` before it gets a
  chance to match. `loading` is an optional prop, so a caller that never
  supplies it relies entirely on the empty-`rows` guard.
- **auto-size-columns**: When `autoSizeColumns` is provided, the component
  MUST forward it to `DataTable` so each column sizes to its widest cell
  content, while the user can still drag a column's trailing border to
  override that width.
- **omit-delete-without-handler**: The component MUST NOT render a Delete
  button in the toolbar when `onDelete` is not provided.
- **forward-loading-state**: When `loading` is true, the component MUST
  forward it to `DataTable` so the table shows its own loading state instead
  of `emptyLabel`.

## Layout

```
┌ ListHeader ─────────────────────────────────────────────────────────┐
│ [ 🔍 filter… ]                           [ …actions… ] | [ Delete ]  │
├─────────────────────────────────────────────────────────────────────┤
│  DataTable (filtered, multi-select)                        ▲ top     │
├ Details ──────── (drag anywhere on the bar) ─────────────────── ⌄ ──┤
│  details:                                                  ▼ bottom  │
│    0 selected → emptyDetail ("Select a row to see details.")         │
│    1 selected → renderDetail(row)                                    │
│   >1 selected → "Select a single row to see details."                │
└─────────────────────────────────────────────────────────────────────┘
```

- Toolbar: the shared `ListHeader` (recessed ButtonBar strip); filter `Input`
  with search icon; spacer `flex-1`; actions right-aligned.
- Details pane: `p-4 text-sm text-apt-text`; hints in `apt-text-muted`.
- The split wrapper uses `min-h-[16rem] flex-1`: `flex-1` claims the remaining
  column height, and the floor prevents the split from collapsing to 0 when the
  container is over-full (ensuring table rows remain hit-testable).
- The bottom pane is draggable + collapsible (disclosure) per `ResizableSplit`.
- No raw hex; no `!important`.

## Shared State

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| selection (`Set<string>`) | ListWithDetailsPane | DataTable, toolbar action + Delete buttons, URL parameter | Down & Up | Component state + prop drilling + `history.replaceState` (when `paramKey` provided) |
| filterText | Caller (controlled) or internal state | Row filter → DataTable | Down | Controlled prop `filterText`/`onFilterTextChange` or internal state |
| rows (`T[]`) | Caller | DataTable, details pane, stale-link pruning | Down | Prop |
| deleteConfirm open | ListWithDetailsPane | AlertAndDialog (AlertModal) | Down | Boolean state |
| selectedIds on delete | ListWithDetailsPane | Caller `onDelete` | Up | Callback |
| split bar position | ResizableSplit (forwarded `storageKey`) | localStorage | Persisted | `ResizableSplit` owns the read/write itself; ListWithDetailsPane only forwards `storageKey` |
| column widths | DataTable (forwarded `columnWidthsKey`) | localStorage | Persisted | `DataTable` owns the read/write itself; ListWithDetailsPane only forwards `columnWidthsKey` |

## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | filter-rows | Type `ada` in the filter | Table narrows to rows matching `ada` |
| T2 | own-selection | Select rows, then change the filter | Selection persists across filtering |
| T3 | disable-selection-actions | 0 rows selected | Delete and `requiresSelection` actions are disabled |
| T4 | disable-selection-actions | ≥1 row selected | Delete and `requiresSelection` actions are enabled |
| T5 | confirm-delete | Click Delete with rows selected, confirm | `AlertModal` opens; on confirm `onDelete(selectedIds)` is called and the entire selection is cleared immediately, synchronously, without waiting for `rows` to update |
| T6 | render-detail-states | Select 0 / 1 / >1 rows | Details pane shows `emptyDetail` / `renderDetail(row)` / the multi-select hint |
| T7 | render-divider-before-action | An action with `dividerBefore: true` | A `Separator` renders before that action's button |
| T8 | support-url-driven-selection | Provide `paramKey="id"`, select a row | URL updates to `?id=<rowId>` without remounting; reload restores selection |
| T9 | clear-stale-deep-link | URL has `?id=deleted-id`, rows load without that id | URL parameter is cleared, selection is empty |
| T10 | persist-column-widths | Provide `columnWidthsKey`, drag a column wider, reload | Column width persists across reload |
| T11 | support-column-reordering | Provide `reorder` config, filter is empty | Rows are draggable to reorder; the component forwards `reorder` unconditionally, so a caller must itself omit `reorder` while its filter is active |
| T12 | clear-stale-deep-link | URL has `?id=some-id`, `rows` is still `[]` and `loading` is `true` | The id is NOT cleared from state or the URL; pruning is deferred until `rows` is non-empty and `loading` is `false` |
| T13 | use-list-header | Render the component | Toolbar renders as the shared `ListHeader`: filter field left, actions right |
| T14 | render-details-header-bar | Render the component | The divider between `DataTable` and the details pane renders as `ResizableSplit`'s always-visible header bar, titled by `detailsLabel` (default `"Details"`) |
| T15 | move-selection-by-keyboard | Table focused, press ↓ then ↑ | Selection moves to the next row, then back to the previous row |
| T16 | auto-size-columns | Provide `autoSizeColumns: true` | Each column initially sizes to its widest cell; the user can still drag a column's trailing border to override that width |
| T17 | omit-delete-without-handler | Render without `onDelete` | No Delete button appears in the toolbar |
| T18 | forward-loading-state | `loading: true`, `rows: []` | `DataTable` shows its own loading state, not `emptyLabel` |
| T19 | support-url-driven-selection, own-selection | Provide `paramKey="id"` and a controlled `filterText` together; URL has `?id=<rowId>` for a row the initial `filterText` excludes from view | Selection is seeded from the URL on mount regardless of `filterText`; the row's absence from the filtered table does not clear its selection (selection is never filtered) |
| T20 | clear-stale-deep-link | URL has `?id=gone`, `rows` is `[]` and `loading` is `false` (a genuinely empty list, or a caller that never supplies `loading`) | The id is NOT cleared from state or the URL; pruning does not run while `rows` is empty, regardless of `loading` |

## Edge Cases

- 0 selected → `emptyDetail`; exactly 1 → `renderDetail`; >1 → the multi-select
  hint.
- A filter matching no rows shows the table's `emptyLabel`, while the selection
  of rows no longer visible is retained (see **own-selection**: ids are pruned
  only when a row leaves `rows`).
- `loading` → the `DataTable` loading state (see **forward-loading-state**);
  empty data → `emptyLabel`.
- On delete confirm, the component clears its entire selection immediately and
  synchronously in the confirm handler (and the URL parameter, if `paramKey` is
  set) — see **confirm-delete**. It does not wait for the caller's `rows` prop
  to update first; the passive pruning in **own-selection** only applies to ids
  removed some other way.
- When `onDelete` is not provided, no Delete button is rendered (see
  **omit-delete-without-handler**).
- When `paramKey` is provided but the URL parameter points to a row no longer in
  `rows`, the parameter is cleared and selection is empty (fail-safe to
  "nothing open") — see **clear-stale-deep-link**, which withholds this while
  `loading` is `true`, and also withholds it whenever `rows` is empty (even with
  `loading` false, or never supplied), so an async row load never clears a valid
  link before its data arrives.
- When both `paramKey` and a controlled `filterText` are provided, the initial
  URL-seeded selection is restored on mount regardless of `filterText`: the
  filter only narrows what `DataTable` renders, never the selection itself, so
  order between the two never matters.
- The layout floor (`min-h-[16rem]`) ensures that when a container is
  over-constrained, the page's own scroll takes overflow and rows remain
  hit-testable (without the floor, the split compresses to 0 and rows become
  unclickable despite appearing in layout).

## Platform Notes

- **React / Web (TypeScript):** Block at `packages/web/packages/ui/src/blocks/list-with-details-pane.tsx` (exported via `./blocks/*`). Composes `DataTable`, `ResizableSplit`, `AlertModal`, `Button`, `Input`, `Separator`. Core responsibilities: filter state (controlled-or-internal), multi-select state as `Set<string>`, URL parameter sync (when `paramKey` provided), stale-link pruning on row changes, split bar and column width persistence via localStorage.
- **SwiftUI:** Start with a `@State` var for selection (`Set<String>`), a `List` for the rows (or a custom table if columns are needed), an `@ViewBuilder` for the detail pane, and a custom header-bar view (drag gesture + disclosure chevron) as the divider between them — matching **render-details-header-bar** rather than a plain `Divider`. Adapt the controlled-or-internal filter pattern using `@State` for internal state and a binding for controlled. The URL parameter pattern (`URLComponents`, `history.replaceState` equivalent) requires reading/writing `NavigationPath` or the app's own route state. Stale-link pruning happens on every rows change (in `onChange` of the list selection or a `.task` tracking rows), gated on the loading state per **clear-stale-deep-link**. Column width and split position persistence use `@AppStorage` or `UserDefaults`. No equivalent to `AlertModal` builtin; compose `Alert` or the `.confirmationDialog` view modifier. Master/detail layout uses `NavigationSplitView` (iPad) or conditional `.sheet` (iPhone).
- **Compose:** Build with `Column` wrapping a `TextField` (filter), a `LazyColumn` for rows (with selection state as `MutableState<Set<String>>`), and a divider + details pane below. Adapt the controlled-or-internal filter pattern with `mutableStateOf()` for internal and a lambda callback for controlled. URL parameter sync (if needed) maps to reading/writing a route state managed by the app's navigation. Stale-link pruning is a `LaunchedEffect` tracking rows, gated on the loading state per **clear-stale-deep-link**. Column width and split position use `SharedPreferences` or a data store. No builtin confirm dialog; use `AlertDialog` or Material's `Dialog`. Master/detail split uses `BoxWithConstraints` (or `WindowSizeClass`) to decide side-by-side vs. stacked layout: a wide window (the `WindowWidthSizeClass.EXPANDED` breakpoint, or an equivalent) is side-by-side, a narrower one is stacked (overflow scrolls).
- **AppKit / UIKit:** For a native, non-SwiftUI implementation: use `NSTableView` (AppKit) or `UITableViewController` (UIKit, legacy) for the table, or compose list-like views if a true table isn't needed. Selection state is a property (mutable set or array). Filter uses a text field and a predicate applied to rows before the table. Stale-link pruning on rows changes (KVO or didSet), gated on the loading state per **clear-stale-deep-link**. Split position via `NSSplitViewController` (AppKit) or manually constraining two views with a draggable divider (UIKit). URL parameter sync (if needed) uses `URLComponents` and reads/writes app state (no `history.replaceState` in native apps; this is web-specific). Persistence uses `UserDefaults` or `NSCoding`. Confirm dialogs use `NSAlert` (AppKit) or `UIAlertController` (UIKit). Not yet implemented for this platform; the mapping above describes how the pattern would translate when it is.
- **WinUI 3:** Build using `Grid` rows: top row is a toolbar (`CommandBar` or `StackPanel` of `Button` + `TextBox` for filter), middle row is a `DataGrid` from the CommunityToolkit (`CommunityToolkit.WinUI.Controls.DataGrid`; not a WinUI 3 built-in) bound to rows, selection via its `SelectionChanged` event, bottom row is a details pane (a `ScrollViewer` with a `StackPanel` of detail content). Selection state is a C# property (`HashSet<string>`; an `ObservableCollection<T>` doesn't fit a set of selected ids). Filter uses a `TextBox.TextChanged` event to apply a predicate. Stale-link pruning is a property change handler on rows, gated on the loading state per **clear-stale-deep-link**. Split position (draggable divider) uses `Grid.RowDefinition` with `*` (flex) sizing and a `GridSplitter`, also from the CommunityToolkit (`CommunityToolkit.WinUI.Controls.GridSplitter`; not a WinUI 3 built-in), between rows; persist via `ApplicationData.Current.LocalSettings`. URL parameter sync (`paramKey` feature) is web-specific and not applicable to WinUI 3. Confirm dialog uses `ContentDialog`. Column width persistence: `DataGrid` columns expose a `Width` property; save/restore in app settings.

### API

`@adh-sdk/ui/blocks/list-with-details-pane`:

```ts
interface ListAction {
  id: string
  label: React.ReactNode
  onClick: (selectedIds: string[]) => void
  requiresSelection?: boolean        // disabled when 0 selected
  dividerBefore?: boolean            // visual separator before this action
  variant?: React.ComponentProps<typeof Button>["variant"]  // default "outline"
}
interface ListWithDetailsPaneProps<T> {
  columns: DataTableColumn<T>[]
  rows: T[]
  getRowId: (row: T) => string
  renderDetail: (row: T) => React.ReactNode
  emptyDetail?: React.ReactNode      // default "Select a row to see details."
  filterText?: string                // controlled; internal state if omitted
  onFilterTextChange?: (t: string) => void
  filterPlaceholder?: string         // default "Filter…"
  filterRow?: (row: T, query: string) => boolean   // default: see filter-rows
  onDelete?: (selectedIds: string[]) => void
  deleteConfirm?: { title: string; description?: React.ReactNode }  // AlertModal copy
  actions?: ListAction[]
  storageKey?: string                // forwarded to ResizableSplit, persists split bar position
  paramKey?: string                  // opt-in URL-driven selection (deep-linkable detail row): mirror single selected row to ?<paramKey>=<id>
  loading?: boolean
  emptyLabel?: string                // table empty text
  autoSizeColumns?: boolean           // size each column to its widest cell, user can drag to override
  columnWidthsKey?: string            // persist dragged column widths under this key (distinct from storageKey)
  reorder?: DataTableReorder          // allow rows to be dragged into a new order; withhold when filter is non-empty
  detailsLabel?: string              // title on the details pane's header bar (default "Details")
  ariaLabel: string                  // toolbar label
  className?: string
}
export function ListWithDetailsPane<T>(props: ListWithDetailsPaneProps<T>): React.ReactElement
```

### Accessibility

The toolbar is `role="toolbar"` + `aria-label`; Delete/action buttons have
labels and their `disabled` reflects the selection (see
**disable-selection-actions**). The delete `AlertModal` traps focus and is
keyboard-dismissable (its own contract).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/list-with-details-pane.tsx` | unverified |

## Design Decisions

**Decision**: The block owns selection as a `Set<string>` rather than the table
owning it.
**Rationale**: Selection must survive filtering and feed the toolbar actions
and details pane.
**Approved**: pending

**Decision**: Generic over row type `T`.
**Rationale**: Reusable platform-wide for any master/detail view of this shape.
**Approved**: pending

**Decision**: Delete always routes through a destructive `AlertModal` confirm.
**Rationale**: Deletion is destructive; a confirm prevents accidental loss.
**Approved**: pending

**Decision**: Filter is controlled-or-internal.
**Rationale**: Callers can drive or observe the query when needed, but the
common case requires no wiring.
**Approved**: pending

**Decision**: URL-driven selection is opt-in via `paramKey`.
**Rationale**: Deep-linking (via URL parameter) is a web pattern and not all
use cases need it; omitting `paramKey` preserves the legacy internal-state-only
behavior byte-for-byte. When provided, selecting a row mirrors the id to the
URL and reloading or sharing the link restores the open row without
remounting.
**Approved**: pending

**Decision**: `storageKey` persists split bar position only, not selection.
**Rationale**: Selection is ephemeral (the user opened a row to read it, not
to remember it forever); the split position is a layout preference worth
retaining. A separate `columnWidthsKey` persists column widths, orthogonal to
split position.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`screen-reader-support`, `keyboard-navigable`, and `semantic-markup` rest on
the source's `role="toolbar"` + `aria-label` toolbar and `DataTable`'s ↑/↓
keyboard navigation and `disabled` states; `focus-management` rests on
`AlertModal`'s own focus-trap contract, composed here for the delete confirm;
and the internationalization checks are `partial` because `emptyDetail`,
`filterPlaceholder`, and `detailsLabel` are prop-overridable while the
multi-select hint string is hard-coded with no override, and none of the four
go through a formal localization-key lookup in the source.
`separation-of-concerns` is partial: rendering is delegated to `DataTable`,
`ResizableSplit`, `ListHeader`, and `SelectionActions`, but
`list-with-details-pane.tsx` itself owns non-trivial business rules —
`writeParam`/`updateSelection`'s URL-param sync, the stale-id pruning
effects, and `defaultFilterRow`'s matching — inline in the block rather than
in an extracted hook. `unit-test-coverage` fails — no test file in the `ui`
package exercises `ListWithDetailsPane`, so none of that URL-sync, pruning,
or filtering logic is asserted.

## Localization

| String Key | Default (en) | Context |
|---|---|---|
| `list-with-details-pane.empty-detail` | Select a row to see details. | Details pane when 0 rows are selected (`emptyDetail`'s default) |
| `list-with-details-pane.multi-select-hint` | Select a single row to see details. | Details pane when more than 1 row is selected; hard-coded in this source with no override prop |
| `list-with-details-pane.details-label` | Details | Default title on the details pane's header-bar divider (`detailsLabel`'s default) |
| `list-with-details-pane.filter-placeholder` | Filter… | Default placeholder in the filter `Input` (`filterPlaceholder`'s default) |

`emptyDetail`, `detailsLabel`, and `filterPlaceholder` are all
prop-overridable, so a caller can already pass localized text through them;
only the multi-select hint has no such override and is hard-coded in the
source. None of the four go through a formal localization-key lookup inside
the component itself. Separately, the default `filterRow`'s case-insensitive
match (see **filter-rows**) uses `.toLowerCase()`, which is locale-sensitive
(e.g. Turkish `İ`/`i`); a caller matching locale-specific text should supply
its own `filterRow` using a locale-aware comparison rather than assume
invariant casing.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 2.2.1 | 2026-09-25 | Mike Fullerton | Fixed clear-stale-deep-link to also withhold pruning while rows is empty (not just while loading); added T20 covering a genuinely-empty rows case; shortened summary to fit 160 chars. |
| 2.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: strip the `must-` prefix from every requirement name and rename `keyboard-moves-selection`/`must-restore-stale-deep-link` for accuracy; add `auto-size-columns`, `omit-delete-without-handler`, and `forward-loading-state` requirements with test vectors; resolve the delete-confirm-vs-passive-pruning contradiction in **confirm-delete**/**own-selection**; gate **clear-stale-deep-link** on `loading` and add its test vector; unify the default-filter definition in **filter-rows**; give **support-column-reordering** an RFC 2119 keyword and correct its attribution (the component forwards `reorder` unconditionally; withholding it during a filter is on the caller, not the component); add `**Approved**: pending` to every Design Decision; replace the Compliance table with real linked accessibility and internationalization checks; fix Shared State ownership/direction for split position and column widths; correct the WinUI 3, Compose, and SwiftUI/AppKit Platform Notes; move the API and Accessibility content into their own Platform Notes subsections and fix the `Button` variant type; add a Localization section; remove app-specific facts from Platform Notes and Design Decisions; and note that the `ingredients` field intentionally lists composed recipes here. |
| 2.1.0 | 2026-09-22 | Mike Fullerton | Add URL-driven selection (`paramKey`), column width persistence (`columnWidthsKey`), row reordering (`reorder`), and auto-sizing (`autoSizeColumns`); expand Platform Notes to cover all five platforms with implementation guidance; document responsive layout floor (`min-h-[16rem]`); add new integration requirements and test vectors. |
| 2.0.0 | 2026-07-10 | Mike Fullerton | Toolbar extracted into the shared ListHeader; divider renders as the details pane's always-visible header bar (`detailsLabel`); list/details peer layout + keyboard selection made explicit. |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial conversion from legacy UI spec. |
