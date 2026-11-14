
- **Finish before any waiter**: `finish` on a box with no waiters MUST settle it and return `true`; a later `value()` returns the stored outcome (`value-after-settle`).
- **Finish with a `CancellationError`**: The box stores whatever `Error` it is given and does not interpret it; callers map cancellation to their own error before calling `finish` (`withSignInDeadline` does). The box MUST NOT rewrite the error.
- **Two finishes at the same instant**: Exactly one MUST win; the lock serialises them, and lock order alone decides which. The loser MUST get `false`.
- **Waiter added while `finish` is resuming others**: A `value()` call that takes the lock after the winner stored the result MUST see the result and resume itself; one that took it before is in the list the winner resumes. Neither MUST be resumed twice or missed (`value-register-atomic`).
- **Box never settled**: `value()` stays suspended. The box has no timeout, no deinit hook and no cancellation path, so a waiter on a box nobody finishes is never released. This is a fact of the source, not a gap: every caller in the repo pairs the box with a timer.
- **Dropped box with waiters**: A suspended `value()` call is a method running on the box, so it keeps the box alive; a box with waiters cannot be released by its other owners going away. It stays suspended until some `finish` wins, as in the never-settled case.
- **Payload copies**: `T` is stored once and handed to every waiter by value through `Result`; `T: Sendable` is the only constraint, so a large value type is copied per waiter.
- **Null and empty input**: `Result<T, Error>` has no empty form; `T` MAY itself be `Void` (the stop path uses `RaceBox<Void>`). An empty waiter list is the normal case for `finish` and MUST be accepted.
- **Boundary values**: Not applicable: the box has no size, count or time parameter.
- **Concurrent access**: Covered by `cross-task-use` and `winner-decided-atomically`; every read and write of `result` and `waiters` is inside `lock.withLock`.
- **Error states and offline state**: Not applicable: the box calls no network, file or other dependency; the only errors it carries are the ones passed to `finish`.

