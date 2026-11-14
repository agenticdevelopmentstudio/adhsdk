
| State | Appearance change |
|-------|------------------|
| Default (light mode) | Sun icon visible; no badge. |
| Default (dark mode) | Moon icon visible; no badge. |
| Default (auto mode) | Sun or moon icon depending on resolved appearance; auto badge visible. |
| Hovered | Color transitions from `var(--color-text-dim)` to `var(--color-text-primary)` over `150ms`, via the optional stylesheet's `:hover` rule; no change if that stylesheet is not imported. |
| Pressed | No appearance change specified by the component or its optional stylesheet. |
| Focused (`:focus-visible`) | A `2px solid var(--color-accent)` outline appears, offset `2px`, via the optional stylesheet; native browser focus styling otherwise. |

