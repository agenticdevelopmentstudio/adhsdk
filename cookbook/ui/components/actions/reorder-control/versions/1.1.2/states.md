
| State | Appearance change |
|-------|-------------------|
| Default | Both buttons fully opaque, interactive if not at boundary |
| Up button at boundary (canMoveUp=false) | Up button appears disabled (reduced opacity, pointer events disabled), down button unaffected |
| Down button at boundary (canMoveDown=false) | Down button appears disabled (reduced opacity, pointer events disabled), up button unaffected |
| Busy/In-flight (busy=true) | Group container dimmed to opacity 60% (buttons dim with it), aria-busy set on the group, aria-disabled set on both buttons (not the group), click handlers guarded |
| Boundary button also busy (e.g. canMoveUp=false AND busy=true) | Both the disabled attribute (boundary) and aria-disabled (busy) are set on the same button; see **overlapping-disabled-states** |
| Focused button | Standard focus styling from Button component (outline/ring) |

