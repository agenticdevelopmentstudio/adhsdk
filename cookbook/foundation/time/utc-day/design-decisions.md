
**Decision**: Day strings are produced with a fixed `UTC` time zone, never the host's current zone.
**Rationale**: The daemon buckets days with `substr(timestamp, 1, 10)` on stored UTC ISO-8601 timestamps, so a Swift-side day in the host zone could disagree with the database boundary.
**Approved**: pending

**Decision**: `dayAfter(_:)` adds a flat 86,400 seconds instead of using a calendar.
**Rationale**: UTC has no daylight-saving shift, so a day is always exactly 86,400 seconds and no calendar object is needed.
**Approved**: pending

**Decision**: `dayAfter(_:)` returns an unparseable input unchanged instead of failing.
**Rationale**: Callers only pass strings this type produced, so the fallback is defensive; it avoids an optional or a throw on a path that should never fail, at the cost that a bad input is silent to the caller.
**Approved**: pending

