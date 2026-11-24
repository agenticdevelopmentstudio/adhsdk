
- **Decision**: Keep the Combobox (autocomplete) and EntityChooser (browse/create) as two separate controls rather than one combined control.
  **Rationale**: They answer different user questions — autocomplete serves someone who already knows the label's name, while the chooser serves someone browsing. Separating them avoids the cognitive load of a mode switch inside one input, and lets the chooser offer creation without conflating "I typed something new" with "I want to create it."
  **Approved**: pending

- **Decision**: Do not create a new label on Enter in the Combobox; require the exact-match acceptance path or the EntityChooser's `allowCreate` row.
  **Rationale**: The source checks for an exact match against `options` before adding anything (see **accept-exact-match-in-combobox**, **no-create-on-enter**). Typing a label name that is not yet in the vocabulary and pressing Enter does not create it — minting a label is the chooser's explicit `allowCreate` action. This avoids accidentally creating labels from typos and keeps creation intent explicit.
  **Approved**: pending

- **Decision**: Render the chips as a sibling row below the control row, not nested inside the EntityChooser's column.
  **Rationale**: Nesting caused layout wrap and misalignment with other form controls (e.g. CategoryField): "No tags yet" text took the first line and pushed the trigger to a second line, 56px below the trigger it should align with, and adding a single tag re-broke the alignment the same way. A full-width row of its own spans the width the chips actually need and leaves the right column exactly one trigger wide in every state.
  **Approved**: pending

- **Decision**: Treat the `options` list as a suggestion list, not a closed set.
  **Rationale**: Items in `value` may exist outside `options` because labels are created by the EntityChooser or by other surfaces in the application (see **options-as-suggestion**). This keeps tag management consistent across the application without requiring this component to sync or reload the vocabulary.
  **Approved**: pending

- **Decision**: Build all microcopy from a singular, lowercase `noun` prop instead of hardcoding "tag".
  **Rationale**: Lets the component be reused for other entity types (e.g. "label", "keyword", "category") without code changes, keeping the interaction pattern uniform across features that manage tagged entities (see **noun-in-placeholders**).
  **Approved**: pending

- **Decision**: Preserve the `value` array's order exactly as the parent provides it — no sorting or canonical reordering.
  **Rationale**: Lets the parent control tag order (e.g. by insertion time, custom ranking, or an external system) (see **maintain-value-order**).
  **Approved**: pending

