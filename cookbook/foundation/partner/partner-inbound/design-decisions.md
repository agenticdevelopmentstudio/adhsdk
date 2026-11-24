
**Decision**: The coalescing key is built from the case and its id only, not from the payload.
**Rationale**: The queue exists so that a burst of ticks or idle events for the same job or session becomes one entry carrying the newest payload; including a summary or title in the key would stop repeats from collapsing.
**Approved**: pending

**Decision**: Owner and lifecycle events have no key.
**Rationale**: Owner messages are distinct instructions and lifecycle notices are one-off facts; collapsing either would lose information the partner must read. The source's own doc comment states that they never collapse.
**Approved**: pending

**Decision**: Idle and exited events for one session use different key prefixes (`idle` and `exit`).
**Rationale**: A session that went idle and then exited are two different facts; the exit must not overwrite or be overwritten by the idle notice.
**Approved**: pending

**Decision**: The event text is fixed English prose with ids inserted as given.
**Rationale**: The text is the partner's input, and the partner's guidelines and base prompt (Partner Base Prompt ([adhsdk.ingredient.foundation.partner.partner-base-prompt](cookbook:1abdd016-954c-4058-8db3-224c52712365))) refer to the events by these phrases. The text is not validated or escaped, so the partner reads exactly what the app knows.
**Approved**: pending

**Decision**: The text of a tick uses UTC ISO 8601 for the previous tick.
**Rationale**: The default ISO 8601 style is locale independent, so the partner reads the same instant regardless of the host's time zone.
**Approved**: pending

