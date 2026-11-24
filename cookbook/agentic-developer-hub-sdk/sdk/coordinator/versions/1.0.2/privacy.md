
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

