
### Contract shapes

- **chatbackend-send-required**: A `ChatBackend` MUST implement
  `sendMessage(text: string, history: ChatMessage[]): Promise<ChatResponse>`,
  where `ChatResponse` is either a plain `string` or an object of
  `{ text: string; content?: ContentItem[]; popover?: PopoverData }`.
- **chatbackend-stream-optional**: A `ChatBackend` MAY implement
  `sendMessageStream(text, history, signal?): AsyncIterable<ChatStreamEvent>`;
  when present, callers (specifically `ChatBackendAdapter`) MUST prefer it
  over `sendMessage`.
- **chatbackend-destroy-optional**: A `ChatBackend` MAY implement
  `destroy(): void` for teardown; callers MUST treat its absence as a no-op
  rather than an error.
- **backend-contract-shape**: A `Backend` MUST implement `send(text,
  attachments): Promise<string>` returning a locally-assigned id, `async
  setLocalTyping(isTyping: boolean): Promise<void>`, `async
  submitWidgetResponse(response: WidgetResponse): Promise<void>`, and a
  `readonly inboundEvents: AsyncIterable<InboundEvent>`.

### EventQueue

- **event-queue-push-buffers-or-delivers**: `EventQueue.push(value)` MUST
  hand `value` directly to the oldest waiting consumer (a pending `drain()`
  iteration) when one exists, and otherwise MUST append it to an internal
  buffer for a future consumer.
- **event-queue-drain-buffer-first**: `drain()` MUST yield every already
  buffered value, in the order it was pushed, before awaiting a new value.
- **event-queue-close-ends-open-waiters**: `close()` MUST resolve every
  currently waiting consumer with `{ done: true }`, ending their `drain()`
  iteration.
- **event-queue-close-idempotent**: A second `close()` call MUST be a no-op
  (`closed` is checked and the method returns immediately).
- **event-queue-push-after-close-noop**: `push(value)` MUST silently discard
  `value` once the queue is closed, rather than buffering it or throwing.
- **event-queue-single-consumer**: `EventQueue` is documented and designed as
  single-consumer: `drain()` returns a fresh `AsyncGenerator` each call, but
  nothing in `push`/`close` fans a value out to more than one waiter, so a
  second concurrent `drain()` iterator competes with the first for buffered
  values and pushes rather than receiving its own copy.

### FetchBackend

- **fetchbackend-post-shape**: `FetchBackend.sendMessage(text, history)` MUST
  `POST` to the configured `url` with a JSON body of exactly `{ message:
  text, history }`.
- **fetchbackend-default-headers**: `FetchBackend` MUST send
  `'Content-Type': 'application/json'` by default, merged with (and
  overridable by) any `headers` supplied in `FetchBackendOptions`.
- **fetchbackend-default-response-mapping**: When no `mapResponse` is
  supplied, `FetchBackend` MUST map a JSON response by reading its `reply`
  field: `(data as { reply: string }).reply`.
- **fetchbackend-custom-mapper**: When `mapResponse` is supplied,
  `FetchBackend` MUST call it with the parsed JSON body and return its result
  as the `ChatResponse`, without applying the default `reply`-field mapping.
- **fetchbackend-http-error**: `FetchBackend.sendMessage` MUST throw an
  `Error` with message `` `Chat backend error: ${response.status}` `` when
  `response.ok` is `false`, without reading the response body.
- **fetchbackend-destroy-aborts**: `FetchBackend.destroy()` MUST call
  `abort()` on the `AbortController` created for the most recent
  `sendMessage` call, if any.
- **fetchbackend-single-controller-field**: `FetchBackend` MUST create a new
  `AbortController` at the start of every `sendMessage` call and MUST store
  it in a single instance field (`this.controller`), overwriting whatever
  `AbortController` a prior, still-in-flight `sendMessage` call had stored
  there.

### MockBackend

- **mockbackend-default-response-table**: `MockBackend` MUST ship a default
  `ResponseMap` (`DEFAULT_RESPONSES`) with exactly these keys: `hello`,
  `text`, `small panel`, `big panel`, `small image`, `big image`, and
  `links`, each a zero-argument function returning a `ChatResponse`.
- **mockbackend-key-normalization**: `MockBackend.sendMessage(text)` MUST
  look up a response using `text.toLowerCase().trim()` as the key, so lookup
  is case-insensitive and tolerant of surrounding whitespace.
- **mockbackend-entry-value-or-thunk**: A `ResponseMap` entry MAY be either a
  `ChatResponse` value or a `() => ChatResponse` thunk; `MockBackend` MUST
  call the thunk (`typeof entry === 'function' ? entry() : entry`) to resolve
  either form to a `ChatResponse`.
- **mockbackend-custom-responses-merge**: `MockBackendOptions.responses`, if
  supplied, MUST be shallow-merged over `DEFAULT_RESPONSES`
  (`{ ...DEFAULT_RESPONSES, ...options.responses }`), so a custom key
  matching a default key replaces it and every other default key survives.
- **mockbackend-fallback-response**: For a key with no matching entry,
  `MockBackend.sendMessage` MUST return the string `` `I don't know that one.
  Try: ${commands}` `` where `commands` is the current response map's keys
  joined with `, `.
- **mockbackend-simulated-delay**: `MockBackend.sendMessage` MUST await a
  delay before resolving: a fixed number of milliseconds when `delayMs` is a
  `number`, or `min + Math.random() * (max - min)` milliseconds when
  `delayMs` is a `[min, max]` tuple; the default is `[400, 1200]`.
- **mockbackend-history-unused**: `MockBackend.sendMessage` MUST NOT read or
  otherwise use its `history` parameter; the response depends only on `text`.

### ShuffleBag and streamTokens

- **shufflebag-nonempty-construction**: `new ShuffleBag(items)` MUST throw an
  `Error` with message `ShuffleBag requires at least one item` when `items`
  is empty; it MUST NOT construct a bag that cannot draw.
- **shufflebag-exhaust-before-repeat**: `ShuffleBag.next()` MUST return every
  item of the bag's item set exactly once, in some order, before any item
  repeats.
- **shufflebag-reshuffle-on-empty**: When the internal draw pile is empty,
  `next()` MUST refill it with a fresh Fisher-Yates shuffle of the full item
  set before drawing.
- **shufflebag-fisher-yates-order**: The reshuffle MUST walk the index range
  from `length - 1` down to `1`, swapping index `i` with a `j` drawn as
  `Math.floor(Math.random() * (i + 1))`, and `next()` MUST draw by popping
  from the end of the shuffled array.
- **streamtokens-tokenization**: `streamTokens(text)` MUST split `text` on
  `/(\s+)/`, so that runs of whitespace are preserved as their own tokens
  interleaved with non-whitespace tokens, rather than being discarded.
- **streamtokens-yields-nonempty-tokens-only**: `streamTokens` MUST `yield {
  type: 'token', text: token }` only for a truthy `token`; a falsy
  (empty-string) split entry MUST NOT produce a `token` event.
- **streamtokens-delay-every-iteration**: `streamTokens` MUST await a delay
  of `minMs + Math.random() * jitterMs` milliseconds on every loop iteration,
  including an iteration whose split entry was empty and so produced no
  `token` event — the delay is unconditional; only the `yield` is guarded.
- **streamtokens-defaults**: `streamTokens` MUST default `minMs` to `45` and
  `jitterMs` to `55` when `StreamTokensOptions` is omitted or leaves a field
  unset.
- **streamtokens-terminal-done**: `streamTokens` MUST `yield { type: 'done'
  }` exactly once, after every token (including for empty input text, where
  it is the only event yielded).

### ChatBackendAdapter

- **adapter-implements-backend**: `ChatBackendAdapter` MUST implement the
  portable `Backend` interface, constructed from a `ChatBackend` and a
  `ChatBackendAdapterOptions` of `{ personaID: string; history: () =>
  ChatMessage[] }`.
- **adapter-send-rejects-after-destroy**: `send` MUST throw `Error('ChatBackendAdapter
  has been destroyed.')` when called after `destroy()`.
- **adapter-send-rejects-attachments**: `send` MUST throw `Error('ChatBackend
  has no attachment channel; send text only.')` when `attachments.length >
  0`.
- **adapter-send-returns-localid-immediately**: `send` MUST generate a
  `localID` with `crypto.randomUUID()` and return it immediately, without
  awaiting the turn it schedules.
- **adapter-history-snapshot-at-send**: `send` MUST call
  `this.options.history()` synchronously at call time — before enqueueing the
  turn on `tail` — and pass that snapshot into the turn. This snapshot is
  taken at `send`'s call time, not when the queued turn actually runs, so a
  turn queued behind an unfinished prior turn runs with a history snapshot
  that predates that prior turn's outcome (see **Two turns submitted back to
  back** in Edge Cases).
- **adapter-turn-serialization**: Turns MUST run one at a time, in submission
  order, by chaining each call's turn onto a private `tail: Promise<void>`
  (`this.tail = this.tail.then(() => this.runTurn(...))`); two turns
  overlapping would interleave their `draftUpdated` events into the one
  shared per-participant draft.
- **adapter-set-local-typing-noop**: `setLocalTyping` MUST resolve without
  emitting any event; `ChatBackend` has no presence channel to forward to.
- **adapter-submit-widget-response-throws**: `submitWidgetResponse` MUST throw
  `Error('ChatBackend does not support interactive widgets.')`.
- **adapter-destroy-cascades**: `destroy()` MUST, exactly once (guarded by a
  `destroyed` flag), abort its internal `AbortController`, call
  `this.backend.destroy?.()`, and close its `EventQueue`.
- **adapter-prefers-streaming**: `runTurn` MUST call `runStreamingTurn` when
  `this.backend.sendMessageStream` is present, and `runUnaryTurn` otherwise.
- **adapter-unary-commit**: `runUnaryTurn` MUST commit a plain string
  response as-is, and MUST commit an object response using its `text`
  (defaulting to `''`) plus its `content` and `popover` fields as the
  committed message's rich display.
- **adapter-streaming-opens-draft-on-first-event**: In `runStreamingTurn`,
  the first stream event of any kind (including one carrying no text) MUST
  open the draft (`turn.opened = true; this.emit(turn.draft())`) before that
  event is otherwise handled.
- **adapter-token-event**: A `token` event MUST append `event.text` to
  `turn.text` and re-emit the draft.
- **adapter-tool-call-started-event**: A `tool_call_started` event MUST open
  an invocation on the `Turn` accumulator, emit a `commandInvoked` event
  carrying it, and then re-emit the draft.
- **adapter-tool-call-completed-event**: A `tool_call_completed` event MUST
  close the matching invocation on the `Turn` accumulator, emit every
  `InboundEvent` `Turn.close` returns, and then re-emit the draft.
- **adapter-content-popover-events**: `content` and `popover` events MUST
  replace `turn.content` / `turn.popover` respectively and re-emit the draft.
- **adapter-error-event-commits-partial**: An `error` event MUST end the turn
  by committing `turn.text || event.message` (falling back to the error's
  message only when no text arrived) with the turn's current display, and
  MUST NOT emit a `transportError`-style event.
- **adapter-done-event-commits**: A `done` event MUST commit `turn.text` with
  the turn's current display and end the turn.
- **adapter-unterminated-stream-still-commits**: If the stream ends (the
  `for await` loop exits) without a `done` or `error` event having been
  seen, and the draft had been opened and the adapter is not destroyed, the
  adapter MUST still commit whatever text and display had accumulated.
- **adapter-commit-encodes-rich-display**: Committing MUST call
  `encodeRichDisplay(display, \`${localID}:display\`)` and attach the result
  (when non-`null`) to the committed `Message`'s `attachments`.
- **adapter-commit-clears-draft**: Committing MUST always be followed by a
  `draftCleared` event for `options.personaID`.
- **adapter-turn-throw-commits-generic-apology**: If `runUnaryTurn` or
  `runStreamingTurn` throws for any reason (including a rejected
  `sendMessage`/`sendMessageStream` call), and the adapter is not destroyed,
  `runTurn`'s catch MUST commit the literal text `"Sorry, something went
  wrong. Let's try again."` with an empty display.
- **adapter-tool-completion-oldest-open-first**: `Turn.close(name, ok,
  result)` MUST match a completion to the oldest still-`'started'` call
  recorded under that `name` (linear scan from index 0), since
  `ChatStreamEvent`'s completion carries a name and no invocation id and
  cannot otherwise distinguish two parallel calls to the same tool.
- **adapter-tool-completion-synthesizes-unmatched**: When `Turn.close` finds
  no open call matching `name`, it MUST synthesize a new invocation (via
  `Turn.open`) already marked completed, and MUST emit both a
  `commandInvoked` and a `commandCompleted` event for it, so the live command
  channel and the committed `toolCalls` record never disagree about an
  invocation the caller never saw start.

### PersonaChatBackend

- **persona-implements-backend**: `PersonaChatBackend` MUST implement the
  portable `Backend` interface, constructed from a
  `PersonaChatBackendOptions` (`personaSlug`, `model?`, `baseURL?`,
  `authorize`, `onStatus?`, `participantID?`).
- **persona-no-network-at-construction**: Constructing `PersonaChatBackend`
  MUST perform no network I/O; the conversation is created lazily on first
  `send`.
- **persona-lazy-conversation-creation**: `ensureConversation` MUST create
  the backing conversation via a `POST` to `${baseURL}/chat/conversations`
  only once (memoized in `conversationID`), and every subsequent turn MUST
  reuse the same conversation id.
- **persona-no-history-sent**: A turn's message `POST` body MUST be exactly
  `{ message: text }`; `PersonaChatBackend` MUST NOT send conversation
  history of its own, because adh owns and reconstructs it server-side.
- **persona-send-rejects-attachments**: `send` MUST throw
  `Error('PersonaChatBackend does not support attachments.')` when
  `attachments.length > 0`, rather than silently dropping them.
- **persona-send-rejects-after-destroy**: `send` MUST throw
  `Error('PersonaChatBackend has been destroyed.')` once `destroy()` has been
  called.
- **persona-turn-serialization**: Turns MUST run one at a time, in send
  order, chained on a private `tail: Promise<void>`; the chain's `.catch`
  MUST emit a `transportError` rather than let a rejection escape and
  silently stop every subsequent turn from ever running.
- **persona-accumulate-draft-text**: Each `token` SSE event MUST append its
  `text` fragment to a running `accumulated` string, and the emitted
  `draftUpdated.text` MUST be that full accumulation, not the fragment alone.
- **persona-commit-once-on-done**: A `done` SSE event MUST commit exactly one
  `messageReceived` (with `text` equal to the full accumulation, `senderID`
  equal to the participant id, and `deliveryStatus: { kind: 'delivered' }`),
  immediately followed by exactly one `draftCleared`, and MUST end the
  stream-consuming loop.
- **persona-empty-reply-still-commits**: A stream that emits `done` with no
  preceding `token` events MUST still commit a `messageReceived` with `text:
  ''`, recording that the turn happened.
- **persona-no-commit-on-incomplete-stream**: If the stream ends (the reader
  loop exits, by natural EOF, thrown error, or abort) without a `done` event
  having been seen, `runTurn`'s `finally` MUST emit `draftCleared` and MUST
  NOT emit `messageReceived`.
- **persona-destroy-aborts-both-controllers**: `destroy()` MUST set
  `destroyed = true`, abort the per-turn `controller` (if any), abort the
  `lifetime` controller (which covers `ensureConversation`'s request window,
  not covered by `controller`), emit a `draftCleared` for the participant,
  and close the event queue.
- **persona-recheck-destroyed-after-conversation-creation**: `runTurn` MUST
  re-check the `destroyed` flag immediately after `ensureConversation`
  resolves, and MUST return without posting the message if it is now `true`
  — a `destroy()` racing an in-flight (already-resolved) creation request
  would otherwise post the user's message into a conversation the caller
  believes is gone.
- **persona-open-heartbeat-ignored**: An `open` SSE event MUST be dropped; it
  is a connection heartbeat, not a transcript event.
- **persona-unknown-sse-events-ignored**: An SSE event whose `event` name
  matches none of `open`, `status`, `token`, `tool_call_started`,
  `tool_call_completed`, `done`, or `error` MUST be ignored, so adh can add
  new event types without breaking older clients.
- **persona-tool-call-correlation-fifo-by-name**: `tool_call_started` MUST
  assign a fresh `crypto.randomUUID()` id and push it onto a per-command-name
  queue (`openInvocations: Map<string, string[]>`); `tool_call_completed`
  MUST shift (oldest-first) the id off that command name's queue and use it
  as `CommandResult.invocationID`.
- **persona-tool-completion-dropped-if-unmatched**: A `tool_call_completed`
  event whose command name has no open entry in `openInvocations` MUST be
  dropped — no `commandCompleted` event is emitted, and no invocation is
  synthesized.
- **persona-status-out-of-band**: `onStatus` transitions (`'thinking'` before
  the conversation/message request, `'responding'` on the first token,
  `'retrying'` on a `status` event with `phase: 'retrying'`, and `null` on
  every turn exit) MUST NOT be reflected as any `InboundEvent`; `TurnStatus`
  is a side channel, not part of the transcript.
- **persona-status-cleared-on-every-exit**: Every code path out of `runTurn`
  (success, `messageFailed`, `transportError`, or an uncaught throw handled
  by the `tail` chain's `.catch`) MUST result in `onStatus` being called with
  `null` before the turn is considered over, via the `finally` block.
- **persona-transport-vs-message-failure**: A rejected `authorize` call in
  `ensureConversation`, a non-`ok` response from `ensureConversation`'s
  `POST` (checked explicitly and thrown), or a rejected `authorize` call for
  the initial message `POST` (nothing reached adh in any of these) MUST be
  reported as `messageFailed` with the originating `localID`; a failure
  while consuming the SSE body (already streaming) MUST be reported as
  `transportError` with no `localID`. A message `POST` that resolves with a
  non-`ok` status is not checked at all — see **Error states** in Edge
  Cases.
- **persona-in-band-error-handling**: An `error` SSE event MUST be treated as
  a failure (`messageFailed`) regardless of the HTTP response's status code,
  since adh answers `200` and reports failure in-band.
- **persona-clear-open-invocations-per-turn**: `openInvocations` MUST be
  cleared (`clearOpenInvocations()`) in `runTurn`'s `finally`, so a later
  turn never inherits a still-open invocation from an earlier, abandoned
  one.
- **persona-set-local-typing-noop**: `setLocalTyping` MUST resolve without
  emitting any event; adh has no typing channel for the local participant.
- **persona-submit-widget-response-throws**: `submitWidgetResponse` MUST throw
  `Error('PersonaChatBackend does not support widgets.')`.

### Cross-implementation divergence

`ChatBackendAdapter` and `PersonaChatBackend` both implement `Backend` for
the same package, and their answers to three of the same design questions
differ. Both are documented above under their own headings; this section
names each divergence explicitly so it is not mistaken for one implementation
being an incomplete copy of the other.

- **divergence-unmatched-tool-completion**: `ChatBackendAdapter` synthesizes
  a `commandInvoked` for a `tool_call_completed` it never saw start
  (**adapter-tool-completion-synthesizes-unmatched**); `PersonaChatBackend`
  drops the same situation silently (**persona-tool-completion-dropped-if-unmatched**).
- **divergence-error-commit-vs-fail**: `ChatBackendAdapter`'s stream `error`
  event commits a message (using whatever partial text arrived, or the
  error's own message) (**adapter-error-event-commits-partial**);
  `PersonaChatBackend`'s stream `error` event never commits — it reports
  `messageFailed`/`transportError` and clears the draft with nothing
  committed (**persona-in-band-error-handling**,
  **persona-no-commit-on-incomplete-stream**).
- **divergence-failure-granularity**: `ChatBackendAdapter` collapses every
  turn-level failure (a rejected `sendMessage`, a rejected
  `sendMessageStream`, or an uncaught exception mid-stream) into one commit
  of a generic apology text (**adapter-turn-throw-commits-generic-apology**);
  `PersonaChatBackend` distinguishes a pre-adh failure (`messageFailed`, tied
  to the outgoing message's `localID`) from a mid-stream failure
  (`transportError`, tied to nothing) and commits neither
  (**persona-transport-vs-message-failure**).

