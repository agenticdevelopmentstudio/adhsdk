
**Decision**: The session replays only the transcript to a new subscriber, never the current state or any missed event.
**Rationale**: The source emits through the attached continuation only; the owner of the session sets state after attaching, and the transcript is the one thing a late UI needs to rebuild a view. Dropping other events keeps memory bounded when no UI is attached.
**Approved**: pending

**Decision**: `events()` replaces the previous subscriber instead of supporting several.
**Rationale**: The protocol documents one long-lived stream to subscribe once; the source finishes the old continuation so a re-created chat view cannot leave a stale stream running.
**Approved**: pending

**Decision**: A whole text block is emitted as one started, one delta, one finished, with `stopReason` nil.
**Rationale**: The partner process delivers complete assistant messages rather than token streams, and the source projects them into the streaming event shape the chat UI already understands; the stop reason is not carried.
**Approved**: pending

**Decision**: An error result is always reported as retryable, and only `resultText` or `subtype` becomes the message.
**Rationale**: The source marks every failed partner turn retryable, since the next turn can run again; the `errors` array and `numTurns` on the stream message are not read. This is a lossy but surfaced projection.
**Approved**: pending

**Decision**: A tool event with no current assistant message id mints a fresh one rather than being dropped.
**Rationale**: Tool calls can precede any assistant text in a turn; a minted id lets the UI show the call, at the cost of an id with no started event.
**Approved**: pending

**Decision**: `clear()` is not overridden and therefore does nothing; the session is cleared by creating a new instance.
**Rationale**: The partner transcript is the owner's standing record, and the protocol supplies a no-op default.
**Approved**: pending

