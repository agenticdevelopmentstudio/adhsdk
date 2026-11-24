
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `theme` | `ThemeKey` | required | Key into the `themes` manifest |
| `scope` | `string` | none | CSS selector to confine the theme to; absent or empty means document-wide |
| `colorMode` | `ThemeColorMode` | `system` | `system` follows `html.dark`; `light` or `dark` forces a variant; scoped use only |

Fixed constants: global id `adh-sdk-theme`; scoped id prefix `adh-sdk-theme-scoped`; never-matching selector `:scope.pc-colormode-off`; document selectors `html.dark :scope`, `html:not(.dark) :scope` and `html[data-color-mode]:not(.dark) :scope`. The injected dependency is the `themes` manifest imported from `./manifest`, which the component test replaces with a mock.

