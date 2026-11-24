
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

