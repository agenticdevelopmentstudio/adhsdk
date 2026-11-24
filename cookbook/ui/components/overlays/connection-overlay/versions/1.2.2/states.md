
| State | Appearance change |
|-------|------------------|
| Hidden (active=false or delay not elapsed) | Component does not render (returns null) |
| Shown (active=true, delay elapsed, deploying) | Heading: "Backend deploying", subheading: deployment-specific text, spinner visible, countdown visible, no detail text |
| Shown (active=true, delay elapsed, unreachable) | Heading: "Backend unreachable", subheading: unreachable-specific text, spinner visible, countdown visible, detail text displayed (if provided) |
| Button focused | No custom focus style is defined in source (no `outline: none`, no `:focus` rule), so the browser's default focus ring applies — see visible-focus-indicator |

