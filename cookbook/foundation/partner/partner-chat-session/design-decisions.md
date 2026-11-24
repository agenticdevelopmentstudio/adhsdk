
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
**Rationale**: The source marks every failed partner turn retryable, since the next turn can run again; the `errors` array and `numTurns` on the stream message are not read. This is a lossy but surfaced projection, and a port that also reads `errors` is a change to this decision, not a conformance failure.
**Approved**: pending

**Decision**: A tool event with no current assistant message id mints a fresh one rather than being dropped.
**Rationale**: Tool calls can precede any assistant text in a turn; a minted id lets the UI show the call, at the cost of an id with no started event.
**Approved**: pending

**Decision**: `clear()` is not overridden and therefore does nothing; the session is cleared by creating a new instance.
**Rationale**: The partner transcript is the owner's standing record, and the source inherits the protocol's default `clear()`, which does nothing.
**Approved**: pending


**Decision**: The tool-name registry is never pruned, and its growth is accepted.
**Rationale**: The source adds one entry per distinct tool id and removes none, not even on `.result`. Entries are short strings and a partner session is long-lived but handles a bounded number of tool calls per day, so the growth is small; pruning on `.result` would risk dropping a name that a late tool result still needs.
**Approved**: pending

**Decision**: The fallback strings `tool` and `error` stay hardcoded English, and the failed `no-hardcoded-strings` check is accepted.
**Rationale**: They are last-resort labels for a tool event with no name and an error result with no text, in a view for the owner of a developer tool; the source has no string table to localise them through.
**Approved**: pending
