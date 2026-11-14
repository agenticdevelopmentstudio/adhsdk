
**Decision**: The counters are grouped by lane kind, `write` and `read`, as two arrays of one `Pool` shape.
**Rationale**: The source's header calls them per-lane bounded-execution counters, and one shape for every lane keeps a new lane a new element and not a new field.
**Approved**: pending

**Decision**: The DTO is `Codable` and `Sendable` but not `Equatable`.
**Rationale**: The source declares only those two conformances; a port should not assume value equality on a stats snapshot.
**Approved**: pending

