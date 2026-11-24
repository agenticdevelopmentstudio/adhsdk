
| Option | Behavior |
|--------|----------|
| Reduce Motion | The component does not apply transition or animation effects; this option has no effect. |
| Increase Contrast | The component relies on the field's text, accent, and border color roles. If the design system's tokens for those roles are updated to provide higher-contrast colors, the component automatically uses them. No component-level implementation required. |
| Differentiate Without Color | On focus the component switches the border to the accent color role and adds a 2px ring at 25% accent opacity; both are color changes, so differentiation still relies partly on hue. Whether the ring's own contrast against its background meets WCAG 1.4.11 Non-text Contrast (3:1) has not been measured from source alone. |

