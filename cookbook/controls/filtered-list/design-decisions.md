
**Decision**: The input is wrapped in a `<form role="search">`.
**Rationale**: This addresses a Safari iOS 26 autofill scoping issue: without a form ancestor, Safari classifies an orphan input field against the entire document and offers the user's contact card as an autofill suggestion, which is undesired. The form is a plain block in `.fl-root`'s column flex and has no visual impact on layout; onSubmit prevents form submission since Enter is already handled by the input's onKeyDown.
**Approved**: pending

**Decision**: onHighlightChange is tracked by item reference, not index, and the callback itself is held in a ref.
**Rationale**: Consumers commonly pass an inline callback; depending on it directly would re-fire the effect on every parent render. Holding the callback in a ref and comparing the resolved highlighted item by reference means the callback fires only when the actual item reference changes — this is reference-equality change detection, not debouncing (no timer is involved) — reducing unnecessary invocations.
**Approved**: pending

**Decision**: ArrowUp on the first highlighted item clears the highlight (index = -1) rather than wrapping to the last item.
**Rationale**: This lets the user escape the list via keyboard and return to the query/input state, rather than cycling back into the list.
**Approved**: pending

**Decision**: Highlight state is local to the component, and the highlighted item's title replaces the query text in the input while highlighted.
**Rationale**: This gives immediate visual feedback about which item Enter would select.
**Approved**: pending

**Decision**: Items are rendered as clickable buttons only when onSelect is provided; without it, items are static (non-button) list content.
**Rationale**: This lets the component serve display-only scenarios where selection is not needed, without forcing button semantics on non-interactive content.
**Approved**: pending

