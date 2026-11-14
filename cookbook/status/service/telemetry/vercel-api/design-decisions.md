
**Decision**: One request primitive shared by Web Analytics and runtime logs.
**Rationale**: The header comment says both readers share the deploy poll's token, quota and 429 cooldown; one client keeps that policy in one place.
**Approved**: pending

**Decision**: Check the shared cooldown before every call, not only a load's first.
**Rationale**: The `vercelRequest` doc comment: several workers run at once, and without the per-call check one 429 leaves the rest hitting a throttled API, whose 429s push the cooldown further out.
**Approved**: pending

**Decision**: `signal` adds to the per-call timeout rather than replacing it.
**Rationale**: A caller deadline must not remove the 20-second ceiling; `AbortSignal.any` combines them.
**Approved**: pending

**Decision**: Return the raw `Response` from `vercelRequest`.
**Rationale**: A caller can stream a large body; `vercelGet` is the parsed variant.
**Approved**: pending

**Decision**: Cap project listing at 20 pages with no signal when it truncates.
**Rationale**: The source gives no reason for the number 20 and no signal when the cap is hit; it only bounds the page loop.
**Approved**: pending

**Decision**: Match the staging and testing suffix only at the end of the name.
**Rationale**: The `isProductionProject` doc comment: `testing-production` is the production site of a site about testing.
**Approved**: pending

**Decision**: Make `productionDomain` a first filter and fallback, not the answer.
**Rationale**: Aliases belong to the latest production deployment, so a queued deployment leaves only `*.vercel.app`; `loadVercelTraffic` asks the domains API for the real answer.
**Approved**: pending

