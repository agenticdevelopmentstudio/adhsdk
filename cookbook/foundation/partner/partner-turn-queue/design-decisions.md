
**Decision**: Coalescing replaces the older entry in place rather than dropping the new event or moving it to the back.
**Rationale**: The partner needs the newest payload (for example the latest tick summary) but should still see it where the first occurrence was queued, so a chatty source cannot reorder or flood the queue; the source comment states "it keeps the position and takes the newer payload".
**Approved**: pending

**Decision**: `enqueueFirst` bypasses coalescing.
**Rationale**: The source doc comment says it is "for a notice the partner must read before any waiting event"; the owner uses it for a `started` notice and for re-sending an interrupted turn, which must not be merged into or replaced by an older entry.
**Approved**: pending

**Decision**: Coalescing keys live on `PartnerInbound`, not on the queue, and owner messages and lifecycle notices have no key.
**Rationale**: Each owner message is distinct intent and each lifecycle notice marks a separate moment, so only repeatable status events (ticks, idle, exit) collapse.
**Approved**: pending

**Decision**: The queue has no capacity limit and no thread safety of its own.
**Rationale**: Coalescing already bounds repeatable events, and the sole owner is `@MainActor`, so synchronisation is the owner's isolation, not the struct's.
**Approved**: pending

