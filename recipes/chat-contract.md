---
id: 1f14e4d7-07ea-4f59-8365-5a15eb162def
title: Chat Contract
domain: adhsdk://recipes/chat-contract
type: ingredient
version: 1.0.2
status: review
language: en
created: '2026-09-23'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: The shared attachments, backend, chat-state, command, configuration, hook,
  message, and permission protocols the Swift and TypeScript chat UIs are both built
  against.
platforms:
- swift
- macos
- ios
- typescript
- web
tags:
- chat
- contract
- backend
- messaging
depends-on: []
related:
- adhsdk://recipes/persona-chat
- adhsdk://recipes/chat-input
- adhsdk://recipes/chat-window-controller
references: []
approved-by: ''
approved-date: ''
---

# Chat Contract

## Overview

The chat contract is the shared logic layer both platforms' chat UIs are built
against: attachments and media, a `Backend` a UI talks through, chat state
(`ChatViewModel`/`ChatUpdate`/`ChatStateObserver`), commands, configuration
(`ChatConfig`/`DisplayConfig`), gating and observing hooks, messages,
conversations and participants, and permissions. It ships in two idiomatic
forms — Swift protocols/enums/structs under
`packages/apple/AgenticDeveloperHubSDK/SDK/Sources/` and TypeScript
interfaces/discriminated unions under
`packages/web/packages/chat/src/contract/` — that agree on shape wherever the
languages allow, and diverge in a small, named set of places (see Cross-Platform
Divergences below). `ScriptedBackend` (Swift) is the one concrete conformer
given as source here; it is the toolkit's own scripted/mock `Backend`, shipped
so a consumer can exercise the contract with no live endpoint configured. The
contract carries no message history and no credentials: `Backend.send`
receives only the new message and its attachments, never a transcript.
`persona-chat` builds a real, network-backed `Backend` on top of this same
contract; `chat-input` and `chat-window-controller` are UI components a host
assembles around a `ChatViewModel` this contract defines.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a chat protocol contract (the shared attachments,
backend, chat-state, command, configuration, hook, message, and permission
interface layer), not a visual component.

## States

Not applicable — this is a chat protocol contract, not a visual component.

## Accessibility

Not applicable — this is a chat protocol contract, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| chat-contract-001 | scripted-backend-start-timing | `ScriptedBackend(script: [...], start: .immediately)` at `init`, no `send` call | Replay begins immediately; `ScriptedBackendTests` exercises this as the `.immediately` case |
| chat-contract-002 | scripted-backend-start-timing | `ScriptedBackend(script: [...], start: .onFirstSend)`, then one `send` | Stream stays silent until the first `send`; that `send` triggers the one-time replay, and a second `send` does not replay again |
| chat-contract-003 | scripted-backend-local-id-sequence | `send(text: "a", attachments: [])` then `send(text: "b", attachments: [])` on a fresh `ScriptedBackend(localIDPrefix: "local")` | First call returns `"local-1"` and appends `("local-1", "a", [])` to `sent`; second returns `"local-2"` and appends `("local-2", "b", [])` |
| chat-contract-004 | scripted-backend-serial-replay-chain | Two `send` calls issued back to back against an `opening`/`turn` `ScriptedBackend` | The second turn's beats do not interleave with the first turn's; `ScriptedBackendTests` pins this as the two turns' events arriving in-order, never interspersed |
| chat-contract-005 | scripted-backend-beat-delay-leads | `Beat(.messageReceived(...), after: .milliseconds(50))` as the first beat of a script | The 50ms delay elapses before the event is yielded, not after |
| chat-contract-006 | draft-replaces-not-appends | `draftUpdated(participantID: "p1", text: "Hel")` then `draftUpdated(participantID: "p1", text: "Hello")` | The observed draft text for `"p1"` becomes `"Hello"`, not `"HelHello"`; `ObservableChatViewModelTests` pins replace-not-append |
| chat-contract-007 | draft-commit-or-abort, draft-never-in-messages | `draftUpdated(participantID: "p1", text: "Hi")` followed by `draftCleared(participantID: "p1")` with no matching `messageReceived` | The draft for `"p1"` disappears from `activeDrafts`, and no `Message` for "Hi" appears in `messages` — an aborted draft |
| chat-contract-008 | read-marker-single-cursor | `readMarkerAdvanced(participantID: "p1", upToMessageID: "m1")` then `readMarkerAdvanced(participantID: "p1", upToMessageID: "m5")` | `readMarkers` holds exactly one `ReadReceipt` for `"p1"`, now pointing at `"m5"` — the first entry is replaced, not duplicated |
| chat-contract-009 | command-invocation-id-uniqueness, command-activity-in-place-update | `commandInvoked` for invocation `"inv-1"` and `"inv-2"` of the same `commandName`, then `commandCompleted` for `"inv-2"` | Two distinct `CommandActivity` entries exist (`"inv-1"`, `"inv-2"`); only `"inv-2"`'s `result` is filled in place, `"inv-1"` remains `isRunning == true` |
| chat-contract-010 | orphan-result-dropped | `commandCompleted` whose `result.invocationID` is `"inv-unknown"`, with no prior `commandInvoked` for that id | No new `CommandActivity` entry is created; the event is dropped |
| chat-contract-011 | status-channel-separation | `statusChanged(participantID: "p1", status: ChatStatus(kind: .think))` | `statuses["p1"]` updates and observers receive `ChatUpdate.statusChanged(participantID: "p1")`, but `messages` and `activeDrafts` are unchanged — `ObservableChatViewModelTests.statusChangedIsOutOfBand`, referenced directly in `ChatUpdate.swift`'s own documentation, pins this |
| chat-contract-012 | chat-update-is-invalidation-not-payload | `ChatUpdate.messagesChanged` delivered to an observer | The observer re-reads `messages` from the view model; the update case itself carries no message data |
| chat-contract-013 | ShuffleBag (`ChatStatus.swift`) — closed-source-behavior, no requirement id (see Design Decisions) | `ShuffleBag(["a","b","c","d"])`, `next()` called repeatedly across a full refill | No two consecutive draws are equal, even across the boundary where the bag reshuffles — `ChatStatusTests` "the shuffle bag never repeats back to back, including across a refill" |
| chat-contract-014 | ShuffleBag — see Design Decisions | `ShuffleBag(["a","b","c","d"])`, `next()` called 4 times | All 4 elements are drawn exactly once before any repeats — `ChatStatusTests` "the shuffle bag exhausts every element before repeating one" |
| chat-contract-015 | ShuffleBag — see Design Decisions | `ShuffleBag(["only"])`, `next()` called twice in a row | Both calls return `"only"` — the single-element case is exempt from the no-repeat rule, matching `guard source.count > 1 else { return source[0] }` |
| chat-contract-016 | ShuffleBag — see Cross-Platform Divergences | `ShuffleBag<String>([])`, `next()` called | Returns `nil`; does not trap |
| chat-contract-017 | ChatStatusKind mapping | `ChatStatusKind(TurnStatus.thinking)`, `.responding`, `.retrying` | Map exhaustively to `.think`, `.respond`, `.retry` respectively, per the switch in `ChatStatusKind.init(_:)` |
| chat-contract-018 | command-activity-lifecycle-divergence | The same `CommandActivity`/`ActiveCommand` entry, long after its `result` is filled, on each platform | apple: the entry remains in `commandActivity` indefinitely. web: the entry is removed from `activeCommands` once the participant's turn ends |
| chat-contract-019 | scripted-backend-typing-and-widget-recording-only | `setLocalTyping(true)` on a fixed-script `ScriptedBackend` in `.onFirstSend` mode, before any `send` | `typingCalls == [true]`; the script does not begin replaying |
| chat-contract-020 | mark-read-implicit-range | `markRead(messageID: "m3")` where messages `m1...m5` exist and none were previously read | The local participant's read cursor advances to `"m3"`; `m1`, `m2`, `m3` are treated as read without a separate call per message |

## Edge Cases

- **empty-send**: The contract sets no minimum content: `Backend.send(text:attachments:)` and `submitMessage` accept any string, including empty with no attachments, and neither reference implementation (`ObservableChatViewModel.submitMessage`, `DefaultOrchestrator.submitMessage`) rejects it, so an empty submission reaches the backend as-is.
- **Concurrent overlapping `send` calls on a generic `Backend` conformer** — `Backend` is a class-bound, `Sendable` protocol whose `send` is a plain `async throws` method with no actor isolation of its own; the protocol grants no ordering guarantee for concurrent calls, leaving serialization to each conformer, the way `ScriptedBackend` provides it through its own actor isolation and `replayChain`.
- **A `commandInvoked` with no matching `commandCompleted`, ever** — the activity's `result` stays `nil` and `isRunning` stays `true` indefinitely; the contract defines no timeout or cancellation policy for a command invocation that never completes, leaving that policy to a conformer or host.
- **Cancelling consumption of `inboundEvents` mid-`ScriptedBackend` replay** — `Self.replay` awaits `try? await Task.sleep(for: beat.delay)`; the `try?` silently discards a `CancellationError` and proceeds to yield the next beat rather than stopping the replay task. This is implemented behavior, not a gap, but it is a swallowed error: a cancelled consumer does not necessarily stop a `ScriptedBackend`'s in-flight replay promptly.
- **`transportError`/`messageFailed` with no retry** — the contract communicates failure (transport-error-is-a-signal-not-a-policy) but defines no backoff, retry count, or reconnection sequence; each `Backend` conformer owns that policy on its own (see Design Decisions).
- **max-participants-enforcement**: NEEDS REVIEW: Not implemented in source. `DisplayConfig.maxParticipants` is declared as a plain optional `Int`/`number`, but no code in either package reads it to enforce a limit — `ObservableChatViewModel` only stores and copies it, and `DefaultOrchestrator` never consults it — so what happens when the roster exceeds it, or when it is `0`, is undefined.
- **duplicate-join-unknown-departure**: The reference implementations upsert: a `participantJoined` for an id already in the roster replaces that entry (`ObservableChatViewModel.upsertParticipant`, `DefaultOrchestrator`'s `findIndex` replace), and a `participantDeparted` for an id never joined removes nothing. The platforms differ on the notification: Swift still emits `participantsChanged`, while the web emits it only when an entry was actually removed.
- **Concurrent access to a `PermissionStore` conformer** — the protocol's methods are synchronous and non-actor-isolated by design (permission-store-is-synchronous); a conformer used from multiple threads MUST provide its own synchronization, since the protocol grants none.
- **Malformed or empty opaque payload strings** (`payloadJSON`, `argumentSchema`, `resultJSON`, `errorMessage`) — these are plain strings with no schema validation defined by the contract itself; parsing and validity are the caller's responsibility, not something a conformer of these protocols is required to check.
- **All optional fields absent at once** (`Message.id`/`timestamp`, `Attachment.displayName`/`byteSize`, `DisplayConfig.maxParticipants`/`themeIdentifier`, `Permission.defaultDecision`, `CommandResult.resultJSON`/`errorMessage`, `Conversation.title`) — each MUST be treated as legitimately absent, not as an error state; none of these fields is required for the shape to be valid.
- **A single-element `ShuffleBag`** — `next()` MUST return that one element on every call rather than trying to enforce a no-repeat rule that a one-element bag cannot satisfy (chat-contract-015).
- **An empty `ShuffleBag`** — `next()` MUST return `nil` (apple) rather than trap; a port choosing to throw instead (matching web) MUST do so deliberately, not by omission (see Cross-Platform Divergences).

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `ChatConfig.conversationID` | `String` | none (required) | The conversation this configuration wires up |
| `ChatConfig.localParticipantID` | `String` | none (required) | Which participant the local client acts as |
| `ChatConfig.initialParticipants` | `[Participant]` | none (required) | The roster to seed before any `participantJoined` event arrives |
| `ChatConfig.commands` | `[any Command]` | none (required) | The commands `listCommands()` returns |
| `ChatConfig.observingHooks` | `[any ObservingHook]` | none (required) | Fire-and-forget hooks wired to the orchestrator |
| `ChatConfig.gatingHooks` | `[any GatingHook]` | none (required) | Blocking hooks wired to the orchestrator |
| `ChatConfig.permissionStore` | `any PermissionStore` | none (required) | Where permission decisions are remembered |
| `ChatConfig.backend` | `any Backend` | none (required) | The transport the view model drives |
| `ChatConfig.display` | `DisplayConfig` | none (required) | Presentation-affecting flags, see below |
| `DisplayConfig.showAvatars` | `Bool` | none (caller-supplied) | Whether a UI should render participant avatars |
| `DisplayConfig.showReadReceipts` | `Bool` | none (caller-supplied) | Whether a UI should render read receipts |
| `DisplayConfig.showTypingIndicators` | `Bool` | none (caller-supplied) | Whether a UI should render typing indicators |
| `DisplayConfig.maxParticipants` | `Int?` | `nil` | An optional roster cap; enforcement point is not given (see Edge Cases) |
| `DisplayConfig.allowJoining` | `Bool` | none (caller-supplied) | Whether new participants may join |
| `DisplayConfig.allowDeparting` | `Bool` | none (caller-supplied) | Whether participants may leave |
| `DisplayConfig.themeIdentifier` | `String?` | `nil` | An opaque theme selector, uninterpreted by this contract |
| `DisplayConfig.reducedMotion` | `Bool` | none (caller-supplied) | Carries the Reduce Motion accessibility setting into display decisions |
| `ScriptedBackend(script:start:delayBetweenEvents:localIDPrefix:)` | initializer | `start: .immediately`, `delayBetweenEvents: .zero`, `localIDPrefix: "local"` | Fixed-script mode |
| `ScriptedBackend(opening:turn:localIDPrefix:)` | initializer | `opening: []`, `localIDPrefix: "local"` | Turn-based conversation mode; `turn` is required |

## Deep Linking

Not applicable: no `Backend`, `ChatViewModel`, or supporting type in these
sources defines or consumes a URL, route, or deep-link identifier.

## Localization

| String Key | Default (en) | Context |
|---|---|---|
| `Permission.displayPromptTemplate` | caller-supplied template string | Shown when a `PermissionPrompt` for this `Permission` is presented; carried by the contract, not authored by it |
| `PermissionPrompt.displayPrompt` | caller-supplied, rendered from the template | The concrete, already-filled-in prompt text a UI displays |
| `ChatStatusWordPair.present` | caller-supplied (e.g. `"Thinking"`) | Present-tense status word shown while a `ChatStatus` is active |
| `ChatStatusWordPair.past` | caller-supplied (e.g. `"Thought"`) | Past-tense status word shown once the status resolves |

These four fields are the only user-facing strings the contract itself
carries; every other field is data, not display text. None of the four is
translated by the contract — each is authored and supplied by the host
already in its target locale, matching `ChatStatusWordPair`'s own
documentation that both words are authored, never derived.

## Accessibility Options

| Option | Behavior |
|---|---|
| Reduce Motion | `DisplayConfig.reducedMotion` carries this setting through to a UI; the contract itself performs no animation and defines no specific behavior change, only the flag a consumer reads |
| Increase Contrast | Not applicable: no field or type in these sources carries a contrast setting |
| Differentiate Without Color | Not applicable: no field or type in these sources carries a color-differentiation setting |

## Feature Flags

Not applicable: no flag-key type, feature-toggle field, or conditional
capability switch appears anywhere in these sources.

## Analytics

Not applicable: no analytics event type, tracking call, or telemetry hook
appears anywhere in these sources.

## Privacy

- **Data collected**: `Backend.send` carries the new message's `text` and
  `attachments` only — never a transcript or prior history, matching the
  toolkit's stated design that a coordinator holds no history. `PermissionStore`
  persists `PermissionDecision` values keyed by `(permission, requesterID)`.
- **Storage**: `PermissionStore` is the one type in these sources responsible
  for retaining anything past a single call (`remember(decision:for:requesterID:)`);
  everything else — messages, drafts, read markers, command activity — lives
  only in the in-memory `ChatViewModel`/`Orchestrator` state these protocols
  describe, with no persistence mechanism given.
- **Transmission**: `Backend.send`, `setLocalTyping`, and
  `submitWidgetResponse` are the three points where locally authored content
  (message text, attachments, typing state, widget responses) leaves the
  client through a `Backend` conformer; the contract defines no encryption or
  transport requirement, leaving that to the conformer.
- **Retention**: Not specified by this contract for messages, drafts, or read
  markers — no expiry, TTL, or deletion method exists on any type here;
  `PermissionStore` decisions persist until a conformer's own storage says
  otherwise, which these sources do not define.

## Logging

Not applicable: no log, print, or diagnostic-emission call appears anywhere in
these sources; `transportError`/`messageFailed`/`HookDecision.block(reason:)`
communicate failure to the caller directly rather than through a log.

## Platform Notes

- **SwiftUI**: Sources live under
  `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/{Attachments,Backend,Chat,Commands,Configuration,Hooks,Media,Messages,Orchestrator,Participants,Permissions}/`.
  `ChatViewModel` is `@MainActor, AnyObject, Sendable`; the two given actor
  conformers (`ScriptedBackend`, and `PersonaChatCoordinator` referenced from
  its doc comments) hold `inboundEvents`/its continuation as `nonisolated
  let`, so a `SwiftUI` view can start consuming the stream without waiting on
  the actor.
- **Compose**: Translate `AsyncStream<InboundEvent>` to a `Flow<InboundEvent>`;
  translate the closed-set enums (`InboundEvent`, `ChatUpdate`,
  `MessageDeliveryStatus`, `AttachmentSource`, `AttachmentPresentation`,
  `ParticipantKind`, `ParticipantConversationState`, `CommandInvoker`,
  `PermissionDecision`, `GatingPoint`, `ObservingPoint`, `HookDecision`) to
  Kotlin `sealed class`/`sealed interface` hierarchies rather than plain
  `enum class`, since several carry payloads; represent `ChatViewModel` as a
  `ViewModel` exposing `StateFlow` properties in place of the
  observer-registration pattern; give a `ScriptedBackend` port its own
  `Mutex`-guarded class, since Kotlin has no built-in actor equivalent.
- **React/Web**: Sources live under
  `packages/web/packages/chat/src/contract/{attachments,backend,chat,commands,configuration,hooks,media,messages,orchestrator,participants,permissions}/`.
  Closed sets are discriminated unions matched on a `kind` field rather than
  enums; collections are typed `ReadonlyArray`/readonly interfaces to signal
  the same immutability `let`/`Sendable` signal on apple; the contract types
  themselves import no React and carry no framework coupling.
- **AppKit/UIKit**: The same Swift package serves both; `ChatViewModel`'s
  `@MainActor` isolation matches AppKit/UIKit's main-thread-only view and
  control update requirement directly, so no additional dispatching is needed
  at the view layer beyond what `@MainActor` already provides.
- **WinUI 3**: `AsyncStream`/async-iterable becomes a
  `System.Threading.Channels.Channel<InboundEvent>` exposed as
  `IAsyncEnumerable<InboundEvent>` via `ChannelReader.ReadAllAsync()`, with a
  single orchestrator consuming it and fanning out through property-change
  notifications. Payload-carrying closed sets (`InboundEvent`, `HookDecision`,
  `MessageDeliveryStatus`, `AttachmentSource`) become an `abstract record` base
  with one `sealed record` per case, pattern-matched with a C# `switch`
  expression, rather than a single enum with nullable fields for every case.
  `Message`/`Participant`/`Attachment`-shaped protocols become C# interfaces
  or `record` types; `ChatViewModel`/`Orchestrator` become an interface
  implementing `INotifyPropertyChanged` for XAML binding, backing
  `messages`/`participants`/`activeDrafts`/`pendingWidgets`/`pendingPermissions`
  with `ObservableCollection<T>` in place of the update-then-re-read pattern
  `ChatUpdate` uses. `Backend.send`/`setLocalTyping`/`submitWidgetResponse`
  become `Task`-returning `async` methods, with `HttpClient` for a networked
  conformer's transport and `System.Text.Json` for the opaque
  `payloadJSON`/`argumentSchema`/`resultJSON` strings. A `ScriptedBackend` port
  replaces `AsyncStream.Continuation` with a `Channel<InboundEvent>` writer and
  `Task.sleep(for:)` with `Task.Delay`, chaining turns with awaited tasks the
  way `replayChain` does. `Windows.Storage` has no role at this layer: the
  contract performs no persistence of its own (see Privacy).

## Design Decisions

- **Decision**: `ScriptedBackend` supports two separate construction modes
  (fixed `script` vs. `opening` + `turn`) instead of one general-purpose
  scripting API.
  **Rationale**: A one-shot demo script and an ongoing scripted conversation
  have different lifecycles — one finishes the stream, the other never does —
  and collapsing them into a single shape would force every fixed-script
  caller to also handle the turn-based case's open-endedness.
  **Approved**: pending

- **Decision**: `Beat.delay` is applied before yielding its event, not after.
  **Rationale**: A script reads top-to-bottom as a timeline ("wait, then act")
  only if the first beat's delay can also produce a pause before anything
  happens; trailing delay would make the very first beat unable to open with
  silence.
  **Approved**: pending

- **Decision**: `draftUpdated.text` is always the whole draft, never a
  fragment to append.
  **Rationale**: A fragment-based design has no way to signal "this is a
  correction, not a continuation," and a dropped or reordered fragment
  silently corrupts the transcript with no error to catch it; replacing the
  whole string every time removes that failure mode entirely.
  **Approved**: pending

- **Decision**: `statusChanged` is a distinct, out-of-band `InboundEvent`
  and `ChatUpdate` case on apple, rather than being folded into
  `draftUpdated` or omitted from `ChatUpdate` entirely.
  **Rationale**: Folding a "thinking" spinner's text into `draftUpdated` would
  commit it into a user-visible `Message` once the draft finalizes; omitting
  a case from `ChatUpdate` would leave a `@MainActor` view with no signal to
  observe at all, since nothing else in the union fires for a status change.
  **Approved**: pending

- **Decision**: Command activity (`commandInvoked`/`commandCompleted`) is its
  own channel, never folded into `draftUpdated`.
  **Rationale**: `CommandInvocation.id` is deliberately independent of
  `commandName` so that two parallel invocations of the same command do not
  collide; a shared channel with drafts would force command activity through
  the same replace-the-whole-string semantics that drafts use, which does not
  fit a command's start/complete lifecycle.
  **Approved**: pending

- **Decision**: apple's `ShuffleBag` returns `nil` on an empty source and
  never repeats an element back-to-back, even across a refill; web's
  `ShuffleBag` throws on empty and can repeat once across the seam between
  refills.
  **Rationale**: Each platform's given source states its own choice
  independently rather than one being a bug relative to the other — apple's
  own documentation frames the stronger no-repeat guarantee as intentional
  ("closing that seam is the whole point at a [status] cadence"), and returning
  `nil` instead of throwing on empty reflects that a toolkit should not trap a
  host that configured no vocabulary, while web's looser guarantee and
  throw-on-empty behavior is its own considered choice, not left to chance.
  **Approved**: pending

- **Decision**: `CommandActivity` (apple) keeps every entry in place
  indefinitely, while the equivalent `ActiveCommand` (web) is cleared when the
  producing participant's turn ends.
  **Rationale**: Both are documented, deliberate choices in their own given
  sources, not an accidental mismatch — apple's transcript keeps a command's
  pill exactly where the user last saw it, while web's model treats command
  activity as scoped to the turn that produced it. A port MUST pick one
  lifecycle per platform on purpose (see Cross-Platform Divergences) rather
  than assume the two are interchangeable.
  **Approved**: pending

- **Decision**: `ChatViewModel` is declared `@MainActor, AnyObject, Sendable`
  rather than `@unchecked Sendable`.
  **Rationale**: `@unchecked Sendable` would silence the compiler without
  proving isolation; `@MainActor` isolation is what actually guarantees
  `ChatViewModel`'s mutable state is only ever touched from one execution
  context, matching how a view's own layout and action handlers run.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [if-frontmatter-complete](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-frontmatter-complete) | passed | artifact-formatting |
| [if-behavioral-requirements](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-behavioral-requirements) | passed | artifact-formatting |
| [if-test-vectors](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-test-vectors) | passed | artifact-formatting |
| [if-platform-notes](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-platform-notes) | passed | artifact-formatting |
| [if-design-decisions](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-design-decisions) | passed | artifact-formatting |
| [if-compliance](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-compliance) | passed | artifact-formatting |
| [if-change-history](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-change-history) | passed | artifact-formatting |
| [best-practices](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [best-practices](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [best-practices](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |
| [reliability](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |
| [reliability](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | partial | reliability |
| [privacy-and-data](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | privacy-and-data |

`unit-test-coverage` is `partial`: most types here are pure protocols/interfaces
with nothing to unit-test directly; only `ScriptedBackend`, the one concrete
conformer given as source, has direct tests (`ScriptedBackendTests`), while
several of the contract's other invariants (draft replace, status
out-of-band, command in-place update, orphan-result drop) are corroborated
only through tests of a conformer not included among the given sources.
`explicit-error-handling` is `partial`: `Backend`/hook/permission methods are
either fallible or answer with an explicit `HookDecision.block(reason:)`, but
`ScriptedBackend.replay` swallows a `Task.sleep` cancellation error via
`try?` rather than propagating or logging it. `fault-tolerance` is `partial`:
failures are always signaled (`transportError`, `messageFailed`,
`HookDecision.block`), but no retry, backoff, or reconnection policy is
defined at this layer — each `Backend` conformer owns that decision.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-09-23 | Claude Sonnet 5 | Initial creation |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Split merged chat-contract-003 cell; fixed 7 if-* compliance URLs missing ingredient-formatting. |
