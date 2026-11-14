
| Option | Behavior |
|--------|----------|
| Reduce Motion | Chevron rotation uses a 150ms transition and heading scroll uses `behavior: "smooth"`, applied unconditionally. The source never checks `prefers-reduced-motion` anywhere, so neither the chevron rotation nor the heading scroll is ever made instant for a reader who has set that preference. |
| Increase Contrast | All text colors (secondary, primary, dim, accent) MUST meet WCAG AA 4.5:1 contrast against their backgrounds at all times; component relies on theme tokens to provide these values and does not override them. |
| Differentiate Without Color | Selected state uses BOTH bold weight and a vertical accent bar, not color alone; this is sufficient for color-blind users to distinguish selected from unselected. |

