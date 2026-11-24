
| State | Appearance change |
|-------|------------------|
| Default | Circle with a 1px theme border, opaque face, theme text color, no shadow. |
| Hover | Border becomes the current text color and a 6px glow at 45% appears, over 0.18s. |
| Focused | Keyboard focus (`:focus-visible`) gets the same border and glow as hover; the default outline is removed, so the border and glow are the only focus indication. |
| Pressed | Not applicable: the stylesheet defines no `:active` rule, so a press looks like hover or focus. |
| Disabled | Not applicable: the component renders a link with no disabled prop or disabled style. |
| Loading | Not applicable: the component fetches nothing and has no async work. |

