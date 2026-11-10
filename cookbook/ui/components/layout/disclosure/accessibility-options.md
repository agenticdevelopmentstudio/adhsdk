
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not handled: the chevron's `transition-transform` runs unconditionally; the source has no `prefers-reduced-motion` check. |
| Increase Contrast | Depends on the `apt-*` design tokens (`apt-border`, `apt-surface`, `apt-text`, `apt-text-muted`); the component itself does no `prefers-contrast` handling. |
| Differentiate Without Color | The chevron's rotation (`rotate-90` when open) indicates state independent of color, and `aria-expanded` carries it for assistive technology. |

