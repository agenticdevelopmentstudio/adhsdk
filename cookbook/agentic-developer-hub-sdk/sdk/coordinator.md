---
id: 9c6338b6-9a7a-4692-8164-a75800875031
title: "Chat Coordinator"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-09-23
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Actor that lazily creates one adh conversation, posts messages with no history, and translates the SSE reply stream into InboundEvent values."
platforms:
  - swift
  - macos
  - ios
tags:
  - chat
  - backend
  - networking
  - streaming
  - logic
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Chat Coordinator

## Overview

`PersonaChatCoordinator` is the Apple implementation of the
`persona-chat-coordinator` ingredient: a `Backend`-conforming actor that
turns a chat UI's `send`/`inboundEvents` contract into calls against adh's
chat API. adh orchestrates the turn — it resolves the persona from its slug,
assembles the prompt, reads and writes history, calls the provider, and
streams the reply — so the coordinator itself holds no history, no prompt,
and no credentials. It lazily creates one adh conversation per instance,
posts each outgoing message with no history attached, and translates the
resulting Server-Sent Events stream (`open`, `status`, `token`,
`tool_call_started`, `tool_call_completed`, `done`, `error`) into
`InboundEvent` values a consumer such as `ChatViewModel` can render.

`SSEParser` is its private, single-purpose collaborator: an incremental
reader that turns raw byte chunks into complete `event:`/`data:` blocks,
buffering across chunk boundaries so a block split mid-word or
mid-separator is never truncated or duplicated.

## Behavioral Requirements

### Sending a message

- **send-returns-local-id-immediately**: `send(text:attachments:)` MUST
  return a freshly generated `localID` (a `UUID` string) as soon as the
  turn's `Task` has been created and adopted by `TurnControl`, without
  waiting for any network request or reply; the reply arrives later on
  `inboundEvents`.
- **no-history-in-request**: The JSON body posted to
  `.../conversations/<id>/messages` MUST contain exactly one field,
  `message`, set to the text passed to `send` — no prior conversation
  history is ever included.
- **attachments-unsupported**: `send` MUST throw
  `PersonaChatError.attachmentsUnsupported` and MUST NOT perform any network
  request when `attachments` is non-empty.
- **destroyed-rejects-send**: `send` MUST throw `PersonaChatError.destroyed`
  and MUST NOT perform any network request once `destroy()` has been called.
- **local-typing-noop**: `setLocalTyping(_:)` MUST return successfully
  without performing any action or emitting any event, because adh has no
  channel for reporting the local participant's typing state.
- **widget-response-unsupported**: `submitWidgetResponse(_:)` MUST always
  throw `PersonaChatError.widgetsUnsupported`; the coordinator supports no
  interactive widgets.
- **message-encode-failure-swallowed**: NEEDS REVIEW: Not implemented in source. `request.httpBody = try? JSONEncoder().encode(SendMessageBody(message: text))` discards an encoding failure instead of propagating it, unlike `ensureConversation()`, which `try`-propagates the equivalent `CreateConversationBody` encoding. If encoding ever fails, `runTurn` proceeds to call `options.authorize(request)` with a `nil` body, silently sending a bodyless POST rather than failing the turn with a diagnosable error. `SendMessageBody` holds only a `String`, so this is unlikely in practice, but the source defines no behavior for the case and no test exercises it. Resolving this requires deciding whether a `send`-time encoding failure should throw synchronously (matching `ensureConversation`'s pattern) or fail the turn via `messageFailed`.

### Conversation management

- **conversation-lazy-creation**: The coordinator MUST NOT make any network
  request when constructed; it MUST create the backing adh conversation only
  on the first call to `send` that reaches `ensureConversation()`.
- **conversation-reuse**: Once `ensureConversation()` has successfully
  returned a conversation id for a `PersonaChatCoordinator` instance, every
  subsequent turn MUST reuse that same id rather than creating a new
  conversation.
- **model-override**: The conversation-creation body MUST include a `model`
  field set to `options.model` when it is non-`nil`; when `options.model` is
  `nil`, the synthesized `Encodable` conformance MUST omit the `model` key
  entirely (Swift's compiler-generated `encodeIfPresent` behavior for an
  `Optional` stored property) rather than encoding it as JSON `null`.
- **conversation-creation-failure-status**: `ensureConversation()` MUST
  throw `PersonaChatError.conversationFailed(status:)` when the
  conversation-creation response's status code is outside `200..<300`.
- **conversation-creation-failure-reported-as-message-failure**: A failure
  raised by `ensureConversation()` MUST surface as
  `InboundEvent.messageFailed(localID:, reason:)` for the `localID` of the
  `send` call that triggered it, never as a `transportError` — nothing
  reached adh, so it is the message's failure, not the transport's.

### Status reporting

- **turn-status-thinking-on-start**: Every turn MUST report
  `TurnStatus.thinking` before any network request for that turn begins.
- **turn-status-responding-on-first-token**: The coordinator MUST report
  `TurnStatus.responding` exactly once per turn, at the first `token` block
  received, and MUST NOT report it again for later tokens in the same turn.
- **turn-status-retrying-on-server-signal**: A `status` SSE block whose
  decoded `phase` is exactly `"retrying"` MUST cause the coordinator to
  report `TurnStatus.retrying`; any other or undecodable `phase` value MUST
  produce no status report.
- **turn-status-cleared-on-exit**: Every turn MUST report a `nil` status
  exactly once when it ends, regardless of whether it committed, failed, or
  was cancelled.
- **status-dual-channel**: Every status transition MUST be reported through
  both the `onStatus` callback (when supplied) and an
  `InboundEvent.statusChanged` event on `inboundEvents`, callback first.
- **status-kind-mapping**: `statusChanged`'s `ChatStatus.kind` MUST map
  `TurnStatus.thinking` to `ChatStatusKind.think`, `.responding` to
  `.respond`, and `.retrying` to `.retry` via `ChatStatusKind.init(_:)`; a
  `nil` `TurnStatus` MUST produce a `nil` `ChatStatus`.
- **status-words-always-nil**: Every `ChatStatus` the coordinator constructs
  MUST leave `words` at its default of `nil` — the coordinator never
  supplies its own present/past word pairs, leaving status vocabulary to the
  consuming application.
- **status-not-a-transcript-event**: A `statusChanged` event, including
  `retrying`, MUST NOT be represented as a `Message`, a `draftUpdated`, or
  any other transcript-shaped event.

### Streaming translation

- **draft-accumulates-full-text**: Each `draftUpdated` event MUST carry the
  entire accumulated reply text so far — every `token` fragment received in
  the turn, concatenated in arrival order — never just the newest fragment.
- **heartbeat-dropped**: An `open` SSE block MUST produce no event of any
  kind; it is a connection heartbeat, not a transcript event.
- **unknown-events-ignored**: An SSE block whose `event` is not one of
  `open`, `status`, `token`, `tool_call_started`, `tool_call_completed`,
  `done`, or `error` MUST be ignored, and block processing MUST continue
  with the next block.
- **malformed-token-fallback**: A `token` block whose `data` fails to decode
  as `TokenPayload`, or whose `text` field is absent, MUST be treated as an
  empty-string fragment rather than aborting the turn.
- **commit-once**: A `done` block MUST cause the coordinator to emit exactly
  one `messageReceived` event carrying the full accumulated text, followed
  immediately by exactly one `draftCleared` event, and MUST end the turn as
  committed. This MUST occur even when the accumulated text is empty (an
  empty reply still commits, so the transcript records that the turn
  happened).
- **received-message-shape**: The `Message` committed on `done` MUST have
  `id: nil`, a freshly generated `localID` (independent of the `send`
  call's own `localID`), `senderID` equal to `participantID`, `timestamp`
  set to the commit time, empty `attachments`, and `deliveryStatus:
  .delivered`.
- **no-commit-on-abort**: If the SSE body ends — successfully or by
  throwing — before a `done` or `error` block is seen, the coordinator MUST
  NOT emit a `messageReceived` event, but MUST still emit a `draftCleared`
  event so no half-typed draft is left on screen.
- **in-band-error-terminal**: An `error` block MUST end the turn as not
  committed and MUST emit `messageFailed(localID:, reason:)`, with `reason`
  taken from the block's decoded `message`, or `"Chat failed."` when the
  payload does not decode. A `2xx` HTTP status on the message request MUST
  NOT be treated as evidence the turn succeeded — adh answers `200` and
  reports failure in-band.
- **transport-error-on-stream-failure**: If reading the SSE body throws for
  a reason other than the coordinator having been destroyed, the coordinator
  MUST emit `transportError(message:)` with the underlying error's
  description (or a fallback string). If `control.destroyed` is `true`
  when the throw is caught, no `transportError` MUST be emitted for it.
- **error-description-prefers-persona-chat-error**: `describe(_:fallback:)`
  MUST return `PersonaChatError.description` for a `PersonaChatError`, MUST
  return `fallback` for a `CancellationError`, MUST return `(error as
  NSError).localizedDescription` for any other error when that string is
  non-empty, and MUST return `fallback` when it is empty.

### Tool call correlation

- **tool-call-opened**: A `tool_call_started` block MUST emit
  `commandInvoked` carrying a freshly generated invocation `id`,
  `commandName` and `argumentsJSON` taken from the payload (`arguments`
  defaults to an empty string when absent), `invokerID` equal to
  `participantID`, `invokerKind: .other`, and `requestedAt` set to the time
  the block was processed. A block that fails to decode MUST produce no
  event.
- **tool-call-ids-distinct**: Two invocations of the same `commandName`
  within a turn MUST receive distinct `id` values.
- **tool-call-closed**: A `tool_call_completed` block MUST be correlated to
  the oldest still-open invocation sharing its `commandName` (first-in,
  first-out per command name), consuming that invocation; it MUST emit
  `commandCompleted` with that invocation's `id` as `result.invocationID`,
  `ok` taken from the payload, `resultJSON` set to the payload's `result`
  (or `""` if absent) when `ok` is `true` and `nil` when `ok` is `false`,
  `errorMessage` set to `nil` when `ok` is `true` and to the payload's
  `result` (or `""` if absent) when `ok` is `false`, and `completedAt` set
  to the time the block was processed. A completion whose `commandName` has
  no open invocation MUST produce no event — it is dropped rather than
  invented.
- **tool-payloads-excluded-from-draft**: `tool_call_started` and
  `tool_call_completed` blocks MUST NOT contribute any text to
  `draftUpdated` or to the committed `Message`; only `token` block text is
  accumulated.
- **open-invocations-cleared-per-turn**: `openInvocations` MUST be cleared
  at the end of every turn, so an invocation left open by an aborted turn
  can never be matched to a `tool_call_completed` block belonging to a
  later turn.

### Cancellation and destruction

- **destroy-cancels-and-closes**: `destroy()` MUST cancel the coordinator's
  in-flight turn (if any), MUST emit exactly one `draftCleared` event for
  `participantID`, and MUST finish `inboundEvents` — all synchronously,
  without the caller awaiting anything.
- **destroy-idempotent-flag**: After the first call to `destroy()`,
  `destroyed` MUST read `true` for the remaining lifetime of the
  coordinator.
- **destroy-nonisolated**: `destroy()` MUST be callable synchronously from
  any isolation context — including a `deinit` or a SwiftUI
  `onDisappear` — without first hopping onto the coordinator's actor, so a
  `send` already queued on the actor cannot start a new turn after the
  caller believes the coordinator is gone.
- **turn-control-manual-locking**: `TurnControl` MUST serialize every read
  and write of its `task` and `isDestroyed` state behind its own `NSLock`,
  since it is declared `final class: @unchecked Sendable` rather than an
  `actor`, specifically so `destroy()` can mutate it synchronously from a
  non-isolated, non-async context.

### Concurrency and isolation

- **coordinator-actor-isolated**: `PersonaChatCoordinator` MUST be declared
  as an `actor`, so `send`, `setLocalTyping`, `submitWidgetResponse`, and
  the turn-processing state (`conversationID`, `openInvocations`) are only
  ever mutated by one call at a time. Only `inboundEvents`, `participantID`,
  `conversationsURL`, and `control` (the `TurnControl`) are declared
  `nonisolated` and are safe to touch synchronously.
- **authorize-injected**: The coordinator MUST attach no credentials of its
  own. Every outgoing `URLRequest` MUST be passed through the
  caller-supplied `Authorize` closure, and the coordinator MUST hold no
  host, credential, or session state beyond `options` and that closure.
- **authorize-is-sendable**: `Authorize` MUST be declared `@Sendable
  (URLRequest) async throws -> AuthorizedResponse`, so a host's
  implementation MUST be safe to invoke from the coordinator's actor
  context without additional synchronization supplied by the coordinator.
- **concurrent-turns**: NEEDS REVIEW: Not implemented in source. `TurnControl` stores only a single `Task<Void, Never>?`; a second `send()` call issued before the first turn's `done`/`error`/abort overwrites that reference (`adopt` replaces `self.task` unconditionally), so `destroy()` after two overlapping sends only cancels the most recently adopted turn — the earlier turn keeps running and calling `options.authorize`, even though its emitted events are silently dropped once `inboundEvents` has finished. Separately, `ensureConversation()` re-checks `conversationID` before suspending on `await options.authorize(request)`; because actors are reentrant across `await`, two `send()` calls issued back-to-back before either has awaited a response can both observe `conversationID == nil` and each `POST` a distinct conversation, with whichever response returns last winning the race and the other becoming an orphaned server-side conversation. No test in `PersonaChatCoordinatorTests.swift` exercises two `send()` calls without awaiting the first turn's completion — `test_pcc002_conversationReuse_twoSendsShareOneConversation` explicitly serializes its two sends with `f.collector.wait(for: 4)` in between — so this is unresolved by both the source and its test suite. Resolving it requires either serializing `send()` behind an actor-held queue, tracking one task per turn in `TurnControl` instead of one per coordinator, or documenting that a second concurrent `send()` before the first turn ends is itself a caller error the type should reject.

### SSEParser

- **sse-block-boundary**: `SSEParser.consume(_:)` MUST buffer partial input
  across calls and only yield a block once a complete `\n\n` separator has
  been seen, so a block split across chunk boundaries — mid-word or
  mid-separator — is neither truncated nor duplicated.
- **sse-default-event-name**: A block with no `event:` line MUST be treated
  as `event: "message"`.
- **sse-comments-ignored**: Within a block, a line that is neither
  `event:`-prefixed nor `data:`-prefixed (including a `:` comment, an
  `id:` line, or a `retry:` line) MUST be ignored; multiple `data:` lines
  MUST be joined with `\n` in encounter order.
- **sse-single-leading-space-stripped**: A `data:` line's value MUST have
  at most one leading space stripped (the SSE convention), never every
  leading space.
- **sse-invalid-utf8-dropped**: A block whose raw bytes cannot be decoded
  as UTF-8 text, or that decodes to an empty string, MUST be silently
  dropped and MUST NOT be yielded from `consume(_:)`.

### Side effects, persistence, and defaults

- **network-only-side-effect**: The coordinator's only side effect MUST be
  network I/O performed through the injected `Authorize` closure — a `POST`
  to `<baseURL>/chat/conversations` and a `POST` to
  `<baseURL>/chat/conversations/<id>/messages`. It MUST NOT read or write
  the file system, spawn a process, or post a system notification.
- **no-persistent-storage**: The coordinator MUST NOT write any state to
  disk. `conversationID` and `openInvocations` MUST exist only in actor
  memory for the lifetime of the `PersonaChatCoordinator` instance, and
  MUST be lost when the instance is deallocated.
- **default-authorize-factory**: The module MAY provide
  `urlSessionAuthorize(session:)`, a default `Authorize` built on
  `URLSession.bytes(for:)` that forwards each completed line (through its
  trailing `\n`, plus any final partial line at stream end) to the caller
  as one `Data` chunk. It attaches no credentials; a host that needs auth
  MUST wrap it rather than use it directly.

## Appearance

Not applicable — this is a non-UI actor (a backend coordinator), not a
visual component.

## States

Not applicable — this is a non-UI actor (a backend coordinator), not a
visual component. Its runtime phases (`TurnStatus.thinking` /
`.responding` / `.retrying`, and the `destroyed` flag) are specified under
Behavioral Requirements, not here.

## Accessibility

Not applicable — this is a non-UI actor (a backend coordinator), not a
visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pcc-001 | conversation-lazy-creation | Coordinator constructed; no `send()` called | Zero HTTP requests recorded — `test_pcc001_lazyConversation_constructedCoordinatorMakesNoRequests` |
| pcc-002 | conversation-reuse | `send("one")`, wait for the turn to reach 4 events, then `send("two")` | Exactly 1 request to `/conversations`, 2 requests to `/messages` — `test_pcc002_conversationReuse_twoSendsShareOneConversation` |
| pcc-003 | no-history-in-request | `send(text: "hello", attachments: [])` | POST body to `/messages` has JSON keys exactly `["message"]`, `message == "hello"` — `test_pcc003_noHistory_requestCarriesOnlyTheNewMessage` |
| pcc-004 | draft-accumulates-full-text | SSE `token("Hel")`, `token("lo")`, `done` | `draftUpdated.text` sequence is `["Hel", "Hello"]`, not `["Hel", "lo"]` — `test_pcc004_accumulate_draftsCarryTheWholeTextSoFar` |
| pcc-005 | commit-once, received-message-shape | Same stream as pcc-004 | Exactly one `messageReceived` with `text == "Hello"`, followed by a `draftCleared`; the commit event precedes the clear event — `test_pcc005_commitOnce_oneMessageThenTheDraftClears` |
| pcc-006 | no-commit-on-abort, transport-error-on-stream-failure | Stream yields `token("par")` then the body throws mid-turn (a network error) instead of `done` or `error` | No `messageReceived`; a `draftCleared` and a `transportError` are both emitted — `test_pcc006_noCommitOnAbort_truncatedReplyDoesNotCommit` |
| pcc-007 | heartbeat-dropped | SSE `open`, `token("hi")`, `done` | `draftUpdated.text == ["hi"]`; exactly 3 non-status-changed events total (draft, message, clear) — `test_pcc007_dropOpen_theHeartbeatIsNotATranscriptEvent` |
| pcc-008 | unknown-events-ignored, malformed-token-fallback | SSE `quux` (unrecognized event), `token("hi")`, `done` | Turn completes normally; committed message text is `"hi"` — `test_pcc008_unknownEvents_areIgnoredAndTheStreamContinues` |
| pcc-009 | tool-call-opened, tool-call-closed | SSE `tool_call_started(name: "search", arguments: {"q":"x"})`, `tool_call_completed(name: "search", ok: true, result: {"hits":2})`, `done` | `commandInvoked.invocation.commandName == "search"`, `argumentsJSON == {"q":"x"}`; `commandCompleted.result.invocationID == invocation.id`, `ok == true`, `resultJSON == {"hits":2}` — `test_pcc009_toolCalls_completionCorrelatesToItsInvocation` |
| pcc-010 | tool-call-ids-distinct | Two `tool_call_started(name: "search")` blocks with no completions, then `done` | The two `commandInvoked.invocation.id` values are distinct — `test_pcc010_invocationIDs_twoCallsOfOneCommandGetDistinctIDs` |
| pcc-011 | tool-payloads-excluded-from-draft | `token("Looking")`, `tool_call_started`, `tool_call_completed(result: "classified")`, `token(" — found it.")`, `done` | `draftUpdated.text` sequence is `["Looking", "Looking — found it."]`; neither draft contains `"secret"` or `"classified"`; committed message is `"Looking — found it."` — `test_pcc011_toolTextSeparation_theDraftCarriesNoToolPayloads` |
| pcc-012 | in-band-error-terminal | `token("par")`, `error({"message":"upstream exploded"})` | No `messageReceived`; `messageFailed(localID, "upstream exploded")` emitted for the `send`'s own `localID` — `test_pcc012_errorTerminal_theTurnFailsInsteadOfCommitting` |
| pcc-013 | in-band-error-terminal | SSE body is a single `error({"message":"model refused"})` block on an HTTP 200 response | `messageFailed` reason is `"model refused"`; no `messageReceived` — `test_pcc013_inBandErrors_http200IsNotSuccess` |
| pcc-014 | conversation-creation-failure-status, conversation-creation-failure-reported-as-message-failure | `/conversations` responds with HTTP 500 | `messageFailed(reason: "Couldn't start the conversation (500).")`; no request to `/messages` is made — `test_conversationCreationFailure_isReportedAgainstTheMessage` |
| pcc-015 | destroy-cancels-and-closes, transport-error-on-stream-failure | `send()` a turn whose stream hangs after one `token`; call `destroy()` mid-turn | The in-flight cancellation flag becomes true; a `draftCleared` is emitted; no `messageReceived`; no `transportError` (because `control.destroyed` is true when the cancellation is caught) — `test_pcc014_destroyAuthoritative_cancelsTheInFlightTurn` |
| pcc-016 | destroyed-rejects-send | `destroy()`, then `send(text: "hey", attachments: [])` | Throws `PersonaChatError.destroyed`; zero HTTP requests recorded — `test_pcc015_noReuseAfterDestroy_sendFailsFast` |
| pcc-017 | turn-status-thinking-on-start, turn-status-retrying-on-server-signal, turn-status-responding-on-first-token, turn-status-cleared-on-exit, status-dual-channel, status-kind-mapping, status-words-always-nil | SSE `status({"phase":"retrying"})`, `token("hi")`, `done` | `onStatus` callback sequence is `[.thinking, .retrying, .responding, nil]`; every one of those four also arrives as a `statusChanged` event whose `status?.kind` is `.think`/`.retry`/`.respond`/`nil` respectively and whose `status?.words` is always `nil`; exactly 3 non-status-changed transcript events total — `test_pcc016_statusOutOfBand_retryDrivesStatusNotTheTranscript` |
| pcc-018 | turn-status-cleared-on-exit | Truncated stream (no `done` or `error`) | The last `onStatus` value observed is `nil` — `test_statusClearsOnEveryExitPath` |
| pcc-019 | attachments-unsupported | `send(text: "hey", attachments: [StubAttachment()])` | Throws `PersonaChatError.attachmentsUnsupported`; zero HTTP requests recorded — `test_attachmentsAreRefusedRatherThanDroppedSilently` |
| pcc-020 | commit-once | SSE body is a single `done({})` block, no `token` blocks | One `messageReceived` with `text == ""` — `test_emptyReplyStillCommits` |
| pcc-021 | sse-block-boundary | `SSEParser.consume` fed the bytes of one `event:token\ndata:{"text":"hi"}\n\n` block split across two arbitrary byte-range chunks, mid-word | Zero blocks returned from a `consume` call that ends before the full `\n\n` separator has arrived; exactly one `SSEBlock(event: "token", data: "{\"text\":\"hi\"}")` returned once the separator completes — traced to `SSEParser.consume`'s buffer/range logic (source; no dedicated `SSEParserTests.swift` exists) |
| pcc-022 | sse-default-event-name, sse-comments-ignored | Block text `": a comment\ndata: hello\n\n"` (no `event:` line) | Returned block has `event == "message"`, `data == "hello"`; the comment line contributes nothing — traced to `SSEParser.parse` (source) |
| pcc-023 | sse-single-leading-space-stripped | Block text `"event: token\ndata:  two spaces\n\n"` | Returned `data == " two spaces"` (only the first space stripped) — traced to `SSEParser.parse`'s `value.hasPrefix(" ")` guard (source) |
| pcc-024 | sse-invalid-utf8-dropped | A chunk containing an invalid UTF-8 byte sequence between two `\n\n` separators | `consume` returns no block for that segment; parsing continues normally on the next segment — traced to `SSEParser.consume`'s `String(data:encoding:.utf8)` guard (source) |
| pcc-025 | model-override | `PersonaChatCoordinatorOptions.model = "model-x"` vs. `model = nil` | The `/conversations` POST body includes `"model":"model-x"` in the first case and omits the `model` key entirely in the second — traced to `CreateConversationBody`'s synthesized `Encodable` conformance (source) |
| pcc-026 | send-returns-local-id-immediately | `send(text:, attachments: [])` called against a stream that never emits any block | The call returns a `String` `localID` before any SSE block has been read — traced to `send`'s `return localID` immediately after `control.adopt(turn)` succeeds (source) |
| pcc-027 | local-typing-noop | `setLocalTyping(true)` | Returns without throwing and produces no `InboundEvent` — traced to the empty method body (source) |
| pcc-028 | widget-response-unsupported | `submitWidgetResponse(_:)` called with any `WidgetResponse` | Throws `PersonaChatError.widgetsUnsupported` unconditionally — traced to the method body (source) |
| pcc-029 | destroy-idempotent-flag, destroy-nonisolated | `destroy()` called twice in a row, then `send(...)` | `destroyed == true` after the first call and remains `true` after the second; the subsequent `send` throws `PersonaChatError.destroyed` — traced to `TurnControl.destroy()`'s sticky `isDestroyed = true` (source) |
| pcc-030 | open-invocations-cleared-per-turn | Turn A opens `tool_call_started(name: "x")` then aborts without a matching completion; a later, fresh turn B receives `tool_call_completed(name: "x")` | Turn B's completion finds no open invocation for `"x"` and produces no `commandCompleted` — traced to `defer { openInvocations.removeAll() }` in `runTurn` (source) |
| pcc-031 | error-description-prefers-persona-chat-error | `ensureConversation()` throws `PersonaChatError.conversationFailed(status: 503)`, reaching `describe(_:fallback:)` | Returned string is exactly `"Couldn't start the conversation (503)."` — `PersonaChatError.description`, not the `fallback` and not an `NSError` bridge — traced to `describe`'s `error as? PersonaChatError` branch (source) |
| pcc-032 | authorize-injected, authorize-is-sendable, no-persistent-storage, network-only-side-effect, coordinator-actor-isolated, turn-control-manual-locking | Inspection of the type declarations, not a runtime call | `PersonaChatCoordinator` is declared `actor`; `Authorize` is declared `@Sendable`; `TurnControl` is `final class: @unchecked Sendable` guarded by `NSLock`; neither source file references `FileManager`, `Process`, or `UserDefaults` — traced to the declarations themselves (source; a structural/compile-time check, not a unit test) |
| pcc-033 | default-authorize-factory | `urlSessionAuthorize()` used as the `Authorize` against a `URLSession` whose response streams bytes incrementally | Each `AuthorizedResponse.body` chunk ends with `\n` (or is the final partial line at stream end); `statusCode` reflects the underlying `HTTPURLResponse.statusCode`, or `0` if the response is not an `HTTPURLResponse` — traced to `urlSessionAuthorize`'s `pump` task (source; `PersonaChatCoordinatorTests.swift` uses a custom `Authorize` fixture instead of this default) |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `personaSlug` | `String` | *(required)* | Persona to converse with; adh resolves everything else — display name, avatar, model, system prompt — from this slug. |
| `baseURL` | `URL` | *(required)* | Root of the adh chat API, e.g. `https://adh.example.com/api`; `chat/conversations` and `chat/conversations/<id>/messages` are appended to it. |
| `authorize` | `Authorize` (`@Sendable (URLRequest) async throws -> AuthorizedResponse`) | *(required)* | Credential-attaching transport injected by the host; the coordinator never constructs or stores credentials itself. |
| `model` | `String?` | `nil` | Overrides the persona's configured model for the conversation this coordinator creates; omitted from the request entirely when `nil`. |
| `participantID` | `String?` | `nil` (resolves to `personaSlug`) | Identifies the persona in every `InboundEvent` the coordinator emits. |
| `onStatus` | `(@Sendable (TurnStatus?) -> Void)?` | `nil` | Receives turn-phase transitions in addition to the `statusChanged` event; cleared with `nil` when a turn ends. |
| `session` (via `urlSessionAuthorize(session:)`) | `URLSession` | `.shared` | Underlying session used only when a host opts into the coordinator's own default `Authorize` factory instead of supplying one. |

## Deep Linking

Not applicable: `PersonaChatCoordinator` exposes no URL scheme or route of
its own. `baseURL` is an API root supplied by the caller, not a
deep-linkable app URL, and neither source file parses or constructs a
`{{app_scheme}}://` or `https://{{app_domain}}/` link.

## Localization

`InboundEvent.messageFailed(reason:)`
and `.transportError(message:)` carry only the hardcoded English strings
produced by `PersonaChatError.description` and the `fallback` arguments to
`describe(error:fallback:)`: `"PersonaChatCoordinator has been destroyed."`,
`"PersonaChatCoordinator does not support attachments."`,
`"PersonaChatCoordinator does not support widgets."`,
`"Couldn't start the conversation (\(status))."`,
`"Couldn't start the conversation."`, `"The chat request failed."`,
`"The chat stream failed."`, and `"Chat failed."`. None of these is backed
by `NSLocalizedString`, a string catalog, or any other lookup mechanism, and
no error code travels alongside `reason`/`message`, so localizing these messages is the host's job: it switches on the thrown
`PersonaChatError` case, not on the English text. A port keeps the same
strings as its fallback text.

## Accessibility Options

Not applicable — this is a non-UI actor (a backend coordinator); it has no
visual presentation to apply Reduce Motion, Increase Contrast, or
Differentiate Without Color to.

## Feature Flags

Not applicable: no feature-flag or remote-config check appears anywhere in
`PersonaChatCoordinator.swift` or `SSEParser.swift`; every code path this
recipe describes is unconditional.

## Analytics

Not applicable: neither source file emits an analytics or telemetry event.
The only outbound calls are the two adh HTTP requests described under
Behavioral Requirements.

## Privacy

- **Data collected**: The literal text passed to `send(text:attachments:)`,
  plus the caller-supplied `personaSlug`, `model` override, and
  `participantID`. The coordinator collects nothing else — it has no
  analytics or telemetry, and, per `no-history-in-request`, no memory of
  prior turns.
- **Storage**: In-memory only, for the lifetime of the
  `PersonaChatCoordinator` actor instance: the cached `conversationID`, and
  the accumulating draft text of the in-flight turn (`accumulated`, a local
  variable in `consumeStream`, never persisted). Nothing is written to
  disk, `UserDefaults`, or any cache the source constructs
  (`no-persistent-storage`).
- **Transmission**: The message text and persona identifiers are sent as
  the JSON body of two requests to `baseURL` (`.../chat/conversations` and
  `.../chat/conversations/<id>/messages`), through the caller-injected
  `Authorize` closure. Credentials themselves are never seen by the
  coordinator — `Authorize` is an opaque closure the host injects to attach
  whatever credential it holds directly to the `URLRequest`
  (`authorize-injected`). The source does not itself verify that `baseURL`
  uses `https`; enforcing transport security is the caller's
  responsibility.
- **Retention**: None beyond the active turn and the cached
  `conversationID`, both released when the coordinator instance is
  deallocated or `destroy()` is called. adh's own retention of conversation
  history is out of this coordinator's scope — it holds no history itself.

## Logging

Not applicable: neither source file calls `os_log`, `Logger`, `print`, or
any other logging API. Failures are surfaced only through `InboundEvent`
values and thrown `PersonaChatError` values, never written to a log.

## Platform Notes

- **SwiftUI**: This is the source: `PersonaChatCoordinator.swift` and
  `SSEParser.swift`, plain `Foundation` with no SwiftUI dependency at all —
  no `@Observable`, no `View`, no SwiftUI-specific types anywhere in either
  file. A SwiftUI host binds to it only indirectly, through a view model
  (e.g. `ObservableChatViewModel`) that subscribes to `inboundEvents`.
- **Compose**: Start from `kotlinx.coroutines` and `kotlinx.serialization`.
  `AsyncStream<InboundEvent>` maps to a `kotlinx.coroutines.flow.Flow`, or a
  `Channel<InboundEvent>` if buffering semantics need to match
  `.unbounded`. `SSEParser`'s buffered block reader ports directly (Kotlin
  has no built-in SSE parser either). The actor's single-writer guarantee
  has no direct Kotlin analogue — use a single-threaded `CoroutineDispatcher`
  or a `Mutex` guarding `conversationID`/`openInvocations` — and
  `TurnControl`'s `NSLock` becomes a `kotlinx.atomicfu` `AtomicRef`/`Mutex`
  pair holding a cancellable `Job` instead of a `Task`.
- **React/Web**: The toolkit already ships a TypeScript counterpart to this
  exact spec, `PersonaChatBackend.ts`
  (`packages/web/packages/chat/src/backends/`) — start there rather than
  re-deriving the contract. It replaces `URLSession.bytes(for:)` with
  `fetch` plus a `ReadableStream` reader, replaces `AsyncStream` with a
  plain event emitter or async generator, and needs no actor-equivalent
  lock at all, since JavaScript's single-threaded event loop already
  serializes calls the way the Swift `actor` does; `AbortController`
  replaces `TurnControl`.
- **AppKit / UIKit**: Same answer as the SwiftUI bullet — the coordinator
  is plain `Foundation` logic with no UI framework tie. Both an AppKit and
  a UIKit host consume it through the same `Backend` protocol and the same
  `inboundEvents` stream; nothing in `PersonaChatCoordinator.swift` differs
  between the two.
- **WinUI 3**: Implement the coordinator as a class registered as a
  singleton or scoped service, using `System.Net.Http.HttpClient` for both
  POSTs. Read the SSE body via
  `HttpResponseMessage.Content.ReadAsStreamAsync()` wrapped in a
  `StreamReader`, buffering into blocks the same way `SSEParser` does — a
  hand-rolled block accumulator, since `HttpClient` has no built-in SSE
  support. Serialize and deserialize with `System.Text.Json`
  (`JsonSerializer.Serialize<SendMessageBody>` /
  `JsonSerializer.Deserialize<TokenPayload>`, mirroring the
  encode/decode-with-fallback pattern). Replace `AsyncStream<InboundEvent>`
  with a `System.Threading.Channels.Channel<InboundEvent>`, exposed to
  WinUI as an `IAsyncEnumerable<InboundEvent>` via
  `ChannelReader.ReadAllAsync()` so a page can `await foreach` it on the UI
  thread. Replace the actor's single-writer serialization with a
  `SemaphoreSlim(1, 1)` guarding `conversationID` and `openInvocations`,
  since C# has no actor-isolation model; replace `TurnControl`'s
  `NSLock` + `Task` pair with a `CancellationTokenSource` field, cancelled
  synchronously from a `Destroy()` method. `Windows.Storage` has no role
  here at all — like the Swift source, the port MUST persist nothing to
  disk. `ObservableCollection` and `INotifyPropertyChanged` belong to the
  *consuming* chat view model, not the coordinator itself, exactly as
  `ObservableChatViewModel` — not `PersonaChatCoordinator` — owns
  presentation state on Apple.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Coordinator/` | unverified |

## Design Decisions

- **Decision**: `describe(_:fallback:)` names the concrete
  `PersonaChatError` type in its `as?` cast instead of casting to
  `CustomStringConvertible`.
  **Rationale**: `any Error` bridges to `NSError` on Apple platforms, and
  `NSError` itself conforms to `CustomStringConvertible` — so `error as?
  CustomStringConvertible` succeeds for every error, not just
  `PersonaChatError`, which silently skipped the `NSError.localizedDescription`
  fallback for every non-`PersonaChatError` case and surfaced a raw Swift
  `String(describing:)` dump (e.g. a verbose `DecodingError` case) instead
  of the friendlier message the function exists to prefer. This is a fixed
  workaround, documented inline in the source, not a hypothetical risk.
  **Approved**: pending
- **Decision**: `send`'s turn `Task` captures `self` weakly and is
  deliberately detached from the caller's own task rather than being a
  child task.
  **Rationale**: The turn outlives the `send` call that started it — the
  reply arrives later, on `inboundEvents` — so tying it to the caller's
  task would cancel the reply the moment the caller's own work finished.
  The capture is `weak` because `TurnControl` holds the task and the actor
  holds `TurnControl`; a strong capture would keep the coordinator alive
  for as long as a turn it is no longer wanted for.
  **Approved**: pending
- **Decision**: Cancellation state (`TurnControl`) lives outside the actor,
  guarded by an `NSLock` instead of actor isolation.
  **Rationale**: `destroy()` has to cancel a turn immediately, from any
  context, including one holding no async capability at all — a `deinit`,
  a SwiftUI `onDisappear`. Actor isolation would turn `destroy()` into a
  request to cancel (queued behind whatever the actor is doing) rather
  than an immediate cancellation.
  **Approved**: pending
- **Decision**: Tool call correlation is by `commandName` and FIFO arrival
  order, not by a server-supplied invocation id.
  **Rationale**: adh's `tool_call_completed` payload carries a `name` and
  no id, so the coordinator has nothing else to correlate on; it assumes
  adh completes calls to the same command in the order it started them.
  **Approved**: pending
- **Decision**: A turn-phase transition is reported through both the
  `onStatus` callback and the `statusChanged` event, with neither derived
  from the other at the call site.
  **Rationale**: `onStatus` is kept for its existing callers while
  `statusChanged` is the newer, out-of-band channel
  (`status-not-a-transcript-event`); both are driven from the same single
  `report(_:via:)` call so they can never disagree, but the source
  maintains them as two explicit sinks rather than one deriving from the
  other.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | passed | Privacy and Data |

`explicit-error-handling` is partial: in-band SSE errors, conversation
creation failures, and stream-transport failures each surface as a typed
`InboundEvent` or thrown `PersonaChatError`, but the outbound message
body's encoding failure is swallowed by `try?` with no error path (see
the open question on message-encode-failure-swallowed), and several
malformed-payload cases — an undecodable SSE block, an unmatched
`tool_call_completed` — are dropped silently by design rather than
surfaced as an error. `graceful-degradation` passes: every one of those
malformed-input paths degrades to "drop the block and keep streaming"
rather than crashing or corrupting the transcript. `fault-tolerance` is
partial because of the open question on concurrent-turns:
`TurnControl` tracks only one in-flight task, so
overlapping `send()` calls can leave a turn `destroy()` cannot cancel, and
`ensureConversation()`'s reentrant check can create two orphaned server-side
conversations. `separation-of-concerns` passes: the coordinator holds no
history, no prompt assembly, and no credentials, delegating all three to
adh and the injected `Authorize` closure. `unit-test-coverage` is partial:
sixteen `pcc-*` vectors plus four supplementary tests cover the
SSE-translation and lifecycle contract thoroughly, but nothing in the repo
exercises `SSEParser` directly or the concurrent-`send()` scenario above.
`secure-transport` is partial: requests go through the caller's
`Authorize` closure and whatever `baseURL` scheme the host configures, but
the source never checks that `baseURL` uses `https`, so an `http://` base
would be sent unencrypted with no warning from the coordinator.
`data-minimization` and `data-retention-policy` pass: the coordinator
holds no history and retains nothing beyond the active turn and the cached
conversation id.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Fixed pcc-006 to match throwing-close test; noted clean-close emits no transportError. |
