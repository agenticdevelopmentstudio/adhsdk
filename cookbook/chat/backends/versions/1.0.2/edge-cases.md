
- **Empty text input (null/empty input)**: `MockBackend.sendMessage('', [])`
  normalizes `''` to the lookup key `''`, which matches no entry in
  `DEFAULT_RESPONSES`, so the fallback response is returned — an empty
  message is treated as an unrecognized command, not a special case.
- **Empty history array (null/empty input)**: `FetchBackend.sendMessage(text,
  [])` sends `history: []` verbatim in the request body; no minimum-length
  check exists.
- **Empty `items` to `ShuffleBag` (null/empty input)**: constructing with `[]`
  throws synchronously per **shufflebag-nonempty-construction**, rather than
  deferring the failure to the first `next()` call.
- **Empty text to `streamTokens` (null/empty input)**: yields only `{ type:
  'done' }`, after the one unconditional per-iteration delay, per
  **streamtokens-delay-every-iteration**.
- **Single-item `ShuffleBag` (boundary value)**: `next()` returns the same
  item on every call; the shuffle of a one-element array is a no-op, so
  "shuffled" and "exhausted" collapse into the same state on every draw.
- **`MockBackendOptions.delayMs` as a single number of `0` (boundary value)**:
  skips the random component entirely; used throughout `MockBackend.test.ts`
  to make tests deterministic and fast.
- **Two turns submitted back to back (concurrent access)**: both
  `ChatBackendAdapter.send` and `PersonaChatBackend.send` return
  immediately and queue the actual turn on a private promise `tail` chain,
  so the turns still run strictly one at a time (**adapter-turn-serialization**,
  **persona-turn-serialization**); nothing in either class rejects an
  overlapping `send` call. For `ChatBackendAdapter`, the queued turn's
  history was snapshotted back at its own `send` call
  (**adapter-history-snapshot-at-send**), before the prior turn's reply
  existed. In `useChatSession`, whose `history` callback is `project()`
  (committed messages plus any active draft), the queued turn's snapshot
  therefore omits the prior reply entirely for a unary backend, or carries
  only the prior reply's in-progress partial draft for a streaming backend
  — not the prior turn's committed outcome, despite running strictly after
  it.
- **Concurrent `sendMessage`/`sendMessageStream` calls directly on a bare
  `ChatBackend` implementation (concurrent access)**: `ChatBackend`
  (`types.ts`) states no concurrency contract for overlapping calls on the
  same instance; see the open question on **chatbackend-no-concurrency-contract**.
- **chatbackend-no-concurrency-contract**: NEEDS REVIEW: Not implemented in source. `ChatBackend` (`types.ts`) states no concurrency contract for overlapping calls to `sendMessage` and/or `sendMessageStream` on the same instance. `FetchBackend` makes this concrete: its `AbortController` lives in a single instance field (**fetchbackend-single-controller-field**), so a second `sendMessage` call issued before the first resolves silently overwrites that field, and a subsequent `destroy()` aborts only the newer request — the older one runs to completion (or hangs) uncancellable. `useChatSession.ts` always reaches a `ChatBackend` through `ChatBackendAdapter`, which serializes turns and so never produces this overlap in practice, but `FetchBackend` and `MockBackend` are also exported standalone from the package's `index.ts` and can be called directly without that serialization. Resolving this requires either a documented "one call at a time" invariant on `ChatBackend` itself, or `FetchBackend` widening its cancellation state to one `AbortController` per call — a decision for whoever owns the `ChatBackend` interface, not something the given source states.
- **Error states (dependency unavailable/error)**: `FetchBackend.sendMessage`
  throws on a non-`ok` HTTP status but does not itself catch a `fetch()`
  network rejection (e.g. offline) — that rejection propagates to the
  caller. Through `ChatBackendAdapter`, an unhandled rejection there is
  caught by `runTurn`'s catch-all and committed as the generic apology
  (**adapter-turn-throw-commits-generic-apology**). `PersonaChatBackend`
  catches a rejected `authorize` call at each call site and reports
  `messageFailed` or `transportError` per
  **persona-transport-vs-message-failure**, never letting a rejection
  propagate uncaught. It has no equivalent check for a message `POST` that
  *resolves* with a non-`ok` status: unlike `ensureConversation` (which
  checks `res.ok` and throws), the message `POST`'s response goes straight
  to the SSE reader with no status check. A non-SSE error body has no
  `\n\n` separator, so the reader reaches EOF, `consumeStream` returns
  `false`, and the turn ends with only a `draftCleared` and `onStatus(null)`
  — neither `messageFailed` nor `transportError` is emitted, and the
  message's `deliveryStatus` stays `'sending'` forever.
- **Offline/disconnected state**: neither `FetchBackend` nor
  `PersonaChatBackend` detects connectivity proactively; both discover it
  only when a request throws or a stream ends abnormally, handled per the
  error-states cases above. `MockBackend` and `ShuffleBag`/`streamTokens`
  perform no network I/O and are unaffected by connectivity.
- **Malformed SSE payload (malformed input)**: `PersonaChatBackend.parseData`
  catches a `JSON.parse` failure and returns `null`. Only the
  `tool_call_started` and `tool_call_completed` handlers check for that
  `null` (`if (!d) break`) and drop the event. The `token` and `error`
  handlers instead use `?.`/`??` fallbacks and still act on a malformed
  event: a malformed `token` still flips `onStatus` to `'responding'` on
  first arrival and emits a `draftUpdated` (with the fragment falling back
  to `''`, so `accumulated` is unchanged), and a malformed `error` still
  emits `messageFailed` with `reason` falling back to `'Chat failed.'` and
  ends the turn, per **persona-in-band-error-handling**.
- **Tool completion with no matching open call (malformed/out-of-order
  input)**: `ChatBackendAdapter.Turn.close` synthesizes the missing
  invocation (**adapter-tool-completion-synthesizes-unmatched**);
  `PersonaChatBackend.closeInvocation` drops the completion
  (**persona-tool-completion-dropped-if-unmatched**) — see
  **divergence-unmatched-tool-completion**.

