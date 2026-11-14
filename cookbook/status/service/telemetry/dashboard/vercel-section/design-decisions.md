
**Decision**: Only production projects are read, and a project whose real domain is `staging.` or `testing.` is dropped after the domain lookup.
**Rationale**: `isProductionProject` explains that every site is three Vercel projects (`x-production`, `x-staging`, `x-testing`) and analytics runs only on the first, so the other two are not sites to report on. The domain check catches projects whose name does not follow the pattern (the project named `odd-name` in the test "drops a project whose real domain turns out to be staging").

**Approved**: pending

**Decision**: The domain comes from the domains API first and the production alias second.
**Rationale**: The domain joins Vercel's numbers to PostHog's, and the test comment says it "can't depend on whether the project happens to be mid-deployment, when its aliases are only `*.vercel.app`".

**Approved**: pending

**Decision**: Counts run for every enabled project, but breakdowns only for projects with traffic.
**Rationale**: The header comment says most projects have none, and the breakdowns cost five calls per project.

**Approved**: pending

**Decision**: `aggregate` sends `limit` 100.
**Rationale**: The constant's comment says 100 is the API's maximum and the default of 10 "would cut a 30-day series short".

**Approved**: pending

**Decision**: Hourly windows send instants, daily windows send dates.
**Rationale**: The `windowParams` comment says the API takes dates for whole days and "hourly needs instants or it can't tell the hours apart".

**Approved**: pending

**Decision**: The `"Others"` row is dropped from the breakdown lists.
**Rationale**: The `shapeMarginal` comment says it is not a page or a country and "cannot be summed across projects as if it were the same thing".

**Approved**: pending

**Decision**: A failed breakdown is `incomplete`, not `failed`.
**Rationale**: A source comment says "Not `failed`: this project's count is in the totals. What is short is its series and lists." The two counters let the dashboard say which numbers are short.

**Approved**: pending

**Decision**: A 429 ends the whole load instead of being recorded per project.
**Rationale**: `VercelRateLimited` is documented as ending a whole read because every further call would 429 too. The loader rethrows it from the breakdown phase because `Promise.allSettled` would otherwise hide it, and each call checks the cooldown so workers already running stop making new calls.

**Approved**: pending

**Decision**: When every count fails, the section throws instead of returning zeros.
**Rationale**: A section of zeros would look like a real quiet day. A thrown error keeps the last good data on screen and shows the error, which is the sectioned-dashboard contract.

**Approved**: pending

**Decision**: Totals sum only projects that had traffic, while the roster shows every listed project.
**Rationale**: The totals are computed over the projects with breakdowns; a project with count 0 adds nothing to a sum either way, and the roster is where a quiet or disabled project still appears (with 0 or null).

**Approved**: pending

**Decision**: The loader does not retry calls.
**Rationale**: Retry belongs to the sectioned-dashboard cache, which schedules the next attempt with backoff when `failed` or `incomplete` is above 0. Retrying inside would spend more of a shared token quota.

**Approved**: pending

