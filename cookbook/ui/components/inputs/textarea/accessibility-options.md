
| Option | Behavior |
|--------|----------|
| Reduce Motion | The source has no `motion-reduce:` variant, so `transition-colors` runs regardless of the `prefers-reduced-motion` preference — color transitions are not made instantaneous when the setting is enabled. |
| Increase Contrast | Implementations SHOULD ensure the chosen token colors (`apt-text`, `apt-gold`, `apt-red`) meet WCAG AA contrast ratios against the background. Token definitions are responsible for maintaining contrast, not this component. |
| Differentiate Without Color | The focus indicator differentiates via both color (golden border/ring) and a visible ring shape, satisfying the requirement for focus. The invalid state (red border/ring) relies on color alone in this source; callers SHOULD pair `aria-invalid` with associated error text (e.g. via `aria-describedby`) to give it a non-color cue too. |

