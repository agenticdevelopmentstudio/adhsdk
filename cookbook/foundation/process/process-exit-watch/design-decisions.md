
**Decision**: The exit is learned from a termination handler installed before launch, not from the blocking wait-until-exit call.
**Rationale**: Per the source comment, on macOS 26.6 the blocking call can miss its wake-up for a child that exits within milliseconds (about 1 in 5 against `/usr/bin/true`) and park its thread forever, while the handler never missed in 500 runs where the blocking call missed 89. One miss froze every later account switch behind a credential round.
**Approved**: pending

**Decision**: The watch is created before `run()`, and the initialiser traps with a precondition if the process is already running.
**Rationale**: A handler installed after launch can be installed after the exit it was meant to catch, so the caller error is made loud instead of a silent hang.
**Approved**: pending

**Decision**: `stop(_:)` has two steps: SIGTERM, then SIGKILL after a 2-second grace, each with its own wait.
**Rationale**: Per the source comment, a tool that ignores SIGTERM is exactly the tool a timeout exists for, so there has to be a second step; two seconds is long enough for an honest cleanup handler and short enough that nobody notices.
**Approved**: pending

**Decision**: `stop(_:)` returns false instead of throwing when the process is still there after both graces.
**Rationale**: Per the source comment, this is real: a process in an uninterruptible kernel wait neither dies nor reaps, and the caller must then not read `terminationStatus`. The caller owns the decision on what to do.
**Approved**: pending

**Decision**: The class is `@unchecked Sendable` with a lock around the exit flag.
**Rationale**: The semaphore and lock are thread-safe, and the one mutable field is guarded; the compiler cannot see that, so the conformance is stated by hand.
**Approved**: pending

**Decision**: The type reports only whether the exit arrived, not its status.
**Rationale**: The caller already holds the `Process` and reads `terminationStatus` from it after a true result; `CommandRunner` is the whole-output form that does this.
**Approved**: pending

