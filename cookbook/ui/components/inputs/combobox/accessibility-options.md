
| Option | Behavior |
|---|---|
| Reduce Motion | Not applicable — the wrapper applies no transition or animation classes to the input or the popup; open/close is an immediate mount/unmount. |
| Increase Contrast | The focus-visible ring (`ring-apt-gold/25`) and the active-row tint (`bg-apt-highlight/15`) are translucent overlays; under Increase Contrast they SHOULD render as solid, higher-contrast fills so the focus and active states stay distinguishable against `apt-surface` / `apt-bg`. |
| Differentiate Without Color | The active row is also identified via `aria-activedescendant` / `data-highlighted`, not color alone; the current-value row adds a check-mark glyph rather than relying on color alone. |

