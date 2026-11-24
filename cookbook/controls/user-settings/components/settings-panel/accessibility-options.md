
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the panel's styles define no transition or animation. |
| Increase Contrast | The panel defines no `prefers-contrast` or forced-colors rules; colors come only from themable tokens, so any response is the theme's. |
| Differentiate Without Color | The selected row is shown by a tinted background and an accent-colored icon, and also exposed as `aria-selected`; the row has no icon-independent visual marker, so a pane without an icon is distinguished visually by tint only. |

