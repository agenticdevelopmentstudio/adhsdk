
**Decision**: Set `tabIndex={-1}` on Flow's root `<main>` element instead of leaving it out of the focus API entirely.
**Rationale**: `tabIndex={-1}` (see **programmatic-focus**) makes `<main>` a valid target for a scripted `.focus()` call without adding it to the sequential (Tab-key) focus order, and Flow sets no height or overflow of its own, so scrolling stays the responsibility of the document or the nearest scrollable ancestor (see **no-scroll-ownership**). Every platform implementation MUST preserve both characteristics.
**Approved**: pending

