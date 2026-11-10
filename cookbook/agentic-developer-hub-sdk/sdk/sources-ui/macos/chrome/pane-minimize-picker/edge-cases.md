
- **Empty available edges set**: If availableEdges is empty, all four buttons are disabled. User cannot select any edge, and onPick is not invoked if a disabled button is tapped. The popover remains open.
- **All edges available**: If availableEdges contains all four edges, all buttons are enabled. User can select any direction.
- **Availability change while popover is shown**: If availableEdges is updated while the popover is displayed, button states update immediately without closing the popover.
- **Button not found**: The component creates one button per `PaneEdge` case in `init`, so every edge always has a button. If that invariant were ever violated, the component fails fast instead of returning an unhandleable `nil` (see the AppKit platform note for the reference mechanism).
- **Disabled button interaction**: Tapping a disabled arrow button has no effect (platform buttons ignore taps when disabled).
- **Dismissal without selection**: The popover uses AppKit's `.transient` behavior, so it also closes on click-outside or Escape without a selection; onPick is wired only to the button-tap handler, so these dismissal paths never invoke it.
- **Right-to-left layout**: The cross's grid columns are fixed by ordinal position (leading's button is always in the left column, trailing's in the right column), and each edge's SF Symbol (`arrow.left` / `arrow.right`) is hardcoded rather than mirrored. In RTL locales the leading/trailing arrows do not swap sides or direction the way a mirrored layout would.

