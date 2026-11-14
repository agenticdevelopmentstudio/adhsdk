
**Decision**: An added bundle id becomes a `TrackedApp` named by the id itself with the `editor` resolver.
**Rationale**: The preferences store only ids, so no display name or resolver kind is known; the source falls back to the id and to `editor`, and the test testRemovedDefaultIsNotAllowedAndAddedAppIs asserts the `editor` resolver.
**Approved**: pending

**Decision**: A removal wins over an addition, and an addition never overrides a default.
**Rationale**: The initializer filters defaults by the removed set and skips added ids that are known defaults or removed, so a default keeps its curated name and resolver.
**Approved**: pending

**Decision**: The lookup table keeps the first, in sorted order, of any duplicate bundle id while `apps` keeps all.
**Rationale**: The dictionary is built with a merge that keeps the first value instead of trapping on a duplicate; the shipped defaults are tested unique, so this protects only injected lists.
**Approved**: pending

**Decision**: Every app on the allowlist is recorded and anything else is never stored.
**Rationale**: The doc comment states the allowlist is the recording boundary, which keeps tracking limited to development apps.
**Approved**: pending

