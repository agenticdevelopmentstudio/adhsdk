
- **Semantic structure**: The component uses an h2 heading element for the title, providing proper document outline hierarchy.
- **Title labeling**: The title prop establishes context for the section. Screen readers announce the h2 and its content as a heading.
- **Content containment**: Child content is rendered in the same `<div>` as the title. The root is a plain `<div>` with no role, landmark or accessible name, so assistive technology does not expose it as a section; the h2 is the only structural cue.
- **Keyboard navigation**: Not applicable — the component is non-interactive. Keyboard focus may enter child elements if they are interactive.

