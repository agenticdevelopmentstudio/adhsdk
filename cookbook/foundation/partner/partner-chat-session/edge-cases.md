
- **Empty or missing text**: An assistant text block with nil or empty text MUST be skipped entirely (MUST). A tool block without a name MUST be announced as `"tool"` (MUST).
- **Unknown tool result**: A tool result whose id was never seen, or has no id, MUST still emit a completed event named `"tool"` (MUST); the registry is never pruned, so it grows by one entry per distinct tool id for the life of the session.
- **Events before a subscriber**: Anything emitted before `events()` is called is lost, apart from the transcript, which `.transcriptLoaded` replays (MUST). Callers that need every event subscribe before applying messages, as the tests do.
- **Second subscriber**: A second `events()` call MUST end the first stream rather than fan out (MUST).
- **Use after close**: After `close()` the session MUST keep accepting `apply`, `noteUserMessage` and `setState` without failing; their events go nowhere until a new stream is attached (MUST). `close()` does not make the session reject later calls.
- **Error result with no text**: `resultText` nil falls back to `subtype`, then to `"error"` (MUST). An error `.result` whose only detail is in `errors` reports `"error"`: that array is deliberately not read, which loses information but still surfaces a failure.
- **Result without error**: A `.result` never emits `.turnFailed` unless `isError` is true (MUST).
- **Partial turns**: A tool event before any assistant text uses a minted id with no `.responseStarted`; a consumer that builds one row per `.responseStarted` will not have a row for that id.
- **Streaming granularity**: Each text block arrives as one start, one delta and one finish; the session never splits text and passes `stopReason` nil (MUST). The `ChatMessage` this type returns and stores always has `isStreaming` false; a consumer folding the events with `ChatTranscriptReducer` sees it true only between the started and finished events, which the session emits back to back.
- **Concurrent calls**: Calls from several threads are safe for the guarded state (MUST); the relative order of their events is not defined beyond acquisition order (see cross-thread-event-order).
- **Network, timeouts, retry, offline**: Not applicable — the session performs no I/O. The send and interrupt closures own delivery to the process; this type adds no timeout, retry or cancellation of its own.
- **Boundary values**: Not applicable beyond the empty cases above — there are no numeric inputs or limits.

