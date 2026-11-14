
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
