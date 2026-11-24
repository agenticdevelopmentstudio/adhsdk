
- **Decision**: Use `NSGridView` rather than nested `NSStackView` to construct the cross layout.
  **Rationale**: The grid layout structurally conveys the cross shape — a user sees four directions around a center — which improves code clarity and maintainability (`simplicity`, `explicit-over-implicit`).
  **Approved**: pending

- **Decision**: Keep `PaneMinimizeCrossView` (the cross buttons) separate from `PaneMinimizePicker` (the popover wrapper).
  **Rationale**: This separation allows tests to verify button state without opening a popover (`tight-feedback-loops`).
  **Approved**: pending

- **Decision**: `button(for:)` raises `fatalError` rather than returning `nil` when a button cannot be found for an edge.
  **Rationale**: Buttons for all four edges are always created in `init` and stored in a `[PaneEdge: NSButton]` dictionary, so a `nil` return cannot be safely handled by any caller; fast failure is the correct semantics (`fail-fast`).
  **Approved**: pending

- **Decision**: Close the popover before invoking onPick.
  **Rationale**: The pane is about to change shape, and a popover anchored to a button inside it would be left pointing at a view that has moved.
  **Approved**: pending

- **Decision**: Update button tint color reactively via `observeTheme` whenever the theme changes.
  **Rationale**: Ensures the picker respects user theme preferences without requiring an explicit refresh call.
  **Approved**: pending

