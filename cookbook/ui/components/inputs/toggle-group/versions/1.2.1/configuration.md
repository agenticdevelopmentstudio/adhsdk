
| Option | Type | Default | Description |
|---|---|---|---|
| `value` | `string[]` | — | Controlled selection. Single-select: pass `[selected]`. |
| `onValueChange` | `(next: string[]) => void` | — | Fired with the next value array; single-select reads `next[0]`. |
| `defaultValue` | `string[]` | — | Uncontrolled initial selection (Base UI owns state). |
| `multiple` | `boolean` | `false` | Allow more than one pressed item. |
| `className` | `string` | — | Extra classes for the group shell; merged via `cn()`. |
| `...props` | Base UI `ToggleGroup.Props` | — | All group props (incl. `aria-label`, `disabled`) forwarded. |

`ToggleGroupItem` props:

| Option | Type | Default | Description |
|---|---|---|---|
| `value` | `string` | — | The value this item represents in the group. |
| `disabled` | `boolean` | `false` | Makes the item inert and dimmed. |
| `className` | `string` | — | Extra classes for the item pill; merged via `cn()`. |
| `...props` | Base UI `Toggle.Props` | — | All toggle props forwarded; `children` may include an icon + label. |

