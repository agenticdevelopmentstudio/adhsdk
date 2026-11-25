
- **Signed out**: Both read states take `enabled: false`; the every-row read
  state issues no request (workspace-switching-002) and the preference read
  state reads nothing and reports `slug: null` (workspace-switching-012).
- **Two copies of the package**: A host that bundles its own copy announces
  with an event this copy did not send. That copy's direct invalidation
  reached its own client, so this copy's subscription sweeps this client
  once (workspace-switching-005); this copy's own announcements add no
  second sweep (workspace-switching-004).
- **Concurrent readers**: The header menu, the rail and a gate can all read
  at once; they share one entry and one subscription per client
  (workspace-switching-004). JavaScript runs these on one thread, so the
  reader count needs no further ordering.
- **Duplicate slugs**: A personal workspace and a team, or an organization
  and a team, can share a slug, and two teams under different owners share
  a composite id. The first-per-slug helper keeps only the row a bare
  `/<slug>` opens (workspace-switching-010); a menu that needs unique ids
  runs it first.
- **Blank names**: The backend names a personal workspace `displayName ??
  slug`, so a display name saved as `''` arrives as `''`; the list-label
  helper still returns a name (workspace-switching-009).
- **Stale browser cache**: A sign-in, sign-out or another tab can rewrite the
  cached slug while a preference reader is mounted; the seed is re-read
  each render, so a previous session's slug does not linger
  (workspace-switching-013).
- **A row with no slug, or a slug outside the list**: A row of `{}` (a
  caller who never chose) reports `slug: null`. A slug the caller no longer
  has is reported as is; the consumer decides what it means.
- **Failed reads and writes**: A failed every-row read surfaces on the query
  result, unretried. A failed preference read keeps the seed and settles. A
  failed preference write is dropped silently with the choice standing in
  both caches.

