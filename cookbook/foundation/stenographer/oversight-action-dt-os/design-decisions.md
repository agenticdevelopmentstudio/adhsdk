
**Decision**: The daemon computes `actionable`, and the client adds terminal support.
**Rationale**: The source states the daemon is the single source of truth for session state, while only the app holds the Automation grant that decides terminal capability.
**Approved**: pending

**Decision**: Safe breakpoint means the last event was `Stop`.
**Rationale**: The source states Claude has then finished a response and waits for the user; acting mid-response is unsafe.
**Approved**: pending

**Decision**: The same `actionable` check gates phase-4 autonomous action.
**Rationale**: The source states this keeps the safety rule in exactly one place.
**Approved**: pending

**Decision**: The app calls the act route only after a successful injection.
**Rationale**: The source states this makes a failure there a rare race, so the result carries a reason and the current status and not a retry protocol.
**Approved**: pending

