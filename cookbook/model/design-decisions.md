
**Decision**: Document `breadcrumbs.ts`'s and `nav.ts`'s private `titleCase`
helper once, as a single title-casing contract, rather than as two separate
requirements.
**Rationale**: The two functions are byte-for-byte identical (split on `-`,
uppercase only each word's first character, join with a space); treating
them as one shared behavior avoids stating conflicting requirements for what
is, in the source, unshared duplicated code — a maintenance liability worth
noting even though this ingredient does not change it.
**Approved**: pending

**Decision**: Preserve `intermediate-segment-nodes`'s exact reuse condition
(an existing child is only reused when it already has at least one child of
its own) rather than describing a simpler "reuse by label" rule.
**Rationale**: A leaf node that happens to share a label with a later
folder-shaped segment is not merged into it — the source creates a sibling
duplicate instead. This is the code's actual, traceable behavior, and
smoothing it into an idealized merge rule would violate source fidelity.
**Approved**: pending

