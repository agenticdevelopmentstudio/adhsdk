
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| filtered-list-001 | render-input-field | Initial render | Text input field with placeholder "Filter…" is rendered |
| filtered-list-002 | filter-items | Query "apple" entered | Only items whose title, subtitle, details, or searchable extras contain "apple" (case-insensitive) are visible |
| filtered-list-003 | arrow-down-navigation | No highlight + ArrowDown pressed | First item becomes highlighted |
| filtered-list-004 | arrow-down-navigation | First item highlighted + ArrowDown pressed | Second item becomes highlighted |
| filtered-list-005 | arrow-down-navigation | Last item highlighted + ArrowDown pressed | Highlight remains on last item (does not wrap) |
| filtered-list-006 | arrow-up-navigation | First item highlighted + ArrowUp pressed | Highlight is cleared (index = -1) |
| filtered-list-007 | arrow-up-navigation | Second item highlighted + ArrowUp pressed | First item becomes highlighted |
| filtered-list-008 | enter-selection | Item highlighted + Enter pressed | onSelect callback is called with highlighted item |
| filtered-list-009 | escape-clears-highlight | Item highlighted + Escape pressed | Highlight is cleared |
| filtered-list-010 | reset-highlight-on-input-change | Item highlighted + user types in input | Highlight is reset to -1 |
| filtered-list-011 | clamp-highlight-when-visible-shrinks | Highlight on item 5, query changes to show 3 items | Highlight moves to item 3 (last visible) |
| filtered-list-012 | render-item-list | Items provided via props | The `<ul>` renders with role="listbox" and all visible items render as `<li>` children |
| filtered-list-013 | render-item-title | Item with getTitle callback, renderItem not provided | Title is rendered in fl-title element |
| filtered-list-014 | render-item-subtitle | Item with getSubtitle callback, renderItem not provided | Subtitle is rendered in fl-subtitle element |
| filtered-list-015 | clickable-items-when-onselect-provided | onSelect callback provided | Each item wraps its content in a button element |
| filtered-list-016 | mouse-hover-highlight | User moves mouse over item | Item becomes highlighted, aria-selected="true" |
| filtered-list-017 | scroll-active-item-into-view | Highlight moves to off-screen item | List container scrolls to show the highlighted item |
| filtered-list-018 | input-shows-highlighted-title | Item highlighted | Input value shows item title instead of query |
| filtered-list-019 | combobox-aria-expanded | Visible items exist | Input has aria-expanded="true" |
| filtered-list-020 | combobox-aria-expanded | No visible items | Input has aria-expanded="false" |
| filtered-list-021 | combobox-aria-activedescendant | Item highlighted | Input aria-activedescendant matches item ID |
| filtered-list-022 | unique-item-ids | Multiple items rendered | Each item has unique id: `{listId}-{itemId}` |
| filtered-list-023 | option-aria-selected | Item highlighted | Item has aria-selected="true" |
| filtered-list-024 | option-aria-selected | Item not highlighted | Item has aria-selected="false" |
| filtered-list-025 | onhighlight-callback | Highlight changes | onHighlightChange callback is invoked with new item or null |
| filtered-list-026 | empty-state-when-no-items | total === 0 | "No items." message is displayed instead of the list |
| filtered-list-027 | custom-empty-content | emptyContent provided + zero visible items while total > 0 | Custom emptyContent is rendered instead of the default no-matches message |
| filtered-list-028 | render-footer | footer prop provided | Footer is rendered as last list item |
| filtered-list-029 | wrap-input-in-form | Initial render | Input is wrapped in `<form role="search">` |
| filtered-list-030 | prevent-form-submission | Enter pressed on input, any highlight state | Form submission is prevented via the form's onSubmit handler regardless of whether an item is highlighted |
| filtered-list-031 | autofill-prevention | Input rendered | noAutofillProps applied to prevent browser autofill |
| filtered-list-032 | autofocus-on-mount | autoFocus={true} prop | Input receives focus on mount |
| filtered-list-033 | escape-clears-highlight | Escape pressed with no item highlighted | No highlight change occurs; default action is not prevented (edge case) |
| filtered-list-034 | render-item-details | Item with getDetails callback, renderItem not provided | Details are rendered in fl-details element |
| filtered-list-035 | custom-item-render | renderItem provided | `renderItem(item)` return value is rendered instead of the default title/subtitle/details layout |
| filtered-list-036 | arrow-keys-noop-when-no-items | No visible items, ArrowDown pressed | Default browser behavior is not prevented (no e.preventDefault call); no highlight change occurs |
| filtered-list-037 | default-no-matches-message | Query yields zero visible items, total > 0, no emptyContent | List's only item is the literal text `No matches for "{query}".` |
| filtered-list-038 | item-role-option | Items rendered | Each `<li>` has role="option" |
| filtered-list-039 | enter-selection | Enter pressed with no item highlighted | onSelect is not called; form submission is still prevented by the form wrapper (see prevent-form-submission) |

