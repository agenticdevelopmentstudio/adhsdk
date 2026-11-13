
**Decision**: Take the history baseline from the profile before listing, and return it as the full sync's cursor.
**Rationale**: The source comment says it is "Taken before listing, so a change made while listing is replayed by the next incremental sync." A baseline read after listing could skip a change made during the listing. The cost is that the next incremental sync may replay a few changes the listing already saw, which is harmless because upserts are idempotent.
**Approved**: pending

**Decision**: Store and tombstone a full sync batch by batch, and tombstone only after the whole pass.
**Rationale**: The doc comment says this lets "a long first sync keep what it has fetched if it fails partway". Tombstoning from a partial listing would wrongly delete rows that were simply not reached. The price is that a failed first sync leaves a partial mirror with no cursor, and the next run repeats the full pass.
**Approved**: pending

**Decision**: Write the cursor and status once, only on success, and leave recording failures to the caller.
**Rationale**: The doc comment on `sync` states it persists them "once, on success". An unchanged cursor on failure means the next run replays the same history or repeats the same full pass. `MailIntegrationService.record` sets the `error` or `revoked` status and skips it for cancellation, which keeps that policy in one place.
**Approved**: pending

**Decision**: The incremental pass also tombstones rows the window has moved past.
**Rationale**: The doc comment says this is done "as a full sync does, so the window bounds what is kept in steady state — a full sync runs only when the cursor is missing or expired." Without the sweep, a row would stay until a full sync ran, which in steady state is almost never.
**Approved**: pending

**Decision**: The incremental pass tombstones a changed message that falls outside the window or the allowed classes, and one Gmail no longer has, rather than ignoring it.
**Rationale**: A message that became archived, or whose date or class no longer qualifies, must leave the mirror. The 404 case covers a message deleted after history was written. The tests `incrementalTombstonesMessageThatBecameArchived` and `incrementalTombstonesOutOfWindowChange` pin this.
**Approved**: pending

**Decision**: Fetch eight messages at a time and store in batches of 100.
**Rationale**: The numbers are `fetchConcurrency` and `upsertBatchSize`; the source does not state why. Eight is small enough to stay modest against Gmail's per-user quota, which `GmailRESTClient` also paces, and 100 bounds how much a partial failure can lose, because the stored count is a multiple of the batch size. Whether eight is the best number is outside the source.
**Approved**: pending

**Decision**: Batch results in completion order, and never in id order.
**Rationale**: The fetch refills the group as soon as any task ends, so a slow message does not hold up the others. The cost is that batch contents vary between runs, which the failure test accounts for by asserting a multiple of 100 rather than exact ids.
**Approved**: pending

**Decision**: Pass `existingId: nil` to the parser and let the store keep the local id.
**Rationale**: The source comment says "The store keeps the local id of a row that already exists." This keeps the worker from reading each row before it fetches, and `resyncKeepsLocalId` pins the result.
**Approved**: pending

**Decision**: The worker does not serialise overlapping syncs, retry, pace, or log.
**Rationale**: Per-connection serialisation, status recording and scheduling live in `MailIntegrationService`; retry, backoff and pacing live in `GmailRESTClient` and `GmailQuotaPacer`. Keeping the worker free of them keeps it testable against a fake API with a fixed clock. A port must put these concerns in the same owners.
**Approved**: pending

**Decision**: Technical debt: the clock is read separately for the query, the fetch, the window start and the stored time.
**Rationale**: The worker calls `now()` several times per run, so on a long run the window start used for the final sweep is later than the one in the query. It is harmless in the tests because the clock is fixed, and the effect is a window that drifts a little during one run. A port may read the clock once, but it should record that as a deliberate change.
**Approved**: pending

