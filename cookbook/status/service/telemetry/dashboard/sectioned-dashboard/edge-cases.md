
- **Empty or missing input**: `sections` is a list of names; with an empty list nothing is ever due, so `read` returns `{ refreshing: false, sections: {} }`. This is not exercised by a test; it follows from the due filter.
- **Unknown key**: Any `K` value creates state on first read. The type `K extends string` bounds the set at compile time only; a caller outside the type system can grow the map without limit. Callers MUST use a bounded enum, as the source comment says.
- **Failure before any success**: A section that has never loaded and fails keeps `data` `null` with `error` set and `updatedAt` `null`.
- **Repeated failures**: The wait doubles each time and is capped at `ttlMs`; after a success the count resets to 0.
- **Backoff exponent**: `2 ** (failures - 1)` grows without bound in the exponent but the result is capped by `Math.min` with `ttlMs`, so a long failure run cannot overflow the interval.
- **Incomplete answer repeated**: A section that keeps coming back incomplete is retried on the backoff schedule. Its `data` is replaced each time since each attempt publishes as a success.
- **`concurrency` of 0 or less**: `mapLimit` starts no workers, so no loader runs and the refresh ends at once. The `finally` step then marks every due section as a failure, so each is retried after the backoff and no section ever loads. The source does not validate `concurrency`. The caller owns passing a positive value; the callers in the dashboard set pass none or rely on the default of 1.
- **Loader not a function**: Calling `loaders[name]()` on a missing entry throws a `TypeError`, which the per-section handler catches as a failure of that section. Not exercised by a test.
- **Loader that never settles**: The refresh never ends, `refreshing` stays true, and later reads never start another refresh for that key. The source has no per-loader timeout; loaders own their own deadlines (the PostHog and Vercel loaders use provider cooldowns and HTTP failure handling in their own modules). `settle` still returns `false` at its deadline.
- **Loaders builder throws**: Covered by `loaders-builder-throws`. Also, because the failure is logged by the outer `catch`, no section-level `console.warn` appears.
- **Concurrent reads**: Reads are synchronous and JavaScript is single-threaded, so only one read at a time checks and starts a refresh. A second read during a refresh returns the current partial state.
- **Concurrent settle calls**: Several `settle` calls on one key MAY wait on the same in-flight promise; each has its own timer, cleared on return.
- **Settle after the refresh ended but before cleanup**: `settle` returns `!state.refreshing`, which is `true` once the refresh's `finally` step has run.
- **Offline or provider unavailable**: The module has no network code. An unreachable provider shows as a rejecting loader, handled by failure-keeps-data and backoff.
- **Process restart**: State is in memory only, so a restart makes every section cold again and the first read refreshes all of them.
- **Clock moves backwards**: `dueAt` is compared with `now()`, so a clock set back delays the next refresh; the module does not guard against it. Not exercised by a test.

