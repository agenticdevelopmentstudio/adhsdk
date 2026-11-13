
**Decision**: Retry covers 429, every 5xx, a 403 that names a rate limit, and four transient network codes; every other status and error fails at once.
**Rationale**: The doc comment on `isRateLimited` states that Gmail reports an exceeded quota as a 403 as well as a 429, and "any other 403 is a real refusal and is not retried". Retrying a permission 403 would only delay a failure that cannot succeed.
**Approved**: pending

**Decision**: Backoff starts at 1 second, doubles and is capped at 32 seconds, with 6 retries.
**Rationale**: The class comment says the retries should "span the minute Gmail's quota is counted over": 1+2+4+8+16+32 is 63 seconds. A `Retry-After` value is honoured but also capped at 32 seconds, so a server asking for a longer wait is not obeyed.
**Approved**: pending

**Decision**: The pacer is consulted before every attempt, retries included, and cost is reserved before the request goes out.
**Rationale**: The class comment says each attempt reserves its cost so "a sync stays under Gmail's per-user rate limit instead of tripping it"; a retry spends quota too. The pacer and the sleep function are injected so tests drive time.
**Approved**: pending

**Decision**: `Retry-After` is read only as whole seconds; an HTTP-date is ignored.
**Rationale**: The code parses the header with `Int(...)` after trimming, so any other form falls back to exponential backoff. A port that honoured dates would wait differently from the source.
**Approved**: pending

**Decision**: Technical debt: the access token is read once per call and reused for every retry.
**Rationale**: The request is built before the retry loop, so a token that expires during up to 63 seconds of backoff plus pacing is not renewed for that call, and a 401 is thrown instead of retried. Whoever supplies the closure owns refreshing. The class comment says the closure supplies a fresh token "per request", which holds per call, not per attempt.
**Approved**: pending

**Decision**: `batchModify` rejects an empty or oversized list with status 0 and leaves chunking to the caller.
**Rationale**: The source comment calls such a list "a caller bug, not a Gmail call". Status 0 marks an error raised locally rather than returned by Google. `MailIntegrationService` chunks by `batchModifyLimit`.
**Approved**: pending

**Decision**: A 404 from `history` becomes `GmailCursorExpired`, and an id both changed and deleted is reported only as deleted.
**Rationale**: The `GmailCursorExpired` doc comment says a 404 means the cursor is older than Gmail keeps and a full sync is needed. Reporting a deleted id as changed would make the engine fetch a message that no longer exists. Label additions and removals count as changes because they alter the stored message.
**Approved**: pending

**Decision**: Listing ids are deduplicated in first-seen order.
**Rationale**: The source applies `unique` without saying why, and test `listMessageIdsDedupesAndToleratesEmpty` fixes the behavior; a port must keep it. The reason is not recorded in the source.
**Approved**: pending

**Decision**: A decode failure, a non-HTTP response and a URL failure are not retried. Technical debt: a decode failure is thrown as a `DecodingError` rather than an `IntegrationError`.
**Rationale**: Only a failure that a later attempt could change is retried. The inconsistent error type is what the code does, so a caller catching only `IntegrationError` misses a malformed success body. A port should wrap it as `IntegrationError.gmail(status: <code>, ...)` so one catch covers every failure.
**Approved**: pending

**Decision**: The client sets no timeout and has no cancellation handling beyond `Task.sleep` and the `URLSession` default.
**Rationale**: Nothing in the source configures a `timeoutInterval`, so timeouts come from the injected session and surface as retried `timedOut` errors. Behavior on a stalled connection is the session's.
**Approved**: pending

**Decision**: `batchModify` is retried like every other call, although it is a POST with no idempotency key.
**Rationale**: Adding or removing a label that is already in that state changes nothing in Gmail, so a repeat after a lost reply or a 5xx leaves the same end state as one application. The code retries on 429, 5xx, rate-limit 403 and the four transient network errors without a separate rule for this call. An operation that is not idempotent in a port must be excluded from network-error retries.
**Approved**: pending

**Decision**: Ids interpolated into `threads/<id>` and `messages/<id>` are not validated or percent-encoded.
**Rationale**: The ids come from Gmail's own listing and history responses, which are opaque hexadecimal strings, so the source trusts them; an id such as `a/b` would change the route instead of failing. Input sanitization is therefore partial in Compliance. A port may encode the segment, at no cost to ids Gmail issues.
**Approved**: pending

**Decision**: The client never logs and offers no retry or backoff hook.
**Rationale**: The source has no log call and no callback, so a stalled call of up to about 63 seconds of backoff shows nothing to an observer, and the token and query cannot leak into a log. Anyone who needs visibility injects a `sleep` closure that records each wait, which is how the tests observe retries. A port that adds a retry event must leave out the token and the query.
**Approved**: pending
