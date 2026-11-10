
| Option | Behavior |
|---|---|
| Reduce Motion | The rail's width transition (collapse/expand/drag) respects the user's `prefers-reduced-motion` OS setting via the global `--apt-anim-scale` CSS variable, which zeroes the transition duration (see **transition-collapse**). |
| Increase Contrast | Not implemented here — color values come from shared `apt-*` theme tokens, so any high-contrast variant is handled at the token layer, not by this component. |
| Differentiate Without Color | Color is never the sole signal: the blocked marker pairs the amber dot with a screen-reader-only ", needs attention" suffix, and the active row pairs the gold selection bar with `aria-current="true"`. |

