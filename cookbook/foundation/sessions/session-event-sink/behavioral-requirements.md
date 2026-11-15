
**Sink protocol**

- **sink-sendable**: `SessionEventSink` MUST be a `Sendable` protocol, so one sink can be shared across the daemon's queues and tasks.
- **sink-broadcast-signature**: A sink MUST implement `broadcast(eventType: String, payload: Data, sessionId: String?)`, which returns nothing and does not throw.
- **sink-status-signature**: A sink MUST implement `broadcastSessionStatus(sessionId: String, status: SessionStatus)` (Session Status ([adhsdk.ingredient.foundation.sessions.session-status](cookbook:787b5da6-2f20-4f3e-8104-1763959a735f))), which returns nothing and does not throw.
- **broadcast-payload-prebuilt**: The `payload` given to `broadcast` MUST be the already-encoded wire JSON of the event; a sink MUST NOT re-encode it.
- **broadcast-session-filter**: `sessionId` MUST be passed so a transport can filter subscribers to one session; it is optional and `nil` means the event is not tied to one session.
- **status-payload-shape**: A transport publishing a session status change MUST publish the payload `{"session_id": ..., "status": ...}` produced by `SessionEventEncoding.encodeSessionStatus(sessionId:status:)`.
- **sink-transport-neutral**: The ingesting code MUST NOT depend on how a sink delivers; whether it uses SSE, XPC, both or neither is the sink's concern.
- **sink-no-delivery-signal**: A sink MUST NOT report delivery success or failure to its caller; neither protocol method returns a value or throws.

**Caller obligations**

- **caller-skips-on-encode-failure**: A caller that encodes an event for a sink MUST NOT call `broadcast` with a payload for that event when `encode` returns `nil`. `EventIngestor` logs a debug line `broadcast encode failed` and returns without publishing, so a failed encode is a logged drop, not a crash.

**Encoding**

- **encode-snake-case**: `SessionEventEncoding.encode(_:)` MUST convert coding keys to snake_case.
- **encode-iso8601**: `SessionEventEncoding.encode(_:)` MUST encode dates in the ISO-8601 strategy.
- **encode-sorted-keys**: `SessionEventEncoding.encode(_:)` MUST output object keys in sorted order, so equal values give equal bytes.
- **encode-optional-result**: `SessionEventEncoding.encode(_:)` MUST return `nil` when encoding fails; it MUST NOT throw and the error is discarded.
- **encode-generic**: `encode(_:)` MUST accept any `Encodable` value.
- **encode-status-fields**: `encodeSessionStatus(sessionId:status:)` MUST produce a JSON object with exactly two keys: `session_id` holding the id and `status` holding the status's raw string.
- **encode-status-raw**: The `status` field MUST be `SessionStatus.rawValue`: `"active"`, `"stale"` or `"ended"`.
- **encode-status-via-encode**: `encodeSessionStatus` MUST encode through `encode(_:)`, so it shares the same options and the same `nil` on failure.
- **encode-stateless**: `SessionEventEncoding.encode(_:)` MUST be stateless and safe to call concurrently; the type holds no shared encoder state.
- **encode-slash-escaping**: `SessionEventEncoding.encode(_:)` MUST escape `/` in string values as `\/`, which is Foundation's default, so that every port gives the same bytes as the Swift source.

