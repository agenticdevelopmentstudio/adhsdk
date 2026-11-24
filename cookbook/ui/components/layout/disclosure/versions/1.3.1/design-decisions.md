
**Decision**: Support both controlled and uncontrolled open state, via an optional `open`/`onOpenChange` pair layered over an internal `useState`.
**Rationale**: Simple cases need no wiring; callers that must observe or drive the state can pass `open`/`onOpenChange` instead.
**Approved**: pending

**Decision**: Render `actions` outside the toggle `<button>`.
**Rationale**: Per-section buttons stay in the header without toggling the section, avoiding a surprise state change when a user clicks an action (principle of least astonishment).
**Approved**: pending

**Decision**: Unmount collapsed children instead of hiding them.
**Rationale**: Collapsed children leave the DOM so they hold no hidden tab stops; the trade-off is that any uncommitted state inside them resets each time the section closes (see Edge Cases).
**Approved**: pending

**Decision**: Implement the toggle as a hand-rolled `<button>` with conditional rendering rather than native `<details>`/`<summary>`.
**Rationale**: The component must support a fully controlled mode that reflects an external `open` prop without mutating internal state, and must unmount rather than hide its children when closed; native `<details>` ties its open state to the DOM `open` attribute and keeps collapsed content in the tree, which fights both requirements without extra imperative sync code.
**Approved**: pending

