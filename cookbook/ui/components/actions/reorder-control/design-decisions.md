
**Decision**: Render disabled buttons at the first/last row boundaries rather than removing them.
**Rationale**: Keeps the column width stable, preventing visual shift when navigating a list, and signals to users that the list has an order even when the current row cannot move (see **boundary-buttons-persist**).
**Approved**: pending

**Decision**: Use arrow icons (↑/↓), not chevrons, for the move actions.
**Rationale**: A deliberate departure from sibling controls like InlineCommitControl; chevrons mean disclosure elsewhere in these packages (e.g. TreeRowLabel), and a row that can both expand and reorder would otherwise carry two different metaphors as the same shape (see **arrow-icons**).
**Approved**: pending

**Decision**: Use aria-disabled, not the HTML disabled attribute, to signal the busy state.
**Rationale**: Borrowed from InlineCommitControl ([adhsdk.ingredient.ui.components.actions.inline-commit-control](cookbook:26df832c-a7f7-4cf6-b3f5-240c61e8bd68)) and preserves keyboard focus for users navigating via keyboard, letting them remain in the control sequence during an in-flight request without losing their place (see **aria-disabled-while-busy**). The [MDN aria-disabled reference](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-disabled) documents this focus-preserving behavior, in contrast to the native disabled attribute.
**Approved**: pending

