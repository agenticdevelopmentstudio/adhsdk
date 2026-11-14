
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cp-001 | accept-open-prop | `open: false` | Dialog is not rendered or is hidden |
| cp-002 | accept-open-prop, focus-input-on-open | `open: true` | Dialog is visible and input receives focus |
| cp-003 | open-change-on-dismiss | User presses Escape | `onOpenChange(false)` is called |
| cp-004 | open-change-on-dismiss, run-on-enter | User selects an item via Enter | `onOpenChange(false)` is called, then item's `onSelect()` is called |
| cp-005 | display-query | `query: "test"` | Input field shows "test" |
| cp-006 | query-change-callback | User types "foo" in input | `onQueryChange("foo")` is called for each keystroke |
| cp-007 | render-groups-in-order | `groups: [{id: "g1", …}, {id: "g2", …}]` | Group headings appear in order g1, then g2 |
| cp-008 | render-groups-in-order | `groups: [{id: "g1", items: []}, {id: "g2", items: [{…}]}]` | Only g2 heading is rendered; g1 is dropped entirely |
| cp-009 | render-groups-in-order | Group with 0 items | Group heading is not rendered |
| cp-010 | render-groups-in-order | Group with 1+ items | Group heading is rendered |
| cp-011 | reset-highlight-to-first-item | Dialog opens with 3 items | First item is highlighted |
| cp-012 | reset-highlight-to-first-item | Item list changes from [A, B, C] to [X, Y] | Highlight moves to X (first of new list) |
| cp-013 | arrow-navigation | Highlight on item 1 of 3, press ArrowDown | Highlight moves to item 2 |
| cp-014 | arrow-navigation | Highlight on item 3 of 3, press ArrowDown | Highlight wraps to item 1 |
| cp-015 | arrow-navigation | Highlight on item 1 of 3, press ArrowUp | Highlight wraps to item 3 |
| cp-016 | home-end-navigation | Highlight on item 2, press Home | Highlight moves to item 1 |
| cp-017 | home-end-navigation | Highlight on item 1, press End | Highlight moves to item 3 |
| cp-018 | run-on-enter | Highlight on item with `onSelect`, press Enter | `onSelect()` is called and dialog closes |
| cp-019 | run-on-click | Item is visible and user clicks it | `onSelect()` is called and dialog closes |
| cp-020 | update-highlight-on-hover | Highlight on item 1, user hovers item 2 | Highlight moves to item 2 |
| cp-021 | scroll-highlighted-item-into-view | Highlight on item outside viewport | Item scrolls into view with nearest block align |
| cp-022 | display-loading-state | `loading: true`, items list populated | Spinner and "Searching…" appear below items; items remain visible |
| cp-023 | display-error-message | `error: "Network error"` | Error message displays in list area |
| cp-024 | display-empty-state | `groups: []`, `loading: false`, `error: null` | "No matches" (or custom `emptyLabel`) displays |
| cp-025 | render-footer-when-provided | `footer: <div>Help text</div>` | Footer strip renders at bottom with top border |
| cp-026 | no-internal-filtering | `groups` contain items whose labels do not contain "xyz"; `query: "xyz"` | Every provided item still renders; no client-side filtering occurs |
| cp-027 | reset-highlight-to-first-item | `open: true`, user selects item (closes), `open: true` again | Highlight resets to first item |
| cp-028 | truncate-long-text | Item with a `label`/`description` longer than the row width | Text is truncated with an ellipsis; the row does not wrap or grow |
| cp-029 | no-reserved-space-for-missing-icon-badge | Item with `icon: undefined`, `badge: undefined` | No empty space is rendered where the icon/badge would be |
| cp-030 | arrow-navigation | Exactly one item, press ArrowDown then ArrowUp | Highlight stays on the single item both times (wraps to itself) |
| cp-031 | display-error-message, display-loading-state | `loading: true` and `error: "Network error"` together | Both the error text and the loading indicator are visible |

