
| Option | Behavior |
|--------|----------|
| Reduce Motion | Transitions are applied (transition-colors on the root, transition-transform on the thumb); the component does not check `prefers-reduced-motion` and does not disable or minimize transitions when the user has Reduce Motion enabled. |
| Increase Contrast | The component uses the `apt-gold` (checked) and `apt-input` (unchecked) tokens from the design system; see the open question on increase-contrast. |
| Differentiate Without Color | The Switch communicates state through both color (apt-gold vs. apt-input) and position change (thumb translates 14px right when checked); the position change provides a non-color indicator for users who cannot distinguish colors. |

- **increase-contrast**: NEEDS REVIEW: Not implemented in source. Confirm the `apt-gold` (checked) and `apt-input` (unchecked) tokens meet the WCAG 1.4.11 non-text contrast ratio (3:1) against their surrounding background — `switch.tsx` only assigns these tokens and doesn't resolve or verify their contrast; the switch's state indicator is a non-text UI component, so the 4.5:1 text threshold doesn't apply.

