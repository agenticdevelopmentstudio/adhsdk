
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `selectedIds` | `string[]` | (required) | Array of IDs of currently selected rows. The caller is responsible for pruning IDs that have left the list. |
| `actions` | `ListAction[]` | `[]` | Array of action definitions. Each action defines an `id`, `label`, and `onClick` handler. Actions may optionally specify `requiresSelection`, `dividerBefore`, and `variant`. |
| `onDelete` | `(selectedIds: string[]) => void` | undefined | Callback invoked after the user confirms deletion. If undefined, the Delete button does not render. |
| `deleteConfirm` | `{ title: string; description?: ReactNode }` | undefined | Custom modal message for the delete confirmation. If undefined, the default title "Delete selected?" is used. |

`ListAction` (each entry of `actions`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | `string` | required | Identifies the action and is its React list key. Callers MUST keep each `id` unique across `actions`. |
| `label` | `ReactNode` | required | The button's content. |
| `onClick` | `(selectedIds: string[]) => void` | required | Called with the currently selected ids when the button is clicked. |
| `requiresSelection` | `boolean` | optional | When `true`, the button is disabled while `selectedIds` is empty. Omitted or `false` leaves it enabled. |
| `dividerBefore` | `boolean` | optional | Renders a vertical separator before the button. |
| `variant` | any variant of `Button` | optional | Defaults to `ghost`. |
