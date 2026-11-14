
| Option | Behavior |
|--------|----------|
| Reduce Motion | The lens sweep does not run when `prefers-reduced-motion: reduce` matches (the lens default). The `transition: color 0.3s` on hover is not gated by a reduced-motion rule in `flow.css`. |
| Increase Contrast | Not applicable: `flow.css` has no `prefers-contrast` rule for the nav. |
| Differentiate Without Color | Not applicable: links are told apart by position and separators, and the hover and focus states change colour plus a focus outline on `:focus-visible`. |

