
| Option | Behavior |
|--------|----------|
| Reduce Motion | Component applies `transition-colors` to the field, animating border/ring color changes on focus and validation-state changes; this transition is not gated by `prefers-reduced-motion` (no `motion-reduce:transition-none` is applied in source) |
| Increase Contrast | Inherits higher-contrast token values through M3 theme tokens (`apt-border`, `apt-gold`, `apt-red`); no additional component logic needed |
| Differentiate Without Color | Default vs. an active state (focus or invalid) is distinguished by the presence of the border/ring itself, not color alone; focus and invalid are distinguished from each other by hue (gold vs. red) only — `aria-invalid` carries the corresponding signal to assistive technology, which does not depend on color |

