
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented: the `orb-row-float` and `orb-row-pulse` animations in `styles/orb-row.css` run unconditionally and have no `prefers-reduced-motion` guard (see Compliance: reduced-motion, failed). |
| Increase Contrast | Not implemented: the component adds no handling; style changes are the consuming stylesheet's responsibility. |
| Differentiate Without Color | Not implemented: the current orb is marked by a gold ring and dot, and by `aria-current="page"` for assistive technology; no shape change is made for users who cannot distinguish color. |
