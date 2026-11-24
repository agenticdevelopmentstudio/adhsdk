
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | `Crud` (object with `create`, `read`, `update`, `delete` boolean keys) | Required | Current CRUD permission state. |
| `parent` | `Crud` (optional) | `undefined` | Parent/ceiling permissions. Capabilities forbidden by parent cannot be toggled on. |
| `disabled` | `boolean` | `false` | When true, all buttons are non-interactive. |
| `onChange` | `(next: Crud) => void` | Required | Callback invoked when user toggles a button. The toggled capability's emitted value is clamped to the parent constraint; other capabilities in `value` are passed through unchanged, even if they already violate `parent` (see **clamp-emitted-values**). |

