
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

