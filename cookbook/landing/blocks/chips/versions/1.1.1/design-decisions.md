
**Decision**: List items receive no baseline per-item class; only an item marked active (`open: true`) gets a modifier class (`lp-chip--open`).
**Rationale**: The list container already carries the shared baseline styling for every chip, so a per-item class only needs to exist for the state that diverges from that baseline (active). Adding a matching baseline class to every item would duplicate what the container already expresses.
**Approved**: pending

**Decision**: The upcoming/de-emphasized treatment (`soon`) is a single modifier on the list container, not a flag on each entry.
**Rationale**: Every chip in an "upcoming" list shares the same de-emphasized treatment together, so expressing it once at the list level lets it compose independently with each entry's own active state, rather than requiring every entry to repeat the same flag.
**Approved**: pending

