
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not handled: the source contains no `prefers-reduced-motion` check, and the `Dialog`/`DialogContent` primitives it composes carry no open/close transition of their own in this file. |
| Increase Contrast | Depends on the `apt-*` design tokens (e.g. `apt-gold`, `apt-text-muted`, `apt-border`); the component itself does no `prefers-contrast` handling. |
| Differentiate Without Color | A selected row's `aria-selected` and a forbidden row's `aria-disabled`/`opacity-40` are both readable independent of color; the chevron's direction (right = collapsed, down = expanded) also carries state without relying on color. |

