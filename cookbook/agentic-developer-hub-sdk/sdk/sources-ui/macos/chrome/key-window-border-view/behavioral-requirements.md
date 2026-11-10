
- **stroke-border**: Component MUST draw a 1-point stroked rounded rectangle aligned to the window's edge.
- **half-point-inset**: Component MUST inset the path by 0.5 points horizontally and vertically so the 1-point stroke lies fully inside `bounds`, which on a 1x display also aligns the stroke to the pixel grid.
- **accent-stroke-color**: Component MUST use the theme's accent color as the stroke color.
- **inactive-alpha**: Component MUST apply `inactiveAlpha` opacity to the stroke when the window is not key.
- **active-alpha**: Component MUST apply `activeAlpha` opacity to the stroke when the window is key.
- **click-through**: Component MUST return `nil` from `hitTest(_:)` and not intercept mouse events.
- **key-state-redraw**: Component MUST observe window key state notifications and redraw when key state changes.
- **initial-key-state**: Component MUST read the window's current key state when it first moves to a window and draw accordingly, without waiting for a subsequent key-state notification.
- **corner-radius-customization**: Component MUST allow the corner radius to be customized via the public `cornerRadius` property.
- **alpha-customization**: Component MUST allow the inactive and active alpha values to be customized via the public `inactiveAlpha` and `activeAlpha` properties.
- **redraw-on-property-change**: Component MUST mark itself for redisplay when `cornerRadius`, `inactiveAlpha`, or `activeAlpha` properties are modified.
- **theme-color-update**: Component MUST observe theme palette changes and update the accent color when the theme changes.
- **observer-cleanup**: Component MUST remove all observers from the notification center when deallocated or moved to a window.
- **main-actor-isolation**: Component MUST be annotated as `@MainActor` to ensure all drawing and observation occur on the main thread.

