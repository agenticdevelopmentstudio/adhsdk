
**Decision**: The http build drops an event whose `cwd` equals the daemon's own working directory before it reads any process environment.
**Rationale**: The comment on the http `build` overload explains that the headless `claude` a daemon spawns inherits the daemon's directory and never sets its own; the `ADH_SDK_HEADLESS` marker is only recoverable while that short-lived process is alive, so relying on it alone races the summarizer's exit and lets a phantom session in. The working-directory match does not depend on timing.
**Approved**: pending

**Decision**: `daemonWorkingDirectory` is read once, lazily.
**Rationale**: A daemon changes into its support directory early in start-up, before the first read, so the first read captures the directory the headless child will inherit. A later change of directory would not be reflected.
**Approved**: pending

**Decision**: A recovered `claude` pid stands in for `ppid` on the http path.
**Rationale**: An http hook carries no `$PPID`; the located pid is Claude's own, which is what the socket path's `ppid` is.
**Approved**: pending

**Decision**: The cache lives for three seconds and caches failures.
**Rationale**: A status-line post arrives on every render, many times per second per session; without a cache each would scan the whole process table. Three seconds collapses a burst to one scan while a mid-window account switch still self-heals within one window; caching the empty result stops a transient read failure from re-scanning each render.
**Approved**: pending

**Decision**: Resolution on a cache miss runs outside the lock.
**Rationale**: Holding the lock during a process-table scan would serialise every hook post; the cost is occasional duplicate scans for one key. The source documents the lock but not this trade-off, so it is recorded here.
**Approved**: pending

**Decision**: `context.process` omits `argv`, `cwd` and `pid` relative to the capture command's envelope.
**Rationale**: The comment in `buildContext` says the hook-firing process has exited by ingest time and a hook script's argv is only its name and the event, which is already top-level; `cwd` is omitted without a stated reason. Other divergences from `HookCaptureCommand` are boolean parsing through `RawSetting.bool` (broader than `1` and `true`), the `session_id` requirement, the daemon-directory check, and the order of token sources (the forwarded environment first here; the process walk first in the capture command).
**Approved**: pending

**Decision**: Account lookups are injected and default to the empty string.
**Rationale**: The toolkit core has no account store; the empty string is the documented "no answer" value, and the caller supplies the real lookups.
**Approved**: pending

**Decision**: The full build requires a `session_id` and rejects events without one.
**Rationale**: The doc comment states it returns nil when a required field is missing, currently the session id; a later session upsert needs it. The source discards the value after checking it.
**Approved**: pending

**Decision**: Remove the unused `event` parameter of `buildContext`.
**Rationale**: The parameter has no effect on the result today; keeping it is dead surface, and removing it is a source cleanup, not a behavior ports must copy.
**Approved**: pending

**Decision**: Accept that a pid reused by another process inside the three-second window returns the earlier process's environment, or key the cache by pid plus process start time.
**Rationale**: The source documents the account-switch case but says nothing about pid reuse; a reused pid could attribute an event to the wrong account for up to one window, so this is recorded as an open choice.
**Approved**: pending
