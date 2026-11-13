
**Decision**: First `finish` wins and later calls are ignored, and `finish` returns whether the caller won.
**Rationale**: The callers use the return value to decide who runs the cleanup: the timer in `withSignInDeadline` calls `cancel()` and cancels the work only if its `finish` won, and the cancellation handler does the same. A port MUST keep the winner signal, not only the first-wins rule.
**Approved**: pending

**Decision**: A box is used instead of a task group.
**Rationale**: The source comment says so: a task group waits for all its children, so a hung child would hold up the caller. The box releases waiters when it settles and does not wait for the losing tasks.
**Approved**: pending

**Decision**: `value()` registers the waiter and checks the stored result under one lock, and `finish` resumes waiters after the lock is released.
**Rationale**: This closes the window between "not settled yet" and "waiting" so a concurrent settle cannot be missed, and it keeps continuations from running while the lock is held. Both are required to avoid a hang and a deadlock.
**Approved**: pending

**Decision**: The class is `@unchecked Sendable` with a hand-written `NSLock`.
**Rationale**: The compiler cannot verify a mutable class, so the type asserts its own safety; every access to `result` and `waiters` goes through the lock. A port with a built-in settle-once primitive does not need this.
**Approved**: pending

**Decision**: `value()` does not respond to cancellation of the caller.
**Rationale**: Cancellation is the caller's job, so the sign-in race wires it to `finish` through `withTaskCancellationHandler`. This keeps the box a pure race cell with no knowledge of tasks.
**Approved**: pending

**Decision**: There is no test file for `RaceBox`.
**Rationale**: None is given in the source. It is covered indirectly by the deadline tests in `GoogleOAuthTests.swift` and the stop-bound test in `MailIntegrationServiceTests.swift`, and the compliance table records the gap under unit-test-coverage.
**Approved**: pending

**Decision**: The recipe marks nothing as an open question.
**Rationale**: The one hazard, a box that is never finished leaving its waiters suspended, is a declared absence of a timeout and every caller supplies a timer, so it is stated as a fact.
**Approved**: pending

