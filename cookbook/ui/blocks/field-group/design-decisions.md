
- **Decision**: The title reuses `fieldCaptionClass` (the same treatment as `Field`
  captions) inside an `<h3>`.
  **Rationale**: Group titles and field captions read as one caption language, and
  the heading gives the section real document-outline structure for AT.
  **Approved**: pending

- **Decision**: `trailing` is a single right-aligned slot rather than a fixed
  actions API.
  **Rationale**: Keeps the group a generic wrapper (status, a button, or a badge)
  and optimizes-for-change by not baking a specific accessory contract into the
  group.
  **Approved**: pending

- **Decision**: The group owns no form state.
  **Rationale**: It stays a pure layout composition over `Field`; value and
  validation policy live in the owning form, keeping the group reusable across
  every settings pane.
  **Approved**: pending

- **Decision**: Recessed `apt-surface-2/40` card on `apt-border`.
  **Rationale**: The group reads as a contained section against the pane
  background without a heavy border or any color literal.
  **Approved**: pending

- **Decision**: The `<h3>` title heading level is fixed rather than exposed as a
  `headingLevel` prop; the group assumes it is placed under an `<h2>`-level pane
  heading.
  **Rationale**: Every current caller nests `FieldGroup` inside a settings/editor
  pane whose own heading is `<h2>`, so a fixed `<h3>` keeps the document outline
  correct without adding an API surface no caller needs yet.
  **Approved**: pending

