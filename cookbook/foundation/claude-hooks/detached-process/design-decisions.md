
**Decision**: A `/bin/sh` trampoline backgrounds the command and exits, instead of spawning the command directly.
**Rationale**: The trampoline's exit reparents the command to launchd, putting it outside the dispatcher's descendant walk so a timeout kill cannot reach it.
**Approved**: pending

**Decision**: The payload travels on descriptor 3, not 0.
**Rationale**: An asynchronous list in a non-interactive shell gets the null device on descriptor 0 unless told otherwise.
**Approved**: pending

**Decision**: Only descriptors 0 to 3 cross into the child.
**Rationale**: A descendant that outlives the dispatcher must not hold open any pipe of the caller's, the dispatcher's stdout among them, or the dispatcher would wait on a pipe that never closes.
**Approved**: pending

**Decision**: The new session is created for the trampoline, so the command is in it too.
**Rationale**: A signal sent to the terminal's process group then misses the command.
**Approved**: pending

**Decision**: The feed lock is a non-blocking `flock` that skips rather than queues.
**Rationale**: Renders arrive faster than feeds finish; the next render carries a newer snapshot, so queueing would only deliver stale ones late.
**Approved**: pending

**Decision**: When no lock file can be made the lock is a no-op that reports success.
**Rationale**: Losing the guard costs duplicate feeds; failing closed would cost the feed itself.
**Approved**: pending

**Decision**: The lock file name carries the daemon name and a sanitised, length-limited session id.
**Rationale**: Daemons and sessions must not contend, and a session id is outside input that must never choose a path.
**Approved**: pending

