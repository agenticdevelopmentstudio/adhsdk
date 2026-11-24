
- **Missing finding**: the daemon answers with a `blocked` target; its `sessionId` is empty and `pid` is 0, so a client MUST NOT try to resolve a pane from it.
- **Resolved finding**: the `blocked` target carries a reason, and an act call returns `succeeded` false. The DTO's documented `status` is the current status, but the HTTP client builds a failed result with an empty `status` and the route's `error` text as `reason`.
- **Session mid-response**: the last event is not `Stop`, so `actionable` is false and `reason` says why.
- **Empty `termSessionId`**: allowed; the client falls back to another way to find the pane, such as resolving the TTY from `pid`.
- **Race at act time**: between injection and the act call the finding may be resolved or removed; the result reports it in `succeeded`, `status` and `reason`.
- **Concurrent access**: both types are immutable `Sendable` values; whether two clients can race to act on one finding is decided by the daemon's status transition, outside these sources.
- **Error and offline states**: no I/O here; an unreachable daemon is the caller's failure, and the shapes carry only a refusal, never a transport error.
- **Boundary values**: `findingId` and `pid` are unbounded `Int`s here; `pid` 0 is the placeholder of a `blocked` target.

