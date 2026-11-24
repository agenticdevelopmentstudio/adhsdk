
**Decision**: A daemon builds one configuration and hands it to the shared runtime; the shared code spells no daemon name or directory.
**Rationale**: The doc comment on `SessionDaemonConfiguration` in `SessionDaemonConfiguration.swift` says so directly ("nothing in the shared code spells a daemon's name or directory itself"). It lets several daemons share one runtime while each keeps its own paths, hook marker and identity.
**Approved**: pending

**Decision**: `summariesDefaultEnabled` has no default.
**Rationale**: The doc comment on `summariesDefaultEnabled` in `SessionDaemonConfiguration.swift` says every daemon states its own: a daemon that must not double LLM spend over sessions another daemon already summarizes passes `false`. A default would let that mistake happen by omission.
**Approved**: pending

**Decision**: Paths and the subsystem are derived from other arguments when the caller passes `nil`, and the initializer stores them as plain values.
**Rationale**: Most daemons want `sessions.db`, `ingest.db` and `errors` in the usual places and a subsystem equal to the label, while still allowing overrides. The cost is that later edits to `supportDirectory` or `label` do not move the derived values.
**Approved**: pending

**Decision**: No argument is validated and the initializer creates nothing on disk.
**Rationale**: The value is cheap and side-effect free; the runtime creates `supportDirectory` when it opens. The cost is that a bad path or interval fails at the point of use instead of at construction.
**Approved**: pending

**Decision**: `test(port:root:)` roots every path, and the hook's `settings.json`, in one directory.
**Rationale**: The doc comment on `test(port:root:)` in `SessionDaemonConfiguration.swift` says a test must never touch the real Claude Code settings. It also uses port 0 so parallel tests do not collide, a 1-second liveness interval so tests do not wait, and `summariesDefaultEnabled` of `false`.
**Approved**: pending

**Decision**: `httpPort`, `label`, `retentionDays` and the two intervals are carried for the host daemon and are not depended on by the shared runtime.
**Rationale**: The host daemon owns the listener, the launchd registration and the timers; the shared struct exists so one value describes the whole daemon.
**Approved**: pending

