---
id: 98a0f3de-1489-465d-b1aa-017f4505d05d
title: "Chat Coordinator Runtime"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-09-23
modified: 2026-09-24
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "TypeScript chat runtime: DefaultOrchestrator, InMemoryPermissionStore, and ScriptedBackend implementing the shared Backend/Orchestrator contract."
platforms:
  - typescript
  - web
tags:
  - chat
  - messaging
  - runtime
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Chat Coordinator Runtime

## Overview

The chat coordinator runtime is the headless reference implementation of the
cross-platform chat contract's `Orchestrator`/`ChatViewModel` surface. It has
no rendered UI of its own — a host layer (`useChatSession` or a similar hook,
outside the scope of this recipe) constructs it and lets UI components read
its state and call its methods. It is three cooperating pieces:

- **`DefaultOrchestrator`** (`DefaultOrchestrator.ts`) — the reference
  `Orchestrator` implementation. It consumes an injected `Backend`'s
  `inboundEvents` stream, maintains every field `ChatViewModel` declares
  (`messages`, `participants`, `activeDrafts`, `activeCommands`,
  `readMarkers`, `typingParticipants`, `pendingWidgets`,
  `pendingPermissions`), and fans out a `ChatUpdate` to every registered
  `ChatStateObserver` after each state-changing event or method call.
- **`InMemoryPermissionStore`** (`InMemoryPermissionStore.ts`) — a
  process-local `PermissionStore`. It remembers only `allowAlways`/
  `denyAlways` decisions (single-use `*Once` decisions are never persisted)
  and falls back to a permission's own `defaultDecision` when nothing is
  remembered.
- **`ScriptedBackend`** (`ScriptedBackend.ts`) — a test-double `Backend`
  driven entirely by explicit `emit()` calls. It records every outbound call
  (`send`/`setLocalTyping`/`submitWidgetResponse`) so a test can assert on
  them, and exposes `inboundEvents` as a hand-rolled async iterable backed by
  a queue and a set of parked waiters.

`DefaultOrchestrator` is the single consumer of whatever `Backend` it is
constructed with (stated in `Backend.ts`'s own doc comment); it never
multiplexes one backend to more than one orchestrator itself. Ports of this
runtime replace `Backend`/`PermissionStore` with a networked or persisted
implementation without changing `DefaultOrchestrator`'s contract.

## Behavioral Requirements

### Construction & Lifecycle

- **constructor-derives-conversation**: Constructing `DefaultOrchestrator(config)` MUST build `conversation` as `{ id: config.conversationID, createdAt: <the construction-time wall-clock Date>, participants: config.initialParticipants }` — `createdAt` MUST be the moment of construction, never a caller-supplied value, because `ChatConfig` has no `createdAt` field; `conversation.title` MUST be left unset because `ChatConfig` has no `title` field either.
- **conversation-participants-frozen**: `conversation.participants` MUST be assigned exactly once, at construction, from `config.initialParticipants`, and MUST NOT be reassigned by any later `participantJoined`/`participantDeparted` event.
- **participants-roster-tracks-live-changes**: The top-level `participants` property MUST initialize to `config.initialParticipants` and MUST be the property that reflects subsequent joins and departures (see Participants below) — it is distinct from, and diverges from, `conversation.participants` the moment the roster changes.
- **construction-copies-config-fields-verbatim**: `displayConfig`, `permissionStore`, `commands`, and `localParticipantID` MUST be taken verbatim from the matching `ChatConfig` fields at construction and MUST NOT be recomputed, validated, or defaulted.
- **start-begins-consumption**: The first call to `start()` MUST begin consuming `backend.inboundEvents` via an internal, un-awaited event-loop task.
- **start-is-idempotent**: Every call to `start()` after the first MUST be a no-op — an internal `started` flag is set `true` on the first call and is never reset, so a second concurrent event-loop task MUST NOT be created.
- **stop-cancels-iterator**: `stop()` MUST set an internal `stopped` flag to `true` and MUST call `return()` on the active async iterator, if one exists, to signal early termination of the inbound stream.
- **stop-before-start-locks-the-loop**: If `stop()` is called before `start()` has ever been called, a later `start()` call MUST still never consume any event — `runEventLoop`'s `while (!this.stopped)` guard is checked before the first `iterator.next()`, and nothing in this source ever resets `stopped` back to `false`.
- **event-loop-recovery**: When `this.iterator.next()` rejects inside the internal event loop, the loop's `catch` block notifies an `error` `ChatUpdate` and the loop function then returns — `started` is never reset to `false`, so a later `start()` call is still a no-op (per start-is-idempotent) and consumption never resumes on that instance. `DefaultOrchestrator.ts` implements no retry, backoff, or reconnect policy, and provides no way to restart event consumption on an already-started instance.

### Display Configuration

- **display-config-mutation**: NEEDS REVIEW: Not implemented in source. `ChatUpdate` defines a `displayConfigChanged` kind, implying `displayConfig` can change after construction and observers can be told about it, but `DefaultOrchestrator` assigns `this.displayConfig = config.display` exactly once, in the constructor, and no method in `DefaultOrchestrator.ts` ever reassigns `displayConfig` or calls `this.notify({ kind: 'displayConfigChanged' })`. Missing: a public method (an `updateDisplayConfig`-shaped API or similar) and the trigger(s) that would call it. Whoever adds a runtime way to change `DisplayConfig` — not present in these three files — would resolve this.

### Sending Messages & Delivery Status

- **submit-message-calls-backend-first**: `submitMessage(text, attachments)` MUST call `backend.send(text, attachments)` before creating or appending any local `Message`.
- **submit-message-failure-no-echo**: If `backend.send` rejects, `submitMessage` MUST notify an `error` `ChatUpdate` whose `message` is `error.message` when the rejection is an `Error`, else `String(error)`, MUST re-throw the same rejection to its own caller, and MUST NOT append any `Message` to `messages`.
- **submit-message-optimistic-echo**: On a successful `backend.send`, `submitMessage` MUST append a new `Message` to `messages` with `localID` set to the resolved id, `senderID` set to `localParticipantID`, `text`/`attachments` as given, `timestamp` set to the call's wall-clock time, `id` left unset, and `deliveryStatus` set to `{ kind: 'sending' }`, and MUST notify a `messagesChanged` update.
- **submit-message-returns-local-id**: `submitMessage` MUST resolve with the `localID` string that `backend.send` returned.
- **message-accepted-updates-in-place**: A `messageAccepted` event MUST update the message whose `localID` matches, setting `id` to `serverID`, `timestamp` to `at`, and `deliveryStatus` to `{ kind: 'sent' }`, and MUST notify `messagesChanged`; an event matching no message MUST leave `messages` and every observer untouched.
- **message-delivered-matches-either-id**: A `messageDelivered` event MUST update the message whose `id` OR `localID` equals `messageID`, setting `deliveryStatus` to `{ kind: 'delivered' }`, and MUST notify `messagesChanged` only if a match was found.
- **message-failed-sets-reason**: A `messageFailed` event MUST update the message whose `localID` matches, setting `deliveryStatus` to `{ kind: 'failed', reason: event.reason }`.
- **inbound-message-appended-verbatim**: A `messageReceived` event MUST append `event.message` to `messages` exactly as given. `DefaultOrchestrator` MUST NOT construct, override, or infer any field of an inbound `Message` — the `composing` and `received` `MessageDeliveryStatus` kinds are therefore never assigned by this handler itself; only whatever produced the event supplies them.
- **inbound-message-clears-sender-draft**: A `messageReceived` event MUST clear any active draft belonging to `event.message.senderID`, whether or not a separate `draftCleared` event is also emitted for that participant.

### Streaming Drafts

- **draft-updated-replaces-not-appends**: A `draftUpdated` event MUST replace, not append to, the stored `text`/`attachments` of the matching participant's `ActiveDraft` — `event.text` is the whole draft so far, never a fragment to accumulate.
- **draft-updated-upserts-by-participant**: A `draftUpdated` event MUST create a new `ActiveDraft` entry if none exists for `event.participantID`, and MUST overwrite the existing entry in place, preserving its array position, if one does.
- **draft-cleared-removes-without-commit**: A `draftCleared` event MUST remove the participant's `ActiveDraft` if present and MUST NOT append anything to `messages` — a `Message` for that content only ever arrives via a later, independent `messageReceived` event.
- **draft-cleared-also-clears-commands**: A `draftCleared` event MUST also remove every `activeCommands` entry belonging to the same `participantID`, treating `draftCleared` as the end of that participant's turn.
- **active-drafts-excluded-from-messages**: `ActiveDraft` entries MUST NOT appear in `messages` at any point.

### Read Cursors

- **mark-read-sets-local-cursor**: `markRead(messageID)` MUST upsert a `ReadReceipt` for `localParticipantID` with `upToMessageID` set to `messageID` and `at` set to the call's wall-clock time.
- **read-marker-advanced-is-one-per-participant**: A `readMarkerAdvanced` event MUST upsert exactly one `ReadReceipt` per `participantID` — a later event for the same participant MUST replace, not add to, that participant's existing entry.
- **read-marker-regression-guard-by-position**: When both the existing and incoming `upToMessageID` are found in `messages`, the upsert MUST be rejected (the existing cursor kept unchanged, no notification) if the incoming id's index in `messages` is earlier than the existing cursor's index.
- **read-marker-regression-guard-by-time**: When either `upToMessageID` cannot be found in `messages`, the upsert MUST instead be rejected only if the incoming event's `at` is earlier than the existing cursor's `at`.
- **read-marker-absence-means-unread**: The absence of a `ReadReceipt` for a participant MUST be interpreted as that participant having read nothing yet; `DefaultOrchestrator` MUST NOT synthesize a default entry for a participant with none.

### Typing Indicators

- **typing-added-once**: A `typing` event with `isTyping: true` MUST add `participantID` to `typingParticipants` only if not already present, and MUST notify `typingChanged` only when the set actually changes.
- **typing-removed-once**: A `typing` event with `isTyping: false` MUST remove `participantID` from `typingParticipants` only if present, and MUST notify `typingChanged` only when the set actually changes.
- **set-local-typing-delegates-only**: `setLocalTyping(isTyping)` MUST call `backend.setLocalTyping(isTyping)` and MUST NOT itself add or remove any entry in `typingParticipants` — the local participant's own state enters `typingParticipants` only if the backend echoes it back as an inbound `typing` event.

### Interactive Widgets

- **widget-presented-appends-and-maps**: A `widgetPresented` event MUST append `event.widget` to `pendingWidgets`, MUST record the mapping from `event.widget.id` to `event.messageID` in the internal widget-to-message map, and MUST notify `pendingWidgetsChanged`.
- **respond-to-widget-removes-optimistically**: `respondToWidget(response)` MUST, before calling the backend, remove any pending widget matching `response.widgetID` from `pendingWidgets` and its entry from the widget-to-message map, notifying `pendingWidgetsChanged` if a removal occurred.
- **respond-to-widget-unconditional-forward**: `respondToWidget` MUST call `backend.submitWidgetResponse(response)` regardless of whether a matching pending widget was found — an unrecognized or already-resolved `widgetID` is still forwarded, unlike `respondToPermission`'s unknown-id handling (see permission-response-ignores-unknown-prompt).
- **respond-to-widget-rollback-on-rejection**: If `backend.submitWidgetResponse` rejects and a widget was removed by this call, `respondToWidget` MUST restore `pendingWidgets` and the widget-to-message map to the values they held before this call, notify `pendingWidgetsChanged` again, notify an `error` update carrying the rejection's message, and re-throw the rejection.
- **widget-response-rollback-ordering**: NEEDS REVIEW: Not implemented in source. The rollback in respond-to-widget-rollback-on-rejection restores `pendingWidgets`/the widget-to-message map to their exact pre-call snapshot, with no check for whether either was mutated by another event (a new `widgetPresented`, a concurrent `respondToWidget` call for a different widget) while the rejected call's `backend.submitWidgetResponse` promise was still pending — any such intervening mutation is silently discarded by the rollback. Missing: an ordering or merge rule for concurrent widget-state mutation. This cannot be settled from `DefaultOrchestrator.ts` alone — no concurrency contract for its public methods is stated anywhere in the given sources.

### Permissions

- **present-permission-prompt-appends**: `presentPermissionPrompt(prompt)` (a non-portable, TS-runtime-only convenience for hooks/policy gates to surface a decision request) MUST append `prompt` to `pendingPermissions` and notify `pendingPermissionsChanged`.
- **permission-response-ignores-unknown-prompt**: `respondToPermission(promptID, decision)` MUST return with no state change and no notification if no entry of `pendingPermissions` has that `id` — an unrecognized id is a silent no-op, unlike `respondToWidget`'s unconditional forward.
- **permission-response-removes-and-remembers**: For a recognized `promptID`, `respondToPermission` MUST call `permissionStore.remember(decision, prompt.permission, prompt.requesterID)`, remove that prompt from `pendingPermissions`, and notify `pendingPermissionsChanged`.
- **hook-and-permission-enforcement**: NEEDS REVIEW: Not implemented in source. `ChatConfig` accepts `gatingHooks: ReadonlyArray<GatingHook>` and `observingHooks: ReadonlyArray<ObservingHook>`, and `GatingPoint`/`ObservingPoint` enumerate specific lifecycle points (`willSubmitMessage`, `willExecuteCommand`, `willEmitUpdate`, `willRequestPermission`, `willAcceptInboundMessage`, `didComposeMessage`, `messageSent`, `messageReceived`, `messageRead`, `didExecuteCommand`, `didEmitUpdate`, `participantJoined`, `participantDeparted`, `permissionResolved`), but no method in `DefaultOrchestrator.ts` calls a hook's `gate()` or `observe()` at any of these points, and `permissionStore.decision()` is never called anywhere in `DefaultOrchestrator.ts` to decide whether a gated action should be allowed to proceed — the only `PermissionStore` operation this source performs is recording a decision via `remember()`. Missing: what MUST happen when a `GatingHook` denies an action, at which of these points each hook fires, and where (if anywhere in this runtime) a remembered `decision()` is consulted before a gated action runs. This cannot be settled from these three files alone; it would be resolved by the code that wires `gatingHooks`/`observingHooks` for a real deployment, which is not present here.

### Commands

- **list-commands-returns-config-commands**: `listCommands()` MUST return exactly the `ReadonlyArray<Command>` passed as `ChatConfig.commands` at construction, unmodified.
- **command-invoked-appends-active-entry**: A `commandInvoked` event MUST append a new `ActiveCommand` (with `result` unset) to `activeCommands` and notify `activeCommandsChanged`.
- **command-completed-matches-by-invocation-id**: A `commandCompleted` event MUST locate the `ActiveCommand` whose `invocation.id` equals `event.result.invocationID`; if none is found, the event MUST be dropped with no state change and no notification, rather than synthesizing a new entry.
- **command-completed-sets-result**: For a matched entry, `commandCompleted` MUST set that entry's `result` to `event.result`, leaving `participantID`/`invocation` unchanged, and MUST notify `activeCommandsChanged`.

### Participants

- **participant-joined-upserts**: A `participantJoined` event MUST replace the existing entry in `participants` if `event.participant.id` matches one already present (preserving array position), or append it if not, then notify `participantsChanged`.
- **participant-departed-removes-if-present**: A `participantDeparted` event MUST remove the matching entry from `participants` and notify `participantsChanged` only if a match existed; otherwise it MUST be a silent no-op.

### Observer Notifications

- **notify-fans-out-synchronously**: `notify(update)` MUST call `chatDidUpdate(update)` synchronously, in the observer set's iteration order, on every observer registered at the moment `notify` runs, before `notify` returns.
- **add-remove-observer-mutate-the-same-set**: `addObserver`/`removeObserver` MUST add to, or delete from, the same internal `Set<ChatStateObserver>` that `notify` iterates; an observer removed before an update fires MUST NOT receive that update.
- **transport-error-relayed-verbatim**: A `transportError` event MUST notify an `error` update whose `message` is `event.message`, unmodified — `DefaultOrchestrator` MUST NOT reinterpret, translate, or suppress it.

### Non-Portable Runtime Extensions

- **deliver-bypasses-backend**: `deliver(event)` MAY be used to apply any `InboundEvent` exactly as if it had arrived from `backend.inboundEvents`, by routing it through the same internal event handler — a TS-runtime convenience for injecting lines (e.g. a scripted persona welcome) that no backend produced; it is not part of the portable `Orchestrator` contract.
- **caller-should-start-before-relying-on-inbound-state**: A caller SHOULD call `start()` before depending on any inbound-event-driven state (`messages` gained via `messageReceived`, `typingParticipants`, `activeDrafts`, etc.), since none of it updates from the backend until the event loop is running. This is a SHOULD, not a MUST, because `submitMessage`, `markRead`, `setLocalTyping`, `respondToWidget`, and `respondToPermission` all function correctly whether or not `start()` was ever called — the only consequence of deferring `start()` is a delay in observing inbound state, not an error (see Design Decisions).

### InMemoryPermissionStore

- **decision-lookup-order**: `decision(permission, requesterID)` MUST return the remembered decision for that exact `(permission.id, requesterID)` pair if one exists, else `permission.defaultDecision` if set, else `undefined`.
- **remember-persists-always-decisions-only**: `remember(decision, permission, requesterID)` MUST persist the decision only when it is `'allowAlways'` or `'denyAlways'`; `'allowOnce'` and `'denyOnce'` MUST NOT be stored.
- **store-is-process-local**: The store MUST hold all state in an in-memory `Map` for the lifetime of the instance and MUST NOT read from or write to any external persistence.
- **store-has-no-revoke-operation**: The store's interface (`decision`/`remember`) provides no method to remove or revoke an already-remembered decision short of discarding the instance — consistent with its documented process-local, non-persistent design (see Design Decisions), not a gap in this source.

### ScriptedBackend

- **send-mints-sequential-local-ids**: `send(text, attachments)` MUST synchronously increment an internal counter starting at `1`, MUST format the id as the configured `localIDPrefix` (default `'local'`) followed by `-` and the counter value, MUST record `{ localID, text, attachments }` in `sent`, and MUST resolve with that `localID`; it MUST NOT itself emit any `InboundEvent` — a matching `messageAccepted` is the caller's/test's responsibility to `emit`.
- **set-local-typing-records-only**: `setLocalTyping(isTyping)` MUST push `isTyping` onto `typingCalls` and MUST NOT emit any event.
- **submit-widget-response-records-only**: `submitWidgetResponse(response)` MUST push `response` onto `widgetResponses` and MUST NOT emit any event or throw.
- **emit-queues-or-delivers-immediately**: `emit(event)` MUST hand `event` directly to the oldest parked `next()` waiter if one exists, else append it to an internal queue for a future `next()` call to consume; `emit` called after `close()` MUST be a silent no-op.
- **close-drains-queue-before-ending**: `close()` MUST resolve every currently parked waiter with a "done" result and MUST mark the backend closed; a subsequent `next()` call on any iterator MUST still drain any events already queued before that iterator reports "done" — closing MUST NOT discard already-queued, undelivered events.
- **inbound-events-shared-across-iterators**: `inboundEvents`'s iterator factory MUST return a new iterator object on each call, but every iterator drains the SAME shared queue and waiter list — matching `Backend.ts`'s documented "the orchestrator is the single consumer" assumption; two concurrent consumers of one `ScriptedBackend` instance would compete for, not both receive, each emitted event.
- **iterator-return-unparks-exactly-once**: Calling an iterator's `return()` MUST mark that iterator done, MUST resolve its own parked wait (if any) with a "done" result, and MUST remove that resolver from the shared waiter list so a later `close()` or `emit()` does not attempt to resolve it a second time.

## Appearance

Not applicable — this is a headless chat state-coordination runtime
(`DefaultOrchestrator`, `InMemoryPermissionStore`, `ScriptedBackend`), not a
visual component; none of these three files renders anything.

## States

Not applicable — this is a headless runtime, not a visual component. Its own
state machines (delivery status transitions, the started/stopped event-loop
lifecycle, draft-to-message commits) are covered under Behavioral
Requirements above, not as a visual-state table.

## Accessibility

Not applicable — this is a headless runtime, not a visual component: it has
no rendered surface, focus, label, or trait for an assistive technology to
describe.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ccr-001 | submit-message-calls-backend-first, submit-message-optimistic-echo, submit-message-returns-local-id | Fresh harness; `submitMessage('hello', [])` | Returns `'local-1'`; `backend.sent` equals `[{ localID: 'local-1', text: 'hello', attachments: [] }]`; `messages` has length 1 with `deliveryStatus` `{ kind: 'sending' }` — `scenarios.test.ts "round-trips a non-streaming exchange and tracks delivery status"` |
| ccr-002 | message-accepted-updates-in-place | After ccr-001, `emit({ kind: 'messageAccepted', localID: 'local-1', serverID: 'srv-1', at })` | `messages[0].id === 'srv-1'`; `deliveryStatus` becomes `{ kind: 'sent' }` — same test |
| ccr-003 | message-delivered-matches-either-id | After ccr-002, `emit({ kind: 'messageDelivered', messageID: 'srv-1', at })` | `deliveryStatus` becomes `{ kind: 'delivered' }` — same test |
| ccr-004 | inbound-message-appended-verbatim | After ccr-003, `emit({ kind: 'messageReceived', message: <persona message> })` | `messages` has length 2; `messages[1].text`/`senderID` match the emitted message exactly — same test |
| ccr-005 | message-failed-sets-reason | `submitMessage('hi', [])`; `emit({ kind: 'messageFailed', localID: 'local-1', reason: 'rate-limited' })` | `deliveryStatus` becomes `{ kind: 'failed', reason: 'rate-limited' }` — `scenarios.test.ts "flips a message to failed when the bus rejects it"` |
| ccr-006 | draft-updated-replaces-not-appends, draft-updated-upserts-by-participant | Three sequential `draftUpdated` events for the same participant: `'Th'`, then `'Thinki'`, then `'Thinking…'` | `activeDrafts` stays length 1 throughout; its `text` is exactly the latest full string, never a concatenation — `scenarios.test.ts "buffers a streaming response in activeDrafts, then commits to messages on messageReceived"` |
| ccr-007 | inbound-message-clears-sender-draft, active-drafts-excluded-from-messages | After ccr-006, `emit({ kind: 'messageReceived', message: <the finalized text> })` for the same participant | `activeDrafts` becomes length 0; `messages` gains exactly one entry with the finalized text — same test |
| ccr-008 | draft-cleared-removes-without-commit | `draftUpdated` for a participant, then `draftCleared` for the same participant, with no `messageReceived` in between | `activeDrafts` becomes length 0; `messages` stays length 0 — `scenarios.test.ts "discards a draft on draftCleared without committing a message"` |
| ccr-009 | mark-read-sets-local-cursor | Fresh harness; `await orchestrator.markRead('srv-42')` | `readMarkers` has length 1; its entry has `participantID` equal to the local user's id and `upToMessageID: 'srv-42'` — `scenarios.test.ts "local markRead advances the local cursor only"` |
| ccr-010 | read-marker-advanced-is-one-per-participant | After ccr-009's local `markRead('srv-1')`, `emit({ kind: 'readMarkerAdvanced', participantID: <persona>, upToMessageID: 'srv-3', at })` | `readMarkers` has length 2; the persona's entry has `upToMessageID: 'srv-3'` — `scenarios.test.ts "inbound readMarkerAdvanced from a peer is recorded as a separate cursor"` |
| ccr-011 | read-marker-advanced-is-one-per-participant | Two sequential `readMarkerAdvanced` events for the same persona: `upToMessageID: 'srv-1'` then `'srv-2'` | `readMarkers` stays length 1; its entry's `upToMessageID` is `'srv-2'` (the second overwrites the first, not appends) — `scenarios.test.ts "a second cursor advance from the same participant overwrites the first"` |
| ccr-012 | typing-added-once, typing-removed-once | `typing` events for one participant: `isTyping: true`, `isTyping: true` again, then `isTyping: false` | `typingParticipants` becomes `[personaID]` after the first event, stays `[personaID]` (no duplicate) after the second, and becomes `[]` after the third — `scenarios.test.ts "adds and removes typing participants on isTyping toggles"` |
| ccr-013 | set-local-typing-delegates-only | `await orchestrator.setLocalTyping(true)`; `await orchestrator.setLocalTyping(false)` | `backend.typingCalls` equals `[true, false]` — `scenarios.test.ts "local setLocalTyping calls through to the backend"` |
| ccr-014 | widget-presented-appends-and-maps, respond-to-widget-removes-optimistically | `emit({ kind: 'widgetPresented', messageID: 'srv-7', widget })`; then `await orchestrator.respondToWidget({ widgetID: widget.id, respondingParticipantID: <local>, payloadJSON: '{"choice":"yes"}' })` | `pendingWidgets` goes from length 1 to length 0; `backend.widgetResponses` has length 1 with `payloadJSON: '{"choice":"yes"}'` — `scenarios.test.ts "presents a widget and clears it on response"` |
| ccr-015 | participant-joined-upserts, participant-departed-removes-if-present | `emit({ kind: 'participantJoined', participant: <observer-1> })`; then `emit({ kind: 'participantDeparted', participantID: 'observer-1' })` | `participants` grows from 2 to 3 then back to 2; `observer-1` is present after the first event and absent after the second — `scenarios.test.ts "handles participantJoined / participantDeparted events"` |
| ccr-016 | present-permission-prompt-appends, permission-response-removes-and-remembers | `orchestrator.presentPermissionPrompt(prompt)`; `await orchestrator.respondToPermission(prompt.id, 'allowAlways')` | `pendingPermissions` goes from length 1 to length 0; `permissionStore.decision(prompt.permission, prompt.requesterID)` returns `'allowAlways'` — `scenarios.test.ts "respondToPermission with allowAlways persists the decision"` |
| ccr-017 | remember-persists-always-decisions-only | Same as ccr-016 but with decision `'allowOnce'` | `permissionStore.decision(...)` returns `undefined` afterward — `scenarios.test.ts "respondToPermission with allowOnce does not persist"` |
| ccr-018 | decision-lookup-order | A `Permission` with `defaultDecision: 'allowAlways'` and no remembered decision for it | `permissionStore.decision(permission, requesterID)` returns `'allowAlways'` — `scenarios.test.ts "falls back to permission.defaultDecision when nothing is remembered"` |
| ccr-019 | notify-fans-out-synchronously | `submitMessage('hello', [])`, then a `typing` event, then a `participantJoined` event, all flushed | The captured update kinds include `'messagesChanged'`, `'typingChanged'`, and `'participantsChanged'` — `scenarios.test.ts "notifies observers for each state-changing event kind"` |
| ccr-020 | transport-error-relayed-verbatim | `emit({ kind: 'transportError', message: 'socket closed' })` | A captured update has `kind: 'error'` and `message: 'socket closed'` — `scenarios.test.ts "emits an error update on transportError events"` |
| ccr-021 | add-remove-observer-mutate-the-same-set | `addObserver(obs)` then `removeObserver(obs)`, then a `typing` event is emitted | `obs` records zero updates — `scenarios.test.ts "does not notify after removeObserver"` |
| ccr-022 | list-commands-returns-config-commands | `createHarness({ commands: [cmd] })` | `orchestrator.listCommands()` equals `[cmd]` exactly — `scenarios.test.ts "listCommands returns the commands handed in via ChatConfig"` |
| ccr-023 | send-mints-sequential-local-ids | Two sequential `backend.send(...)` calls on a fresh `ScriptedBackend` with the default prefix | Resolved ids are `'local-1'` then `'local-2'`, both recorded in `sent` in call order — derived directly from `ScriptedBackend.send`'s counter (no dedicated `ScriptedBackend` test file exists; this is not exercised by a named test) |
| ccr-024 | close-drains-queue-before-ending | `backend.emit(eventA)` with no consumer awaiting yet; then `backend.close()`; then a consumer's first, then second, `next()` call | The first `next()` still yields `eventA` (`done: false`); the second `next()` resolves `done: true` — derived directly from the `inboundEvents` iterator checking its queue before checking closed state (no dedicated `ScriptedBackend` test file exists) |

## Edge Cases

- **Empty message text (null/empty input).** `submitMessage('', [])` is accepted with no validation — it produces a message with empty `text` and `deliveryStatus: { kind: 'sending' }` exactly like any other call. MUST (submit-message-optimistic-echo performs no content validation).
- **Unrecognized permission prompt id (null/empty input).** `respondToPermission` with a `promptID` matching no entry in `pendingPermissions` is a silent no-op — no state change, no notification. MUST (permission-response-ignores-unknown-prompt).
- **Unrecognized widget id (null/empty input).** `respondToWidget` with a `widgetID` matching no entry in `pendingWidgets` still calls `backend.submitWidgetResponse` — unlike the permission case, it is forwarded, not rejected early. MUST (respond-to-widget-unconditional-forward).
- **Read cursor to a never-seen message id (boundary value).** `markRead(messageID)` for an id absent from `messages` still upserts a `ReadReceipt` — the regression guard falls back to comparing `at` timestamps when the id cannot be located, and does not require the id to exist. MUST (read-marker-regression-guard-by-time).
- **Command result with no matching invocation (boundary value).** A `commandCompleted` event whose `invocationID` matches no entry of `activeCommands` — because the invocation was never seen, or its participant's turn already ended via `draftCleared` — is dropped with no state change. MUST (command-completed-matches-by-invocation-id).
- **Concurrent access — synchronous handlers are safe.** Every event handler and every public method's mutations, up to its first (if any) `await`, run to completion as one JavaScript microtask with nothing else able to interleave; state reads and writes that never straddle an `await` (e.g. `handleEvent`'s branches, `respondToPermission`) cannot race with each other. MUST (a property of the single-threaded JS runtime the source relies on, not a mechanism the source implements itself).
- **Concurrent access — the one real hazard.** `respondToWidget`'s rollback path is the one place state mutation straddles an `await` (the pending `backend.submitWidgetResponse` call); a concurrent `widgetPresented` or another `respondToWidget` call that completes during that window can have its effect silently discarded on rejection. See the open question on widget-response-rollback-ordering. Callers SHOULD NOT assume `pendingWidgets`/the widget-to-message map are safe from lost updates when responses are in flight concurrently.
- **Concurrent access — one backend, one consumer.** Driving two `DefaultOrchestrator` instances (or calling the iterator factory twice and consuming both) from the same `ScriptedBackend` instance does not broadcast events to both — they compete for the same shared queue. MUST NOT (inbound-events-shared-across-iterators; matches `Backend.ts`'s documented single-consumer assumption).
- **Error states — outbound send failure.** `backend.send` rejecting produces an `error` update and a re-thrown rejection, with no local echo ever added. MUST (submit-message-failure-no-echo).
- **Error states — inbound stream failure.** The `inboundEvents` iterator itself rejecting produces one `error` update, then permanently halts consumption on that instance with no retry. See event-loop-recovery.
- **Offline / disconnected state.** `DefaultOrchestrator` has no network-awareness of its own; connectivity loss is only observable if the injected `Backend` emits a `transportError` event (relayed verbatim, see transport-error-relayed-verbatim) or lets its `inboundEvents` iterator reject (see event-loop-recovery above). There is no built-in reconnect, backoff, or offline queue in `DefaultOrchestrator.ts`, `InMemoryPermissionStore.ts`, or `ScriptedBackend.ts`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ChatConfig.conversationID` | `string` | required | Seeds `conversation.id`. |
| `ChatConfig.localParticipantID` | `string` | required | Identifies which `Participant` is "this" client for `submitMessage`/`markRead`/`setLocalTyping`. |
| `ChatConfig.initialParticipants` | `ReadonlyArray<Participant>` | required | Seeds both the frozen `conversation.participants` and the live `participants` roster. |
| `ChatConfig.commands` | `ReadonlyArray<Command>` | required | Returned verbatim by `listCommands()`. |
| `ChatConfig.observingHooks` | `ReadonlyArray<ObservingHook>` | required | Accepted but never invoked by `DefaultOrchestrator` — see the open question on hook-and-permission-enforcement. |
| `ChatConfig.gatingHooks` | `ReadonlyArray<GatingHook>` | required | Accepted but never invoked by `DefaultOrchestrator` — see the open question on hook-and-permission-enforcement. |
| `ChatConfig.permissionStore` | `PermissionStore` | required | Consulted only via `remember()` inside `respondToPermission`; `decision()` is never called by `DefaultOrchestrator` itself. |
| `ChatConfig.backend` | `Backend` | required | The sole source of `InboundEvent`s and the sole sink for `send`/`setLocalTyping`/`submitWidgetResponse`. |
| `ChatConfig.display` | `DisplayConfig` | required | Stored verbatim as `displayConfig`; never read or branched on internally by these three files (see Accessibility Options and Feature Flags below). |
| `ScriptedBackend` constructor option `localIDPrefix` | `string`, optional | `'local'` | Prefix used to format minted local ids as `<prefix>-<n>`. |

## Deep Linking

Not applicable: `DefaultOrchestrator.ts`, `InMemoryPermissionStore.ts`, and
`ScriptedBackend.ts` define no URL, route, or scheme handling of any kind.

## Localization

These three files carry, but do not author or localize, user-facing text.
`presentPermissionPrompt` stores a caller-supplied `PermissionPrompt`
(`displayPrompt`/`permission.displayPromptTemplate`) untouched in
`pendingPermissions`. Error text — `ChatUpdate`'s `error.message`,
`MessageDeliveryStatus`'s `failed.reason` — is forwarded verbatim from a
caught `Error`'s message, `String(error)`, or the inbound event's own field,
in whatever language the throwing code or the backend produced it. None of
`DefaultOrchestrator.ts`, `InMemoryPermissionStore.ts`, or `ScriptedBackend.ts`
contains a translation table, a locale lookup, or pluralization logic;
localizing any of this text is the responsibility of whatever authors it (a
`GatingHook`/`ObservingHook`, the real `Backend`, or the UI layer), which is
out of scope for this recipe.

## Accessibility Options

Not applicable: `displayConfig.reducedMotion` is stored verbatim (see
construction-copies-config-fields-verbatim) but never read or branched on by
`DefaultOrchestrator.ts`, `InMemoryPermissionStore.ts`, or `ScriptedBackend.ts`
— responding to it is a rendering concern for whatever UI layer reads
`displayConfig`, not this runtime.

## Feature Flags

Not applicable: no flag, toggle, or config-gated code path exists in
`DefaultOrchestrator.ts`, `InMemoryPermissionStore.ts`, or `ScriptedBackend.ts`.

## Analytics

Not applicable: none of these three files emits an analytics or telemetry
event of any kind.

## Privacy

- **Data collected**: `Message.text`/`attachments` (arbitrary caller- and
  backend-supplied content), participant identifiers
  (`Participant.id`/`senderID`/`requesterID`), and permission-grant history
  (a `PermissionDecision` keyed by `permission.id` plus `requesterID` in
  `InMemoryPermissionStore`). None of these three files treats any of it as a
  credential or token, but message text and attachments can carry arbitrary
  content a user chooses to type or attach.
- **Storage**: Entirely in-memory — plain class fields in `DefaultOrchestrator`
  and a `Map` in `InMemoryPermissionStore` — for the lifetime of the owning
  instance; nothing in these three files writes to disk, `localStorage`, or a
  database.
- **Transmission**: None directly. These three files perform no network I/O
  themselves; all transmission is delegated to whichever concrete `Backend`
  implementation is injected (out of scope for this recipe). `ScriptedBackend`
  performs no transmission at all — it only records calls in memory.
- **Retention**: For the lifetime of the instance only. Constructing a new
  `DefaultOrchestrator`/`InMemoryPermissionStore` (or restarting the process)
  discards all of it; there is no expiry or revoke path for an already
  remembered `allowAlways`/`denyAlways` decision short of that (see
  store-has-no-revoke-operation).

## Logging

Not applicable: no `console.*`, `os_log`, or other logging call appears
anywhere in `DefaultOrchestrator.ts`, `InMemoryPermissionStore.ts`, or
`ScriptedBackend.ts`.

## Platform Notes

- **React/Web** (source platform): This IS the reference implementation —
  `packages/web/packages/chat/src/runtime/DefaultOrchestrator.ts`,
  `InMemoryPermissionStore.ts`, and `ScriptedBackend.ts`. State lives in plain
  class fields reassigned via immutable copies (`[...this.messages, message]`,
  a fresh `Map`), notification is a `Set<ChatStateObserver>` iterated
  synchronously, and the inbound stream is a native `AsyncIterable`/
  `AsyncIterator` consumed by a `while (!this.stopped)` loop awaiting
  `iterator.next()`.
- **SwiftUI**: Model `Orchestrator` as an `@Observable` (or, on older targets,
  `ObservableObject` with `@Published`) class exposing the same fields; back
  the inbound stream with Swift's native `AsyncStream<InboundEvent>` (the
  direct analog of a JS async iterable) and drive the consumer with a `Task`
  that `for await`s it, cancelling that `Task` in place of `stop()`'s
  `iterator.return()`. Port `PermissionStore` as a small `actor` (or a
  `@MainActor`-isolated class) wrapping a `Dictionary`, since
  `InMemoryPermissionStore`'s backing `Map` has no synchronization of its own
  in source and Swift's concurrency checker will require an explicit
  isolation choice once the type crosses an `async` boundary.
- **Compose**: Expose the view-model's fields as `mutableStateOf`/
  `SnapshotStateList` properties (or a `StateFlow<ChatViewModel>` for
  Flow-oriented composition) so recomposition tracks the same fields
  `DefaultOrchestrator` reassigns wholesale. Back `Backend.inboundEvents` with
  a Kotlin `Flow<InboundEvent>` and drive the consumer with
  `flow.collect { }` inside a `viewModelScope.launch` coroutine, in place of
  the async `while` loop. Back `PermissionStore` with a `MutableMap` guarded
  by a `Mutex` (or hosted on a single-threaded `CoroutineDispatcher`), since
  nothing in `InMemoryPermissionStore.ts` synchronizes concurrent access
  either.
- **AppKit / UIKit**: No SwiftUI dependency is required — the same
  `Orchestrator`-conforming reference type works as a plain reference type
  whose `ChatStateObserver`s are AppKit/UIKit controllers implementing
  `chatDidUpdate`. Source notifies synchronously and inline, with no thread
  hop of its own, so an AppKit/UIKit host MUST hop to the main queue itself
  before touching views — `DefaultOrchestrator.ts` performs no such hop.
- **WinUI 3**: Model `ChatViewModel`'s mutable array-valued fields
  (`messages`, `participants`, `activeDrafts`, `activeCommands`,
  `readMarkers`, `pendingWidgets`, `typingParticipants`) as
  `ObservableCollection<T>` properties on a class implementing
  `INotifyPropertyChanged`, raising collection-changed/`PropertyChanged`
  events in place of the source's `notify(ChatUpdate)` fan-out to a
  `HashSet<ChatStateObserver>` (a WinUI host would more naturally bind views
  directly to the `ObservableCollection`s than replicate the
  `ChatStateObserver` push model one-for-one, though a thin
  `IObservable<ChatUpdate>`-style event can be layered on top to match call
  sites exactly). Back `Backend.InboundEvents` with `IAsyncEnumerable<InboundEvent>`
  (`System.Text.Json` for any wire encoding, `HttpClient` inside a concrete
  `Backend` for a networked implementation) and drive the consumer with
  `await foreach (var evt in backend.InboundEvents.WithCancellation(cts.Token))`
  inside a `Task.Run`, cancelling a `CancellationTokenSource` from `Stop()` in
  place of `iterator.return()`. Port `InMemoryPermissionStore` as a class
  wrapping a `Dictionary<string, PermissionDecision>` guarded by a `lock` (or
  a `ConcurrentDictionary`) — .NET gives no free single-threaded guarantee the
  way the JS runtime does, so the "no internal synchronization" characteristic
  documented in Design Decisions MUST become an explicit lock on this
  platform rather than staying implicit.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/chat/src/runtime/` | unverified |

## Design Decisions

- **Decision**: Locally submitted messages get an immediate optimistic echo
  into `messages` (with `deliveryStatus: { kind: 'sending' }`) before the
  backend confirms anything, while inbound messages from other participants
  only ever appear via a `messageReceived` event.
  **Rationale**: The sender already knows they sent the message the instant
  they call `submitMessage`; waiting for `messageAccepted` before showing it
  would make the UI feel unresponsive. A receiver has no equivalent local
  intent to echo, so their copy is only ever the confirmed, backend-produced
  `Message`.
  **Approved**: pending
- **Decision**: `draftUpdated` events carry the whole draft text so far and
  each one REPLACES the stored text rather than appending a fragment.
  **Rationale**: Documented directly in `InboundEvent.ts`'s comment: this
  keeps `Message` immutable while preserving token-by-token streaming UX, and
  a backend that instead emitted fragments would silently produce a
  transcript missing every reply's prefix, with no error to catch it.
  **Approved**: pending
- **Decision**: `conversation.participants` is frozen at construction from
  `ChatConfig.initialParticipants`, while the separate top-level
  `participants` property is the one that tracks every subsequent
  `participantJoined`/`participantDeparted` event.
  **Rationale**: Not called out in a source comment, but directly observable
  from the code: `handleEvent`'s `participantJoined`/`participantDeparted`
  branches only ever reassign `this.participants`, never
  `this.conversation.participants`. A port author reading only the
  `Conversation` type might reasonably expect its `participants` field to
  stay live; it does not in this implementation, and the two fields diverge
  the moment the roster changes for the first time.
  **Approved**: pending
- **Decision**: `Backend.inboundEvents` is documented as having exactly one
  consumer (`DefaultOrchestrator`), and `ScriptedBackend`'s iterator factory
  shares one queue and one waiter list across every iterator it produces
  rather than fanning events out to each independently.
  **Rationale**: `Backend.ts`'s own doc comment states multiplexing to
  multiple observers is the orchestrator's job, not the backend's — the
  backend only needs to support one reader. `ScriptedBackend` is a test
  double built to exactly that contract, not a general-purpose broadcast
  stream; a caller that drives two consumers off one `ScriptedBackend`
  instance is outside what it was built to support (see the concurrent-access
  edge case above).
  **Approved**: pending
- **Decision**: `InMemoryPermissionStore` persists only `allowAlways`/
  `denyAlways` decisions, is purely in-memory and process-local, and offers
  no way to revoke a remembered decision other than discarding the instance.
  **Rationale**: Stated directly in the class's own doc comment: `*Once`
  decisions are inherently single-use and would be meaningless to remember.
  Being in-memory and revocation-free is consistent with a lightweight,
  per-session store — a caller needing durable, revocable grants needs a
  different `PermissionStore` implementation; this reference one is not it.
  **Approved**: pending
- **Decision**: A caller SHOULD, but is not required to, call `start()`
  before relying on inbound-event-driven state.
  **Rationale**: Every public method that does not depend on the inbound
  stream (`submitMessage`, `markRead`, `setLocalTyping`, `respondToWidget`,
  `respondToPermission`) works identically whether or not `start()` has been
  called, because none of them read `started`/`stopped`. The only consequence
  of calling them before `start()` is that no inbound event will yet have
  been observed — there is no error path or invalid state to guard against,
  which is why this is a SHOULD (a usage recommendation) rather than a MUST.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |

`explicit-error-handling` is partial: `submitMessage` and `respondToWidget`
surface backend failures as an `error` update and a re-thrown rejection, but
an `inboundEvents` iterator rejection is surfaced once and then the event
loop halts permanently with no further signal (see event-loop-recovery).
`separation-of-concerns` passes: `DefaultOrchestrator` (view-model state),
`InMemoryPermissionStore` (permission memory), and `ScriptedBackend` (test
transport) each own exactly one responsibility behind the `Backend`/
`PermissionStore` interfaces, and `DefaultOrchestrator` never reaches into
either implementation's internals. `unit-test-coverage` is partial:
`scenarios.test.ts` exercises `DefaultOrchestrator` extensively (18 test
cases) and, through it, `InMemoryPermissionStore` and `ScriptedBackend`
indirectly, but neither `InMemoryPermissionStore` nor `ScriptedBackend` has a
dedicated test file of its own — `close()`'s queue-draining behavior and
`send()`'s id-minting are untested directly (see ccr-023 and ccr-024).
`fault-tolerance` is partial for the same reason as `explicit-error-handling`:
the scheduler-equivalent here (the event-loop task) has no catch-up or retry
mechanism once its source throws. `graceful-degradation` is partial: known,
recognized failures (a rejected `send`, a rejected `submitWidgetResponse`, an
unrecognized permission/widget id) degrade cleanly to a documented no-op or
error signal, but an unrecovered inbound-stream failure and the
gating/observing hook surface (see the open question on hook-and-permission-enforcement) leave no
degraded-but-functioning path — they leave the runtime either fully working
or silently missing a whole mechanism.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
