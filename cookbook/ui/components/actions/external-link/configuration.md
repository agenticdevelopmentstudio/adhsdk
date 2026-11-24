
| Option | Type | Default | Description |
|---|---|---|---|
| `glyph` | `boolean` | `true` | Render the trailing `↗`. Set `false` when a leading icon carries the external affordance. |
| `children` | `ReactNode` | — | The visible label (and any leading icon); becomes the accessible name. |
| `className` | `string` | — | Extra classes merged after the base skin via `cn()` (restyle font/color/gap). |
| `...props` | `React.ComponentProps<"a">` | — | Native anchor props (`href`, `onClick`, `title`, `data-*`, …) forwarded onto the `<a>`. |

