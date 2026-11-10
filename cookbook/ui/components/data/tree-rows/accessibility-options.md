
| Option | Behavior |
|--------|----------|
| Reduce Motion | The component applies `transition-transform` to the chevron icon rotation but never queries `prefers-reduced-motion`; the animation plays regardless of the user's motion preference. |
| Increase Contrast | Focus ring color and hover state text color use the `apt-gold` and `apt-text` design tokens; see the open question on contrast. |
| Differentiate Without Color | Toggle state is communicated by aria-expanded, title, and icon rotation (visual), not by color alone. Focus is indicated by a ring, not color. |

- **contrast**: NEEDS REVIEW: Not implemented in source. Focus ring and hover-state text colors are set from the `apt-gold` and `apt-text` design tokens (`tree-rows.tsx`); their resolved contrast ratios cannot be verified from this file — confirm they meet the required WCAG contrast ratios.

