
**Decision**: Keep the rules apart from the fetcher and the store.
**Rationale**: The header comment says each is then testable alone, and the store and the route share one copy of every rule.
**Approved**: pending

**Decision**: Each read replaces the stored groups instead of accumulating.
**Rationale**: Per the header comment, a group's count is then its count in the 24-hour window and nothing is deduplicated across reads.
**Approved**: pending

**Decision**: Group by message shape (ids read `:id`, digit runs read `#`) and normalized path.
**Rationale**: `Order 8231 not found` and `Order 8270 not found` are one error; without it every occurrence is its own group. The test "a message that embeds an id, number or timestamp is one error" records the case of 40 requests.
**Approved**: pending

**Decision**: Take the shape from the whole first line, then cut to 200 characters.
**Rationale**: A number of varying length would move the cut and split one error into a group per occurrence (comment in `groupIdentity`).
**Approved**: pending

**Decision**: Do not re-window groups against the clock.
**Rationale**: Per the `runtimeErrorsReport` comment, a reader whose reads fail should see old groups dated as old rather than watch them disappear.
**Approved**: pending

**Decision**: Treat an unknown level as below every known one (`-1`).
**Rationale**: A new Vercel level must not outrank `fatal`; the test `worseLevel("error","mystery")` returns `error`.
**Approved**: pending

**Decision**: Only a path segment with a digit counts as a hex or token id.
**Rationale**: Test `/about/facebook-account` stays a word while `/blob/deadbeef1234abcd` reads `:id`; words that happen to be hex letters must not be hidden.
**Approved**: pending

