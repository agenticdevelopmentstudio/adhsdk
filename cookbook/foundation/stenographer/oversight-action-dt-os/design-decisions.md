
**Decision**: The daemon computes `actionable`, and the client adds terminal support.
**Rationale**: The source states the daemon is the single source of truth for session state, while only the app holds the Automation grant that decides terminal capability.
**Approved**: pending

**Decision**: Safe breakpoint means the last event was `Stop`.
**Rationale**: The source states Claude has then finished a response and waits for the user; acting mid-response is unsafe.
**Approved**: pending

**Decision**: The same `actionable` check gates phase-4 autonomous action.
**Rationale**: The source states this keeps the safety rule in exactly one place.
**Approved**: pending

**Decision**: The shapes are flat Strings and Bools, not enums or a blocked/actionable sum type.
**Rationale**: The source types `status` and `termProgram` as Strings and lets `actionable` and `reason` be set independently, so the wire shape stays simple and a new value decodes without a shape change, at the cost of no compile-time check.
**Approved**: pending

**Decision**: The shape does not constrain `injectText`.
**Rationale**: The source carries the daemon's text as a plain String, so whether to allow-list it (for example to known slash commands) before typing it into a terminal is the consuming app's decision.
**Approved**: pending

**Decision**: The app calls the act route only after a successful injection.
**Rationale**: The source states this makes a failure there a rare race, so the result carries a reason and the current status and not a retry protocol.
**Approved**: pending

