
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not supported: `css/base.css` defines no `prefers-reduced-motion` override, so the `0.25s` bar transition runs at full speed regardless of the setting. |
| Increase Contrast | Not supported: `css/base.css` defines no `prefers-contrast` override; bar color is fixed to `currentColor`. |
| Differentiate Without Color | Not applicable: The icon is purely visual and the accessible name is always provided via `aria-label`. |

