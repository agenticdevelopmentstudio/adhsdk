
**Decision**: The reply carries the daemon's failure reason as a field instead of failing the call.
**Rationale**: The source comment states the aim: the app's Summarize shows the daemon's reason (such as the memory guard's refusal) instead of a generic failure.
**Approved**: pending

**Decision**: A nil XPC reply stays "transport or encoding failed", distinct from a reply with an `error`.
**Rationale**: The source comment states it, so the app can tell an unreachable daemon from a daemon that declined.
**Approved**: pending

**Decision**: One type with two optional fields, not a result enum.
**Rationale**: The source keeps the wire shape `{session_id, summary}` or `{session_id, error}` flat; the one-of rule is left to the producer.
**Approved**: pending

**Decision**: The type tolerates both fields nil and both set instead of rejecting them in `init(from:)` and the initializer.
**Rationale**: The source declares plain optionals with synthesized `Codable`, so the illegal states are representable. A custom decoder would parse the reply into a result instead of validating it afterwards, but the source does not do that, so the tolerance is recorded here for review.
**Approved**: pending

