
- **Null and empty input**: A pid with no readable launch data MUST give nil (or an empty name set). An environment entry with no `=` or with an empty body MUST be dropped. An empty-valued token MUST be treated as absent.
- **Boundary values**: Pid 1 or lower MUST end a walk, and `claudePid(aboveHookParent:)` MUST reject a settled pid of 1 or lower. `maxHops` of 0 MUST test no process (`token-walk-bounds`). The cache MUST allow exactly 128 entries without eviction and MUST evict only once it holds more.
- **Concurrent access**: The cache MUST be lock-protected; two threads may walk the same pid at once and each store a result, with the last store winning, since the lock is released during the walk. Both results are the same unless the process table changed between the walks.
- **Error states**: A failed kernel call MUST give nil (no error is thrown or logged). A walk that cannot read a process's environment MUST go on to its parent when it can.
- **Truncated or malformed launch data**: Parsing MUST stop at the end of the buffer without reading past it; arguments fewer than the recorded count are returned as found.
- **Stale data**: The environment is the launch-time snapshot. A token changed in the running process after launch is not seen. A cached entry older than 30 seconds MUST NOT be used, but it is removed only when an insert pushes the cache over 128 entries; an unread entry can stay in memory past 30 seconds while the cache is under its ceiling.
- **Pid reuse**: Entries are keyed by pid with no process start time, so within 30 seconds a reused pid answers with the earlier process's result.
- **Offline or disconnected state**: Not applicable — this type reads local kernel data only and does no network access.

