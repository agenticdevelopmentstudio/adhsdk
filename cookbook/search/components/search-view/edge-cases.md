
- **Empty query, no facets**: No fetch occurs; a prompt ("Search research documents…") is shown. This remains until the user enters a query or selects a facet.
- **Query with no results and no error**: A "No matching documents" message is displayed. If facets are active, a hint "Try a different search or remove filters" appears; if no facets, only "Try a different search."
- **Fetch error with no cached results**: A full error block (centered, min-height 160px) displays the error message and a Retry button. The view is blocked; no partial results are shown.
- **Fetch error while results are cached**: A compact error strip appears above the cached result list. The list remains visible and scrollable. The user can browse cached results or click Retry to re-fetch.
- **Result set shrinks mid-navigation**: If the active index exceeds the new item count, it is clamped to `Math.min(activeIndex, itemCount - 1)` to prevent out-of-bounds access.
- **Selecting an already-selected result**: If the preview is already disclosed and the same result is selected again, focus moves into the preview without re-opening it. If the preview is collapsed, selecting the same result opens it (discloses) and moves focus (see **reselect-focuses-without-reopening**).
- **Pressing Escape with no selection**: Escape in the list has no effect if no result is selected (no preview is open) (see **escape-noop-without-selection**).
- **Chip removal**: Clicking a chip's remove button clears only that facet (category or tag), not others. The query persists; only the facet is cleared.
- **Multiple facet filters active**: Both category and tag can be active simultaneously. Each has its own removable chip. "Clear filters" clears both.
- **Filtering with no results**: The chips remain visible (as feedback that filters are active), and the "No matching documents" message is shown. The user can remove filters via the chips or the "Clear filters" button.

