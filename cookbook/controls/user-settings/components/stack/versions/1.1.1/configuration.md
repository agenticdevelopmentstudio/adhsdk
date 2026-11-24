
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `children` | `ReactNode` | `undefined` | Child elements rendered inside the stack. |
| `gap` | `number \| string` | `undefined` | Spacing between children. Numbers convert to pixel strings; strings are applied as-is. |
| `align` | `CSSProperties['alignItems']` (CSS keyword union, or any string) | `undefined` | Maps to the CSS `alignItems` property. |
| `justify` | `CSSProperties['justifyContent']` (CSS keyword union, or any string) | `undefined` | Maps to the CSS `justifyContent` property. |
| `className` | `string` | `undefined` | Appended after the base `aws-stack` and direction classes. |
| `style` | `CSSProperties` | `undefined` | Merged into the computed inline style last, taking precedence over `gap`/`align`/`justify`. |

No other props are accepted. `id`, `role`, `aria-*`, and any other attribute are not forwarded to the root element (see **no-rest-prop-forwarding**).

