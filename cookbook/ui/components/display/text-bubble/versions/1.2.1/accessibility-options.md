
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not detected by the component itself; hosts MAY gate `active` off when `prefers-reduced-motion: reduce` is set (see the reduced-motion **Design Decision**). |
| Increase Contrast | Not applicable — glyph colours come from the caller (`colorFrom`/`colorTo`) or default to `currentColor`; the component introduces no colours of its own to adjust. |
| Differentiate Without Color | Not applicable — the colour shift is decorative only and conveys no information that would need a non-colour alternative. |

