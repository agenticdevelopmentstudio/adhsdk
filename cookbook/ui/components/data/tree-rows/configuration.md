
### `flattenTree(rows, options)`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | `(row: T) => string` | Required | Accessor returning a unique string ID for each row. `flattenTree()` does not validate uniqueness — see Edge Cases → Duplicate IDs for the behavior when this precondition is violated. |
| `parentId` | `(row: T) => string \| null \| undefined` | Required | Accessor returning the ID of the row's parent, or null/undefined for a root. |
| `expanded` | `ReadonlySet<string>` | Omit (expand all) | Set of parent row IDs whose children SHOULD be shown. If omitted, all rows are expanded. See **omit-collapsed-descendants**. |
| `compare` | `(a: T, b: T) => number` | Omit (input order) | Comparison function to sort roots and sibling groups. If omitted, input order is preserved. |

**Output — `TreeRow<T>`**

| Field | Type | Description |
|-------|------|-------------|
| `row` | `T` | The caller's own row object, unchanged. |
| `depth` | `number` | 0 for a root; +1 per ancestor. |
| `hasChildren` | `boolean` | Whether the row has any immediate children at all, regardless of expansion state. |

### `ancestorIds(rows, focusId, { id, parentId })`

| Parameter | Type | Description |
|-----------|------|-------------|
| `rows` | `readonly T[]` | The full row set to search. |
| `focusId` | `string` | The row whose ancestors are being computed. |
| `id`, `parentId` | accessors | The same accessors passed to `flattenTree`. |

Returns `Set<string>` — see **compute-ancestor-path**, **halt-ancestor-search-at-cycle**, and **halt-ancestor-search-at-missing-parent**.

### `TreeRowLabel` props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `depth` | `number` | Required | Nesting level. MUST be a non-negative integer — not validated; see Edge Cases → TreeRowLabel with negative depth. |
| `hasChildren` | `boolean` | Required | Whether to render the toggle button (`true`) or the spacer (`false`). |
| `expanded` | `boolean` | Required | Current expand/collapse state; drives the chevron rotation and the aria-label/title text. |
| `onToggle` | `() => void` | Required | Called with no arguments when the toggle button is clicked. |
| `label` | `string` | Required | Names the row for the toggle's accessible name ("Expand {label}" / "Collapse {label}"). |
| `className` | `string` | Omit | Merged with the component's default classes. |
| `children` | `React.ReactNode` | Required | Rendered after the toggle/spacer. |

