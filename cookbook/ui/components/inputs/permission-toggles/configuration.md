
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | `Crud` (object with `create`, `read`, `update`, `delete` boolean keys, in that canonical order, which fixes the button order C, R, U, D) | Required | Current CRUD permission state. |
| `parent` | `Crud` (optional) | `undefined` | Parent/ceiling permissions. Capabilities forbidden by parent cannot be toggled on. |
| `disabled` | `boolean` | `false` | When true, all buttons are non-interactive. |
| `onChange` | `(next: Crud) => void` | Required | Callback invoked when user toggles a button. A parent-blocked capability cannot be toggled (see **blocked-toggle-no-op**); other capabilities in `value` are passed through unchanged, even if they already violate `parent` (see **pass-through-other-keys**). |

