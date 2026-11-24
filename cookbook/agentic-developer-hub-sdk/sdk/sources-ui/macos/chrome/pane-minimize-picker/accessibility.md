
- **Role**: Each arrow button is a button control.
- **Label**: Each button's accessibility label is the edge's exact `PaneEdge.displayName` string (see table below) — for example, "Minimize to Top", not "Minimize top".
- **ID**: Each button has an accessibility ID in the format `pane.minimize.{edge.rawValue}` (see table below).
- **Tooltip**: Each button's tooltip matches the same `displayName` string.
- **Symbol description**: The SF Symbol's accessibility description also matches the same `displayName` string.
- **Button size**: On macOS, arrows use the AppKit `.accessoryBarAction` bezel style, which renders well under 44×44pt; that is expected for a pointer-driven accessory control and is not a tap-target defect. The 44×44pt (iOS) / 48×48dp (Android) minimum applies to the touch-platform implementations in Platform Notes, not to this macOS control.
- **Keyboard**: Standard `NSButton` keyboard focus and activation (Tab to move focus, Space/Return to activate) apply; the component adds no custom key handling beyond `NSPopover`'s default `.transient` dismissal (see Edge Cases).

### PaneEdge reference

| `PaneEdge` raw value | Display name (label / tooltip / symbol description) | Accessibility ID | SF Symbol |
|---|---|---|---|
| top | Minimize to Top | pane.minimize.top | arrow.up |
| leading | Minimize to Left | pane.minimize.leading | arrow.left |
| bottom | Minimize to Bottom | pane.minimize.bottom | arrow.down |
| trailing | Minimize to Right | pane.minimize.trailing | arrow.right |

