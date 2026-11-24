
**Decision**: List and ListItem manage no internal state and enforce no content structure.
**Rationale**: Simplicity and reusability; state management is left to parent components.
**Approved**: pending

**Decision**: Both components forward all remaining props to their underlying HTML element.
**Rationale**: Allows flexible composition and styling without a bespoke prop API.
**Approved**: pending

**Decision**: Use `data-slot` attributes (`data-slot="list"`, `data-slot="list-item"`) instead of a class-based API.
**Rationale**: Follows the shadcn `data-slot` convention that parent selectors and tests rely on, so they can target a component without depending on its Tailwind classes.
**Approved**: pending
**Decision**: The List component does not add `role="list"` itself; consumers who need it pass it through the forwarded props.
**Rationale**: Safari/VoiceOver drops list semantics on a flexed `<ul>`, but a default `role="list"` would override the element's implicit role for every caller, including ones that pass their own `role` (see **prop-forwarding**). The component stays a plain wrapper and the Accessibility section tells consumers when to add it.
**Approved**: pending
