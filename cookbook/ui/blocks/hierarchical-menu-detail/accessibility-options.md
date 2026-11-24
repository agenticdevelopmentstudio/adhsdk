
Responds to platform accessibility preferences as inherited by React/Web:

| Option | Behavior |
|--------|----------|
| Reduce Motion | No transition in this component is gated on `prefers-reduced-motion` — a deliberate decision, not a gap (see the reduced-motion Design Decision). |
| Increase Contrast | Focus rings and borders use the applied theme's contrast tokens. Component does not override or adapt further. |
| Differentiate Without Color | Selection is marked for assistive technology with `aria-current="true"`; the visual highlight is the selection accent colour (delegated to TopicRail), so the non-colour cue for sighted users is TopicRail's concern. |

