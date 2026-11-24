
- **React/Web**: `SendIcon.tsx` in `packages/web/packages/chat/src/components/` renders a 20×20 SVG with `fill="none"`, `stroke="currentColor"`, and `strokeWidth="2"`. The `<line>` and `<polygon>` geometry follows `#appearance/geometry`. No props or state management.

- **SwiftUI**: Implement using `Image(systemName: "paperplane")` — the outline variant, matching the stroke-only design, not `paperplane.fill`. Size it with `.font(.system(size: 20))` or an explicit `.frame(width: 20, height: 20)`, and tint it with `.foregroundStyle(.primary)` (not the deprecated `.foregroundColor`) to inherit the surrounding text color like `currentColor`.

- **Compose**: Draw the geometry from `#appearance/geometry` inside a `Canvas` composable using `drawPath`, styled with `Stroke(width = 2.dp, cap = StrokeCap.Round, join = StrokeJoin.Round)`. Use `LocalContentColor.current` directly as the stroke color — there is no `Color.currentColor` analog — so the icon inherits the surrounding content color. Wrap it in `Box(modifier = Modifier.size(20.dp))` to fix the icon's size to match the web dimensions.

- **AppKit / UIKit**: Implement as a custom `UIView` subclass (`NSView` on AppKit) that draws the `#appearance/geometry` path with `UIBezierPath` / `NSBezierPath`. On UIKit, set the stroke color from `tintColor` so the icon inherits the surrounding tint; on AppKit, set it explicitly from `contentTintColor` (`UIColor.label` / its AppKit equivalents do not pick up the parent's tint). Render at a fixed 20×20 point size to match the web dimensions.

- **WinUI 3**: Implement as a single `<Path>` in XAML with path-markup `Data="M22,2 L11,13 M22,2 L15,22 L11,13 L2,9 Z"` (`<Line>`/`<Polygon>` elements are not valid inside `<Path.Data>`), `StrokeThickness="2"`, `StrokeStartLineCap="Round"`, `StrokeEndLineCap="Round"`, and `StrokeLineJoin="Round"`. Bind `Stroke="{Binding Foreground, RelativeSource={RelativeSource TemplatedParent}}"` instead of a hard-coded brush like `SystemBaseHighBrush`, so the icon inherits the parent's `Foreground`. Set `Width="20"` and `Height="20"` with `Stretch="Uniform"` to preserve the aspect ratio.

