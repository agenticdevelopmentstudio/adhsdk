
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
