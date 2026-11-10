
The component uses standard ARIA attributes and does not detect or respond to platform accessibility settings.

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented in source. Component does not apply `prefers-reduced-motion`; animation behavior depends on `tabItemClass` styling (caller's responsibility). |
| Increase Contrast | Not implemented in source. Contrast is determined by `tabItemClass` styling (caller's responsibility to ensure WCAG AA compliance). |
| Differentiate Without Color | Not implemented in source. Active state is indicated by `data-active` attribute and `aria-selected`/`aria-current`; visual styling via `tabItemClass` (caller's responsibility). |

