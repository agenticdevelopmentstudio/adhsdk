
**Decision**: Request fields are all optional, and an omitted field leaves the stored value alone.
**Rationale**: A partial update lets each app push only the fields it owns, so one app does not overwrite a value another app set; the snapshot push sends all of them when it wants a full write. The alternative, a full-state request, would force every caller to read the stored values first.
**Approved**: pending

**Decision**: `SummaryPreferenceResponse.enabled` and `selectedConfigId` are optional.
**Rationale**: The doc comment on `SummaryPreferenceResponse` in `StenographerPreferenceDTOs.swift` states that older daemons did not return them, and a missing field must not make the whole reply undecodable. Making every field optional would also tolerate those daemons, but it would hide a genuinely malformed reply.
**Approved**: pending

**Decision**: The DTOs do not clamp tuning values.
**Rationale**: The daemon is the single owner of the ranges (`SummaryLimits`), so a second copy of the clamp here could drift from it; a value sent out of range comes back changed in the reply, which the caller can see.
**Approved**: pending

**Decision**: Requests are not `Equatable`; responses are.
**Rationale**: A response is the stored state a caller compares to see whether a pushed value came back unchanged, while a request is a transient update nobody needs to compare.
**Approved**: pending

