
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable; the component does not animate |
| Increase Contrast | The component SHOULD respect the deck's increased-contrast theme if available, rendering text and background with higher contrast ratios. Under `forced-colors: active`, it SHOULD keep the `lp-hairline` border visible and defer to system colors (e.g. `CanvasText` / `Canvas`) rather than the theme's custom background and border tokens, which forced-colors mode overrides. |
| Differentiate Without Color | Not applicable; the component does not rely on color alone to convey information |

