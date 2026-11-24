
| State | Appearance change |
|---|---|
| Empty (`value` ≤ 0) | Indicator fully translated out (`translateX(-100%)`); `aria-valuenow` = 0 |
| Partial (0 < `value` < 100) | Indicator revealed proportionally; `aria-valuenow` = rounded value |
| Full (`value` ≥ 100) | Indicator fully revealed (`translateX(-0%)`); `aria-valuenow` = 100 |
| Transitioning | Fill animates between positions via `transition-transform` (300ms ease-out) |
| Tinted (`indicatorClassName`) | Fill color overridden (e.g. amber while building, green when done) |
| Indeterminate (Controls, `indeterminate` prop) | Fill width fixed at 35%, sliding continuously via the `aws-progress-indeterminate` keyframe; `aria-valuenow` omitted |

