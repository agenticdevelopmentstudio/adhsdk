
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | `boolean` | — (required) | Whether the alert is visible. The component is fully controlled by this prop (controlled-visibility). |
| `onDiscard` | `() => void` | — (required) | Invoked when the user confirms discarding unsaved changes. |
| `onStay` | `() => void` | — (required) | Invoked when the user cancels and stays, from any dismissal path that resolves to Stay (dismissal-outcomes). |
| `description` | `string` | `"Your unsaved changes will be lost."` | Overrides the default description sentence naming what is at risk. |

