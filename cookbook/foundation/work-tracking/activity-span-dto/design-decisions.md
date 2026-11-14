
**Decision**: Timestamps are ISO-8601 strings, not `Date`.
**Rationale**: The source comments declare `startedAt` as "ISO-8601 UTC" and the type holds `String` throughout, which keeps the wire shape identical across processes and platforms and avoids date-strategy mismatches between encoder and decoder.
**Approved**: pending

**Decision**: Absence is encoded as the empty string, not as an optional.
**Rationale**: The comments `"" = unresolved`, `"" = no repo`, `"" = open` and `"" = no heartbeat yet` name each sentinel, so every field is always present on the wire and decoders never see `null`.
**Approved**: pending

**Decision**: Only `windowTitle`, `endedAt` and `lastSeenAt` are mutable.
**Rationale**: A span's identity, app, location and start are fixed when it opens, while the title, close time and heartbeat change as the span lives; the `let` and `var` split in the source encodes that.
**Approved**: pending

**Decision**: `isOpen` is derived from `endedAt` alone.
**Rationale**: One source of truth avoids a stored flag drifting from the end timestamp.
**Approved**: pending

**Decision**: No field validation in the type.
**Rationale**: The source has no checks; callers such as the recorder own correctness, which keeps the DTO a pure carrier.
**Approved**: pending

