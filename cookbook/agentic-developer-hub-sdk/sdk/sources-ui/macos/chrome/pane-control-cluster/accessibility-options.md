
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: The component has no animations; it renders states instantly. Reduce Motion does not affect visual appearance. |
| Increase Contrast | Not supported: the component observes only `ThemeManager`/`ThemeScope` theme-change notifications, and nothing posts one for the OS Increase Contrast setting. The palette's secondary/tertiary text colors are fixed sRGB values with no dynamic/high-contrast variant, so the tint does not react to Increase Contrast — see **theme-aware-tinting**. |
| Differentiate Without Color | Supported: state is conveyed by glyph shape (xmark, minus/plus, the two diagonal-arrow variants) and by accessibility labels, never by color alone. |

