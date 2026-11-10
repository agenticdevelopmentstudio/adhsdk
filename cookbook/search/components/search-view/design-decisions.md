
- **Decision**: Track `activeIndex` (the roving-focus cursor) separately from `selectedId` (the previewed row).
  **Rationale**: This lets keyboard navigation move focus independently of the preview, preventing arrow keys from forcing a preview open on every keystroke. Only Enter/Space on the focused row, or an explicit selection, opens the preview.
  **Approved**: pending

- **Decision**: Escape collapses the preview dock AND deselects the hit — both list Escape (**handle-escape-in-list**) and preview Escape (**handle-escape-in-preview**) call the same `clearSelection`, which sets `selectedId` to `null` as well as collapsing the dock.
  **Rationale**: Escape is a single "back out of what I opened" action; there is no code path that collapses the dock while leaving a hit selected, so re-expanding via the collapse toggle afterward shows the no-selection empty state, not the hit. A consumer that wants the selection preserved across Escape needs to layer that behavior on top — it is not what the shipped component does.
  **Approved**: pending

- **Decision**: "Clear filters" clears the active facets (category, tag) only, never the query.
  **Rationale**: A query the user typed should not be erased when they remove a facet; this preserves intent and allows quick filter refinement.
  **Approved**: pending

- **Decision**: No fetch occurs until a query or facet filter is present; a prompt is shown instead.
  **Rationale**: Avoids an expensive initial fetch of an empty-scoped corpus and improves perceived performance on page load.
  **Approved**: pending

- **Decision**: Debounce search input (default 250ms) but let Enter commit immediately.
  **Rationale**: Debouncing avoids hammering the server while typing; Enter lets the user force a search sooner if the debounce feels slow. This balances responsiveness with backend load.
  **Approved**: pending

- **Decision**: `urlSync` defaults to `true`.
  **Rationale**: Shareability is a primary use case for search results — users expect to copy a results URL and share it. Disabling sync requires explicit opt-out.
  **Approved**: pending

- **Decision**: Preview disclosure is independent of selection; the dock can be collapsed while a hit stays selected.
  **Rationale**: Lets the user keep the same result selected but hide its preview temporarily (e.g., to focus on the list); re-expanding the dock re-shows the preview without re-selection.
  **Approved**: pending

- **Decision**: Chips persist on empty results.
  **Rationale**: Chips remain visible even when results are empty after filtering, giving feedback that filters are active and guiding the user to remove them. A second, separately-labelled "Clear filters" control in the empty state would be redundant with the chips already shown.
  **Approved**: pending

- **Decision**: Roving tabindex is scoped to the result list only; buttons and the collapse toggle outside the list remain standard Tab stops.
  **Rationale**: Keeps focus management simple and aligns with ARIA authoring practices for listbox-like widgets.
  **Approved**: pending

- **Decision**: Focus movement into the preview is gated by an internal one-shot flag armed only on an explicit user selection.
  **Rationale**: Prevents focus from moving on unrelated re-renders (e.g., a header toggle without a selection change), avoiding disorienting focus jumps.
  **Approved**: pending

- **Decision**: The SplitDivider renders only while the preview dock is disclosed.
  **Rationale**: When collapsed there is nothing to resize (the dock is its natural header height); omitting the divider when it would be non-functional reduces visual clutter.
  **Approved**: pending

