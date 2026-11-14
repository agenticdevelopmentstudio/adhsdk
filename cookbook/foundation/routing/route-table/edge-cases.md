
- **Null / empty input**: An empty table MUST return `nil` for every request. A table of only declining handlers MUST return `nil`. An `exact` handler built with an empty component list matches only a request whose `pathComponents` are empty, such as path `/` (derived; no test beside the source).
- **Boundary values**: A request path with extra, fewer or reordered segments than the `exact` components MUST be declined (test: exactClaimsOnlyItsMethodAndPath covers extra segments and the empty path). Two tables merged repeatedly keep every handler in order, with no deduplication.
- **Overlapping handlers**: When two handlers could both claim a request, the earlier one wins and the later one is never reached; ordering is the only precedence rule.
- **Malformed input**: The table does not validate the request; a malformed path is just its split components, and an `exact` handler claims it only if those components equal its own exactly.
- **Concurrent access**: `RouteTable` is `Sendable` with an immutable handler array and `@Sendable` handlers, so one table can serve requests concurrently from many tasks. Within one `handle` call the handlers run sequentially. Whether a handler's own shared state is safe is that handler's responsibility, not the table's.
- **Handler failure**: A handler cannot throw (its type is not `throws`), so the table has no failure path; a handler that traps takes the process with it. What a daemon does when `handle` returns `nil` (usually a 404) is outside this code.
- **Offline / disconnected state**: Not applicable: the table performs no network access; the daemon's HTTP layer owns transport.
- **Cancellation and timeouts**: The table adds no timeout and does not check for cancellation itself; `handle` is `async`, so cancellation of the calling task reaches a handler only if that handler checks it.

