
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `items` | `PopupMenuItem[]` | (required) | Array of selectable items; each must have unique `id` and a `label`. |
| `selectedId` | `string \| null` | (required) | The currently selected item's id, or null for "All" (nothing focused). |
| `onSelect` | `(id: string \| null) => void` | (required) | Callback invoked when an item or "All" is selected. |
| `allLabel` | `string \| null` | `"All"` | Label for the "All" (nothing focused) row; omits the row if null. |
| `onNew` | `() => void` | (optional) | Callback invoked when "New…" is selected; if not provided, the row is omitted. |
| `newLabel` | `string` | `"New…"` | Label for the "New…" entry (shown only if `onNew` is provided). |
| `ariaLabel` | `string` | (required) | Accessible label for the trigger button. |
| `icon` | `ReactNode` | (optional) | Custom icon to display on the trigger; defaults to the default affordance icon. |
| `className` | `string` | (optional) | Extra CSS classes for the trigger, merged with built-in classes so consumer classes win. |

