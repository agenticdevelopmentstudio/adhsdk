
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: component performs no animations. |
| Increase Contrast | Not supported: the component does not react to `prefers-contrast` or `forced-colors`; colors come from fixed theme tokens, and the token pairing is not verified against WCAG contrast ratios by this component. |
| Differentiate Without Color | Partial: an ancestor link and the current-page crumb are distinguished by semantics (link vs. plain text) and by hover-only color change; at rest, an unvisited link and the current crumb are not distinguished by anything but color. |

