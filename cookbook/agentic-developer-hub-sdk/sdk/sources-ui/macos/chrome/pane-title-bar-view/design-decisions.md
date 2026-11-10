
- **Decision**: The title truncates in the middle rather than at the trailing edge.
  **Rationale**: File names keep their extension and distinguishing suffix visible when the middle is elided instead of the end — "VeryLong…extension" still identifies the file, where "VeryLongFile…" would not. (The gear's trailing position is held by its own layout constraints, not by the title's truncation mode.)
  **Approved**: pending

- **Decision**: The bar has a fixed height of 26pt.
  **Rationale**: 26pt accommodates a 13pt label and a small square button while keeping chrome minimal, so a three-pane editor does not spend a quarter of its height on chrome — a deliberate trade-off between readability and usable content area.
  **Approved**: pending

- **Decision**: `yieldWidthToContainer()` is opt-in; it is not called by default.
  **Rationale**: The default respects the intrinsic width needs of the title and controls. A container that divides width among panes (e.g., a split view) calls it explicitly to override that preference for constrained layouts; the switch is one-way because restoring would mean remembering a per-view priority for a case that never happens.
  **Approved**: pending

- **Decision**: Reassigning `accessoryViews` removes all old views from the view tree before adding the new ones.
  **Rationale**: This atomic replacement prevents old and new views from briefly coexisting, keeping layout consistent and predictable.
  **Approved**: pending

- **Decision**: The title label's tooltip is kept in sync with the title text.
  **Rationale**: When the title truncates, hovering reveals the full text — a standard AppKit pattern that avoids separate UI for displaying the complete title.
  **Approved**: pending

