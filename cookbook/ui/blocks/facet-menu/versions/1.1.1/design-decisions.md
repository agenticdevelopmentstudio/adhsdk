
- **Decision**: The count displayed in the trigger (e.g., "Category (3)") is shown whenever one or more values are selected, not hidden by default.
  **Rationale**: Operators rely on this count to verify that filters are active without opening the popover; a hidden count risks acting on a filtered set as though it were the full list — for example, deleting the "wrong" rows when a filter is invisibly active.
  **Approved**: pending

- **Decision**: Both "All" and "None" quick-select buttons are kept, even though selecting every option and clearing the selection show the same filtered rows.
  **Rationale**: They serve different interaction purposes: "All" is the starting point for excluding a single option ("everything except this"), which requires the boxes to actually be checked to represent that intent; "None" is the way back to no active filter. The trigger's count (N vs. 0) makes the two states visibly distinct.
  **Approved**: pending

- **Decision**: Checkboxes do not carry an individual `aria-label`; each is wrapped in a `<label>` element with text content, and the base checkbox component points `aria-labelledby` at that wrapping label.
  **Rationale**: Adding an `aria-label` on top of the `<label>`/`aria-labelledby` association would make the computed accessible name announce the option text twice.
  **Approved**: pending

- **Decision**: The option list is constrained to a maximum height (16rem / 256px) with vertical scrolling enabled; horizontal scrolling is not enabled.
  **Rationale**: This keeps the popover from exceeding the visible viewport on small screens and keeps the behavior consistent across platforms; long labels are expected to wrap or be truncated by the host container instead.
  **Approved**: pending

- **Decision**: FacetMenu is implemented and documented as a popover that stays open across multiple selections, not as a native auto-dismissing menu.
  **Rationale**: A native menu (SwiftUI `Menu`, `NSMenu`/`UIMenu`, a dismiss-on-pick WinUI `MenuFlyout`) closes after each item is picked, which breaks the multi-select toggle interaction the component depends on.
  **Approved**: pending

- **Decision**: "All" replaces the selection with exactly the current `options`, and "None" replaces it with an empty set — both drop any stale selected values not present in `options`.
  **Rationale**: The component only ever sets `selected` to values it can see; a value that came from a since-filtered-out option has no representation in the current option list, so neither quick-select action can special-case it.
  **Approved**: pending

