
- **Null / empty input**: Empty strings are accepted for every string field; `supersededBy` may be empty (the default); `summary` and `skipReason` are nil until something sets them. The type validates nothing.
- **Boundary values**: `supersededBy` may hold any number of SHAs and keeps their order; a review may name itself or an unknown SHA, because the type does not check.
- **Concurrent access**: Both structs are `Sendable` values; copies are independent. Which writer wins when two update the same review is decided by the store that holds the reviews, not by this type.
- **Error states**: Decoding a missing required key, a wrong-typed value or an unknown state raises a decoding error, as **required-keys** requires; encoding cannot fail for these field types.
- **Offline / disconnected state**: Not applicable: the type is data and performs no network access.
- **Cancellation**: Not applicable: the type has no asynchronous operation.
- **Inconsistent combinations**: A `skipped` review with no `skipReason`, a `done` review with no `summary` and a `running` review with no `startedAt` are all representable; consumers MUST handle the optional fields as possibly nil in every state.

