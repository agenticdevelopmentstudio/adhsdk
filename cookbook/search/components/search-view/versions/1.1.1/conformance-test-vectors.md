
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| search-view-001 | no-auto-fetch | Component mounted with empty query and no facet filters | No fetch occurs; EmptyState prompt is displayed |
| search-view-002 | debounce-search | User types in the search field | Fetch is debounced by the `debounceMs` prop (default 250ms) before firing |
| search-view-003 | fetch-on-enter | User types "foo" and presses Enter | Fetch fires immediately, flushing any pending debounce |
| search-view-004 | render-loading-skeleton | A query becomes active | 3 skeleton placeholder bars render with `aria-busy="true"` |
| search-view-005 | render-result-count | Results settle (no error) | A live result count appears above the list (e.g. "3 results") |
| search-view-006 | support-roving-focus | Focus is in the result list; user presses ArrowDown | Focus moves to the next row; active index increments |
| search-view-007 | support-roving-focus | Focus is on the last row; user presses ArrowDown | Focus stays on the last row; active index does not change |
| search-view-008 | support-roving-focus | Focus is in the list; user presses Home | Focus moves to the first row; active index resets to 0 |
| search-view-009 | support-roving-focus | Focus is in the list; user presses End | Focus moves to the last row; active index equals item count − 1 |
| search-view-010 | render-zero-results | A query settles with 0 results and no error | "No matching documents" message displays; Retry does not appear |
| search-view-011 | render-hard-error | A fetch error occurs with no cached results | Full error block (min-height 160px) with error message and Retry button displays |
| search-view-012 | render-stale-error | A fetch error occurs while results are cached | Compact error strip appears above the list; Retry button is present |
| search-view-013 | render-filter-chips | A category filter is active | A removable chip displays the category name; a "Clear filters" button appears |
| search-view-014 | render-filter-chips | A tag filter is active | A removable chip displays the tag name; a "Clear filters" button appears |
| search-view-015 | clear-facets-only | "Clear filters" button is clicked | Category and tag filters are cleared; the query string is NOT cleared |
| search-view-016 | manage-preview-disclosure | A result is selected | The preview dock discloses (expands); the preview content region receives focus |
| search-view-017 | handle-escape-in-preview | Row 2 is reached via ArrowDown (active index = 2) and selected via Enter, opening its preview; focus moves into the preview content region; Escape is pressed | The dock collapses, the selection clears, and focus returns to row 2 — the roving-focus cursor (active index), which in this keyboard-driven scenario is also the row that opened the preview |
| search-view-018 | focus-preview-on-select | A result is selected via click/Enter | The preview content `<div>` (tabIndex={-1}) receives programmatic focus |
| search-view-019 | render-split-divider | The preview dock is disclosed | A SplitDivider appears above the dock; it is draggable and keyboard-operable |
| search-view-020 | render-split-divider | The preview dock is collapsed | No SplitDivider is rendered |
| search-view-021 | support-url-sync | `urlSync` is true (default) and filters change | `q`, `tag`, and `category` are written to the URL query string |
| search-view-022 | support-url-sync | Browser back/forward buttons are used | Filter state re-syncs from the URL; results view updates |
| search-view-023 | label-result-list | Component renders the result list | The `<ul>` has `aria-label="Search results"` |
| search-view-024 | announce-result-count | Results settle and the count changes | The count element has `role="status"` and `aria-live="polite"` |
| search-view-025 | accept-optional-props | Component is mounted without `searchPlaceholder` prop | The search input uses the default placeholder "Search…" |
| search-view-026 | accept-optional-props | Component is mounted with `debounceMs={500}` | Search debounce uses 500ms instead of the default 250ms |
| search-view-027 | clamp-cursor-on-resize | Results are requeried and the set shrinks; active index was 5 but only 2 results remain | Active index is clamped to 1 (item count − 1) |
| search-view-028 | handle-escape-in-list | Focus is in the result list; a result is selected; Escape is pressed | The preview dock collapses, the selection clears; focus stays in the list (does not move) |
| search-view-029 | no-unrelated-refocus | The preview is already disclosed for a selected hit; the collapse toggle collapses and then re-expands it without a new selection | Focus does not move into the preview content region on the re-expand |
| search-view-030 | label-search-region | Component mounts with default props | The search and filter bar sit inside a `role="search"` landmark labelled "Document search" |
| search-view-031 | label-search-input | Component mounts with default props | The search input has the accessible label "Search documents" |
| search-view-032 | label-preview-region | Component mounts and a query is active | The preview dock `<section>` has `aria-label="Document preview"` |
| search-view-033 | label-preview-region | The preview dock is disclosed | The preview content region has `aria-label="Document preview content"` |
| search-view-034 | render-preview-title-collapsed | The dock is collapsed and no hit is selected | The header bar shows "Preview" |
| search-view-035 | render-preview-title-collapsed | The dock is collapsed and a hit is selected | The header bar shows the selected hit's title |
| search-view-036 | render-preview-metadata-disclosed | The dock is disclosed and a hit is selected | The type's `PreviewHeader` metadata renders in the header region |
| search-view-037 | render-preview-metadata-disclosed | The dock is disclosed and no hit is selected | The header renders nothing; the body's EmptyState is the sole "Select a result to preview it." text |
| search-view-038 | handle-escape-in-preview | Row 2 is reached via ArrowDown (active index = 2) and selected via Enter, opening its preview; focus moves to the collapse toggle inside the disclosed dock; Escape is pressed | The dock collapses, the selection clears, and focus returns to row 2 — the roving-focus cursor (active index), which in this keyboard-driven scenario is also the row that opened the preview |
| search-view-039 | render-filter-chips | Both a category and a tag filter are active; the category chip's remove button is clicked | Only the category filter clears; the tag chip and its filter remain |
| search-view-040 | reselect-focuses-without-reopening | The preview is already disclosed for a hit; the same hit is selected again | Focus moves into the preview content region; disclosure and selection state do not change |
| search-view-041 | escape-noop-without-selection | Focus is in the result list; no result is selected; Escape is pressed | Nothing changes; focus remains in the list |
| search-view-042 | handle-escape-in-preview | The roving-focus cursor is on row 0 (active index = 0, reached via keyboard earlier); the user then clicks row 3, selecting it and opening its preview (a click does not update active index); focus is in the preview content region; Escape is pressed | The dock collapses and the selection clears, but focus returns to row 0 (the active index), not row 3 that opened the preview |

