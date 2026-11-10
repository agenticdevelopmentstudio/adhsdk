
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | boolean | (required) | Whether the dialog is visible. |
| `node` | CategoryTreeNode &#124; null | null | The category being renamed. `null` renders nothing only until a non-null value has been supplied at least once; after that the component keeps showing the last-held node (via `useLastPresent`) through a `null` reversion, so the exit animation can finish — see **render-nothing-when-closed**. The host may keep the dialog mounted between opens. |
| `nodes` | readonly CategoryTreeNode[] | (required) | The full vocabulary for duplicate-name validation. |
| `extraNames` | readonly string[] | [] | Additional names to treat as taken (e.g., names known to the host but not yet in `nodes`). |
| `noun` | string | (required) | Singular, lowercase term for microcopy (e.g., "category", "folder"). Interpolated into error messages and dialog title. |
| `onRename` | (node, nextName) => void &#124; `Promise<void>` | (required) | Async or sync callback to persist the rename. Receives the node and trimmed new name. |
| `onRenamed` | (node, nextName) => void &#124; undefined | undefined | Optional callback invoked after successful rename with the node and new name. |
| `onClose` | () => void | (required) | Callback invoked when the dialog closes (success, cancel, or unchanged name). |

