
### Attachments & Media

- **attachment-identity**: An `Attachment` MUST expose a stable `id` string, a
  `mediaType` (a `MediaType` with a `Sendable`/`Hashable` `identifier` string
  on apple, a plain string-keyed type on web), an `AttachmentSource`, and an
  `AttachmentPresentation`; it MAY expose `displayName` and `byteSize`.
- **attachment-source-duality**: `AttachmentSource` MUST be exactly one of two
  cases — `remote(URL)` (apple) / `{ kind: 'remote', url }` (web), a
  fetch-by-reference resource, or `inline(Data)` / `{ kind: 'inline', data }`,
  bytes already carried in memory.
- **attachment-presentation-duality**: `AttachmentPresentation` MUST be
  exactly one of `inline` or `attached`, describing how a consumer renders the
  attachment relative to its message; no third value is defined.
- **inline-document-empty-contract**: `InlineDocument` MUST add no members
  beyond `Attachment`; it exists only as a named subtype for attachments
  rendered inline in a message body.
- **interactive-widget-response-flag**: `InteractiveWidget` (an
  `InlineDocument`) MUST expose `hasResponse` indicating whether a
  `WidgetResponse` has already been recorded for it.
- **widget-response-identity**: `WidgetResponse` MUST carry `widgetID`,
  `respondingParticipantID`, and `payloadJSON`, an opaque, already-serialized
  JSON string, never a typed payload.

### Backend & Inbound Events

- **backend-send-returns-local-id**: `Backend.send(text:attachments:)` MUST
  return the `localID` the backend assigns at submission time; a
  server-assigned id, if any, MUST arrive later only through
  `InboundEvent.messageAccepted(localID:serverID:at:)`.
- **backend-send-is-fallible**: `send` MUST be able to fail (`async throws` on
  apple, a rejected `Promise` on web) rather than guarantee delivery.
- **backend-is-reference-type**: `Backend` MUST be a class-bound protocol
  (`AnyObject`); a struct or enum MUST NOT conform, because `inboundEvents`
  and any internal mutable state need stable identity across calls.
- **backend-set-local-typing**: `setLocalTyping(_:)` MUST report the LOCAL
  participant's own typing state to the backend; it MUST NOT be conflated with
  `InboundEvent.typing`, which reports another participant's typing state
  arriving from the bus.
- **backend-submit-widget-response**: `submitWidgetResponse(_:)` MUST submit a
  `WidgetResponse` to the backend and MUST be fallible the same way `send` is.
- **backend-single-consumer-stream**: `inboundEvents` MUST be a single cold,
  cancellable asynchronous sequence (`AsyncStream` on apple, an async iterable
  on web) per `Backend` instance; fanning events out to multiple observers is
  the orchestrator's job, not the `Backend`'s.
- **inbound-event-closed-set**: `InboundEvent` MUST be a closed set — message
  lifecycle (`messageAccepted`, `messageDelivered`, `messageFailed`,
  `messageReceived`), read state (`readMarkerAdvanced`), drafts
  (`draftUpdated`, `draftCleared`), roster (`participantJoined`,
  `participantDeparted`), `typing`, widgets (`widgetPresented`), commands
  (`commandInvoked`, `commandCompleted`), transport (`transportError`), and,
  apple-only, `statusChanged` (see Cross-Platform Divergences).
- **draft-replaces-not-appends**: `draftUpdated`'s `text` MUST be the WHOLE
  draft so far; each event MUST REPLACE the receiver's stored text for that
  `participantID`, never append to it — a backend that emits fragments would
  otherwise produce a transcript missing every reply's prefix, with nothing to
  catch the mistake.
- **draft-commit-or-abort**: `draftCleared` MUST end a participant's draft. If
  the draft finalized, a `messageReceived` for the same content MUST follow;
  if it was aborted, no `messageReceived` MUST arrive for it.
- **draft-never-in-messages**: An active draft MUST NOT appear in
  `ChatViewModel.messages` before it commits as a `Message` via
  `messageReceived`.
- **read-marker-single-cursor**: There MUST be exactly one `ReadReceipt` per
  (conversation, participant); a `readMarkerAdvanced` for a participant that
  already holds a cursor MUST replace that cursor's `upToMessageID`/`at`
  rather than adding a second entry. This is deliberately narrower than the
  per-message read receipts of Matrix `m.read`, XMPP XEP-0333 `displayed`,
  Slack `conversations.mark`, or Discord `READ_STATE` — one cursor per
  participant, not one ack per message.
- **command-invocation-id-uniqueness**: `CommandInvocation.id` MUST be unique
  per invocation and MUST NOT be derived from `commandName`; two parallel
  invocations of the same command MUST receive distinct ids.
- **command-channel-separation**: Command activity (`commandInvoked`,
  `commandCompleted`) MUST be its own channel; it MUST NOT be folded into
  `draftUpdated` or otherwise committed into a user-visible `Message`.
- **status-channel-separation** (apple): `statusChanged` MUST be out-of-band —
  it MUST NOT create or mutate a `Message` or an `ActiveDraft` — while still
  notifying observers.
- **transport-error-is-a-signal-not-a-policy**: `transportError(message:)`
  MUST carry a diagnostic string communicating that something failed; the
  contract itself defines no retry, backoff, or reconnection behavior (see
  Edge Cases and Design Decisions).

### Chat State & View Model

- **view-model-main-actor** (apple): `ChatViewModel` MUST be `@MainActor`
  isolated; every property read and method call happens on the main actor,
  matching where a view's layout and action handlers run.
- **view-model-sendable-reference-type** (apple): `ChatViewModel` MUST be
  declared `AnyObject, Sendable`; conformers achieve that safety through
  `@MainActor` isolation, never through `@unchecked Sendable`.
- **view-model-surface**: `ChatViewModel` MUST expose `conversation`,
  `participants`, `messages`, `displayConfig`, `pendingPermissions`,
  `pendingWidgets`, `typingParticipants`, `readMarkers`, `activeDrafts`, and a
  per-platform command-activity collection (see Cross-Platform Divergences),
  plus `addObserver`/`removeObserver`, `submitMessage`, `markRead`,
  `setLocalTyping`, `respondToWidget`, `respondToPermission`, and
  `listCommands`.
- **mark-read-implicit-range**: `markRead(messageID:)` MUST advance the local
  participant's read cursor to `messageID`, implicitly marking every earlier
  message read; it MUST NOT require marking messages one at a time.
- **observer-registration**: A `ChatStateObserver` MUST register through
  `addObserver`/`removeObserver`; `chatDidUpdate(_:)` MUST be invoked on the
  main actor (apple: a `@MainActor` protocol method).
- **chat-update-is-invalidation-not-payload**: Every `ChatUpdate` case other
  than `error` and `statusChanged` MUST carry no payload; it signals only that
  the observer should re-read the corresponding `ChatViewModel` property —
  `.messagesChanged` is read back through `messages`, not through the update
  itself.
- **orchestrator-adds-permission-store**: `Orchestrator` MUST extend
  `ChatViewModel` with exactly one additional member, `permissionStore`; a
  plain `ChatViewModel` reference MUST NOT expose it.

### Commands

- **command-shape**: A `Command` MUST expose `name`, `description`,
  `allowedInvokers` (a set of `CommandInvoker`), an optional `permission`, and
  `argumentSchema`, an opaque schema string.
- **command-invoker-closed-set**: `CommandInvoker` MUST be exactly `user` or
  `other`, with no other case.
- **skill-tool-specialization**: `Skill` and `Tool` MUST each extend `Command`
  with exactly one additional identifying field — `skillIdentifier` and
  `builtInIdentifier` respectively — and MUST add no other member.
- **command-result-shape**: `CommandResult` MUST carry `invocationID`
  (matching the `CommandInvocation.id` it completes), `ok`, an optional
  `resultJSON`, an optional `errorMessage`, and `completedAt`.
- **orphan-result-dropped**: A `commandCompleted` event whose
  `result.invocationID` matches no invocation the view model has seen MUST be
  dropped, not turned into a new activity entry.
- **command-activity-in-place-update** (apple): A `commandCompleted` event
  MUST fill the matching `CommandActivity`'s `result` in place, at the same
  `id` and index, rather than appending a second entry.

### Configuration & Hooks

- **chat-config-shape**: `ChatConfig` MUST supply `conversationID`,
  `localParticipantID`, `initialParticipants`, `commands`, `observingHooks`,
  `gatingHooks`, `permissionStore`, `backend`, and `display`.
- **display-config-shape**: `DisplayConfig` MUST expose `showAvatars`,
  `showReadReceipts`, `showTypingIndicators`, an optional `maxParticipants`,
  `allowJoining`, `allowDeparting`, an optional `themeIdentifier`, and
  `reducedMotion`, all as plain read-only values; the type itself MUST supply
  no default-computing logic.
- **gating-hook-shape**: A `GatingHook` MUST declare the `GatingPoint`s it
  participates in via `points` and MUST answer `gate(point:context:)` with a
  `HookDecision` of exactly `proceed` or `block(reason:)`.
- **observing-hook-shape**: An `ObservingHook` MUST declare its `points` and
  MUST implement `observe(point:context:)`, returning no value — a
  fire-and-forget notification, never a gate.
- **gating-and-observing-points-are-distinct-closed-sets**: `GatingPoint` and
  `ObservingPoint` MUST each be a closed enumeration, and MUST NOT be used
  interchangeably; `willEmitUpdate` is the one point name both enumerations
  share, and each hook type receives it only through its own protocol.
- **hook-context-shape**: `HookContext` MUST expose `conversationID` and an
  opaque `payloadJSON` string; it MUST NOT expose a typed payload.

### Messages, Conversations & Participants

- **message-shape**: A `Message` MUST expose an optional server `id`, a
  required `localID`, `senderID`, `text`, an optional `timestamp`,
  `attachments`, and `deliveryStatus`.
- **message-delivery-status-closed-set**: `MessageDeliveryStatus` MUST be
  exactly one of `composing`, `sending`, `sent`, `delivered`,
  `failed(reason:)`, or `received`.
- **conversation-shape**: A `Conversation` MUST expose `id`, `createdAt`, an
  optional `title`, and `participants`.
- **participant-shape**: A `Participant` MUST expose `id`, `displayName`, an
  optional `avatarURL`/`profileURL`, `address`, a set of `kinds`
  (`ParticipantKind`), and `conversationState` (`ParticipantConversationState`).
- **participant-kind-and-state-closed-sets**: `ParticipantKind` MUST be
  exactly `user`, `persona`, or `observer`; `ParticipantConversationState`
  MUST be exactly `joining`, `joined`, `departing`, or `departed`.
- **read-receipt-shape**: A `ReadReceipt` MUST expose `participantID`,
  `upToMessageID`, and `at`.

### Permissions

- **permission-shape**: A `Permission` MUST expose `id`,
  `displayPromptTemplate`, and an optional `defaultDecision`.
- **permission-decision-closed-set**: `PermissionDecision` MUST be exactly one
  of `allowOnce`, `allowAlways`, `denyOnce`, or `denyAlways`.
- **permission-prompt-shape**: A `PermissionPrompt` MUST expose `id`,
  `permission`, `requesterID`, `displayPrompt`, and `requestedAt`.
- **permission-store-is-reference-type**: `PermissionStore` MUST be a
  class-bound (`AnyObject`), `Sendable` type; memoized decisions require
  stable identity, so a struct or enum MUST NOT conform.
- **permission-store-is-synchronous**: `PermissionStore.decision(for:requesterID:)`
  and `remember(decision:for:requesterID:)` MUST be synchronous calls a
  conformer answers directly, never through an async round trip; a conformer
  that needs to serialize concurrent access MUST do so itself (see Edge
  Cases), since the protocol grants no actor isolation.

### ScriptedBackend (reference conformer, apple)

- **scripted-backend-two-modes**: `ScriptedBackend` MUST support exactly two
  construction modes: a fixed `script` that replays once and finishes the
  stream, or an `opening` + `turn` conversation that replays an unprompted
  opening and then one reply per `send`, and never finishes the stream.
- **scripted-backend-start-timing**: In fixed-script mode, `.immediately` MUST
  begin replay at `init`, with no `send` required; `.onFirstSend` MUST stay
  silent until the first `send` and MUST NOT replay again on later sends.
- **scripted-backend-beat-delay-leads**: Each `Beat`'s `delay` MUST be applied
  BEFORE yielding its event, not after, so a script can express "wait, then
  act" even for its very first event, and so pacing reads as a timeline.
- **scripted-backend-local-id-sequence**: Each `send` MUST assign a new
  sequential local id of the form `"<localIDPrefix>-N"` starting at 1, MUST
  append the call to `sent`, and MUST return that id.
- **scripted-backend-serial-replay-chain**: Two `send` calls in quick
  succession MUST NOT interleave their turns' events; each new turn's beats
  MUST await the previous turn's replay before yielding.
- **scripted-backend-typing-and-widget-recording-only**: `setLocalTyping` and
  `submitWidgetResponse` on `ScriptedBackend` MUST only record the call
  (`typingCalls`, `widgetResponses`); `setLocalTyping` MUST NOT start a fixed
  script's replay.

### Cross-Platform Divergences

- **status-channel-is-apple-only**: apple's `InboundEvent` adds
  `statusChanged(participantID:status:)` and `ChatViewModel` adds
  `statuses: [String: ChatStatus]`, matched by
  `ChatUpdate.statusChanged(participantID:)`; the web `InboundEvent`,
  `ChatUpdate`, and `ChatViewModel` given here have no equivalent case or
  property. `ChatStatus.swift`'s own documentation places web's equivalent
  signal on a separate `onStatus`-style callback the consuming component
  subscribes to, not on this union — a port targeting web parity MUST NOT
  invent a `statusChanged` case on web's `InboundEvent`/`ChatUpdate` to close
  this gap.
- **command-activity-naming-divergence**: The same concept is named
  `commandActivity: [CommandActivity]` /
  `ChatUpdate.commandActivityChanged` on apple, and
  `activeCommands: ReadonlyArray<ActiveCommand>` /
  `ChatUpdate.activeCommandsChanged` on web. A port MUST NOT assume the
  case or property names align across platforms even though the underlying
  shape — an `invocation` paired with an optional `result` — is equivalent.
- **command-activity-lifecycle-divergence**: apple's `CommandActivity`
  entries MUST be kept in place indefinitely once added — its own
  documentation states a finished one "keeps its place... so a transcript's
  pills stay where the user last saw them" — and no clearing behavior is
  given anywhere in the apple sources. web's `ActiveCommand` documentation
  states the opposite: entries live in `activeCommands` "for the duration of
  the turn that produced it" and are cleared once that turn ends. A port MUST
  choose one lifecycle deliberately per platform rather than assuming parity
  (see Design Decisions).
- **shufflebag-empty-behavior-divergence**: apple's `ShuffleBag.next()` MUST
  return `nil` for an empty source and MUST NOT trap; the given source states
  that web's `ShuffleBag` throws in the same situation. A port MUST choose
  its own failure mode deliberately here rather than copying the other
  platform's.
- **command-activity-is-a-struct-not-a-protocol** (apple): `CommandActivity`
  MUST be a concrete `struct`, unlike its sibling `[any Protocol]`-typed
  properties on `ChatViewModel`, because it only pairs two protocols
  (`CommandInvocation`, `CommandResult`) the host already supplies, with
  nothing left for a conformer to vary.

