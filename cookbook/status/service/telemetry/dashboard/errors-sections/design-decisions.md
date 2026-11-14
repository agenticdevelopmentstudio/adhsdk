
**Decision**: The board's rule, not a second one.
**Rationale**: `active` calls the board's `errorCountsAsProblem`, so the dashboard and the board agree on which errors count, allowlist included.
**Approved**: pending

**Decision**: Throw on a failed read.
**Rationale**: A failed unresolved read throws so the section cache keeps its last good answer, rather than returning an empty list that would look like zero errors.
**Approved**: pending

**Decision**: Resolved count cached for an hour.
**Rationale**: Counting means walking every resolved page for one KPI figure that barely moves; the issue list refreshes every 60 seconds (the GlitchTip cache TTL set by [adhsdk.ingredient.status.service.telemetry.dashboard.dashboard-set](cookbook:f03325ef-f4c6-43ab-9a88-1a0bf3daa002)), so counting on each refresh would spend up to twenty requests a minute on it.
**Approved**: pending

**Decision**: Failures not cached, caps cached.
**Rationale**: A failed read is retried next refresh; a capped walk would cap again, so it stands for the TTL.
**Approved**: pending

**Decision**: No events series.
**Rationale**: GlitchTip's stats answer nulls on this instance, so a chart would mislead.
**Approved**: pending

