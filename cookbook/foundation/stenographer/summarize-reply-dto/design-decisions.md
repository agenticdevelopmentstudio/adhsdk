**Decision**: The reply carries the daemon's failure reason as a field instead of failing the call.
**Rationale**: The source comment states the aim: the app's Summarize shows the daemon's reason (such as the memory guard's refusal) instead of a generic failure.
**Approved**: pending

**Decision**: A nil XPC reply stays "transport or encoding failed", distinct from a reply with an `error`.
**Rationale**: The source comment states it, so the app can tell an unreachable daemon from a daemon that declined.
**Approved**: pending

**Decision**: One type with two optional fields, not a result enum.
**Rationale**: The source keeps the wire shape `{session_id, summary}` or `{session_id, error}` flat; the one-of rule is left to the producer.
**Approved**: pending
