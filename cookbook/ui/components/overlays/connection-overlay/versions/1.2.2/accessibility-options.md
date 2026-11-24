
| Option | Behavior |
|--------|----------|
| Reduce Motion | The spinner carries the `animate-spin` class unconditionally and the source never reads `prefers-reduced-motion`, so the rotation and the once-per-second countdown update continue unchanged when Reduce Motion is on. No enter or exit transition is applied to the overlay, so there is nothing else to disable. See respects-reduced-motion. |
| Increase Contrast | Not applicable: All colors use ADH theme tokens (var(--color-apt-*)) that are defined by the consuming application. The component passes through whatever theme colors are set; contrast is determined by the theme, not the component. |
| Differentiate Without Color | Not applicable: The spinner and countdown are identifiable by non-color attributes (animated icon shape, numeric countdown value). The primary status message is text-based. |

