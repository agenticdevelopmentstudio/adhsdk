
- **Null / empty input**: A missing or empty timestamp MUST mean no bound (`.success(nil)`, or `""` for `activitySince`). A missing `limit` or `offset` MUST use the default; a missing path is not possible, and `/` yields no components.
- **Boundary values**: `limit` of 0 and -1 MUST become 1; `limit` above the ceiling MUST become the ceiling; `offset` of -40 MUST become 0. An integer string too large for `Int` fails to parse and takes the default (derived from `Int(String)` returning `nil`; no test beside the source).
- **Repeated query values**: When a key repeats, `query`, `queryInt`, `boundedLimit`, `boundedOffset` and `validatedTimestamp` MUST read only the last value, while `queryAll` returns all.
- **Malformed input**: A non-numeric `limit` or `offset` is silently replaced by the default; a non-ISO `since` is a failure, not a default. This asymmetry is deliberate (see Design Decisions).
- **Ceiling below one**: See the open question on `ceiling-below-one`.
- **Missing key versus empty value**: For timestamps both mean unbounded; for integers an empty value is unparseable and takes the default.
- **Concurrent access**: A `RouteRequest` is an immutable `Sendable` value and every method is pure, so handlers running concurrently can share one without ordering rules. The shared ISO formatters live in `TimestampParsing`; each canonicalization here builds its own `ISO8601DateFormatter`.
- **Error states**: Timestamp validators return a typed failure and never throw; the other accessors have no failure path.
- **Offline / disconnected state**: Not applicable: the type performs no network access; it describes a request already received.
- **Cancellation and timeouts**: Not applicable: every call is a synchronous in-memory computation.

