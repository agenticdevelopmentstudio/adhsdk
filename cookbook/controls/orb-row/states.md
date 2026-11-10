
| State | Appearance change |
|-------|------------------|
| Default | Orb shows emoji with gradient background; tooltip hidden until hover or focus. |
| Current | `is-current` class applied; aria-current="page" set; indicator span rendered. |
| Focused | `:focus-visible` pauses the floating animation, applies a box-shadow ring, and reveals the tooltip (see **render-focus-indicator**, **show-tooltip-on-focus**). |
| Docked | `is-docked` class applied to container; specific layout adjustments via stylesheet. |

