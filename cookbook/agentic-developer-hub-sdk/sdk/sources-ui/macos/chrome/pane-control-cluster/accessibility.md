
- **Role/trait**: Container with three buttons, each with button role
- **Accessibility IDs**: Close: "pane.close"; Minimize: "pane.minimize" (or "pane.restore" when minimized); Zoom: "pane.zoom"
- **Accessibility labels**: Close: "Close Pane"; Minimize: "Minimize Pane" or "Restore Pane"; Zoom: "Zoom Pane" or "Unzoom Pane"
- **Tooltips**: Identical to accessibility labels; displayed on hover
- **Glyph accessibility**: Each button's SF Symbol includes an accessibility description matching its label (e.g., "Close Pane" for the xmark)
- **State announcements**: Minimize button's label and glyph change reflect the state; screen readers announce the change on next access
- **Minimum target size**: macOS (pointer-based, `.accessoryBarAction` bezel): no fixed minimum is enforced; the button matches the compact sizing convention of system window controls. iOS (touch, per the UIKit port in Platform Notes): 44×44pt per Apple HIG.

