
**UI**:

| Option | Type | Default | Description |
|---|---|---|---|
| `value` | `number` | `0` | Percentage complete, 0–100; clamped to that range. |
| `indicatorClassName` | `string` | — | Extra classes for the fill element (e.g. `bg-apt-green`); merged via `cn()`. |
| `className` | `string` | — | Extra classes for the track element; merged via `cn()`. |
| `...props` | `React.ComponentProps<"div">` | — | Any native div props (incl. `aria-label`, `id`, `data-*`) are forwarded onto the track. |

**Controls**:

| Option | Type | Default | Description |
|---|---|---|---|
| `label` | `ReactNode` | — | Optional label rendered above the track in an `aws-field__label` div. |
| `hint` | `ReactNode` | — | Optional hint text rendered below the track in an `aws-field__hint` paragraph. |
| `value` | `number` | — | Raw progress value; reported verbatim as `aria-valuenow` (not clamped or rounded) and used to compute the clamped fill width. Omitted from `aria-valuenow` when `undefined` or when `indeterminate`. |
| `max` | `number` | `100` | Upper bound used for the fill-width calculation and `aria-valuemax`; `aria-valuemin` is always `0`. |
| `indeterminate` | `boolean` | — | Switches to the indeterminate animation, applies `aws-field--progress-indeterminate`, and omits `aria-valuenow`. |
| `className` | `string` | — | Extra classes appended to the wrapper's `aws-field aws-field--progress[ aws-field--progress-indeterminate]` class list. |

