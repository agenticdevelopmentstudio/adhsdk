
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

