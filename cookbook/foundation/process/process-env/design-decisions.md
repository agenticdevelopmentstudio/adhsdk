
**Decision**: The token is read from the parent `claude` process's launch environment, not from the hook's own environment.
**Rationale**: The doc comment on `oauthTokenWalkingUp(from:maxHops:)` in `ProcessEnv.swift` and the type's overview comment say Claude Code scrubs the token from the environment it gives hook and status-line commands, but the process itself still carries it and a same-user read is allowed (as `ps eww` shows).
**Approved**: pending

**Decision**: The walk caches results, including "nothing found", for 30 seconds per start pid.
**Rationale**: The daemon calls per event, and each call would otherwise walk the process table with several kernel calls per hop.
**Approved**: pending

**Decision**: The cache is capped at 128 entries, evicted inline on insert: stale entries first, then all but the newest 128.
**Rationale**: The doc comment on the `cache` property in `ProcessEnv.swift` explains that a time limit checked only on read never frees an entry nobody reads again, and hook pids are short-lived and never looked up twice, so the dictionary would grow over weeks of daemon uptime while holding a token per entry. An evicted entry costs one walk to rebuild; an unevictable one costs a token held forever.
**Approved**: pending

**Decision**: `claudePid(aboveHookParent:)` checks names rather than trusting the parent's position.
**Rationale**: The doc comment on `claudePid(aboveHookParent:)` says a wrong pid would aim a text injection at someone else's terminal, while nil only leaves the session's pid unknown. The accepted shapes are the native install (name `claude`, found through argument 0 even though the executable is a version number) and the npm install (`node`).
**Approved**: pending

**Decision**: `processNames` returns the basenames of both the executable and argument 0.
**Rationale**: Neither alone names `claude` in both installs, as the doc comment on `processNames(of:)` explains.
**Approved**: pending

**Decision**: The boundary form of the walk is uncached and stops short of the boundary.
**Rationale**: A process's environment is its launch-time one, so a caller that has just changed the token in an ancestor shell sees that shell and everything above it still showing the older token; only a process started below it can show a new one. Such a caller asks once per run, so there is nothing to cache (doc comment on `oauthTokenWalkingUp(from:below:maxHops:)`).
**Approved**: pending

**Decision**: Short names (`i`, `s`, `eq`, `pp`) are kept in the launch-data parser.
**Rationale**: The comments in the launch-data parser in `ProcessEnv.swift` say they mirror the standard `KERN_PROCARGS2` parsing idiom and renaming them would make the byte-offset walk harder to check by eye.
**Approved**: pending

**Decision**: The cache is keyed by pid alone, with no process start time, and the pid-reuse risk is accepted.
**Rationale**: Hook pids are short-lived and a reused pid within 30 seconds would return the earlier process's token, which hands a credential to the wrong process. The accepted risk is bounded by the 30-second lifetime and the same-user read rule; revisit by keying on (pid, process start time) if a caller ever uses the token across users or for anything beyond identifying its own session.
**Approved**: pending
