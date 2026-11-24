
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable; the component does not animate |
| Increase Contrast | The component SHOULD render text and background with higher contrast ratios when `@media (prefers-contrast: more)` matches, for example by a host overriding `--lp-ink` and `--lp-card`; the component itself has no such rule. Under `forced-colors: active`, it SHOULD keep the `lp-hairline` border visible and defer to system colors (e.g. `CanvasText` / `Canvas`) rather than the theme's custom background and border tokens, which forced-colors mode overrides. |
| Differentiate Without Color | Not applicable; the component does not rely on color alone to convey information |

