
**Decision**: The exit is learned from a termination handler installed before launch, not from the blocking wait-until-exit call.
**Rationale**: See the Overview for the macOS 26.6 lost wake-up and its figures. As a past incident, one miss held a credential round open for good and froze every later account switch behind it.
**Approved**: pending

**Decision**: The watch is created before `run()`, and the initialiser traps with a precondition if the process is already running.
**Rationale**: A handler installed after launch can be installed after the exit it was meant to catch, so the caller error is made loud instead of a silent hang.
**Approved**: pending

**Decision**: `stop(_:)` has two steps: SIGTERM, then SIGKILL after a 2-second grace, each with its own wait.
**Rationale**: The doc comment on `terminationGrace` says a tool that ignores SIGTERM is exactly the tool a timeout exists for, so there has to be a second step; two seconds is long enough for an honest cleanup handler and short enough that nobody notices.
**Approved**: pending

**Decision**: `stop(_:)` returns false instead of throwing when the process is still there after both graces.
**Rationale**: The doc comment on `stop(_:)` says this is real: a process in an uninterruptible kernel wait neither dies nor reaps, and the caller must then not read `terminationStatus`. The caller owns the decision on what to do.
**Approved**: pending

**Decision**: The class is `@unchecked Sendable` with a lock around the exit flag.
**Rationale**: The semaphore and lock are thread-safe, and the one mutable field is guarded; the compiler cannot see that, so the conformance is stated by hand.
**Approved**: pending

**Decision**: The type reports only whether the exit arrived, not its status.
**Rationale**: The caller already holds the `Process` and reads `terminationStatus` from it after a true result; `CommandRunner` is the whole-output form that does this.
**Approved**: pending

**Decision**: Creating the watch replaces any termination handler already on the process.
**Rationale**: A `Process` has one termination handler slot, and the watch's guarantee that the exit signal arrives depends on owning it; chaining or failing on a set handler would add a second path for the exit to be lost. A caller that needs its own handler composes it after the watch reports the exit.
**Approved**: pending

**Decision**: `stop(_:)` takes the `Process` as an argument even though the watch was built for one.
**Rationale**: The watch does not store the process, so it needs one to signal; the shape is kept as the source has it, and passing a different process is undefined (`stop-same-process`). A parameterless `stop()` is the cleaner shape for a port that stores the process.
**Approved**: pending
