
**Decision**: The activity is derived on each read from recorded inputs and is not stored.
**Rationale**: The doc comment on `SessionActivity.derive` in `SessionActivity.swift` says the daemon records what happened, not what it means, so the meaning can be re-read or re-mapped for a new event type without a schema change.
**Approved**: pending

**Decision**: A live subagent promotes an `idle` turn to `working` but never overrides `waiting`.
**Rationale**: The same `derive` doc comment says a live subagent reads as working because it is, and a session blocked on a permission prompt still needs the user whatever its subagents are doing. The quieter reading must not bury the louder one, as the test `testALiveSubagentNeverOverridesWaiting` records.
**Approved**: pending

**Decision**: Any event type not listed, including events added later, reads as `working`; the empty string is listed and reads `idle`.
**Rationale**: The comment on the `default` branch of `turnActivity(lastEventType:)` in `SessionActivity.swift` says the agent is mid-turn for everything else, so an unmapped hook event shows as busy rather than silently idle. The cost is that a new turn-ending event reads `working` until it is added to the idle list.
**Approved**: pending

**Decision**: One enum serves both the Sessions window icon and `steno conversation status`.
**Rationale**: The doc comment on the `SessionActivity` enum in `SessionActivity.swift` states this is so the two can never disagree about what a session is doing.
**Approved**: pending

**Decision**: `SessionActivity` is kept separate from `SessionStatus`.
**Rationale**: Status answers "does a process exist"; activity answers what a live process is doing. Collapsing them would force a single enum to carry both questions.
**Approved**: pending

