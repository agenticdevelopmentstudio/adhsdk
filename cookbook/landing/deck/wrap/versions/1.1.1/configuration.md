
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--lp-measure` | CSS custom property (length) | `70rem` | Maximum content width Wrap caps its children at. |
| gutter | fixed, not configurable | `2.5rem` | Subtracted once from the available width (`100% - 2.5rem`) — total across both sides, not per side — before comparing that result to `--lp-measure` and taking the smaller. When this branch wins, centering splits it evenly into `1.25rem` per side; when `--lp-measure` wins instead, the gutter plays no role in the actual per-side margin. |

