
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

