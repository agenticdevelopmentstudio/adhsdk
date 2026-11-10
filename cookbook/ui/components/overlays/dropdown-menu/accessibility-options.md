
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: this component implements no animation directly in its source. If the external `components.css` theme layer adds an open/close transition, that layer MUST honor `prefers-reduced-motion`. |
| Increase Contrast | The `adh-dropdown-menu__item--accent` accent styling MUST meet WCAG AA contrast in high-contrast mode; enforced by the semantic CSS theme layer this component's classes hook into (see support-accent-items). |
| Differentiate Without Color | Satisfied: checked and selected states render the Check/Circle icon in the indicator slot regardless of color, so selection state is never conveyed by color alone. |

