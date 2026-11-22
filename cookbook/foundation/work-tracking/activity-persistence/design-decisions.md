
**Decision**: A span shorter than one second is deleted on close instead of being kept.
**Rationale**: The protocol doc comment states it; a sub-second span carries no billable time. `DaemonDatabase` also deletes the open billing segment derived from that span, which nothing else would close (review F7).
**Approved**: pending

**Decision**: Recovery ends a crashed span at its last heartbeat, pulled back to an open idle start, and never at `now`.
**Rationale**: The `ActivityRecovery` doc comment: "Never later than the heartbeat — downtime is never billed." The time between a crash and the restart is not work.
**Approved**: pending

**Decision**: Recovery counts only spans it closed, not spans it deleted.
**Rationale**: A deleted span is not a recovered one (review F31); the count reports surviving spans.
**Approved**: pending

**Decision**: Re-closing a closed span keeps its first end, and opening a used id throws.
**Rationale**: An id is a span's identity, and the first close is the true end (review F33). The SQL host gets both from its primary key and its `AND ended_at = ''` guard; the in-memory host copies them.
**Approved**: pending

**Decision**: What prune may delete ("derived") is left to the host.
**Rationale**: The protocol says so, and `ActivityPersistenceContract` leaves prune out for that reason. The SQL host prunes only spans billing has derived, so it never loses unbilled time.
**Approved**: pending

**Decision**: Hosts keep an old idle interval that a kept span still overlaps, which the protocol doc comment does not mention.
**Rationale**: Re-deriving a kept span needs its idle time, and losing it would bill idle time (the comment on the `DaemonDatabase` prune). `prune-idle` states the rule both hosts follow.
**Approved**: pending

**Decision**: Idle intervals are written but not readable through the protocol.
**Rationale**: Only recovery consumes them inside the store; the conformance suite observes them through recovery instead.
**Approved**: pending

**Decision**: Timestamps are fixed-width ISO-8601 UTC strings compared as strings.
**Rationale**: `UTCTimestamp` is the one owner of the wire instant, and string order is chronological only while every writer produces the same width, so `recoveredEnd` canonicalizes before comparing.
**Approved**: pending

**Decision**: The conformance suite ships in Core beside the protocol and returns failure messages instead of asserting.
**Rationale**: Its doc comment: it returns messages "so a host can run them from its own XCTest target". The file imports only Foundation, so it ships in the framework rather than a test target, and each host (the Activity tier's in-memory store, the Database tier's `DaemonDatabase`) asserts the result is empty in its own test target.
**Approved**: pending

**Decision**: `close-outcomes` and `recover-atomic` are SHOULD, not MUST.
**Rationale**: `ActivitySpanClose` is not part of the public protocol signature and atomicity is not stated in the protocol; both hosts do both, but a host MAY reach the same observable result differently.
**Approved**: pending

