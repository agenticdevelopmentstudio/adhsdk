
**Decision**: Every failure collapses into nil.
**Rationale**: The service doc comment says reads and writes answer nil when the daemon was unreachable, refused, or its reply couldn't be read; the caller needs only "could not do it", and distinguishing causes would need an error type on every call. The cost is a caller that cannot say why.
**Approved**: pending

**Decision**: A failed spans read is nil, not an empty array.
**Rationale**: The comment on `spans` says "a failed read is never 'none'" in the source; a nil reads as unknown while an empty array reads as nothing happened.
**Approved**: pending

**Decision**: Recheck and preferences push each wait 15 seconds.
**Rationale**: The comments explain the daemon answers only after a live Accessibility check that stalls about ten seconds on `tccd` without the grant. A shorter wait drops the "denied" about to arrive (review F24) or counts a failure on a change the daemon applied.
**Approved**: pending

**Decision**: No retries on any call.
**Rationale**: Every call passes `retries: 0`, and the source states no reason for it, so the reason is an open question for the maintainer (the approval stays pending until it is answered). The effect is that a timed-out preferences push is not repeated by the client, so the caller sees nil and decides whether to read `status()` or push again.
**Approved**: pending

**Decision**: The client is generic over a small transport protocol.
**Rationale**: The comment says the protocol has "the shape DaemonKit's XPCClient already has", so the SDK tier links no daemon framework and tests use a scripted transport.
**Approved**: pending

**Decision**: One decoder reads all replies, and the failure sentinel arrives camel-cased.
**Rationale**: `makeReplyDecoder()` is "the one JSON reading of a work-tracking reply"; because it converts from snake case, the sentinel key `work_tracking_read_failed` is read as `workTrackingReadFailed`.
**Approved**: pending

