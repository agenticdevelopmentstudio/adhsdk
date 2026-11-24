
**Decision**: The response is a set of independently cached sections plus a derived `views` object, instead of one finished document.
**Rationale**: The sections let the client show data as each provider answers; the views keep the shaping on the server so pages draw directly.
**Approved**: pending

**Decision**: Unknown, unreadable or short values are signalled with `null`, `incomplete`, `failed`, `truncated` and `complete` fields rather than being zero-filled or hidden.
**Rationale**: A zero would claim a count that was never read. The flags let a page show that a total is a floor instead of whole.
**Approved**: pending

**Decision**: The client keeps a hand mirror of these types, held to the server by a type-level parity test.
**Rationale**: The web client has the server only as a devDependency, so it cannot import the types at runtime; a type-level parity check holds the mirror to the server without that dependency. This is a known cost: the test runner transpiles without type-checking, so the mirror can drift without a failing test run.
**Approved**: pending

**Decision**: `sessions` in `TrafficSection.totals` sums per-bucket uniques.
**Rationale**: The total is the sum of the per-bucket series and not a distinct count.
**Approved**: pending

**Decision**: The errors response has a separate `refreshingSources` object besides `refreshing`.
**Rationale**: `refreshing` is true when either source is refreshing. GlitchTip and PostHog refresh independently, and a page can tell which is still filling in.
**Approved**: pending

**Decision**: The Vercel runtime section is read fresh from the store on every request and is not part of any cached view input.
**Rationale**: No view uses the runtime section, so it does not need to join the cached view inputs, and reading it fresh costs one store read.
**Approved**: pending

