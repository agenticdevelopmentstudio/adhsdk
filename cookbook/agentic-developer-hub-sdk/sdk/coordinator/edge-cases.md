
- **Empty text (MUST)**: `text: ""` is sent to `/messages` as
  `{"message":""}` with no client-side validation; a successful empty reply
  (`done` with no prior `token`) still commits as a `Message` with `text:
  ""` (`commit-once`, `pcc-020`).
- **Empty attachments (MUST)**: `attachments: []` is the only value for
  which `send` proceeds. Any non-empty array, even a single attachment,
  throws `attachmentsUnsupported` before any request is made
  (`attachments-unsupported`).
- **Unbounded message length (SHOULD)**: The source imposes no maximum
  length on `text`. An arbitrarily large string is passed through
  `JSONEncoder` and posted in a single request with no chunking, since
  neither `SendMessageBody` nor `runTurn` size-limits it.
- **`participantID` boundary (MUST)**: When `options.participantID` is
  `nil`, it MUST default to `options.personaSlug` exactly, so every emitted
  event's `participantID` is the persona slug unless the host overrides it.
- **Concurrent sends (open question)**: the open question on
  concurrent-turns — two `send()` calls issued before the first
  turn ends are not given a defined ordering by the source or its test
  suite; both the single-task `TurnControl` and the reentrant
  `ensureConversation()` check are affected.
- **Concurrent tool correlation (MUST)**: `openInvocations` is
  coordinator-wide, not per-turn, so if two turns are ever in flight at
  once (see the open question on concurrent-turns), a `tool_call_completed` block is
  matched to the oldest open invocation of that command name regardless of
  which turn opened it — the source's per-command FIFO does not
  distinguish turns.
- **Conversation creation fails (MUST)**: A non-`2xx` status from
  `/conversations` throws `conversationFailed(status:)`, reported as
  `messageFailed` for the triggering `send`'s `localID`; no `/messages`
  request is attempted (`pcc-014`).
- **Message request transport failure (MUST)**: If `options.authorize`
  itself throws while posting the message (e.g. no route to host, DNS
  failure), it is caught in `runTurn` and reported as
  `messageFailed(localID:, reason:)` via `describe(error:,
  fallback: "The chat request failed.")`. The conversation id already
  cached by `ensureConversation()` is NOT cleared, so the next `send` still
  reuses it.
- **In-band error on HTTP 200 (MUST)**: An `error` SSE block is treated as
  a failure regardless of the HTTP status code the message POST returned;
  a `2xx` status is never itself evidence of success (`in-band-error-terminal`,
  `pcc-013`).
- **Connectivity lost mid-stream (MUST)**: If the `for try await chunk in
  body` loop throws mid-turn, the coordinator catches it in
  `consumeStream`; if not destroyed, it emits `transportError(message:)`
  with the underlying error's description. Either way, no `messageReceived`
  is emitted for that turn (`pcc-006` models this with a stream that throws
  mid-turn). If the loop instead ends cleanly — the body closes without
  `done` or `error` but without throwing — `consumeStream` simply falls out
  of the loop and returns `false`; `runTurn` emits only `draftCleared`, with
  no `transportError` for that case.
- **No client-driven retry (MUST NOT)**: The coordinator itself never
  re-issues the HTTP request after a transport failure or a dropped
  connection. Only a server-declared `status: "retrying"` block is relayed
  as `TurnStatus.retrying`; the source contains no retry loop or backoff
  logic of its own.
- **`destroy()` mid-turn (MUST)**: The in-flight `Task` is cancelled,
  `draftCleared` is emitted, and `inboundEvents` finishes. Because
  `control.destroyed` becomes `true` before the resulting
  `CancellationError` is caught in `consumeStream`, no `transportError` is
  emitted for that cancellation (`pcc-015`).
- **`destroy()` with no turn ever started (MUST)**: `control.destroy()`
  returns `nil` (nothing to cancel); `draftCleared` and the stream finish
  still occur, which is harmless since no consumer has an active draft.
- **`destroy()` called twice (SHOULD)**: Effectively idempotent —
  `isDestroyed` is already `true` and `events.finish()` was already called,
  so the second call's `draftCleared` yield and second `finish()` land on
  an already-finished `AsyncStream` and have no observable effect on a
  consumer.
- **Malformed SSE payloads (MUST)**: A block whose `data` fails to decode
  is handled per event type rather than aborting the stream: `token` falls
  back to an empty-string fragment (`malformed-token-fallback`),
  `status`/`error` are treated as if the field were absent, and
  `tool_call_started` is dropped entirely with no event.
- **Unmatched tool completion (MUST)**: A `tool_call_completed` block
  naming a command with no open invocation is dropped — `closeInvocation`
  returns `nil` and no `commandCompleted` is emitted, "dropped rather than
  invented" per the source's own comment.

