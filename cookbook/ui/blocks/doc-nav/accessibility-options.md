
| Option | Behavior |
|--------|----------|
| Reduce Motion | When the reader has set `prefers-reduced-motion`, the chevron rotation MUST be instant and the heading scroll MUST use `behavior: "auto"` instead of `"smooth"`. The source does not do this yet (see Compliance). |
| Increase Contrast | All text colors (secondary, primary, dim, accent) MUST meet WCAG AA 4.5:1 contrast against their backgrounds at all times; component relies on theme tokens to provide these values and does not override them. |
| Differentiate Without Color | Selected state uses BOTH bold weight and a vertical accent bar, not color alone; this is sufficient for color-blind users to distinguish selected from unselected. |

