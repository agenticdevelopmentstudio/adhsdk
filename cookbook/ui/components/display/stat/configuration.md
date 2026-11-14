
| Option | Type | Default | Description |
|---|---|---|---|
| `label` | `ReactNode` | — (required) | The micro uppercase-mono caption. |
| `value` | `ReactNode` | — (required) | The big mono-bold figure. |
| `tone` | `StatTone` | `neutral` | Value tint: `neutral`/`muted`/`accent`/`blue`/`orange`/`success`/`error`. |
| `valueClassName` | `string` | — | Extra classes for the value; merged after the tone class (escape hatch for categorical hues). |
| `className` | `string` | — | Extra classes for the wrapper; merged via `cn()`. |
| `align` (`Stat` only) | `"start"` \| `"end"` | `"end"` | Which edge the value and label share: `end` is the hero-strip form, `start` left-aligns them. |

`StatStrip` takes `children` and an optional `className`.

Exports from `@adh-sdk/ui/components/stat`: `StatRow`, `Stat`, `StatStrip`, the
`StatTone` type, and the `StatProps` and `StatColumnProps` interfaces.

