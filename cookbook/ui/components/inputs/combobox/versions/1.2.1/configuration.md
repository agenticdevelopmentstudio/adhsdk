
| Option | Type | Required | Default | Description |
|---|---|---|---|---|
| `items` | `readonly string[]` | Yes | — | Suggestions, filtered case-insensitively as the user types. |
| `value` | `string` | Yes | — | Controlled input text. |
| `onValueChange` | `(value: string) => void` | Yes | — | Fired on every edit and on pick. |
| `ariaLabel` | `string` | Yes | — | Required; labels the input. |
| `placeholder` | `string` | No | — | Input placeholder. |
| `emptyLabel` | `string` | No | `"No matches"` | Popup text when nothing matches. |
| `disabled` | `boolean` | No | `false` | Disables the control. |
| `className` | `string` | No | — | Extra classes for the input. |
| `id` | `string` | No | — | Optional input id (to pair with an external `<label htmlFor>`). |

