
**Decision**: Separate the user's layout preference from the effective layout shown on screen.
**Rationale**: This allows the user's choice to be remembered and restored when the viewport widens, rather than silently demoting to a one-pane experience and losing the choice. This design reduces cognitive friction: the user doesn't have to re-select split after rotating their device or resizing their window.
**Approved**: pending

**Decision**: Ignore the empty array the underlying ToggleGroup emits when a user clicks an already-selected toggle item, by checking `if (picked)` before updating state.
**Rationale**: This implements a segmented control pattern where selection is always maintained, rather than a toggle pattern where clicking twice returns to a deselected state.
**Approved**: pending

**Decision**: Do not render the layout toggle at all on narrow viewports (using a conditional `{wide &&}`), rather than rendering it and disabling it.
**Rationale**: This follows the principle that an affordance you can see but never use (a disabled button) is worse than no affordance at all. Users on small screens see a smaller, simpler control.
**Approved**: pending

**Decision**: Render the separator only when both the layout toggle (wide viewport) and pane toggle (tabbed mode) are visible.
**Rationale**: This visually groups the two controls. In split mode, no pane toggle is needed, so no separator appears.
**Approved**: pending

**Decision**: Point each pane toggle item's `aria-controls` at the container element that wraps both panes, not at the individual pane elements.
**Rationale**: In tabbed mode, only one pane is mounted at a time; an `aria-controls` reference to the hidden pane would be a dangling reference (ignored by assistive technology). Pointing to the container keeps the relationship always valid.
**Approved**: pending

**Decision**: Require a `subject` parameter so that accessible names are context-specific (e.g., "Editor layout" vs. "Document layout").
**Rationale**: This avoids generic, unhelpful labels when multiple SplitViewControls appear on the same page. The host must provide this context.
**Approved**: pending

