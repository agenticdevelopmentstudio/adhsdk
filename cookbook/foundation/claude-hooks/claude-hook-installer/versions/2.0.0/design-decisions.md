
**Decision**: Hooks are `command` entries that run a helper which writes a drop file and always exits 0, rather than `http` hooks.
**Rationale**: An `http` hook that cannot connect is an error in every Claude session and a lost event; a drop file needs no running daemon and a stopped daemon ingests it on its next start.
**Approved**: pending

**Decision**: Delegation and non-hook event types are excluded and scrubbed on every install.
**Rationale**: Hooks under delegation types make owning tools fail, and hooks under `StatusLine` raise an unknown-event warning; earlier versions registered them, so installs actively remove them.
**Approved**: pending

**Decision**: Registrations are identified by a marker and compared against the exact current rendering, and anything else of this owner's is rewritten.
**Rationale**: Several daemons share one file, so each touches only its own entries; comparing the whole command also detects a moved bundle without a version bump, and additive registration needs no marker change for a new event type.
**Approved**: pending

**Decision**: The helper must be runnable before any hook is written, otherwise install leaves the file alone.
**Rationale**: A hook pointing at a missing helper fails silently behind `exit 0` and capture stops with no error anywhere.
**Approved**: pending

**Decision**: Two locks are taken in a fixed order, the shared `.settings.lock` first, and acquisition times out.
**Rationale**: The shared lock is the contract other tools follow, the own lock keeps older builds out, a fixed order prevents deadlock, and a bounded wait stops the daemon hanging on a stopped holder.
**Approved**: pending

**Decision**: Another tool's `statusLine` command is adopted as a renderer instead of replaced, and uninstall hands the slot back by rule.
**Rationale**: The slot holds one command; the dispatcher lets several tools share it, so no tool refuses or wraps another's command and a leaving tool never strands the slot.
**Approved**: pending

**Decision**: A status-line failure never fails the install, and the status line step runs after the legacy scrub and before hook registration.
**Rationale**: Losing the line is cheaper than losing event capture; turning the display on reports the reason by throwing.
**Approved**: pending

**Decision**: The router pointer is compared by exact string equality with `routerBaseURL`, and any other value, including a non-object `env`, is never overwritten or removed; enabling over it throws a conflict carrying only a redacted display form.
**Rationale**: `ANTHROPIC_BASE_URL` may belong to the user or another proxy, so only a value this router wrote is treated as its own; the display form drops userinfo and path because the value can carry credentials.
**Approved**: pending

**Decision**: Suspension is a marker file beside `settings.json`, written before the pointer is removed and deleted only after a resume's save, and any explicit `setRouterPointer` call forgets it.
**Rationale**: While the router's daemon is down Claude Code must reach Anthropic directly rather than fail every request; the write order means a failed save never loses the record of a suspension, and the user's own choice must not be undone by a later resume.
**Approved**: pending

**Decision**: Turning tracking off (`uninstallHooks()`) keeps the router pointer; only `uninstallHooks(removingRouterPointer: true)`, used when removing the router's owner, takes it out.
**Rationale**: The router does not depend on tracking, and removing the pointer with the hooks would make Claude Code silently stop going through the router.
**Approved**: pending

