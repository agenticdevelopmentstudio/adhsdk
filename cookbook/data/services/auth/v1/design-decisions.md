
**Decision**: `listAllV1` is the only function that walks a collection; callers do not loop `starting_after` themselves.
**Rationale**: The module header states it is the one place that does, so the cursor and `has_more` handling lives once and a fix reaches every caller.
**Approved**: pending

**Decision**: `listAllV1` throws when `has_more` is true and the last row has no id, instead of returning what it has.
**Rationale**: The gateway pages by id, so a row with no id cannot advance the cursor; the doc comment says it throws "rather than returning a silently truncated list", trading a visible failure for an invisible data loss.
**Approved**: pending

**Decision**: `listAllV1` requests the maximum page size of 100 on every page and overwrites a caller-supplied `limit`.
**Rationale**: Fewest round trips for a full walk; the page size is fixed by `V1_PAGE_MAX`, the widest page the gateway serves, so a caller wanting a smaller page uses `listV1Page`.
**Approved**: pending

**Decision**: `withV1Query` deletes a key before setting or appending it, which replaces a repeated key and moves it to the end of the query.
**Rationale**: The doc comment says a key already in the URL is replaced so a cursor can be advanced on a URL that carries one; the delete-then-set order makes that true for arrays as well. The side effect is reordering, noted by query-preserves-existing-order.
**Approved**: pending

**Decision**: Malformed page bodies degrade to empty pages instead of throwing.
**Rationale**: `Array.isArray(page?.data)` guards and `has_more === true` in `listV1Page` make the helpers tolerant of a null or malformed body. The cost is that a broken gateway response looks like an empty collection; the source does not report it. The `has_more === true` strict check in `listV1Page` differs from the truthiness check in `listAllV1`, so a truthy non-boolean `has_more` such as `'true'` continues the walk in `listAllV1` but reports `hasMore` false in `listV1Page`.
**Approved**: pending

**Decision**: `unixToIso` is overloaded so a plain number returns a string and a nullable input returns a nullable string, and it maps non-finite input to `null` rather than throwing.
**Rationale**: Optional `/v1` timestamps (`updated` may be absent) can be converted in one call. The range `RangeError` is left uncaught, so the null mapping covers missing or non-finite values only.
**Approved**: pending

**Decision**: The module has no timeout, page cap, retry or cancellation of its own.
**Rationale**: Transport concerns belong to `authedJson` and the caller's `init`; the one refresh-and-retry on a 401 comes from there. A caller needing a deadline passes an `AbortSignal` in `init`.
**Approved**: pending

**Decision**: The module is documented against `adh`'s Stripe-shaped `/v1` API, and the matching server conventions (DELETE tombstone, `include[]` expansion) are described but not implemented here.
**Rationale**: `V1Deleted` and the `include[]` convention are declared for client use; the gateway owns their server side, and `withV1Query` is the client half of `include[]`.
**Approved**: pending

