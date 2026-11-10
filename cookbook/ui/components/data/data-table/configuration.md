
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

