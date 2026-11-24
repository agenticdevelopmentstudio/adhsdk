
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | "top" \| "right" \| "bottom" \| "left" | "right" | Specifies which edge the drawer slides in from. |
| `showCloseButton` | boolean | `true` | Controls whether the close button is rendered in the top-right corner. |
| `open` | boolean | uncontrolled | On `Sheet`: whether the drawer is open, for controlled use. |
| `defaultOpen` | boolean | `false` | On `Sheet`: whether the drawer starts open when uncontrolled. |
| `onOpenChange` | `(open, details) => void` | — | On `Sheet`: called when the drawer opens or closes, including a pointer or Escape dismissal. |
| `disablePointerDismissal` | boolean | `false` | On `Sheet`: when true, clicking the overlay no longer closes the drawer (see **close-on-overlay-click**). |
