
**Decision**: Document `breadcrumbs.ts`'s and `nav.ts`'s private `titleCase`
helper once, as a single title-casing contract, rather than as two separate
requirements.
**Rationale**: The two functions are byte-for-byte identical (split on `-`,
uppercase only each word's first character, join with a space); treating
them as one shared behavior avoids stating conflicting requirements for what
is, in the source, unshared duplicated code — a maintenance liability worth
noting even though this recipe does not change it.
**Approved**: pending

**Decision**: Callers SHOULD memoize the `SearchIndex` passed into
`useSearchState`, and SHOULD memoize the `entries` array passed to
`createSearchIndex` and `buildNavTree`.
**Rationale**: `results-track-query`'s `useMemo` depends on the referential
identity of `index`; passing a newly constructed `SearchIndex` on every
render defeats that memoization and rebuilds the underlying Fuse instance on
every re-render, even though `index.query`'s selection of matches would be
identical either way. This is a caller-side performance recommendation, not
a contract the five sources themselves enforce.
**Approved**: pending

**Decision**: Preserve `intermediate-segment-nodes`'s exact reuse condition
(an existing child is only reused when it already has at least one child of
its own) rather than describing a simpler "reuse by label" rule.
**Rationale**: A leaf node that happens to share a label with a later
folder-shaped segment is not merged into it — the source creates a sibling
duplicate instead. This is the code's actual, traceable behavior, and
smoothing it into an idealized merge rule would violate source fidelity.
**Approved**: pending

