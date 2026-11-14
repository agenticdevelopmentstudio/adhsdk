
**Decision**: Day strings are produced with a fixed `UTC` time zone, never the host's current zone.
**Rationale**: Days are bucketed with `substr(timestamp, 1, 10)` on stored UTC ISO-8601 timestamps, so a Swift-side day in the host zone could disagree with the database boundary.
**Approved**: pending

**Decision**: `string(from:)` and `dayAfter(_:)` delegate day formatting and parsing to the shared UTC timestamp ingredient, with the UTC zone.
**Rationale**: One owner of the civil-date arithmetic keeps the output equal to the day prefix of a wire instant.
**Approved**: pending

**Decision**: `dayAfter(_:)` adds a flat 86,400 seconds instead of using a calendar.
**Rationale**: UTC has no daylight-saving shift, so a day is always exactly 86,400 seconds and no calendar object is needed. The result cannot be told apart from calendar arithmetic, so this is a design choice and not a requirement.
**Approved**: pending

**Decision**: `dayAfter(_:)` returns an unparseable input unchanged instead of failing.
**Rationale**: The source's doc comment calls the fallback defensive, since callers only pass strings this type produced; it avoids an optional or a throw on a path that should never fail, at the cost that a bad input is silent to the caller.
**Approved**: pending

