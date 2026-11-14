
- **Input role**: MUST be `combobox` with aria-controls pointing to the list ID and aria-expanded indicating whether the list has items.
- **Input aria-activedescendant**: MUST point to the currently highlighted item's ID, or be undefined if no item is highlighted.
- **List role**: MUST be `listbox` with a unique id.
- **Item role**: Each item MUST have role="option" (see **item-role-option**) and aria-selected reflecting highlight state.
- **Form role**: MUST be `role="search"` for semantic meaning.
- **Keyboard navigation**: MUST support ArrowUp, ArrowDown, Enter, and Escape keys as specified in Behavioral Requirements.
- **Focus management**: DOM focus MUST remain on the input at all times; the combobox pattern (aria-activedescendant) communicates the highlighted item to assistive technology without moving focus. List items are not part of the tab order (item buttons use tabIndex={-1}); highlight changes via keyboard or mouse hover never move DOM focus to a list item.
- **Label for input**: Component renders no `<label>` element, and `FilteredListProps` has no `aria-label` or `label` field, so the only user-facing description available is the input's placeholder text (default "Filter…", set via the `placeholder` prop); a consumer cannot pass an accessible name through this component's typed props.
- **Minimum touch target size**: Not guaranteed by the component. `.fl-item-button` (source: filtered-list.css) sets only `padding: 0.5rem 0.6rem` with no explicit min-height/min-width, so the rendered hit area depends on content length and any consumer CSS overrides; the component itself does not enforce a 44×44px minimum.

