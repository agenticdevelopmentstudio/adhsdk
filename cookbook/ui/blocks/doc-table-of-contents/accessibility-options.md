
| Option | Behavior |
|--------|----------|
| Reduce Motion | Component SHOULD respect the `prefers-reduced-motion` media query; the `transition-colors` class on heading links SHOULD be disabled when reduce-motion is enabled. |
| Increase Contrast | Component color tokens (`--color-accent`, `--color-text-primary`, etc.) SHOULD be adjusted by the theme to meet contrast ratios. Component does not control this. |
| Differentiate Without Color | Active headings rely on color to indicate state. The component SHOULD apply a visual indicator (e.g., bold text, border) in addition to color. Currently, the component uses both color and font-weight (medium) to indicate the active state, satisfying this requirement. |

