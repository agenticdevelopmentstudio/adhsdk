---
id: 91891cc2-3511-4d00-888a-1ff7585c0b64
title: "Chat Coordinator Backends"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-09-23
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The chat package's transport layer: ChatBackend/Backend contracts, FetchBackend/MockBackend/streamTokens, and ChatBackendAdapter/PersonaChatBackend."
platforms:
  - typescript
  - web
tags:
  - chat
  - backend
  - transport
  - coordinator
depends-on:
  - cfb09ec6-c38f-474a-bd79-be8f67ab523c
related:
  - 447d0e33-c66e-4bf9-8511-e7823bdbcf9b
references: []
approved-by: ""
approved-date: ""
---

# Chat Coordinator Backends

## Overview

`packages/web/packages/chat/src/backends/` is the chat package's transport
layer: seven files defining two conversation-transport interfaces and the
concrete classes that implement them.

- **`types.ts`** declares `ChatBackend`, the package's original, web-only
  transport interface: `sendMessage` (required), `sendMessageStream`
  (optional, preferred when present), and `destroy` (optional).
- **`../contract/backend/Backend.ts`** (outside this directory, but the
  interface every class here ultimately targets) declares the portable,
  cross-platform `Backend` contract: `send`, `setLocalTyping`,
  `submitWidgetResponse`, and a push-based `inboundEvents: AsyncIterable<InboundEvent>`.
- **`EventQueue.ts`** is the single-consumer async push queue every `Backend`
  implementation here uses to back `inboundEvents`.
- **`FetchBackend.ts`** and **`MockBackend.ts`** implement `ChatBackend`
  directly: an HTTP JSON POST transport and a canned-response transport for
  demos and tests, respectively.
- **`ShuffleBag.ts`** exports `ShuffleBag`, a general-purpose shuffle-bag
  utility, and `streamTokens`, a token-by-token text-streaming generator —
  both exported from the package for building custom `ChatBackend`s (in
  practice, `MockBackend`-style implementations that want to look like they
  are typing).
- **`ChatBackendAdapter.ts`** implements `Backend` by wrapping any
  `ChatBackend`, translating its `ChatStreamEvent`s (or its unary
  `ChatResponse`) into `InboundEvent`s.
- **`PersonaChatBackend.ts`** implements `Backend` directly against adh's
  Server-Sent-Events chat API, with no `ChatBackend` in between. It is the
  reference implementation of the separate `persona-chat-coordinator`
  ingredient spec (`docs/specs/ingredients/persona-chat-coordinator.md`); see
  `related` above.

The package's only consumer of this directory, `hooks/useChatSession.ts`,
accepts `backend?: ChatBackend | Backend`, narrows with a `'inboundEvents' in
backend` type guard (`isContractBackend`), and wraps a raw `ChatBackend` in a
`ChatBackendAdapter` before handing it to the orchestrator — so every backend
the rest of the package deals with is, in the end, a `Backend`.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a transport/coordinator layer with no visual
rendering of its own; every class here produces data (`InboundEvent`s or a
`ChatResponse`) for a consumer to render.

## States

Not applicable — this is a transport/coordinator layer, not a visual
component; the runtime states it participates in (turn-in-flight, draft
open/cleared, invocation open/closed, `TurnStatus`) are specified under
Behavioral Requirements rather than a visual-state table.

## Accessibility

Not applicable — this is a transport/coordinator layer; it renders no DOM and
exposes no interactive control.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| ccb-001 | fetchbackend-post-shape, fetchbackend-default-headers | `FetchBackend({ url: '/api/chat' }).sendMessage('hi', [])`, mocked `fetch` resolving `{ ok: true, json: async () => ({ reply: 'Hello back!' }) }` | `fetch` called with `'/api/chat'`, `{ method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{"message":"hi","history":[]}' }`; returns `'Hello back!'`. (`__tests__/FetchBackend.test.ts`, "sends POST with message and history") |
| ccb-002 | fetchbackend-default-headers | `FetchBackend({ url: '/api/chat', headers: { Authorization: 'Bearer token123' } })` | `fetch` called with headers `{ 'Content-Type': 'application/json', Authorization: 'Bearer token123' }`. (`__tests__/FetchBackend.test.ts`, "sends custom headers") |
| ccb-003 | fetchbackend-custom-mapper | `FetchBackend({ url: '/api/chat', mapResponse: (d) => d.data.answer })`, response `{ data: { answer: 'Mapped!' } }` | Returns `'Mapped!'`. (`__tests__/FetchBackend.test.ts`, "uses custom response mapper") |
| ccb-004 | fetchbackend-http-error | `FetchBackend({ url: '/api/chat' }).sendMessage('hi', [])`, mocked `fetch` resolving `{ ok: false, status: 500 }` | Rejects with `Error('Chat backend error: 500')`. (`__tests__/FetchBackend.test.ts`, "throws on non-ok response") |
| ccb-005 | fetchbackend-destroy-aborts, fetchbackend-single-controller-field | Call `sendMessage('hi', [])` (never-resolving `fetch`), then `destroy()` | The `AbortSignal` passed to `fetch` has `aborted === true`. (`__tests__/FetchBackend.test.ts`, "aborts in-flight request on destroy") |
| ccb-006 | mockbackend-key-normalization | `new MockBackend({ delayMs: 0 }).sendMessage('text', [])` | Returns `'Just a plain text reply with no panels or extras.'`. (`__tests__/MockBackend.test.ts`, "returns canned response for known commands") |
| ccb-007 | mockbackend-key-normalization | `sendMessage('HELLO', [])` | Result contains `'Try:'`. (`__tests__/MockBackend.test.ts`, "is case-insensitive") |
| ccb-008 | mockbackend-key-normalization | `sendMessage('  text  ', [])` | Returns `'Just a plain text reply with no panels or extras.'`. (`__tests__/MockBackend.test.ts`, "trims whitespace") |
| ccb-009 | mockbackend-fallback-response | `sendMessage('unknown command', [])` | Result contains `"I don't know that one"` and `'hello'`. (`__tests__/MockBackend.test.ts`, "returns fallback for unknown messages") |
| ccb-010 | mockbackend-default-response-table | `sendMessage('small panel', [])` | Returns an object with `text: 'Here are some quick links for you.'`, `popover.title: 'Quick Reference'`, `content` of length 1. (`__tests__/MockBackend.test.ts`, "returns rich response objects") |
| ccb-011 | mockbackend-custom-responses-merge | `new MockBackend({ delayMs: 0, responses: { greet: 'Hi there!' } })`, then `sendMessage('greet', [])` and `sendMessage('text', [])` | `'greet'` returns `'Hi there!'`; `'text'` still returns the default text reply. (`__tests__/MockBackend.test.ts`, "custom responses merge with defaults") |
| ccb-012 | mockbackend-simulated-delay | `new MockBackend({ delayMs: [50, 100] }).sendMessage('text', [])`, timed | Elapsed time is at least ~45ms (tolerance). (`__tests__/MockBackend.test.ts`, "respects delay range") |
| ccb-013 | shufflebag-exhaust-before-repeat | `new ShuffleBag(['a','b','c','d'])`, call `next()` four times | The four results, sorted, equal `['a','b','c','d']`. (`__tests__/ShuffleBag.test.ts`, "exhausts every item before repeating any") |
| ccb-014 | shufflebag-reshuffle-on-empty | `new ShuffleBag(['a','b'])`, call `next()` four times | `'a'` appears exactly twice and `'b'` appears exactly twice. (`__tests__/ShuffleBag.test.ts`, "refills after exhaustion") |
| ccb-015 | shufflebag-exhaust-before-repeat | `new ShuffleBag(['only'])`, call `next()` twice | Returns `['only', 'only']`. (`__tests__/ShuffleBag.test.ts`, "repeats the sole item of a one-item bag") |
| ccb-016 | shufflebag-nonempty-construction | `new ShuffleBag([])` | Throws `Error('ShuffleBag requires at least one item')`. (`__tests__/ShuffleBag.test.ts`, "rejects an empty bag at construction") |
| ccb-017 | shufflebag-fisher-yates-order | `Math.random` stubbed to always return `0`; `new ShuffleBag(['a','b','c','d'])`, call `next()` four times | Returns exactly `['a','d','c','b']`. (`__tests__/ShuffleBag.test.ts`, "draws in Fisher-Yates order for a stubbed Math.random") |
| ccb-018 | streamtokens-tokenization, streamtokens-terminal-done | `streamTokens('hi there', { minMs: 0, jitterMs: 0 })`, collect all events | `[{type:'token',text:'hi'},{type:'token',text:' '},{type:'token',text:'there'},{type:'done'}]`. (`__tests__/ShuffleBag.test.ts`, "emits every token then a done event, preserving whitespace") |
| ccb-019 | streamtokens-terminal-done | `streamTokens('', { minMs: 0, jitterMs: 0 })` | `[{type:'done'}]`. (`__tests__/ShuffleBag.test.ts`, "emits just done for empty text") |
| ccb-020 | streamtokens-delay-every-iteration, streamtokens-yields-nonempty-tokens-only | `streamTokens('', { minMs: 50, jitterMs: 10 })` with `Math.random` stubbed to `0`, fake timers | The lone `done` event's promise is unresolved at +49ms and resolved at +50ms. (`__tests__/ShuffleBag.test.ts`, "still delays on the empty split entry even though nothing is yielded for it") |
| ccb-021 | streamtokens-defaults | `streamTokens('x')` (opts omitted), `Math.random` stubbed to `0`, fake timers | The token after `'x'` resolves at +45ms, not before. (`__tests__/ShuffleBag.test.ts`, "falls back to the 45ms/55ms defaults when opts is omitted") |
| ccb-022 | persona-lazy-conversation-creation, persona-no-network-at-construction | Construct `PersonaChatBackend`, await a microtask, inspect calls made to `authorize` | Zero calls. (`backends/__tests__/personaChatConformance.test.ts`, "pcc-001") |
| ccb-023 | persona-lazy-conversation-creation | `send('one')`, drain 4 events, `send('two')`, drain 4 events | Exactly one call to the `/conversations` path and two calls to the `/messages` path. (personaChatConformance.test.ts, "pcc-002") |
| ccb-024 | persona-no-history-sent | `send('just this', [])` | The `/messages` request body parses to exactly `{ message: 'just this' }`. (personaChatConformance.test.ts, "pcc-003") |
| ccb-025 | persona-accumulate-draft-text | SSE stream `token 'Hel'`, `token 'lo'`, `done` | The two `draftUpdated.text` values are `['Hel', 'Hello']`, not `['Hel', 'lo']`. (personaChatConformance.test.ts, "pcc-004") |
| ccb-026 | persona-commit-once-on-done | Same stream as ccb-025, drain 4 events | Exactly one `messageReceived` (`text: 'Hello'`, `senderID: 'aria'`), and the last event is `draftCleared`. (personaChatConformance.test.ts, "pcc-005") |
| ccb-027 | persona-empty-reply-still-commits | SSE stream `done` only | First event is `messageReceived` with `message.text: ''`. (personaChatConformance.test.ts, "pcc-005 ... empty reply") |
| ccb-028 | persona-no-commit-on-incomplete-stream | SSE stream truncated after a `token` event, no `done` | No `messageReceived` is emitted; `draftCleared` is. (personaChatConformance.test.ts, "pcc-006 ... truncatedSse") |
| ccb-029 | persona-destroy-aborts-both-controllers, persona-no-commit-on-incomplete-stream | SSE stream hangs after one `token`; call `destroy()` mid-stream | No `messageReceived` is ever emitted. (personaChatConformance.test.ts, "pcc-006 ... destroy mid-stream") |
| ccb-030 | persona-open-heartbeat-ignored | SSE stream `open`, `done` | Emitted event kinds are exactly `['messageReceived', 'draftCleared']` — no event for `open`. (personaChatConformance.test.ts, "pcc-007") |
| ccb-031 | persona-unknown-sse-events-ignored | SSE stream `quux` (unknown), `token 'ok'`, `done` | Emitted event kinds are `['draftUpdated', 'messageReceived', 'draftCleared']`. (personaChatConformance.test.ts, "pcc-008") |
| ccb-032 | persona-tool-call-correlation-fifo-by-name | SSE stream `tool_call_started('search', ...)`, `tool_call_completed('search', ok, ...)` | The `commandCompleted.result.invocationID` equals the preceding `commandInvoked.invocation.id`. (personaChatConformance.test.ts, "pcc-009") |
| ccb-033 | persona-tool-call-correlation-fifo-by-name | SSE stream with two `tool_call_started('search', ...)` events in a row | Two `commandInvoked` events with two distinct `invocation.id`s. (personaChatConformance.test.ts, "pcc-010") |
| ccb-034 | persona-transport-vs-message-failure | Stream `token 'partial'`, then `error 'rate limited'` | No `messageReceived`; a `messageFailed` with the original `localID` and `reason: 'rate limited'`. (personaChatConformance.test.ts, "pcc-012") |
| ccb-035 | persona-in-band-error-handling | Stream `error 'refused'` only, HTTP status 200 throughout | First event is `messageFailed` with `reason: 'refused'`. (personaChatConformance.test.ts, "pcc-013") |
| ccb-036 | persona-destroy-aborts-both-controllers | Stream hangs after a `token`; call `destroy()` | The request's `AbortSignal.aborted` becomes `true`; the only remaining emitted event is `draftCleared`. (personaChatConformance.test.ts, "pcc-014") |
| ccb-037 | persona-send-rejects-after-destroy | `destroy()`, then `send('hi', [])` | Rejects matching `/destroyed/i`; no `authorize` calls were made. (personaChatConformance.test.ts, "pcc-015") |
| ccb-038 | persona-turn-serialization | `send('one')`, `send('two')` without awaiting either turn to finish, settle microtasks | Only one `/messages` request has gone out (`message: 'one'`); after the first turn's stream emits `done`, the second `/messages` request goes out (`message: 'two'`). (personaChatConformance.test.ts, "pcc-017") |
| ccb-039 | persona-recheck-destroyed-after-conversation-creation | `send('hi')`; while the `/conversations` request is gated open, call `destroy()`; then release the gate | The `/conversations` request's signal is aborted; after release, no `/messages` request is ever made. (personaChatConformance.test.ts, "pcc-018") |
| ccb-040 | persona-status-out-of-band | Stream `status {phase:'retrying'}`, `token 'ok'`, `done` | `onStatus` was called with `'retrying'`; the emitted `InboundEvent` kinds are `['draftUpdated', 'messageReceived', 'draftCleared']` — no status-related transcript event. (personaChatConformance.test.ts, "pcc-016") |
| ccb-041 | persona-transport-vs-message-failure | `authorize` for the `/conversations` path resolves with a `500` | A `messageFailed` carrying the `localID` from `send`. (personaChatConformance.test.ts, "ci-transport-vs-message") |
| ccb-042 | persona-send-rejects-attachments | `send('hi', [{ id: 'a', ... } as Attachment])` | Rejects matching `/attachment/i`. (personaChatConformance.test.ts, "ci-attachments") |
| ccb-043 | persona-status-cleared-on-every-exit | A successful turn and a turn that ends in an `error` event, both drained fully | `onStatus`'s last call in both cases is `null`. (personaChatConformance.test.ts, "status clears when a turn ends, on success and on failure") |
| ccb-044 | adapter-error-event-commits-partial | `ChatBackendAdapter` wrapping a `ChatBackend` whose `sendMessageStream` yields `{type:'token',text:'partial'}` then `{type:'error',message:'boom'}`; drain events | A `messageReceived` commits with `text: 'partial'` (the accumulated text, not `'boom'`), followed by `draftCleared`; traced to `ChatBackendAdapter.ts`'s `case 'error': this.commit(turn.text \|\| event.message, turn.display())` — no dedicated test file exists for `ChatBackendAdapter`, so this vector is traced to source rather than to an existing test. |
| ccb-045 | adapter-turn-throw-commits-generic-apology | `ChatBackendAdapter` wrapping a `ChatBackend` whose `sendMessage` rejects | A `messageReceived` commits with `text: "Sorry, something went wrong. Let's try again."`; traced to `ChatBackendAdapter.ts`'s `runTurn` catch block — no dedicated test file exists for `ChatBackendAdapter`, so this vector is traced to source rather than to an existing test. |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `FetchBackendOptions.url` | `string` | required | Endpoint `FetchBackend` POSTs to. |
| `FetchBackendOptions.headers` | `Record<string, string>` | `{}` (merged under `'Content-Type': 'application/json'`) | Extra/overriding request headers. |
| `FetchBackendOptions.mapResponse` | `(data: unknown) => ChatResponse` | `(data) => (data as { reply: string }).reply` | Maps the parsed JSON body to a `ChatResponse`. |
| `MockBackendOptions.responses` | `ResponseMap` | `{}` (merged over `DEFAULT_RESPONSES`) | Additional or overriding canned responses, keyed by lowercased/trimmed input text. |
| `MockBackendOptions.delayMs` | `number \| [min: number, max: number]` | `[400, 1200]` | Simulated response latency. |
| `ChatBackendAdapterOptions.personaID` | `string` | required | Sender id stamped on every emitted event and committed message. |
| `ChatBackendAdapterOptions.history` | `() => ChatMessage[]` | required | Caller-supplied accessor for the transcript as `ChatBackend.sendMessage`/`sendMessageStream` expect it, read once per `send` call. |
| `PersonaChatBackendOptions.personaSlug` | `string` | required | Persona adh resolves the conversation against. |
| `PersonaChatBackendOptions.model` | `string \| null` | `undefined` (adh uses the persona's configured model) | Overrides the persona's configured model when set. |
| `PersonaChatBackendOptions.baseURL` | `string` | `/api` | Root of the adh chat API; conversations live at `${baseURL}/chat/conversations`. |
| `PersonaChatBackendOptions.authorize` | `(path: string, init: RequestInit) => Promise<Response>` | required | Host-injected, credential-attaching fetch wrapper; `PersonaChatBackend` never handles credentials itself. |
| `PersonaChatBackendOptions.onStatus` | `(status: TurnStatus \| null) => void` | `undefined` | Receives out-of-band turn-phase transitions (`'thinking' \| 'responding' \| 'retrying' \| null`). |
| `PersonaChatBackendOptions.participantID` | `string` | `personaSlug` | Sender id stamped on emitted events, when different from the persona's resolution slug. |
| `ShuffleBag` constructor arg | `readonly T[]` | required | The item set to draw from; MUST be non-empty (**shufflebag-nonempty-construction**). |
| `StreamTokensOptions.minMs` | `number` | `45` | Floor delay between emitted tokens. |
| `StreamTokensOptions.jitterMs` | `number` | `55` | Additional random delay (uniform `[0, jitterMs)`) added to `minMs`. |

## Deep Linking

Not applicable: none of these seven files perform navigation or construct a
URL beyond the caller-supplied API endpoint(s) they `POST`/`fetch` to.

## Localization

Every user-facing string in this directory is a hardcoded English literal
with no localization mechanism (no `Intl`, no message catalog, no `t()`
call):

- `ChatBackendAdapter`'s catch-all apology: `"Sorry, something went wrong.
  Let's try again."`
- `ChatBackend`'s `sendMessage`/`submitWidgetResponse` error messages:
  `'ChatBackend has no attachment channel; send text only.'`, `'ChatBackend
  does not support interactive widgets.'`, `'ChatBackendAdapter has been
  destroyed.'`.
- `FetchBackend`'s HTTP-error message template: `` `Chat backend error:
  ${status}` ``.
- `MockBackend`'s entire `DEFAULT_RESPONSES` table (all seven canned replies,
  their `popover` titles/descriptions, and link labels) and its fallback
  string `` `I don't know that one. Try: ${commands}` ``.
- `PersonaChatBackend`'s fallback error strings: `"Couldn't start the
  conversation."`, `` `Couldn't start the conversation (${status}).` ``,
  `'The chat request failed.'`, `'No response stream from adh.'`,
  `'PersonaChatBackend does not support attachments.'`,
  `'PersonaChatBackend does not support widgets.'`,
  `'PersonaChatBackend has been destroyed.'`, `'The chat stream failed.'`.

None of these strings pass through any localization layer; a non-English
deployment would need to intercept or replace them at a layer above this
directory.

## Accessibility Options

Not applicable: this is a transport/coordinator layer with no visual
rendering, so it responds to none of Reduce Motion, Increase Contrast, or
Differentiate Without Color.

## Feature Flags

Not applicable: none of these seven files read a feature-flag key or gate a
branch on one.

## Analytics

Not applicable: none of these seven files emit an analytics event or call a
tracking API.

## Privacy

- **Data collected**: the caller's typed message text and (for `ChatBackend`
  implementations) the full `ChatMessage[]` history are passed into
  `sendMessage`/`sendMessageStream`; tool-call `argumentsJSON` and
  `resultJSON`/`errorMessage` payloads flow through unmodified and may
  contain arbitrary caller/tool data. None of these classes inspect or
  redact that content.
- **Storage**: none of these seven files write to `localStorage`,
  `sessionStorage`, IndexedDB, or disk; all state is held in memory for the
  lifetime of the class instance.
- **Transmission**: `FetchBackend` POSTs `{ message, history }` as JSON to
  the caller-configured `url` over `fetch`, with whatever `headers` the
  caller supplies (including, potentially, credentials placed there by the
  caller). `PersonaChatBackend` never attaches credentials itself — every
  outbound request goes through the caller-injected `authorize` function,
  which is documented as the credential-attaching layer
  (`PersonaChatBackendOptions.authorize`); this class only supplies the path
  and body.
- **Retention**: none of these seven files persist or expire data of their
  own; retention of the conversation is entirely adh's (for
  `PersonaChatBackend`) or the caller's endpoint's (for `FetchBackend`)
  concern.

## Logging

Not applicable: none of these seven files call `console.*` or any other
logging API.

## Platform Notes

- **SwiftUI**: no view is involved. Port `ChatBackend`/`Backend` as Swift
  `protocol`s; `EventQueue<T>` maps onto `AsyncStream<T>.makeStream()` (its
  `continuation.yield`/`continuation.finish` replace `push`/`close`, and
  `AsyncStream` is itself multi-consumer-safe if that is ever needed, unlike
  the source's `EventQueue`). `FetchBackend` becomes a `URLSession` POST with
  a per-call `Task` holding its own cancellation (rather than one shared
  field) so **fetchbackend-single-controller-field**'s concurrency gap has no
  Swift equivalent by construction. `PersonaChatBackend`'s SSE loop maps onto
  `URLSession.bytes(for:)` line-by-line parsing (or `EventSource`-style
  helper) feeding the same `AsyncStream`; `lifetime`/`controller` become two
  `Task`s (or one `Task` holding a nested child `Task`), cancelled
  independently to preserve **persona-destroy-aborts-both-controllers**.
- **Compose**: `ChatBackend`/`Backend` become Kotlin `interface`s;
  `EventQueue<T>` maps onto a `Channel<T>` (`UNLIMITED` or `BUFFERED`
  capacity) exposed as a `Flow<T>` via `receiveAsFlow()`. `FetchBackend`
  becomes an OkHttp/Ktor POST inside a per-call coroutine `Job`, cancelled
  independently per call rather than sharing one field. `PersonaChatBackend`
  parses SSE from a streaming response body inside a coroutine, using a
  `CoroutineScope`'s `Job` hierarchy for the `lifetime`/`controller` split
  (cancelling the child job cancels only the in-flight turn; cancelling the
  scope cancels everything, mirroring `lifetime.abort()`).
- **React/Web** (source platform): `packages/web/packages/chat/src/backends/*.ts`
  — plain TypeScript classes and functions with no React import; `fetch`,
  `AbortController`, `crypto.randomUUID()`, `ReadableStream`/`TextDecoder`
  (for SSE), and hand-rolled `Promise`-based queuing (`EventQueue`, the
  `tail` chain) stand in for whatever platform-native equivalents another
  port uses. The only call site, `hooks/useChatSession.ts`, wraps a
  `ChatBackend` in `ChatBackendAdapter` before use.
- **AppKit / UIKit**: the same Swift port described under SwiftUI applies
  unchanged — nothing here is UI-framework-specific; an `NSViewController`
  or `UIViewController` consumes the same `AsyncStream<InboundEvent>` a
  SwiftUI view would.
- **WinUI 3**: `ChatBackend`/`Backend` become C# `interface`s.
  `EventQueue<T>` maps onto `System.Threading.Channels.Channel<T>`
  (`Channel.CreateUnbounded<T>()`, with `Writer.TryWrite`/`Writer.Complete`
  replacing `push`/`close`, and `Reader.ReadAllAsync()` replacing `drain()`).
  `FetchBackend` becomes an `HttpClient.PostAsync` call with a per-call
  `CancellationTokenSource` (never a single reused field, avoiding
  **fetchbackend-single-controller-field**'s gap) passed as the call's
  `CancellationToken`. `PersonaChatBackend`'s SSE consumption maps onto
  reading `HttpResponseMessage.Content.ReadAsStreamAsync()` line-by-line (or
  a library such as `System.Net.ServerSentEvents` where available), exposed
  as an `IAsyncEnumerable<InboundEvent>`; `lifetime`/`controller` become two
  `CancellationTokenSource`s, one covering the whole backend's lifetime and
  one recreated per turn, `Dispose`d/cancelled independently exactly as the
  source's two `AbortController`s are.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/chat/src/backends/` | unverified |

## Design Decisions

**Decision**: `ChatBackendAdapter` translates any `ChatBackend` into a
`Backend` at one seam, rather than teaching `useChatSession` (or every
consumer) to speak both vocabularies.
**Rationale**: `ChatBackend` streams `ChatStreamEvent`s that mutate a
placeholder bubble in place; the contract streams `InboundEvent`s into an
immutable transcript plus a separate `ActiveDraft`. Translating once here is
what lets `useChatSession` own no transport type-switch of its own — every
backend it is handed, legacy or contract, reaches it as `InboundEvent`s.
**Approved**: pending

**Decision**: Both `ChatBackendAdapter` and `PersonaChatBackend` serialize
their turns on a private promise `tail` chain rather than allowing
overlapping turns.
**Rationale**: Each holds exactly one draft per participant and (for
`PersonaChatBackend`) one cancellation handle and one open-invocation map per
instance; two turns racing would either interleave one draft's text from two
different replies, or let the second turn's per-turn state silently clobber
the first's. Nothing upstream (no chat surface disables its composer while a
turn is in flight) prevents the caller from trying anyway, so the
serialization has to live here.
**Approved**: pending

**Decision**: Both implementations correlate a tool-call completion to its
invocation by command name plus arrival order (oldest-open-first), never by
an id carried on the wire.
**Rationale**: Neither `ChatStreamEvent`'s `tool_call_completed` nor adh's
SSE `tool_call_completed` event carries an invocation id — only a name. Given
that constraint, oldest-open-first is the one answer both `Turn.close`
(`ChatBackendAdapter`) and `closeInvocation` (`PersonaChatBackend`) settle on,
so the package has one rule for this rather than two.
**Approved**: pending

**Decision**: `ChatBackendAdapter.Turn.close` synthesizes an invocation for a
tool completion it never saw start, rather than dropping it.
**Rationale**: The live command channel (`commandInvoked`/`commandCompleted`)
and the frozen `toolCalls` record on the committed message are meant to
agree about which invocations happened; dropping an unmatched completion
would show its result in the committed record and nowhere on the live
channel. See **divergence-unmatched-tool-completion** for the contrasting
choice `PersonaChatBackend` makes for the same situation.
**Approved**: pending

**Decision**: `PersonaChatBackend.closeInvocation` drops a tool completion it
never saw start, rather than synthesizing an invocation for it.
**Rationale**: adh is the single source of truth for what tool calls exist in
a live conversation; an unmatched completion arriving from adh is treated as
a protocol anomaly to ignore rather than a gap for the client to paper over
with a fabricated invocation record. See **divergence-unmatched-tool-completion**.
**Approved**: pending

**Decision**: `ChatBackendAdapter` commits a message on a stream `error`
event (using whatever text had accumulated, or the error's own message when
none had); `PersonaChatBackend` never commits on an equivalent failure and
reports `messageFailed`/`transportError` instead.
**Rationale**: `ChatBackendAdapter` preserves behavior from the placeholder
era it replaced — sites are rendering the commit-on-error case today, so
changing it would be an unannounced behavior change to every existing
`ChatBackend` consumer. `PersonaChatBackend` is new code with no such
installed base, and treats a truncated/errored reply as never having
happened rather than displaying a partial answer as if it were complete. See
**divergence-error-commit-vs-fail**.
**Approved**: pending

**Decision**: `ChatBackendAdapter` collapses every turn-level failure into
one generic committed apology; `PersonaChatBackend` distinguishes
`messageFailed` (nothing reached adh) from `transportError` (the stream
itself failed) and commits neither.
**Rationale**: `ChatBackendAdapter` wraps an arbitrary caller-supplied
`ChatBackend` whose failure modes it cannot enumerate in advance, so one
generic fallback is the only response it can give without guessing.
`PersonaChatBackend` talks to one known API (adh) whose two failure classes
it can and does tell apart, and callers (`ci-transport-vs-message` in the
`persona-chat-coordinator` ingredient spec) rely on the distinction to decide
whether the outgoing message itself failed. See
**divergence-failure-granularity**.
**Approved**: pending

**Decision**: `EventQueue<T>` is single-consumer, backed by a plain array
buffer and an array of waiting resolvers, rather than a general
multi-subscriber pub/sub primitive.
**Rationale**: Every `Backend.inboundEvents` in this package has exactly one
consumer, the orchestrator; a fan-out primitive would add complexity (and a
"who gets which events on reconnect" question) that nothing here needs.
**Approved**: pending

**Decision**: `FetchBackend`'s default `mapResponse` assumes the response
body is `{ reply: string }`, rather than the raw JSON body or a required
mapper.
**Rationale**: Keeps the zero-configuration path usable against the simplest
possible echo-style backend, which is `FetchBackend`'s primary use case
(demos, quick integrations); a caller with a different response shape
supplies `mapResponse` rather than the common case paying for it.
**Approved**: pending

**Decision**: `MockBackend` matches on the exact lowercased, trimmed input
text rather than any fuzzy or substring matching.
**Rationale**: `MockBackend` exists to give a deterministic, scriptable
canned-response backend for demos and tests; exact-match keeps its behavior
fully predictable from its `ResponseMap`, at the cost of not recognizing
"tell me about the big panel" as `'big panel'`.
**Approved**: pending

**Decision**: `ShuffleBag` reshuffles lazily, on the draw that empties the
pile, rather than precomputing a long shuffled sequence up front.
**Rationale**: The bag's caller (`MockBackend`-style canned replies driven by
`streamTokens`) draws indefinitely over an unbounded session; reshuffling
on demand keeps memory bounded to one copy of the item set regardless of how
many draws have happened.
**Approved**: pending

**Decision**: `streamTokens` preserves whitespace runs as their own tokens
and delays on every loop iteration, including one that yields nothing.
**Rationale**: Splitting on `/(\s+)/` and delaying unconditionally keeps
whitespace appearing with realistic timing, rather than every space
appearing instantly attached to the word before or after it, which is what
made a persona's canned reply look like it was actually being typed rather
than pasted in two chunks.
**Approved**: pending

**Decision**: `PersonaChatBackend` holds a `lifetime` `AbortController`
separate from the per-turn `controller`, rather than one `AbortController`
covering both the conversation-creation request and the message stream.
**Rationale**: `ensureConversation` can be in flight before any turn has a
`controller` of its own; a single shared controller left a `destroy()` during
that window with nothing to abort, and the creation request ran to
completion (and could then post the user's message) after the caller
believed the backend was gone.
**Approved**: pending

**Decision**: `PersonaChatBackend.onStatus` transitions are delivered on a
dedicated callback, never as an `InboundEvent`.
**Rationale**: A retry, or the thinking/responding phase, is progress
information about the turn, not something that happened in the conversation;
folding it into the transcript stream would give a consumer no way to tell a
transient status blip from an actual event without hardcoding knowledge of
which `InboundEvent` kinds are "really" status.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/91ba975a-1f6a-5a85-8652-26e76cf324f4) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-platform-notes](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90c2d8c2-cf79-5465-bffd-54f9fb1453bc) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-design-decisions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f5b5cbe6-22e8-5954-a18d-0362ee387941) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-change-history](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/14bf2d1d-875b-5e58-b43d-be492c9f941a) | passed | Artifact Formatting |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |

`unit-test-coverage` is `partial`: `FetchBackend`, `MockBackend`, `ShuffleBag`/`streamTokens`,
and `PersonaChatBackend` each have direct test coverage (`__tests__/FetchBackend.test.ts`,
`__tests__/MockBackend.test.ts`, `__tests__/ShuffleBag.test.ts`,
`backends/__tests__/personaChatConformance.test.ts`), but `ChatBackendAdapter` and `EventQueue`
have no dedicated test file of their own — `ChatBackendAdapter` is exercised only indirectly
through `__tests__/useChatSession.test.ts`, and `EventQueue` only as the queue underneath every
`Backend`'s `inboundEvents`. `explicit-error-handling` is `partial`: `FetchBackend`'s reused,
single-field `AbortController` (**fetchbackend-single-controller-field**) leaves the
concurrent-direct-use case under Edge Cases unresolved by the source rather than explicitly
handled.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial recipe covering `types.ts`, `EventQueue.ts`, `FetchBackend.ts`, `MockBackend.ts`, `ShuffleBag.ts`, `ChatBackendAdapter.ts`, and `PersonaChatBackend.ts`; documents the cross-implementation divergences between `ChatBackendAdapter` and `PersonaChatBackend` and the open question around concurrent direct use of a bare `ChatBackend`.
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Fixed ccb-044 pipe escape, history/transport-failure/SSE edge cases; kebab-cased 4 req names. |
