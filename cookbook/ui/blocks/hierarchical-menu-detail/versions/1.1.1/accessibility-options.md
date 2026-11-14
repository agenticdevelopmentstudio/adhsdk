
Responds to platform accessibility preferences as inherited by React/Web:

| Option | Behavior |
|--------|----------|
| Reduce Motion | No transition in this component is gated on `prefers-reduced-motion` — a deliberate decision, not a gap (see Design Decision 8). |
| Increase Contrast | Focus rings and borders use the applied theme's contrast tokens. Component does not override or adapt further. |
| Differentiate Without Color | Selection is marked with `aria-current` and a text-colour change, not colour alone. |

