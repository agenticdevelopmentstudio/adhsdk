
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented in source. The component uses no animations; transitions are applied by the Popover component (not in scope here). |
| Increase Contrast | Component relies on design system tokens (`apt-gold`, `apt-highlight`, `apt-text`, etc.) for contrast. If the design system provides high-contrast token overrides, the component will inherit them. No explicit contrast adjustments are coded in the component. |
| Differentiate Without Color | The selected state is indicated by a check mark icon (shape-based, not color-only) and position in the list. The disabled state uses opacity + text styling. Color is not the sole differentiator for any state. |

