
| Option | Behavior |
|---|---|
| Reduce Motion | Not respected. The busy spinner's `animate-spin` (see **show-busy-indicator**) and each button's `transition-all` (from the shared `Button` component) play regardless of `prefers-reduced-motion`. Layout itself never triggers `transition-all` — that is the point of resolving it in CSS before paint (see **settle-before-interactive**) — so the gap is limited to the spinner's rotation and `Button`'s hover/press/variant transitions. |
| Increase Contrast | Delegated: color and contrast are carried entirely by `Button` theme tokens; `DialogActions` renders no colors of its own. |
| Differentiate Without Color | Not applicable: the component carries no color-only affordances — state is also conveyed by the presence/absence of buttons, the `disabled` attribute, and the spinner's `role="status"`. |

