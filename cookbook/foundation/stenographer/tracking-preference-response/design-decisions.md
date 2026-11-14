
**Decision**: One response shape serves both the read and the write.
**Rationale**: A caller that toggles the preference and a caller that reads it want the same three facts; the `outcome` word (`current` for a read) tells them which call produced it.
**Approved**: pending

**Decision**: `outcome` is a free string rather than an enum.
**Rationale**: The wire stays open to new outcomes without breaking an older reader; the cost is that readers must handle values they do not know.
**Approved**: pending

**Decision**: A write reports the requested `enabled` and, separately, the marker's real state.
**Rationale**: The route's comment says the app owns the cross-process marker so a toggle while the daemon is offline self-heals at the next boot; reporting both lets the caller see when they differ.
**Approved**: pending

**Decision**: A failed install returns an error, not a response with a failure outcome.
**Rationale**: The failure is a thrown error mapped to status 500 with the installer's message, so a caller never mistakes a failed enable for a state.
**Approved**: pending

