
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented in source. The component uses `transition-colors` on the visual line unconditionally and does not respond to `prefers-reduced-motion`. Callers SHOULD override the transition via CSS if reduced motion is required. |
| Increase Contrast | Not implemented in source. The component uses `apt-border` and `apt-border-strong` tokens, which are defined by the design system. Callers relying on increased contrast SHOULD provide theme overrides or use high-contrast token values. |
| Differentiate Without Color | The component distinguishes state primarily by visual cues: the thin line's color/position changes on hover and focus, and the step buttons display directional glyphs (▲/▼, ◀/▶) that persist regardless of color, satisfying WCAG 2.1 SC 1.4.1 (Use of Color) for color-only signalling. Whether the line and the `apt-gold/40` focus ring also meet the 3:1 contrast that SC 1.4.11 (Non-text Contrast) requires depends on the resolved values of the `apt-border`/`apt-gold` tokens, which the source does not resolve or verify — see the `contrast-ratio` compliance check below. |

