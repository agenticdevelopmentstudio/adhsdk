
### Construction and shape

- **generic-sendable-payload**: `RaceBox` MUST be generic over a payload type `T` that conforms to `Sendable`.
- **no-arguments-init**: `RaceBox` MUST be constructible with `init()` and no arguments, and a new box MUST be unsettled with no waiters.
- **cross-task-use**: `RaceBox` MUST be safe to call from any number of tasks and threads at once; the source declares this with `@unchecked Sendable` and backs it with one `NSLock`.

### finish

- **finish-signature**: `finish(_ outcome: Result<T, Error>)` MUST take the outcome as a `Result` (a value or an `Error`) and MUST return a `Bool`; the result is `@discardableResult`.
- **first-finish-wins**: The first call to `finish` on an unsettled box MUST store its outcome and MUST return `true`.
- **later-finish-ignored**: A call to `finish` on a box that is already settled MUST return `false` and MUST NOT change the stored outcome.
- **winner-decided-atomically**: The check "is the box settled" and the store of the outcome MUST happen under the same lock acquisition, so exactly one of any set of concurrent `finish` calls returns `true`.
- **failure-is-an-outcome**: `finish(.failure(error))` MUST settle the box the same way a success does; a failure counts as the winning call.
- **release-all-waiters**: The winning `finish` MUST resume every waiter that was suspended in `value()` with the winning outcome, in the order they were added.
- **waiters-cleared**: The winning `finish` MUST empty the waiter list when it settles the box, so no continuation is resumed twice.
- **resume-outside-lock**: The winning `finish` MUST resume waiters after the lock is released, so a resumed continuation can call back into the box without deadlocking.
- **loser-resumes-nothing**: A losing `finish` MUST NOT resume any waiter.

### isFinished

- **is-finished-flag**: `isFinished` MUST return `false` on an unsettled box and `true` once any `finish` has won, and it MUST read the state under the lock.

### value

- **value-signature**: `value()` MUST be `async throws` and MUST return `T`.
- **value-after-settle**: When the box is already settled, `value()` MUST return the stored success value at once, or throw the stored error, without suspending on the waiter list.
- **value-waits**: When the box is unsettled, `value()` MUST suspend until a `finish` wins.
- **value-delivers-outcome**: A waiter MUST receive the winning outcome: the value for `.success`, the thrown `Error` for `.failure`.
- **value-register-atomic**: `value()` MUST read the stored result and append its continuation under the same lock acquisition, so a `finish` that wins at the same moment can neither be missed nor resume the continuation twice.
- **value-many-callers**: Any number of callers MAY call `value()` on one box, before or after it settles; every one MUST get the same outcome.
- **value-repeatable**: A call to `value()` after the box has settled MUST return the same outcome each time; the outcome is not consumed.

### Lifetime and cancellation

- **one-shot**: A settled box MUST stay settled; there is no reset, and the outcome never changes.
- **losers-not-awaited**: The box MUST NOT wait for, track or cancel the tasks that lose the race; releasing waiters depends only on a winning `finish`.
- **value-not-cancellable**: `value()` itself MUST NOT react to cancellation of the calling task; the source registers a checked continuation and nothing else, so a caller that wants cancellation to end the wait must race a `finish` of its own (as `withSignInDeadline` does with `withTaskCancellationHandler`).
- **never-settled-never-returns**: If no `finish` is ever called, `value()` suspends for as long as the box lives. The box has no timeout of its own; the owner supplies one by racing a timer.

