
- **Decision**: Follow-tail is enabled by default (`followTail: true`).
  **Rationale**: Appropriate for real-time log inspection; consumers who want to preserve the user's scroll position can disable it.
  **Approved**: pending

- **Decision**: Scroll-to-bottom detection uses a 4-pixel slack (`const slack = 4`) instead of strict equality.
  **Rationale**: Accounts for rounding errors and sub-pixel rendering while balancing user intent (scrolled near the bottom) with responsiveness.
  **Approved**: pending

- **Decision**: The visible row set is memoized (`useMemo`) keyed on `[lines, maxLines]`.
  **Rationale**: Avoids recomputing the slice on every render; assumes `lines` and `maxLines` are the only factors affecting visibility.
  **Approved**: pending

- **Decision**: Level-based colors are applied through CSS variables with fallbacks rather than hard-coded color values.
  **Rationale**: Lets consumers override log-level colors at the stylesheet level without modifying the component.
  **Approved**: pending

- **Decision**: Cell tooltips use the native HTML `title` attribute rather than a custom tooltip element.
  **Rationale**: Relies on native browser tooltip behavior and requires no additional markup.
  **Approved**: pending

- **Decision**: The layout uses CSS Grid with ARIA roles (`row`, `columnheader`, `cell`) rather than native `<table>`/`<thead>`/`<tbody>` elements.
  **Rationale**: Lets CSS Grid handle layout while preserving accessibility roles for assistive technology.
  **Approved**: pending

- **Decision**: Click and double-click events are stopped at the cell (`stopPropagation()`) when a cell handler runs, rather than left to bubble.
  **Rationale**: Ensures the cell's own callback is the only handler invoked for that interaction.
  **Approved**: pending

- **Decision**: Undefined cell values are normalized to empty text (`{text: ''}`).
  **Rationale**: Ensures no rendering errors when a row is missing a value for a column.
  **Approved**: pending

