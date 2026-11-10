
- **Decision**: Ship `sectionLabelClass` as an exported string alongside the `SectionLabel` component.
  **Rationale**: Lets an element that can't be a `SectionLabel` (a `<legend>`, an existing div) still wear the exact treatment, keeping the look in one place.
  **Approved**: pending

- **Decision**: Keep three distinct heading treatments — `SectionLabel`, `fieldCaptionClass`, and `SectionHeader` — rather than one shared heading component.
  **Rationale**: The display micro-label is quieter (dimmer, smaller, wider-tracked) than a form caption, and it is a plain label rather than the gold page title. Keeping them separate prevents a one-size heading that fits none of the three roles.
  **Approved**: pending

- **Decision**: Build the common "label + one action opposite it" pane head into `SectionLabel` via a single `trailing` prop, rather than a separate row component.
  **Rationale**: This is the most common pane head, so building it in avoids forcing every caller to hand-roll a flex row.
  **Approved**: pending

- **Decision**: Render a `div` (or `span`), not a semantic heading element.
  **Rationale**: It is a display label, not an outline node; semantic headings are the caller's choice when the outline matters.
  **Approved**: pending

