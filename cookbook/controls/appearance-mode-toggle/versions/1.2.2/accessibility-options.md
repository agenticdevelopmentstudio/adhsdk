
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented: the optional stylesheet's `150ms` `color` transition on hover (see Appearance) has no `prefers-reduced-motion` or reduce-motion-setting guard in `appearance-mode-toggle.css`. The badge and icon swap themselves are instant either way — only the hover color change animates, and it does so unconditionally. |
| Increase Contrast | Not implemented: Component uses `currentColor` for icons and relies on parent button styling for contrast. Icon contrast depends on parent button's text color. |
| Differentiate Without Color | Satisfied: Component conveys mode state via icon shape (sun vs. moon) and badge presence, not color alone. No additional implementation needed. |

