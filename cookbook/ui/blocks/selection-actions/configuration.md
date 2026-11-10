
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `selectedIds` | `string[]` | (required) | Array of IDs of currently selected rows. The caller is responsible for pruning IDs that have left the list. |
| `actions` | `ListAction[]` | `[]` | Array of action definitions. Each action defines an `id`, `label`, and `onClick` handler. Actions may optionally specify `requiresSelection`, `dividerBefore`, and `variant`. |
| `onDelete` | `(selectedIds: string[]) => void` | undefined | Callback invoked after the user confirms deletion. If undefined, the Delete button does not render. |
| `deleteConfirm` | `{ title: string; description?: ReactNode }` | undefined | Custom modal message for the delete confirmation. If undefined, the default title "Delete selected?" is used. |

