
**Decision**: The counters are grouped by lane kind, `write` and `read`, as two arrays of one `Pool` shape.
**Rationale**: The source's header calls them per-lane bounded-execution counters, and one shape for every lane keeps a new lane a new element and not a new field.
**Approved**: pending

**Decision**: The DTO is `Codable` and `Sendable` but not `Equatable`.
**Rationale**: A stats snapshot is a point-in-time reading with floating-point latencies, so nothing needs to compare two of them for equality; a port should not assume value equality on one.
**Approved**: pending

