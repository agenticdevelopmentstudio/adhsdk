
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| search-dialog-001 | closed-by-default | `open: false` | Component returns `null`; nothing renders. |
| search-dialog-002 | open-as-modal | `open: true` | Root div has `role="dialog"` and `aria-modal="true"`. |
| search-dialog-003 | dismissible-backdrop | `open: true`, click backdrop | `onClose()` callback is invoked. |
| search-dialog-004 | focus-input-on-open | `open: false` → `true` | Input field is focused after the dialog renders (implementation defers via `requestAnimationFrame`; see Design Decisions). |
| search-dialog-005 | reset-search-state-on-open | `open: false` → `true` | Search state is reset to its initial values: query cleared, no results, `state.selectedIndex` reset to `0` (not `-1`) — nothing is visibly highlighted only because the results section is empty until a query is typed. |
| search-dialog-006 | input-row-with-search-icon | `open: true` | Form renders containing the SVG search icon and the input field (form's `role="search"` verified in search-dialog-032). |
| search-dialog-007 | escape-hint | `open: true` | Keyboard hint element displaying "Esc" is rendered. |
| search-dialog-008 | placeholder-prop | `open: true`, no `placeholder` prop | Input field displays "Search documentation..." placeholder. |
| search-dialog-009 | placeholder-prop | `open: true`, `placeholder: "Find items"` | Input field displays "Find items" placeholder. |
| search-dialog-010 | escape-dismisses | `open: true`, user presses Escape in input | `onClose()` is invoked immediately. |
| search-dialog-011 | enter-selects-highlighted-result | `open: true`, result selected, user presses Enter | `onSelect(selectedEntry)` is invoked; page does not navigate. |
| search-dialog-012 | enter-selects-highlighted-result | `open: true`, `state.selectedIndex: -1` (an out-of-range value the component's own reset/`setQuery` never produce — `state.selectedIndex` otherwise starts at, and resets to, `0` — exercised here as a defensive bounds check), user presses Enter | No callback is invoked; page does not navigate. |
| search-dialog-013 | delegate-other-keys | `open: true`, user presses ArrowDown | `state.handleKey(e)` is called with the keyboard event. |
| search-dialog-014 | update-query-on-input | `open: true`, user types "test" | `state.setQuery()` is called for each keystroke; input value updates. |
| search-dialog-015 | show-results-only-when-querying | `open: true`, `state.query: ""` | Results section is not rendered. |
| search-dialog-016 | show-results-only-when-querying | `open: true`, `state.query: "docs"` | Results section is rendered (or empty state if no results). |
| search-dialog-017 | limit-results-to-twenty | `open: true`, 50 results in `state.results` | Only top 20 results are processed and displayed. |
| search-dialog-018 | group-results-by-section | `open: true`, results with sections `["guides", "api", "api", "guides"]` | Results render as two section groups, in first-occurrence order: `guides`, then `api`. |
| search-dialog-019 | group-results-by-section | `open: true`, result without section property | Result is grouped under `"other"`. |
| search-dialog-020 | translate-section-labels | `open: true`, `sectionLabels: { guides: "How-To Guides" }` | Section displays as "How-To Guides", not "guides". |
| search-dialog-021 | translate-section-labels | `open: true`, `sectionLabels: {}`, section is "api" | Section displays as "api" (no translation provided). |
| search-dialog-022 | empty-state-when-no-results | `open: true`, `state.query: "xyzabc"`, no results | Message displays: `No results for "xyzabc"`. |
| search-dialog-023 | result-title-and-summary | `open: true`, results present | Each result displays `entry.frontmatter.title`. |
| search-dialog-024 | result-title-and-summary | `open: true`, result with summary | Result displays both title and summary below it. |
| search-dialog-025 | result-title-and-summary | `open: true`, result without summary | Result displays title only; summary section not rendered. |
| search-dialog-026 | result-as-button | `open: true`, result visible | Result is a `<button type="button">` element. |
| search-dialog-027 | result-as-button | `open: true`, user clicks result | `onSelect(entry)` is invoked with that result's entry. |
| search-dialog-028 | highlight-selected-result | `open: true`, `state.selectedIndex: 2` | The row at grouped render position 2 (not necessarily `state.results[2]`) has class `awt-search-dialog__result--selected`. |
| search-dialog-029 | highlight-selected-result | `open: true`, `state.selectedIndex: 999` (≥ number of rendered results) | No result is highlighted. |
| search-dialog-030 | stable-result-identity | `open: true`, results rendered, then re-rendered with the same entries reordered | Each result's identity stays tied to its `slug` rather than its position (implementation detail: React `key`; verified via reconciliation, not a DOM attribute). |
| search-dialog-031 | prevent-form-submission | `open: true`, user presses Enter with form focused | Form's `onSubmit` prevents default; no page navigation. |
| search-dialog-032 | search-role-on-form | `open: true` | Form element has `role="search"`. |
| search-dialog-033 | suppress-autofill-suggestions | `open: true` | Input field carries the attributes needed to suppress the browser's autofill suggestion UI (`noAutofillProps` in source; see Design Decisions). |
| search-dialog-034 | enter-selects-highlighted-result, highlight-selected-result | `open: true`, ranked results `[A(guides), B(api), C(api), D(guides)]` (grouped render order: guides → A, D; api → B, C), `state.selectedIndex: 1` | Row D (grouped position 1) is highlighted, but Enter invokes `onSelect(B)` — `state.results[1]` in rank order — not `onSelect(D)`; the highlighted row and the Enter target diverge whenever sections interleave. |

