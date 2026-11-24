
| Option | Type | Default | Description |
|---|---|---|---|
| `label` | `ReactNode` | — (required) | The micro uppercase-mono caption. |
| `value` | `ReactNode` | — (required) | The big mono-bold figure. |
| `tone` | `StatTone` | `neutral` | Value tint: `neutral`/`muted`/`accent`/`blue`/`orange`/`success`/`error`. |
| `valueClassName` | `string` | — | Extra classes for the value; merged after the tone class (escape hatch for categorical hues). |
| `className` | `string` | — | Extra classes for the wrapper; merged via `cn()`. |

Exports from `@adh-sdk/ui/components/stat`: `StatRow`, `Stat`, the `StatTone`
type, and the `StatProps` interface.

