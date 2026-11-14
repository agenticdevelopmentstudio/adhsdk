**Decision**: Request fields are all optional, and an omitted field leaves the stored value alone.
**Rationale**: The source comment states it: a partial update lets an app push only what it owns; the snapshot push sends all of them.
**Approved**: pending

**Decision**: `SummaryPreferenceResponse.enabled` and `selectedConfigId` are optional.
**Rationale**: The source comment states that older daemons did not return them, and a missing field must not make the whole reply undecodable.
**Approved**: pending

**Decision**: The client does not clamp tuning values.
**Rationale**: The source comment states that the daemon clamps them through `SummaryLimits`, so the daemon is the single owner of the ranges.
**Approved**: pending

**Decision**: Requests are not `Equatable`; responses are.
**Rationale**: The source marks only the responses `Equatable`; a response is the stored state a caller compares, while a request is a transient update.
**Approved**: pending
