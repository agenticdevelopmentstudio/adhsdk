
**Decision**: The response is a set of independently cached sections plus a derived `views` object, instead of one finished document.
**Rationale**: `AnalyticsDashboardResponse.views` is described as "what the pages draw, derived from `sections` on the server". The sections let the client show data as each provider answers; the views keep the shaping on the server so pages draw directly.

**Approved**: pending

**Decision**: Unknown, unreadable or short values are signalled with `null`, `incomplete`, `failed`, `truncated` and `complete` fields rather than being zero-filled or hidden.
**Rationale**: The roster comment says a null count "is not a zero". The flags let a page show that a total is a floor instead of whole.

**Approved**: pending

**Decision**: The client keeps a hand mirror of these types, held to the server by a type-level parity test.
**Rationale**: The comment says status-web has the server only as a devDependency, and that the parity test is a typecheck "that catches drift: `pnpm test` transpiles without checking types". This is a known cost: the mirror can drift without a failing test run.

**Approved**: pending

**Decision**: `sessions` in `TrafficSection.totals` sums per-bucket uniques.
**Rationale**: The field comment states "a session spanning two buckets counts twice". The total is the sum of the per-bucket series and not a distinct count.

**Approved**: pending

**Decision**: The errors response has a separate `refreshingSources` object besides `refreshing`.
**Rationale**: The comment says "`refreshing` is either of them". GlitchTip and PostHog refresh independently, and a page can tell which is still filling in.

**Approved**: pending

**Decision**: The Vercel runtime section is read fresh from the store on every request and is not part of any cached view input.
**Rationale**: The `dashboard-set.ts` comment says "Runtime is read fresh every request and no view uses it, so it is not an input".

**Approved**: pending

