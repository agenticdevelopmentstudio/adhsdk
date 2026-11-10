
| Option | Type | Default | Description |
|---|---|---|---|
| `open` | `boolean` | — | Controls the `Dialog`. |
| `nodes` | `readonly CategoryTreeNode[]` | — | The owner's whole vocabulary; folded internally with `buildCategoryTree`. |
| `title` | `string` | — | Dialog title — the host's words. |
| `description` | `React.ReactNode` | — | Optional dialog description. |
| `confirmLabel` | `string` | — | The confirm button's verb ("Move", "Choose…") — the host's, because only it knows what the pick is for. |
| `disabledIds` | `readonly string[]` | `[]` | Ids that cannot be picked — for a move, the category itself and its descendants. |
| `allowRoot` | `boolean` | `false` | Offers a "no parent" row that confirms with `null`. |
| `rootLabel` | `string` | `"Top level"` | Copy for the root row. |
| `initialSelectedId` | `string \| null` | `null` | Pre-selected category id. `null` selects the root row — highlighted and confirmable (while the filter is empty) when `allowRoot` is set; unhighlighted with Confirm disabled when it is not. |
| `error` | `string \| null` | `null` | A rejected confirm's message — the host owns it. |
| `busy` | `boolean` | `false` | Disables the field and replaces both action buttons with a `role="status"` loading spinner (`DialogActions`) while a confirm is in flight. |
| `onConfirm` | `(categoryId: string \| null) => void` | — | Fired on confirm with the pending selection. |
| `onCancel` | `() => void` | — | Fired on Cancel, Esc, or a non-busy outside dismiss. |

Exports: `CategoryPickerDialog`, `CategoryPickerDialogProps`.

