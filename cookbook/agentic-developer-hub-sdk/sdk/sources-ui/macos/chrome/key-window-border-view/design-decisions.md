
- **Decision**: Inset the stroke path by 0.5 points on all sides.
  **Rationale**: A 1-point stroke is centered on its path, so half its width would fall outside `bounds` without the inset; insetting keeps the full stroke within the view. At 1x this also lands the stroke on a single pixel column rather than straddling two, avoiding blur — on Retina displays 0.5pt maps to a whole number of device pixels, so the pixel-alignment benefit is a 1x-specific side effect rather than the primary reason for the inset.
  **Approved**: pending

- **Decision**: Default `inactiveAlpha` to 0.28 and `activeAlpha` to 0.85.
  **Rationale**: The gap between the two is deliberate: the inactive line must read as the window's edge rather than a highlight, while the active line must be bright enough to clearly signal which window has focus. These defaults are calibrated for readability against both light and dark desktops.
  **Approved**: pending

- **Decision**: Implement click-through by overriding `hitTest(_:)` to always return `nil`, rather than hiding the view or intercepting events another way.
  **Rationale**: Returning `nil` from `hitTest(_:)` is the standard `NSView` mechanism for excluding a view from mouse-event dispatch — AppKit's hit-testing walks the view tree and skips any view whose `hitTest(_:)` returns `nil`, passing the event to the view underneath. This keeps the border purely decorative while every window beneath it remains fully interactive.
  **Approved**: pending

- **Decision**: Observe theme changes via `ThemePaletteObserver` rather than reading the accent color once at init.
  **Rationale**: Ties the border's color to the app's live theme so it updates immediately if the user or the app changes the accent color, instead of requiring the view to be recreated.
  **Approved**: pending

