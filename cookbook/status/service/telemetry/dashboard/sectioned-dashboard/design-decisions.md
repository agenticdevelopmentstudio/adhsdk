
**Decision**: `read` never waits; it returns what is known and starts a refresh when one is due.
**Rationale**: The source comment explains the cold dashboard can take a minute, which is past the rewrite proxy's limit, and holding a request open would delay sections that could already be on screen. Each section publishes as it finishes and the client polls while `refreshing`.
**Approved**: pending

**Decision**: Refreshes are driven by reads, not timers.
**Rationale**: The source comment states "an idle dashboard costs no provider quota". A timer would keep calling PostHog and Vercel whether or not anyone is looking.
**Approved**: pending

**Decision**: Each section has its own schedule, and a refresh re-runs only due sections.
**Rationale**: The source comment says one failing section is retried on its own "rather than dragging every healthy one back to the provider with it".
**Approved**: pending

**Decision**: Failure backoff doubles from `retryMs` up to `ttlMs`.
**Rationale**: The source comment says retries back off "rather than hitting a provider that keeps failing once a minute for as long as it fails". A one-off blip costs `retryMs` and not a whole TTL; the doubling stops at the TTL so a failing section is never retried less often than a healthy one.
**Approved**: pending

**Decision**: A failed section keeps its last good `data` and `updatedAt`, and only `error` changes.
**Rationale**: The `DashboardSection` comment says the last good answer "survives a later failure, so stale data stays on screen".
**Approved**: pending

**Decision**: An `incomplete` answer is published as a success with no error but is retried on the failure schedule.
**Rationale**: The option comment says it is "shown but known to be short (some of its calls failed)". The partial data is still useful on screen; holding it for the whole TTL would leave a chart flat after one project timed out.
**Approved**: pending

**Decision**: Sections run strictly one after another by default.
**Rationale**: The source comment says PostHog's API 503s under concurrency. Sections therefore queue unless the caller opts into a higher `concurrency`.
**Approved**: pending

**Decision**: `settle` exists apart from `read` and never starts a refresh.
**Rationale**: The `settle` comment says a server-side reader such as `/report` must not push the polling that `read` implies onto its own client; it reads, settles, and reads again.
**Approved**: pending

**Decision**: State per key is kept forever, so keys must come from a bounded enum.
**Rationale**: Stated in the source header comment. Bounded keys (the analytics ranges, or the single key `all`) keep the map small without an eviction policy.
**Approved**: pending

**Decision**: A `loaders` builder that throws counts as a failure of every due section that did not settle.
**Rationale**: The source comment says this lets such sections be "retried rather than left due on every read"; without it a throwing builder would be called on every read.
**Approved**: pending

