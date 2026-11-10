
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | `boolean` | — | Controls whether the dialog is visible. REQUIRED. |
| `node` | `CategoryTreeNode \| null` | — | The category to delete. When `null` and no prior node has been supplied, the component renders nothing. REQUIRED. |
| `orphanedNames` | `readonly string[]` | `[]` | Names of subcategories that will be orphaned by deletion. Optional; an empty array hides the orphaned message. |
| `itemNoun` | `string` | — | The plural, lowercase name of items filed in categories (e.g., "notes", "documents"). Inserted into the main explanation text. REQUIRED. |
| `error` | `string \| null` | `null` | Error message to display, or `null` if no error. Optional. |
| `busy` | `boolean` | `false` | Indicates an async action (e.g., API call) is in progress. Replaces both action buttons with a loading indicator and blocks dismissal when `true`. Optional. |
| `onConfirm` | `() => void` | — | Callback invoked when the user clicks "Delete". REQUIRED. |
| `onCancel` | `() => void` | — | Callback invoked when the user clicks "Cancel" or uses the close affordance while not busy. A backdrop click never invokes it — the shared `Dialog` primitive disables pointer-based outside dismissal unconditionally. REQUIRED. |

