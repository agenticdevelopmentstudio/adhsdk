
- **Decision**: Fixed height of 22pt.
  **Rationale**: Sized to match the visual weight of this toolkit's own macOS tab bar height so a window using both elements does not read as bottom-heavy; this is an internal consistency choice for the toolkit's chrome components, not a cited platform guideline.
  **Approved**: pending

- **Decision**: Truncate the status string by the middle rather than the end.
  **Rationale**: Status strings are typically paths or identifiers where the end (filename or key identifier) is more important than the beginning (directory structure); middle truncation preserves both ends, maximizing recognizability when the text is clipped.
  **Approved**: pending

- **Decision**: Require an accessibility prefix string at initialization rather than defaulting one.
  **Rationale**: The bar is meant to sit under more than one kind of window; requiring a prefix keeps accessibility identifiers unique per window type and avoids a UI test addressing "the footer" ambiguously matching whichever instance came first.
  **Approved**: pending

- **Decision**: 10pt leading/trailing margins with an 8pt minimum inter-element gap.
  **Rationale**: An internal consistency choice for this toolkit's chrome components rather than a cited platform guideline; the 8pt gap keeps breathing room between the status text and accessories without wasting space.
  **Approved**: pending

- **Decision**: Expose trailing accessories as a settable array property rather than a slot builder/closure.
  **Rationale**: A fixed array is simpler for callers to manage than a closure; removal and replacement are explicit and obvious, reducing layout surprises.
  **Approved**: pending

