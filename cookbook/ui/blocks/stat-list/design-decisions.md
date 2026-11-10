
- **Decision**: split into `StatList` (wrapper) + `StatListRow` (row) rather than one
  data-driven component.
  **Rationale**: the two real call sites differ only in the
  trailing content (a bold duration vs a count + deep link); a `trailing` slot keeps
  the row declarative for the common part while letting each site own its tail without
  a config explosion.
  **Approved**: pending
- **Decision**: the dot is always decorative (no aria label).
  **Rationale**: the row's
  visible label + trailing already convey the item; labeling the dot too would make a
  screen reader announce the status twice — the same a11y trap StatusDot's own
  unlabeled-is-decorative ([adhsdk.ingredient.ui.components.display.status-dot](cookbook:1a044d34-d585-46b4-b703-dea3fb9b9642))
  requirement addresses.
  **Approved**: pending
- **Decision**: `divided` is a boolean, not a caller-supplied className.
  **Rationale**:
  both sites use the identical top-border-and-padding treatment when the
  list sits under card content; a named flag keeps that one decision in the block.
  **Approved**: pending
- **Decision**: `as` picks the element (`ul`/`li` vs `div`).
  **Rationale**: a monitor's
  down sites ARE a semantic list, while a card's freeform tail may not be; the block
  supports both without forcing list semantics where they don't fit.
  **Approved**: pending

