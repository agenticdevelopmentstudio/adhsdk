
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: Component does not apply transitions on mode change; mode changes are instantaneous. |
| Increase Contrast | Not applicable: Component is an unstyled icon button relying on host application styling via `className` prop. Contrast adjustments are the host's responsibility. |
| Differentiate Without Color | Component uses three distinct icon shapes (Sun for light, Moon for dark, RefreshCw for auto) as the primary visual indicator, plus complete text labels in `aria-label` and `title` attributes, ensuring mode is communicated without relying solely on color. |

