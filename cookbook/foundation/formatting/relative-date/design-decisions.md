
**Decision**: The cutoff is a parameter that can be turned off, not a fixed rule.
**Rationale**: The two call sites this formatter replaced never switched to an absolute date, and moving them onto it must not change what they show; a history list wants the absolute day for old commits.
**Approved**: pending

**Decision**: Each call builds its own `RelativeDateTimeFormatter` rather than sharing a cached one.
**Rationale**: The style and locale vary per call, and a shared formatter would need locking to be safe from more than one thread; building one is cheap next to drawing the row that shows it.
**Approved**: pending

