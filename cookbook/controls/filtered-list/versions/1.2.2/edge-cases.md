
- **Empty item list** (total === 0): Component displays "No items." text and does not render the list element. No keyboard navigation occurs (see **empty-state-when-no-items**).
- **No visible items after filter** (total > 0, visible.length === 0): Empty state message is displayed — custom emptyContent if provided, otherwise the default `No matches for "{query}".` message (see **default-no-matches-message**, **custom-empty-content**).
- **Query is empty string or only whitespace**: Filtering is cleared; all items are visible. Input shows the query text, not a highlighted item's title, until an item is highlighted via keyboard or mouse.
- **Highlight index exceeds visible array**: When visible.length shrinks, highlightedIndex is automatically clamped to the last visible index or -1 if empty (see **clamp-highlight-when-visible-shrinks**).
- **Keyboard navigation with no visible items**: Arrow keys, Enter, and Escape do nothing; the handler returns early without calling preventDefault (see **arrow-keys-noop-when-no-items**).
- **Mouse hover while item is already highlighted via keyboard**: Hover changes highlight to the hovered item; onHighlightChange is called.
- **Escape when no item is highlighted**: No action; default is not prevented.
- **Enter when no item is highlighted**: onSelect is not called and the input's own keydown handler does not call preventDefault; the form's onSubmit still prevents the browser's default submission unconditionally (see **enter-selection**, **prevent-form-submission**).
- **Rapid query changes**: onHighlightChange is only invoked when the resolved highlighted item's reference actually changes between renders, not on every render — tracked via a ref, not a timer, so this is reference-equality change detection rather than debouncing.
- **scrollIntoView unavailable**: Component checks `typeof el.scrollIntoView === 'function'` before calling; if unavailable, the item is not scrolled into view but navigation continues.

