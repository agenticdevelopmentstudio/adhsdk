
- **Unknown string**: A string outside the three raw values MUST fail to convert, yielding `nil` from `init(rawValue:)`. The sessions table's `CHECK` constraint keeps the column to the three values, so the case arises from external input such as the `status` query parameter of the session list route, where an unrecognized value becomes `nil` and the list is returned unfiltered. The enum has no fallback case, so the caller owns the handling.
- **Empty string**: `SessionStatus(rawValue: "")` MUST yield `nil`.
- **Case variants**: `"Active"` and `"ENDED"` MUST yield `nil`; the raw values are lowercase and the match is exact.
- **Stale in the SDK's own writes**: No SDK daemon code sets `stale`, so a port MAY omit a transition into it, but MUST keep the case so rows and payloads from other writers still convert (`stale-declared`).
- **Concurrent access**: Not applicable: the enum is an immutable `Sendable` value with no state of its own; ordering of writes to the status column belongs to the database layer.
- **Boundary values, errors, offline**: Not applicable: the enum has no numeric inputs, throws nothing and does no I/O.

