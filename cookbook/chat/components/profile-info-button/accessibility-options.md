
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the 0.18s border and glow transition is not gated on `prefers-reduced-motion`; the stylesheet has no media query for it. |
| Increase Contrast | Not applicable: the stylesheet has no `prefers-contrast` rule; colors come from theme tokens only. |
| Differentiate Without Color | Not applicable: the stylesheet has no rule for it; the button is identified by its circle shape and "i" glyph, and the hover and focus highlight is a border color change plus a glow. |

