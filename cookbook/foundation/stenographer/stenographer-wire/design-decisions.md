
**Decision**: The JSON spelling is defined once, as factories, and used by every end of a relayed request.
**Rationale**: The source comment states the aim: the three ends cannot drift into three dialects, and a `Date` added to a DTO decodes the same everywhere.
**Approved**: pending

**Decision**: Snake_case keys and ISO-8601 dates.
**Rationale**: The source comment names them as the daemon's spelling; the route bodies and replies in the HTTP client use them.
**Approved**: pending

**Decision**: Factories return new instances.
**Rationale**: The source returns a new `JSONEncoder` or `JSONDecoder` per call, so no mutable coder is shared through a global.
**Approved**: pending

