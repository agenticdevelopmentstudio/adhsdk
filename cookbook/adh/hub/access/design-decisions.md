
**Decision**: `ACCESS_FEATURES` is exported but `listFeatures` never consults it.
**Rationale**: The source's comment frames it as a degraded path for a backend that predates
the features route and warns that the authoritative registry is per-deployment. Keeping
`listFeatures` strict leaves the fallback decision to the caller and stops a real
response mismatch from looking like an old backend.
**Approved**: pending

**Decision**: `restrictItem` and `restoreItem` use `authedJson` although they are declared
`Promise<void>`, so a 204 throws.
**Rationale**: Recorded as observed behavior, not smoothed into the declared type. A port
preserves it rather than switching to `authedRequest`, because the backend's actual response
for these routes is outside this checkout.
**Approved**: pending

**Decision**: Only `listFeatures` validates its response at runtime; `listRoles`,
`listAssignments`, `listSubjects` and `effective` rely on the typed cast or a plain mapping.
**Rationale**: The `isAccessFeatureRow` comment explains the guard was added after a bare
cast let a malformed features response look like real data. No equivalent fix exists for the
other reads, so the asymmetry is recorded as fact.
**Approved**: pending

**Decision**: `listFeatures` rejects `has_more: true` instead of paging.
**Rationale**: It asks for the widest page (100) and treats a longer registry as malformed, so
the roles matrix never renders a silently truncated set of columns.
**Approved**: pending

**Decision**: `putAssignment` does not check that `feature` and `itemId` are given together.
**Rationale**: The field's comment states the pairing and the client leaves enforcement to the
backend, whose handling of a half-scoped write is outside this checkout. A client guard or a
discriminated input type would close the gap.
**Approved**: pending

**Decision**: `accessTargetKey` keeps the `workspace:<slug>` prefix for workspace targets.
**Rationale**: The source's comment says panes that share an entry, such as the roles list,
must keep sharing it after ecosystem targets were added.
**Approved**: pending

