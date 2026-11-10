
- **Decision**: The `<ul>` element for a group is rendered only when `items.length > 0`.
  **Rationale**: An empty `<ul>` is invisible on screen but still carries the list's CSS spacing, so it would read as a layout bug rather than absent content.
  **Approved**: pending

- **Decision**: The "coming soon" state is carried by the boolean `soon` field on `ChecklistItem`, not by a phrase embedded in `text`.
  **Rationale**: A structural field lets the component apply one consistent visual treatment via a CSS class without duplicating the concept as text in multiple places. Per the source comment: "The distinction has to be structural, which is why it is a field here and not a phrase in `text`."
  **Approved**: pending

- **Decision**: `heading` and `text` accept `ReactNode`, not just strings.
  **Rationale**: This allows rich content (nested elements, conditionals, fragments) without changing the component; the parent is responsible for the accessibility of any complex content it supplies.
  **Approved**: pending

- **Decision**: The array index is used as the React key for both groups (`key={i}`) and items (`key={j}`).
  **Rationale**: This is appropriate for stable lists that are not reordered, filtered, or have items inserted; see **stable-group-order** for the resulting constraint on callers.
  **Approved**: pending

