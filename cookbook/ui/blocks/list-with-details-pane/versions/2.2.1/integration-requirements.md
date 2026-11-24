
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

