
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not handled: the transitions in **animate-transitions** run regardless of `prefers-reduced-motion: reduce`; the source contains no reduced-motion check. |
| Increase Contrast | Design system color tokens (apt-text, apt-text-muted, apt-border) SHOULD be defined with sufficient contrast to meet WCAG 2.1 AA standards (4.5:1 for text). Component itself does not implement special handling for prefers-contrast media query; contrast depends on token values. |
| Differentiate Without Color | Chevron icon direction (down = closed, up = open) provides state indication independent of color. The aria-expanded attribute provides semantic indication for assistive technology. |

