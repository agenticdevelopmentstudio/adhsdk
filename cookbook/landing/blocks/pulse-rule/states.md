
The rule is inert: it has no pressed, disabled, focused or loading state, and no prop or event changes its appearance.

| State | Appearance change |
|-------|------------------|
| Default | Breathing: opacity cycles between the floor (0.35 by default) and 1 over the period (6s by default) |
| Reduced motion | At rest at opacity 1, no animation (`prefers-reduced-motion: reduce`) |
| Pressed | Not applicable: the rule is not interactive and has no pressed state |
| Disabled | Not applicable: the rule is not a control and has no disabled state |
| Focused | Not applicable: an `<hr>` is not focusable and the source adds no `tabIndex` |
| Loading | Not applicable: the rule does no asynchronous work |

