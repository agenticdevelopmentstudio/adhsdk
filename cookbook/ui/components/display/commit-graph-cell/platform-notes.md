
- **SwiftUI**: A `Canvas` drawing the same segments, sized by `row.width × columnWidth`.
- **Compose**: A `Canvas` composable with the same geometry.
- **React/Web**: An inline SVG per row, or one canvas for the visible rows.
- **AppKit / UIKit**: AppKit: an `NSView` drawing with `NSBezierPath` in `draw(_:)`. UIKit: a `UIView` with the same drawing.
- **WinUI 3**: A `Canvas` of `Line` and `Ellipse` shapes, or Win2D for long lists.

