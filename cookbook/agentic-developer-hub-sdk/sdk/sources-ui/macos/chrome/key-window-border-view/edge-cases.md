
- **Window move between windows**: If the view is moved from one window to another, observers for the old window are removed and re-registered for the new window. The stroke is redrawn to reflect the new window's key state. See **observer-cleanup**.
- **Nil window**: If `viewDidMoveToWindow()` is called and `window` is `nil` (view removed), all observers are cleaned up and no drawing occurs. See **observer-cleanup**.
- **Zero or negative corner radius**: The behavior is not explicitly constrained by the source; the underlying `NSBezierPath` method determines the rendering. A host that sets invalid radii accepts that consequence.
- **Alpha values outside [0, 1]**: Setting `inactiveAlpha` or `activeAlpha` to values outside the valid range does not raise an error; the `NSColor.withAlphaComponent(_:)` method handles or clips the value, and drawing proceeds.
- **Theme change during deallocating**: The `ThemePaletteObserver` is held by the view; when the view deallocates, the observer is released and no further theme updates are received.
- **Rapid key state toggles**: Each key-state notification calls `keyStateChanged()`, which sets `needsDisplay = true`. AppKit coalesces multiple `needsDisplay` requests made within the same run-loop pass into a single redraw before the next display cycle, so rapid toggles do not produce one draw call per notification.

