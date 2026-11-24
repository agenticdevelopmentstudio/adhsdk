
| Option | Type | Default | Description |
|---|---|---|---|
| `tone` | `"neutral" \| "muted" \| "accent" \| "blue" \| "orange" \| "success" \| "error"` | `"neutral"` | Selects the `apt-*` color that drives both fill and glow. |
| `size` | `number` | `10` | Diameter in px; the glow radius scales with it (`max(6, round(size*0.55))`). |
| `label` | `string` | — | Accessible name. Present → `role="img"` + `aria-label`; omitted → `aria-hidden` decoration. |
| `className` | `string` | — | Extra classes merged after the tone class via `cn()` (e.g. layout/margins). |

