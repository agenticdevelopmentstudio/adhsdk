
**Decision**: One `onToggle` callback, not separate `onAdd` and `onRemove` callbacks.
**Rationale**: The caller already knows which way the press goes — it supplied `mine`. A second
callback would let the two disagree and would push the same decision into every consumer.
**Approved**: pending

**Decision**: The bar holds no tallies itself.
**Rationale**: Optimistically mutating a count here would fork the truth: the server's answer
arrives moments later and the bar would have to reconcile a state it does not own. Keeping it
presentational is also what lets one component serve every subject kind.
**Approved**: pending

**Decision**: Announce the pressed state with `aria-pressed` rather than colour alone.
**Rationale**: The pressed/not distinction is the whole interaction; a border tint states it
only to people who can see it.
**Approved**: pending

**Decision**: The palette trigger is the `PopoverTrigger` primitive itself, styled directly, not
a `Button` wrapped in one.
**Rationale**: Wrapping a `Button` inside a `PopoverTrigger` nests two focusable elements;
styling the trigger directly is the sibling `OptionMenu` / `SectionHeader` idiom in this
package.
**Approved**: pending

**Decision**: `DEFAULT_REACTIONS` is exported and deliberately short.
**Rationale**: Exported so the default palette is one fact rather than a literal per surface;
short because a long grid is a picker, and a picker is a different component.
**Approved**: pending

**Decision**: `busy` disables controls rather than hiding them.
**Rationale**: Removing chips mid-write moves the pointer's target between the press and its
result.
**Approved**: pending

