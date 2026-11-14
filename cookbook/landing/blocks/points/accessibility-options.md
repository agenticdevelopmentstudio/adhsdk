
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: Points is a static list with no animations or transitions. |
| Increase Contrast | Delegated to CSS; the component sets no inline color, and colors come from host-supplied tokens in `blocks.css` (`--lp-ink-dim`, `--lp-ink`, `--lp-accent`). Parent styles SHOULD ensure sufficient contrast (see [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa)). |
| Differentiate Without Color | Delegated to CSS; the component does not rely on color to distinguish content. The term is marked with bold weight (`<b>` element) and distinct in layout. |

