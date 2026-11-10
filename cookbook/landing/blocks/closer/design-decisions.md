
- **h2 as title element**

  **Decision**: The component always renders the title within an h2 heading and does not expose a heading-level parameter.
  **Rationale**: Provides semantic structure and establishes a consistent position in the screen reader outline; the component assumes it is always a section-level conclusion.
  **Approved**: pending

- **className merge strategy**

  **Decision**: The className prop is merged with the base class via `[base, className].filter(Boolean).join(' ')`, with `lp-closer` always placed first.
  **Rationale**: `.filter(Boolean)` drops falsy values so an empty or undefined `className` produces no leading, trailing, or doubled whitespace, letting callers pass conditional class names without manual trimming. `lp-closer` is placed first only to produce a deterministic, testable className string — class order in the attribute has no effect on CSS specificity.
  **Approved**: pending

- **No default styling within the component**

  **Decision**: The Closer component applies no inline styles. All visual styling, including centering, spacing, and the border, is delegated to the `lp-closer` CSS class.
  **Rationale**: Allows consumers to fully control appearance via CSS and avoids inline/CSS style conflicts.
  **Approved**: pending

- **ReactNode flexibility**

  **Decision**: Both `title` and `children` accept ReactNode and are passed through without transformation or cloning.
  **Rationale**: Supports rich content (not just strings) and enables complex compositions in parent layouts.
  **Approved**: pending

