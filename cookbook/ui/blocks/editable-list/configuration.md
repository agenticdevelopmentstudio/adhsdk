
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

