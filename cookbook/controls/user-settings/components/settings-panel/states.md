
| State | Appearance change |
|-------|------------------|
| Default (row) | Transparent background, transparent border, inherited text color |
| Hover (row, enabled) | Background becomes `--aws-surface-hover`; the hover rule is more specific than the selected rule, so hovering the selected row also shows the hover background in place of the accent tint |
| Selected (row) | Background becomes `--aws-accent-dim`; icon turns to `--aws-accent`; `aria-selected` is true |
| Focused (row) | Keyboard focus shows a 2px solid `--aws-accent` outline with 1px offset (`focus-visible` only) |
| Disabled (row) | Opacity `0.5`, `not-allowed` cursor, no hover background, `disabled` attribute set |
| No selection | Detail area is empty (data-driven mode) or no Pane renders (compound mode); occurs only when no pane is enabled |
| Pressed | Not applicable: the stylesheet defines no active or pressed style for rows. |
| Loading | Not applicable: the panel renders synchronously from props and registrations and has no loading state. |

