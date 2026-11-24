
**Decision**: Set `tabIndex={-1}` on Flow's root `<main>` element instead of leaving it out of the focus API entirely.
**Rationale**: `tabIndex={-1}` (see **programmatic-focus**) makes `<main>` a valid target for a scripted `.focus()` call without adding it to the sequential (Tab-key) focus order.
**Approved**: pending

