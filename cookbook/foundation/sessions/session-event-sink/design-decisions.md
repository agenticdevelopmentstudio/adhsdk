
**Decision**: Ingestion encodes each event once and hands every sink the same bytes.
**Rationale**: The doc comment on `SessionEventSink` in `SessionEventSink.swift` says the encoding is not the sink's concern, so two daemons publish identical payloads whatever their transports, and no transport serializes the event twice on the ingest hot path (the comment in `broadcastIngestedEvent` in `Database/Daemon/Ingestion/EventIngestor.swift`, line 261).
**Approved**: pending

**Decision**: The sink protocol returns nothing and cannot throw.
**Rationale**: Ingestion must not depend on, or be blocked by, delivery. A transport with no subscribers is a normal condition, and the source gives callers no delivery signal.
**Approved**: pending

**Decision**: `encode` returns `nil` on failure, using `try?`, rather than throwing.
**Rationale**: The caller treats an unencodable event as a dropped broadcast and logs it. The cost is that the underlying error is discarded, which is a deliberate lossy projection and not a silent one: the caller logs the failure.
**Approved**: pending

**Decision**: Keys are sorted and converted to snake_case, and dates are ISO-8601.
**Rationale**: The source names these as the wire format (snake_case, ISO-8601 dates, sorted keys). Sorted keys make equal values byte-equal, so payloads from two daemons can be compared.
**Approved**: pending

**Decision**: The status payload is built with explicit coding keys in a private struct.
**Rationale**: It pins `session_id` and `status` as the contract regardless of the key strategy, and sends the status as its raw string.
**Approved**: pending

