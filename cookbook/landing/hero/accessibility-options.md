
| Option | Behavior |
|--------|----------|
| Reduce Motion | Nothing in the hero animates: the glow is a static radial gradient (`.lp-glow` in base.css), not a keyframe animation. base.css also carries a `prefers-reduced-motion` reset that sets `animation: none` and `transition: none` on every element of a deck or flow page, so any host-added motion inside the hero stops too. |
| Increase Contrast | Not implemented in source; the web component adds no rule of its own. A port SHOULD honor the platform's increased-contrast setting by raising the tagline's dim ink toward the full ink color; on web a host does this by overriding `--lp-ink-dim` under `@media (prefers-contrast: more)`. |
| Differentiate Without Color | Not applicable; Hero uses no color-only differentiation. |

