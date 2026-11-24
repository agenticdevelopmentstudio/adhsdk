
**Decision**: Visual appearance is delegated entirely to CSS (base classes `lp-screen` and `lp-screen--center`) rather than exposed through component props.
**Rationale**: Keeps component logic minimal and lets host applications customize styling without modifying the component code.
**Approved**: pending

**Decision**: `glow` is an optional boolean prop (default `false`) rather than leaving ordering to the host.
**Rationale**: Placing a `<Glow />` before or after Screen's other children is order-sensitive; making `glow` a prop lets Screen guarantee the correct order automatically. The default is `false` because lighting every screen in a deck is a host-level design decision, not a component default.
**Approved**: pending

**Decision**: The `as` prop lets Screen render as either a landmark (`<section>`) or a generic container (`<div>`).
**Rationale**: Gives the host control over information architecture without requiring an extra wrapper element around Screen.
**Approved**: pending

