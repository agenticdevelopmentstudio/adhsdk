
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `collapsed` | `boolean` | — | Required. Current collapse state; `true` = collapsed, `false` = expanded. |
| `onToggle` | `(e: MouseEvent<HTMLButtonElement>) => void` | — | Required. Callback invoked when button is clicked. Receives React MouseEvent for modifier key inspection. |
| `label` | `string` | — | Required. Region name for aria-label; appears in accessible label as "Expand {label}" or "Collapse {label}". |
| `controls` | `string \| undefined` | `undefined` | Optional. `id` of the region this button controls; passed to `aria-controls`. |
| `className` | `string \| undefined` | `undefined` | Optional. Additional CSS class(es) merged with component defaults via class utility. |

