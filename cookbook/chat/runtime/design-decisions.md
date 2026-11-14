
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
  **Rationale**: `markRead`, `setLocalTyping`, `respondToWidget`, and
  `respondToPermission` work identically whether or not `start()` has been
  called, and `submitMessage` still calls the backend and echoes the message
  locally. The consequence of never starting is that no inbound event is
  observed: a submitted message is never acknowledged and stays in `sending`
  forever. That is a stuck state rather than an error, which is why this is a
  SHOULD (a usage recommendation) rather than a MUST.
  **Approved**: pending
- **Decision**: Event-loop recovery: when the backend's `inboundEvents` iterator rejects, the loop notifies one `error` update and ends, and the instance never resumes consumption or restarts.
  **Rationale**: `DefaultOrchestrator` implements no retry, backoff, or reconnect policy, and a later `start()` is a no-op (see start-is-idempotent). Reconnecting is the injected `Backend`'s job, or the host's by constructing a new orchestrator. This leaves a stopped instance silently inert, which is recorded here as known debt rather than as a requirement.
  **Approved**: pending
