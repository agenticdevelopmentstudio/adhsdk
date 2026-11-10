
| Option | Behavior |
|--------|----------|
| Reduce Motion | The source declares no `transition-*`, `animate-*`, or duration class; the swap between `»` and `«` and the hover color change are instant re-renders. No transition is applied; nothing to disable under Reduce Motion. |
| Increase Contrast | The source pins the foreground to the `apt-text-muted` token, raises it to `apt-text` on hover, and draws the focus ring as `apt-gold/40`. It declares no high-contrast variant and no `prefers-contrast` query, so the contrast delivered is whatever those tokens resolve to in the active theme. Implementations MUST use the same tokens rather than substituting fixed color values, so a theme that raises contrast raises this control's contrast with it. |
| Differentiate Without Color | Color is never the sole carrier of state. Collapsed versus expanded is carried by the glyph shape (`»` versus `«`), by `aria-expanded`, and by the `aria-label`/`title` text, none of which depend on color. The one color-only change in the source is the `hover:text-apt-text` shift, which signals pointer position rather than component state. |

The component also inherits the platform's focus-visible behavior: the `focus-visible:ring-2` style paints only when the browser judges focus to be keyboard-driven.

