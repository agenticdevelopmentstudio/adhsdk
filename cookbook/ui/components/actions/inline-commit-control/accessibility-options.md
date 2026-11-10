
| Option | Behavior |
|---|---|
| Reduce Motion | Not honored: the idle-trash reveal is the control's own `transition-opacity` on its `Button` classes (not something `Button` itself handles), and it carries no `motion-reduce:` variant, so the fade plays regardless of the system preference. |
| Increase Contrast | Not handled directly: foreground/background pairs come from `apt-gold` / `apt-text-muted` / destructive-red design tokens; any high-contrast adaptation is whatever those tokens resolve to, not logic in this control. |
| Differentiate Without Color | Handled: the armed state is also carried by icon shape (trash vs. ✓/✕) and `aria-pressed`, and armed-delete content is also struck through, not color-coded alone. |

