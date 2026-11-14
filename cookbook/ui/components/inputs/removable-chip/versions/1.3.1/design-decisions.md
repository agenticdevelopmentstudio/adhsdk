
**Decision**: Use a real `<button type="button">` for the ✕, not a clickable icon.
**Rationale**: An `aria-label`-carrying native button gives keyboard operability and a clear accessible name for free — a bare icon with an `onClick` would be invisible to AT and keyboard users.
**Approved**: pending

**Decision**: Reuse `Badge` for the chip body instead of restyling.
**Rationale**: The chip body is the shared `Badge`, so it inherits every tone and the established pill styling; the recipe adds only `flex items-center gap-1` and the trailing button, keeping one source of truth for chip appearance.
**Approved**: pending

**Decision**: Make the component stateless.
**Rationale**: The chip signals `onRemove` and nothing else; the consumer owns the list. This keeps the element reusable across any input that lets users remove items from a list, without baking in a list model.
**Approved**: pending

**Decision**: Centralize the badge-plus-✕ treatment in one component.
**Rationale**: Every caller that needs removable items shares identical removal semantics and accessibility rather than each re-deriving them.
**Approved**: pending

