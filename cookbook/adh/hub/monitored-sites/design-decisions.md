
**Decision**: `createSite` builds its body as a plain object literal (`{ name, slug, site_group_id:
body.groupId }`) rather than passing it through `compact()`, even though `createGroup` and
`createEndpoint` both do.
**Rationale**: `CreateSiteBody`'s three fields are all required (unlike `CreateGroupBody.retentionDays`
or `CreateEndpointBody`'s optional fields), so `compact()` would be a no-op here; the source omits the
call rather than applying it unconditionally for consistency.
Platform scope: Web — this is a detail of this platform's own implementation of the body-compaction
helper, not a behavior a port needs to reproduce beyond the observable request body.
**Approved**: pending

**Decision**: the module's own top-of-file comment states "the client-side narrowing in
`listSites()`/`listEndpoints()` stays as defense-in-depth," but `listSites`'s current implementation
performs no owner/workspace filter — only a `sortByText` by name.
**Rationale**: `listSites`'s own inline comment explains the server now owner-scopes `sites` identically
to `site_groups`, and the earlier client-side intersection (against the groups list) was removed
specifically because it round-tripped an extra request and hid rows whose group fell past a capped groups list; the top-of-file
comment appears to predate that refactor and was not updated to drop the `listSites()` half of its claim.
This recipe records the code as it actually behaves — no client-side owner narrowing in `listSites` — per
the source-fidelity guideline's requirement to describe the code as it is rather than as a stale comment
describes it.
**Approved**: pending

**Decision**: `listEndpoints` sends no site filter and narrows by `siteId` on the client, over the whole
endpoints collection.
**Rationale**: the /v1 endpoints collection declares no `site_id` filter, so the only way to return one
site's endpoints is to page the full owner-scoped collection through the shared paging helper and filter
the mapped rows; every operation builds its URL through the same `scoped()`/`withV1Query` helper, so the
workspace pin is uniform. A port reproduces the request and the client-side filter, not the helper names.
**Approved**: pending

**Decision**: endpoint `kind` is not validated client-side against the fixed set of valid endpoint kinds before create or update; an unknown kind is sent to the backend as given.

**Rationale**: a shared value-narrowing helper exists for exactly this purpose but neither operation calls it, and whether the backend rejects an unknown kind is not visible in this checkout; closing the gap would take narrowing `kind` through that helper (or a union type) in both operations.

**Approved**: pending

