
- **Null and empty input**: There is no optional input. `drainedAt` is nil before the first reservation and is treated as the current time, so the first call is paced only by its own cost beyond the burst allowance. This MUST hold.
- **Zero units**: A reservation of 0 units adds nothing to the backlog and returns the wait the existing backlog implies, or `.zero` when there is none. This MUST hold.
- **Negative units**: The sign of `units` is never validated; a negative value moves `drainedAt` earlier and returns a reduced wait. This is what the code does, and the open question on `units-nonnegative` records it.
- **Boundary at the burst allowance**: Reservations that total exactly `burstUnits` still return `.zero`; the first unit past it returns a positive wait. This MUST hold.
- **Zero burst**: `burstUnits` of 0 is valid and makes even the first call wait its own cost divided by the rate. This MUST hold.
- **Invalid configuration**: A rate of 0 or below, or a negative burst, traps in the initializer through `precondition`. A `NaN` for either value also traps, because the comparisons are false. A release build compiled with unchecked optimisation removes the check. This is what the code does.
- **Unbounded configuration**: A burst or rate that makes a duration exceed the range of `Int64` nanoseconds (about 9.2 billion seconds, which includes an infinite burst) passes the precondition and then traps in the conversion to `Duration`. The source does not guard this; callers pass finite constants.
- **Very large rate**: An infinite `unitsPerSecond` passes the precondition, makes every cost zero seconds, and so turns pacing off. This is what the code does.
- **Clock moves backward**: With an injected clock that returns an earlier instant than before, `drainedAt` stays ahead of the current time, so the backlog is longer than real time implies. The default `ContinuousClock` never moves backward.
- **Clock moves forward**: Time passing drains the backlog, and once the clock passes `drainedAt` the backlog is gone and no credit beyond the burst allowance remains. This MUST hold.
- **Concurrent access**: Calls arriving together from many tasks are serialised by the actor; each sees the `drainedAt` left by the one before. This MUST hold. The pacer does not decide who is first.
- **Cancellation**: The pacer cannot be cancelled mid-call because `reserve(_:)` is synchronous inside the actor. A caller cancelled while it sleeps out the returned wait keeps its reservation, so quota is over-counted rather than exceeded.
- **Failed or retried requests**: The pacer cannot tell a failed request from a successful one. `GmailRESTClient` reserves once per attempt, so each retry after a 429, a 5xx or a transient network error reserves its cost again.
- **Error states, network and offline**: Not applicable: the pacer performs no I/O and has no dependency that can fail; it raises no errors and returns a `Duration` on every call.
- **Other processes and other clients**: The pacer paces only its own process. Other processes, devices or Google clients sharing the same account quota are not seen; the 200-unit shared rate leaves headroom for them but cannot guarantee it.
- **Server-side enforcement**: Whether Google applies the quota exactly as described is outside this source. A call that still exceeds the quota is answered with 429 or a rate-limit 403, which `GmailRESTClient` handles by backoff and retry.

