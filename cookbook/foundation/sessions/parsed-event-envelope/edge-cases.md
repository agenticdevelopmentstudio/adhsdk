
- **Empty or missing data** (MUST): an empty `hookData` encodes as `{}`; `sessionId` is then empty and the parser skips it.
- **Non-serializable payload** (MUST): throws `notSerializable` with the event type, before any bytes are produced.
- **Empty event type** (MUST): encodes without error and fails at parse time as `.unparseable`; the encoder does not guard it.
- **Number and boolean fidelity** (MUST): values pass through `JSONSerialization`, so numbers come back as Foundation numbers; a port MUST preserve the JSON number and boolean distinction.
- **Large payloads** (not applicable): the source sets no size limit.
- **Concurrent access** (MUST): safe on one event, since every field is immutable and the function does no shared writes.
- **Error states, offline or disconnected** (not applicable): the function does no I/O beyond in-memory encoding; the spool write that follows and its failures belong to the caller.
- **Cancellation, timeouts** (not applicable): the function is synchronous.

