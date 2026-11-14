---
id: fed0a111-253c-427b-89c0-14f729657a7d
title: "SearchView"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A document search interface combining query input, facet filters, result listing with keyboard navigation, and a collapsible preview dock."
platforms:
  - typescript
  - web
tags:
  - search
  - document-search
  - result-listing
  - keyboard-navigation
depends-on:
  - 2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
  - f09feb7c-6778-445a-8a68-863c5d60b5cc
  - e86eb195-1ec2-4b12-8a24-79f8c03f65ce
  - c57b1aed-ef38-4803-b38a-2d7e0aeced5f
  - 240f8d48-45af-49ea-aebf-95d756d74707
related: []
references: []
approved-by: ""
approved-date: ""
---

# SearchView

## Overview

SearchView is a configurable, composable document-search interface for web applications. It combines a search query input, multi-facet filtering (category and tag), a scrollable result list with roving keyboard focus, and a collapsible preview dock below. The component is driven by three injected seams: a search scope (endpoint and parameters), a document-type configuration (result rendering and preview), and a link builder. It fetches results on-demand (debounced query and facet changes, plus instant-on-Enter), renders results through a supplied row component, previews the selected result through a supplied preview component, and synchronizes filter state to the URL for shareability. Until a query or facet filter is active, it shows a prompt instead of fetching or displaying results.

## Behavioral Requirements

- **accept-search-source**: Component MUST accept a `source` prop defining the API endpoint, base URL, and request parameter map for document search.
- **accept-document-type**: Component MUST accept a `documentType` prop containing a result row renderer, a preview component, a preview header renderer, and two extractors (`getId`, `getTitle`).
- **accept-document-href**: Component MUST accept a `documentHref` function prop that returns the public-page URL for a hit; this is the primary link seam and has no default.
- **render-search-filter-bar**: Component MUST render a SearchFilterBar with a text query input, a category dropdown filter, and a tag dropdown filter; all three are always mounted.
- **render-filter-chips**: Component MUST render a chip for each active facet filter (category, tag); each chip MUST have a remove button that clears only that chip's own facet, leaving any other active facet unchanged; a "Clear filters" button MUST appear when any facet is active.
- **no-auto-fetch**: Component MUST NOT fetch results until a query or facet filter becomes active; until then it MUST display a prompt (EmptyState).
- **debounce-search**: Component MUST debounce search and filter changes by the `debounceMs` prop (default 250ms) before fetching.
- **fetch-on-enter**: Component MUST fetch immediately (flushing the debounce) when Enter is pressed in the search input.
- **render-result-count**: Once results have settled, component MUST render a live result count above the list (e.g. "3 results" or "No results").
- **render-result-list**: Component MUST render the result list as a `<ul>` with one `<li>` per hit; each hit MUST be rendered through the supplied ResultRow component with `hit`, `href`, `query`, `selected` (boolean), `active` (boolean), `controlRef`, and `onSelect` props.
- **support-roving-focus**: Result list MUST implement roving tabindex: only one row is a Tab stop at any time; ArrowUp/ArrowDown move focus; Home/End jump to first/last; Enter/Space activate the focused row (left to the ResultRow's native handler).
- **track-active-index**: Component MUST track an internal active index (cursor position) distinct from `selectedId`; the cursor moves with arrow keys. Opening the cursor's row into the preview on Enter/Space is the ResultRow's own responsibility — see **support-roving-focus**.
- **clamp-cursor-on-resize**: When results are requeried and the result set shrinks, component MUST clamp the active index to the new item count to prevent out-of-bounds access.
- **render-loading-skeleton**: During the initial fetch (while no results have settled), component MUST render 3 placeholder skeleton bars with `aria-busy="true"` and `aria-label="Loading results"`.
- **render-zero-results**: When results settle with an empty list and no error, component MUST render a "No matching documents" message; if facets are active, include a hint to remove filters.
- **render-hard-error**: When a fetch error occurs and no results are cached, component MUST render a full error block with the error message and a Retry button.
- **render-stale-error**: When a fetch error occurs while results are cached (re-query failure), component MUST render a compact error strip above the list with the error message and a Retry button.
- **support-preview-dock**: Component MUST render a collapsible preview dock below the result list; the dock has a minimal header bar (title, collapse toggle) when collapsed, and expands to show the full preview header and rendered content when disclosed.
- **render-split-divider**: When the preview dock is disclosed, component MUST render a horizontal SplitDivider above it that is draggable (mouse) and keyboard-operable to resize the list/preview ratio; the divider MUST NOT render when the dock is collapsed.
- **manage-preview-disclosure**: Component MUST manage preview disclosure state independently of selection; selecting a result both opens the dock (discloses it) and moves focus into the preview content region (labeled "Document preview content").
- **reselect-focuses-without-reopening**: When the already-selected hit is selected again while the preview is already disclosed, the component MUST move focus into the preview content region without changing selection or disclosure state (no re-render of either).
- **handle-escape-in-list**: While focus is in the result list, Escape MUST collapse the preview dock and clear the selection (if a result is selected), without moving focus.
- **escape-noop-without-selection**: While focus is in the result list, if no result is currently selected, Escape MUST have no effect — no dock-state change and no focus move.
- **handle-escape-in-preview**: While focus is anywhere in the preview dock — the header controls (the collapse toggle and any links rendered by the type's `PreviewHeader`) or the body — Escape MUST collapse the dock, clear the selection, and move focus to the row at the roving-focus cursor (`activeIndex`). `activeIndex` coincides with the row that opened the preview only when that row was reached by keyboard (Arrow/Home/End) and then activated there; a preview opened by clicking a different row (a click never updates `activeIndex`) leaves the cursor on whatever row it was on before, so focus returns to that cursor row instead, not the row that opened the preview. The handler sits on the outer preview section so it fires uniformly from either area.
- **support-url-sync**: Component MUST synchronize `q`, `tag`, and `category` filters to the URL query string (if `urlSync` prop is true, the default); the synchronization MUST be SSR-safe and framework-agnostic, allowing results to be shared and back/forward to re-sync state.
- **label-search-region**: The search and filter bar MUST sit inside a `role="search"` landmark with an accessible label (`searchLandmarkLabel` prop, default "Document search"); the label MUST be distinct when multiple search regions render on a page.
- **label-search-input**: The search input MUST have an accessible label (`searchLabel` prop, default "Search documents").
- **label-result-list**: The result list `<ul>` MUST have `aria-label="Search results"`.
- **label-preview-region**: The preview dock section MUST have `aria-label="Document preview"` and the preview content region MUST have `aria-label="Document preview content"`.
- **announce-result-count**: The result count MUST have `role="status"` and `aria-live="polite"` to announce count changes to screen readers.
- **announce-loading-container**: The outer container holding the list MUST have `aria-busy` set to true while in the loading phase.
- **focus-preview-on-select**: When a result is selected, component MUST programmatically focus the preview content region (a `<div tabIndex={-1}>`) so keyboard users land on the opened preview.
- **no-unrelated-refocus**: Focus movement into the preview MUST only occur on user selection, not on unrelated re-renders or header-toggle disclosure changes; this is gated by an internal flag.
- **category-filter-label**: The category dropdown label MUST be the static text "Filter by category" (it never varies).
- **tag-filter-label**: The tag dropdown label MUST be the static text "Filter by tag" (it never varies).
- **accept-optional-props**: Component MUST accept optional props: `searchPlaceholder` (default "Search…"), `debounceMs` (default 250), `timeoutMs` (optional, passed to data-fetching hooks), `urlSync` (default true), `className` (extra classes on root).
- **clear-facets-only**: The "Clear filters" button MUST clear only active facets (category and tag), NOT the query string.
- **accept-hit-id-extraction**: Component MUST use the supplied `getId` function from documentType to extract the hit identifier.
- **accept-hit-title-extraction**: Component MUST use the supplied `getTitle` function from documentType to extract the hit title for display in the preview dock header.
- **render-preview-title-collapsed**: When the preview dock is collapsed, the minimal header bar MUST show the selected hit's title or "Preview" if nothing is selected.
- **render-preview-metadata-disclosed**: When the preview dock is disclosed and a hit is selected, the full metadata header from the type's `PreviewHeader` component MUST render in the header region; if nothing is selected while disclosed, the header renders nothing and the body's EmptyState is the sole "Select a result…" text.

## Appearance

- **Corner radius**: Preview dock: 0.75rem. Error blocks and empty-state cards (zero-results, inactive prompt): 0.5rem.
- **Padding**: Root stack: 1rem (16px) gap between the search bar, the filter chips, and the list/preview area. Filter chips: 0.5rem (8px) gap between chips. Preview dock header: 0.75rem horizontal × 0.5rem vertical. Result list: 0.75rem (12px) gap between items. Result list container: small right padding (0.25rem / 4px) reserved for the internal scrollbar.
- **Font**: Result count label: 0.75rem. Chip labels: inherited from Badge. Preview title (collapsed): 0.875rem, medium weight. Preview subtitle: 0.75rem. Error message: 0.875rem. Empty/zero-results title: 0.875rem, medium weight; its hint text: 0.75rem.
- **Background**: Preview dock: `apt-surface` (primary surface token). Error blocks: `apt-red` at 5% opacity. Loading skeleton: `apt-surface-2` (secondary surface token). Chip hover: `apt-surface-2`.
- **Foreground/Text**: Result count: `apt-text-dim` (muted text token). Chip text: inherited from Badge; chip hover text: `apt-text`. Preview subtitle: `apt-text-muted`. Error text: `apt-red`. Empty/zero-results title: `apt-text-muted`; its hint text: `apt-text-dim`.
- **Border**: Default border color: `apt-border`. Error blocks: `apt-red` at 40% opacity. Preview dock: 1px border, `apt-border`, drawn with the 0.75rem corner radius above. Between the dock's header and its content region (when disclosed): 1px top border, `apt-border`. Empty/zero-results cards: dashed border, `apt-border`.
- **Shadow**: None.
- **Min/Max size**: The split container (list + divider + preview dock) targets 65% of viewport height with a 320px floor on small viewports, and 70% of viewport height with a 420px floor from the small breakpoint up. Both the result list and the disclosed preview dock are allowed to shrink below their content size so they scroll internally rather than overflow the container. Individual result rows are otherwise unconstrained in height.

## States

| State | Appearance change |
|-------|------------------|
| Default | —  |
| Loading | Loading skeleton: 3 placeholder bars with `animate-pulse` and `bg-apt-surface-2`. Container has `aria-busy="true"`. |
| Inactive (no query/facet) | EmptyState prompt displayed; no list or fetch occurs. |
| Empty results | "No matching documents" message with optional "remove filters" hint. |
| Hard error (error, no cache) | Full error block (min-height 160px) centered, with error message and Retry button. |
| Stale error (error, cached results) | Compact error strip above cached results; no min-height, self-start Retry button. |
| Preview collapsed | Preview dock shows minimal header: collapse toggle, title (or "Preview"), subtitle hint. No body region. |
| Preview disclosed | Preview dock expands to fill its flex ratio; metadata header and rendered body visible; SplitDivider above the dock appears. |

## Accessibility

- **Role/trait**: Root is a generic `<div>`. Search region is a landmark with `role="search"` and `aria-label`. Result list is a `<ul>` with `aria-label="Search results"`. Each result is a `<li>`. Preview dock is a `<section>` with `aria-label="Document preview"`. Preview content is a focusable `<div tabIndex={-1}>` with `aria-label="Document preview content"`. Chip removers are `<button type="button">`. Clear filters is a Button component. Result count has `role="status"` and `aria-live="polite"`. Error blocks have `role="alert"`. Loading list has `aria-busy="true"` and `aria-label="Loading results"`. List container has `aria-busy` true while loading.
- **Label requirements**: Search input has `label` prop; category and tag filters have labels. Result count is announced via aria-live. Chip remover buttons have descriptive aria-labels (e.g. "Remove Category filter: Science"). Collapse toggle has descriptive labels ("Collapse preview" / "Expand preview") and `aria-controls` pointing to the content region.
- **Announce state changes**: Loading state is communicated via `aria-busy` and aria-label on the list. Result count changes are announced via `aria-live="polite"`. Error state is communicated via `role="alert"` on the error block. Preview disclosure is communicated via `aria-expanded` on the CollapseToggle.
- **Minimum tap target**: Chip remove buttons use an invisible `::after` overlay (24×24 CSS px) over a visible 16px icon to meet WCAG 2.2 SC 2.5.8. Collapse toggle on the preview dock and other button controls inherit minimum touch targets from the Button and CollapseToggle components (see their recipes).
- **Keyboard navigation**: Search input accepts Enter to commit the search. Result list supports ArrowUp/ArrowDown (move focus), Home/End (jump to bounds), Enter/Space (activate focused row via ResultRow's handler). Escape in the list clears the selection and collapses the preview; Escape in the preview clears the selection, collapses the dock, and returns focus to the row at the roving-focus cursor (`activeIndex`) — the row that opened the preview only when it was reached by keyboard (see **handle-escape-in-preview**). Tab navigation is managed by roving tabindex: only the active row is a Tab stop; arrows move focus without Tab.

## Conformance Test Vectors

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

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `source` | `SearchSource` | — (required) | The search scope: base URL, endpoint, and request parameter map for document search. |
| `documentType` | `DocumentTypeConfig<Hit>` | — (required) | Result row renderer, preview component, preview header renderer, and `getId`/`getTitle` extractors. |
| `documentHref` | `(hit: Hit) => string` | — (required) | Builds the public-page URL for a hit; the primary link seam, deliberately without a default. |
| `searchLabel` | `string` | `"Search documents"` | Accessible label for the search input. |
| `searchPlaceholder` | `string` | `"Search…"` | Placeholder text in the search input. |
| `searchLandmarkLabel` | `string` | `"Document search"` | Accessible name for the `role="search"` landmark. |
| `debounceMs` | `number` | `250` | Debounce (ms) for search/filter changes before fetching. |
| `timeoutMs` | `number` | `undefined` | Per-request timeout (ms) for the search, facet, and preview fetches. |
| `urlSync` | `boolean` | `true` | Mirrors `q`/`tag`/`category` to the URL query string for a shareable, back/forward-safe results view. |
| `className` | `string` | `undefined` | Extra classes applied to the root element. |

## Deep Linking

Not applicable: SearchView does not define deep-link paths. The documentHref prop is the seam through which the host provides document links; navigation is handled by the host's router, not the component.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `searchLabel` (prop) | Search documents | Accessible label for the search input |
| `searchPlaceholder` (prop) | Search… | Placeholder text in the search input |
| `searchLandmarkLabel` (prop) | Document search | Accessible name for the search region landmark |
| `emptyStateInactiveTitle` | Search research documents to get started. | Hardcoded prompt title when no query or facet is active; not exposed as a prop |
| `emptyStateInactiveDescription` | Type a query above, or pick a category or tag, to search across every researcher. | Hardcoded prompt description; not exposed as a prop |
| `resultCountZero` / `resultCountSingular` / `resultCountPlural` | No results / {n} result / {n} results | Result count labels generated by `resultCountLabel`; English-only singular/plural, not locale-aware plural rules |
| `zeroResultsTitle` | No matching documents | Hardcoded message when a query matches no results |
| `zeroResultsHintWithFacets` | Try a different search or remove filters. | Hardcoded hint when filters are applied but no results match |
| `zeroResultsHintNoFacets` | Try a different search. | Hardcoded hint when no filters are applied |
| `categoryFilterLabel` | Filter by category | Hardcoded label for the category dropdown |
| `categoryFilterAllLabel` | All categories | Hardcoded "all" option for the category dropdown |
| `tagFilterLabel` | Filter by tag | Hardcoded label for the tag dropdown |
| `tagFilterAllLabel` | All tags | Hardcoded "all" option for the tag dropdown |
| `chipLabelCategory` / `chipLabelTag` | Category / Tag | Hardcoded prefix for chip labels (e.g. "Category: Science") |
| `clearFiltersLabel` | Clear filters | Hardcoded button label that clears all active facets |
| `activeFiltersAriaLabel` | Active filters | Hardcoded accessible label for the filter chips container |
| `chipRemoveAriaLabel` | Remove {label} filter {value} | Hardcoded template for chip remove button aria-labels |
| `collapseTogglePreviewLabel` | preview | Hardcoded label passed to `CollapseToggle` (prefix for "Collapse preview" / "Expand preview") |
| `previewDockAriaLabel` | Document preview | Hardcoded accessible label for the preview dock section |
| `splitDividerLabel` | Resize preview | Hardcoded accessible label for the resize divider |
| `splitDividerGrowBottomLabel` | Enlarge preview | Hardcoded label for growing the preview pane |
| `splitDividerGrowTopLabel` | Enlarge results | Hardcoded label for growing the results pane |
| `previewCollapsedFallbackTitle` | Preview | Hardcoded fallback title in the collapsed dock when nothing is selected |
| `previewCollapsedSubtitle` | Collapsed — expand to preview | Hardcoded subtitle when the dock is collapsed with a selection |
| `previewEmptySelectionText` | Select a result to preview it. | Hardcoded subtitle (collapsed, no selection) and body empty-state title (disclosed, no selection) |
| `previewContentAriaLabel` | Document preview content | Hardcoded accessible label for the preview body |
| `loadingSkeletonAriaLabel` | Loading results | Hardcoded accessible label during the loading state |
| `resultListAriaLabel` | Search results | Hardcoded accessible label for the result list |
| `errorFallbackMessage` | Something went wrong loading results. | Hardcoded fallback error message when none is supplied |
| `retryButtonLabel` | Retry | Hardcoded button label to retry a failed fetch |

Only `searchLabel`, `searchPlaceholder`, and `searchLandmarkLabel` are exposed as overridable props; every other string above is hardcoded in the component with no override seam, and the "String Key" column for those rows is a descriptive identifier assigned for this table, not a key that exists in source.

## Accessibility Options

- **Reduce Motion**: The loading skeleton uses `animate-pulse` (a CSS animation). On `prefers-reduced-motion: reduce`, this animation SHOULD be removed or replaced with a static appearance. This is a style concern, not specific to SearchView's behavior, so it defers to the host's style implementation.
- **Increase Contrast**: All text colors (`text-apt-*`) and backgrounds inherit from the design system's apt-* tokens. The host's design system is responsible for providing high-contrast variants; SearchView does not handle this.
- **Differentiate Without Color**: Error state is communicated with a red background and text color, but color is not the only signal — the error message text itself and the `role="alert"` announcement both convey the error independent of color.

## Feature Flags

Not applicable: SearchView has no feature flags defined in the source.

## Analytics

Not applicable: SearchView does not emit analytics events directly. Analytics are the responsibility of the host application or the data-fetching hooks (useDocumentSearch, useUrlFilters, useFacets).

## Privacy

- **Data collected**: SearchView itself collects no data beyond what the user types or selects. The search query, filters, and selected result are held in local state and passed to the host's data-fetching layer and link builder.
- **Storage**: Filters are written to the URL query string if `urlSync` is true. No other persistent storage is used by the component.
- **Transmission**: The component performs network requests itself, via its `useDocumentSearch` and `useFacets` hooks (plain `fetch`), against the endpoint and parameters defined by the host's `source` prop; the supplied `Preview` component may issue additional requests. The host controls the destination through `source`, but SearchView — not just the host application — is the one making the calls.
- **Retention**: The component itself retains no data beyond the current render. However, because the query and active facets are written into the URL (when `urlSync` is enabled), they persist wherever the URL persists — browser history, bookmarks, shared links, and server referrer logs — for as long as those retain it, independent of the page session and outside the component's control.

## Logging

Not applicable: SearchView does not define logging events in the source.

## Platform Notes

- **React/Web**: Source files: `packages/web/packages/search/src/components/SearchView.tsx` and related modules. Uses React hooks (useState, useEffect, useCallback, useRef, useId), event handlers (KeyboardEvent), and Tailwind CSS for styling. Data fetching is delegated to custom hooks (useDocumentSearch, useUrlFilters, useFacets). The component is SSR-safe; filter state is synced bidirectionally with the URL.
- **SwiftUI**: A SearchView equivalent on iOS/macOS would use SwiftUI's `@State` and an `@Observable` model for state management. Use a `VStack` for the layout (filter bar, chips, list, divider, preview dock). Implement keyboard navigation via `.onKeyPress()` modifiers. Use `List` with roving focus via `.focusable()` and programmatic focus management with `FocusState`. Manage the collapsible preview with a disclosure indicator (chevron) and animated height/opacity changes. Synchronize state with URLComponents or AppStorage. Touch targets meet Apple HIG minimums (44×44pt).
- **Compose**: A Compose version would use `MutableState` for filter and selection state. Layout as a `Column` with the SearchFilterBar, chips, a scrollable `LazyColumn` for results, and a collapsible `Surface` below for the preview. Implement roving keyboard focus via `Modifier.onPreviewKeyEvent()` and `FocusRequester`. Use `animateContentSize()` for the collapsible preview. Render the divider as a draggable `Box` with `pointerInput()`. Material Design 3 defines touch targets at 48×48dp; implement via padding and `minimumInteractiveComponentSize`.
- **AppKit / UIKit**: On macOS, use an `NSStackView` (vertical) composing `NSSearchField` (query), `NSPopUpButton` (category/tag filters), an `NSTableView` for the result list (roving/keyboard navigation via `NSTableViewDelegate` and the responder chain's key-view loop), and a collapsible bottom pane for the preview dock — a resizable `NSView` (or an `NSSplitView` with a collapsible pane), with a custom `NSView`-based divider for the resize handle. On iOS, use a `UITableView` for the result list (`UITableViewDelegate` drives selection; a hardware keyboard's `UIKeyCommand` drives arrow/Home/End navigation), `UITextField` for the search input, and `UIControl` subclasses for filters and buttons; implement the collapsible preview dock with a custom container view — not `UISplitViewController`, which targets side-by-side master/detail panes rather than a stacked collapsible dock — animating its height/constraint changes with `UIView.animate`. Touch targets on iOS meet Apple HIG (44×44pt); macOS supports keyboard-only navigation natively.
- **WinUI 3**: Use `StackPanel` (vertical) for the layout. Implement the search bar with `TextBox` (query) and `ComboBox` (filters). Use `ItemsRepeater` or `ListView` for the result list with `KeyDown` event handlers for arrow navigation. Manage focus via `FocusManager.TryFocusAsync()`. Render the collapsible preview with a `Grid` and `RowDefinition` `Height` binding; animate disclosure via a `Storyboard` driving the row's height (WinUI has no `ThicknessAnimation`; use a `DoubleAnimation` against a `GridLength`-aware helper, such as the CommunityToolkit's `AnimationBuilder`). Implement the resize divider with a native `GridSplitter` from `CommunityToolkit.WinUI.Controls`, or a custom draggable `Thumb` — never a third-party commercial control such as Telerik's. Fluent 2 Design System defines touch targets at 40×40px minimum (40×44px on touch devices); use `Padding` to meet the target.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/search/src/components/SearchView.tsx` | unverified |

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | passed | Internationalization |
| [adc.check.internationalization.plural-forms](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d24616b8-d1af-593d-ba01-f51ee4a91ea4) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | partial | Privacy and Data |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Statuses rest on the component's own source: explicit `aria-*` attributes, roving-tabindex handlers, and focus management in `SearchView.tsx`/`PreviewDock` for Accessibility; the `resultCountLabel` formatter (`toLocaleString`, English-only plural ternary) and the literal UI strings enumerated in Localization for Internationalization; the local state shape and URL-sync behavior described in Privacy for Privacy and Data; and the unsanitized query pass-through to `useDocumentSearch`/`documentHref` for Security. `separation-of-concerns` passes: data fetching and faceting are delegated to the `useDocumentSearch`/`useFacets` hooks, URL sync to `useUrlFilters`, and presentation to shared `SearchFilterBar`/`Badge`/`Button`/`CollapseToggle`/`EmptyState`/`SplitDivider` components — `SearchView.tsx` itself owns only UI-local orchestration state (selection, roving-focus cursor, split ratio, preview disclosure). `unit-test-coverage` fails: no test in the `search` package renders `SearchView`; the package's tests (`buildSearchUrl.test.ts`, `paperSearchSource.test.ts`) exercise a different component, `PaperSearchView`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: merged duplicate requirements (loading aria, URL back/forward, escape-from-header), resolved the Enter-ownership conflict between roving focus and active-index tracking, corrected the Privacy transmission/retention claims, rewrote Appearance in tokens/measurements instead of raw Tailwind classes and fixed its accuracy errors (gap size, corner-radius conflict, a typo), populated Configuration and Compliance as real tables, reformatted Design Decisions to the Decision/Rationale/Approved form and retitled a misleading one, corrected Platform Notes APIs (SwiftUI, WinUI, AppKit/UIKit) and replaced the commercial WinUI splitter suggestion, rebuilt the Localization table's misused columns, generalized app-specific wording in a merged requirement, added two new requirements for previously-orphaned edge cases plus test vectors for all previously-uncovered requirements, retagged two mistagged vectors, and renamed every requirement to subject-only kebab-case with no `must-` prefix. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Escape deselects (both list/preview); preview Escape refocuses activeIndex, not opened row. |
