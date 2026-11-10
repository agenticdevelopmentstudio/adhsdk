
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable; divider has no motion or animation. |
| Increase Contrast | The divider's line color comes from a themable separator-color token rather than a fixed value (see **Appearance**), not from the component itself; on native platforms this SHOULD map to a system separator color (e.g. `NSColor.separatorColor`, `UIColor.separator`, `DividerStrokeColorDefaultBrush`) that already adapts automatically when Increase Contrast is enabled. |
| Differentiate Without Color | Not applicable; divider is rendered as a line, not dependent on color alone. |

