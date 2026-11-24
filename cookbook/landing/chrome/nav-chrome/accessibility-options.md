
| Option | Behavior |
|--------|----------|
| Reduce Motion | The component itself performs no animation, but its behavior drives two host-controlled motion effects: the drawer's open/close transition (triggered by the `.lp-drawer--open` class) and the smooth scroll on fragment navigation (`scroll-behavior: smooth` on the host's `html`). Host CSS MUST honor `prefers-reduced-motion` by disabling or reducing both, e.g. `@media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto } .lp-drawer { transition: none } }`. |
| Increase Contrast | Not applicable: styling is the responsibility of host CSS; component provides only class names and semantic elements. |
| Differentiate Without Color | Not applicable: component uses no color to convey state; state is conveyed through aria-expanded, aria-hidden, and class name changes that are styled by the host. |

