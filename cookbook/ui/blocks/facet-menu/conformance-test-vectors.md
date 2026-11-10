
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| facet-001 | render-trigger, omit-count-when-empty, empty-selection-semantics | options: ["A", "B"], selected: empty | Trigger displays "Label" only, no count; the component performs no filtering logic of its own |
| facet-002 | render-trigger, omit-count-when-empty | options: ["A", "B"], selected: {"A"} | Trigger displays "Label (1)" |
| facet-003 | disable-trigger | options: [], selected: empty | Trigger button's `disabled` attribute is `true`; clicking it does not open the popover |
| facet-004 | show-chevron | options: ["A", "B"], selected: empty | ChevronDown icon is visible and aria-hidden="true" |
| facet-005 | render-popover | options: ["A", "B"], trigger clicked | Popover opens, displaying "All", "None", and checkbox list |
| facet-006 | render-options | options: ["Apple", "Banana"], selected: empty | Checkboxes labeled "Apple" and "Banana" are rendered |
| facet-007 | label-transform | options: ["a", "b"], labelOf: (v) => v.toUpperCase(), selected: empty | Checkboxes labeled "A" and "B" are rendered |
| facet-008 | toggle-on-checkbox-click | options: ["A", "B"], selected: {"A"}, click checkbox "B" | onChange called with {"A", "B"} |
| facet-009 | render-all-button | options: ["A", "B", "C"], selected: empty | "All" button is rendered and clickable |
| facet-010 | disable-all-button | options: ["A", "B"], selected: {"A", "B"} | "All" button is disabled |
| facet-011 | render-none-button | options: ["A"], selected: {"A"} | "None" button is rendered and clickable |
| facet-012 | disable-none-button | options: ["A"], selected: empty | "None" button is disabled |
| facet-013 | handle-overflow | options: [40 items], selected: empty | Option list scrolls vertically when popover is open |
| facet-014 | preserve-selection-state | options: ["A", "B"], selected: {"A"}, open and close popover | Selection remains {"A"} |
| facet-015 | trigger-expanded-state | options: ["A", "B"], selected: empty, popover closed then opened | Trigger's `aria-expanded` is "false" when closed and "true" when open; `aria-haspopup` is present at all times |
| facet-016 | render-all-button | options: ["A", "B", "C"], selected: {"A"}, click "All" | onChange called with {"A", "B", "C"} |
| facet-017 | render-none-button | options: ["A", "B"], selected: {"A", "B"}, click "None" | onChange called with an empty Set |
| facet-018 | toggle-on-checkbox-click | options: ["A", "B"], selected: {"A", "B"}, click checkbox "A" (uncheck) | onChange called with {"B"} |
| facet-019 | disable-trigger | options: [], attempt to activate trigger via Enter or Space | Popover does not open |
| facet-020 | toggle-on-checkbox-click | options: ["A"], selected: empty, checkbox "A" focused via keyboard, press Space | onChange called with {"A"} |
| facet-021 | preserve-selection-state | options: ["A", "B"], selected: {"A"}, popover open, press Escape | Popover closes; selection remains {"A"} |
| facet-022 | stale-selection-values | options: ["B"], selected: {"A", "B"} (A stale), popover opened | Only checkbox "B" is rendered; trigger displays "Label (2)" |
| facet-023 | stale-selection-values, disable-all-button | options: ["B", "C"], selected: {"A", "B"} ("A" stale, "C" unselected), click "All" | "All" is enabled (not every current option is selected); onChange called with {"B", "C"} (stale "A" dropped) |
| facet-024 | stale-selection-values | options: ["B"], selected: {"A", "B"}, click "None" | onChange called with an empty Set (stale "A" dropped) |
| facet-025 | synchronous-selection-update | options: ["A", "B"], selected: {"A"}, checkbox "B" clicked twice in immediate succession with no intervening prop update | onChange is invoked twice, each call computed from selected={"A"} (both calls yield {"A", "B"}); the component does not accumulate a running selection internally |

