
**Decision**: The command swallows every failure and always returns 0 with no output.
**Rationale**: The source contains no print, log or stderr call, and the comment on the write says stderr from a hook can confuse Claude Code and that the next event brings the same information; the type comment states the contract as "never fail, never produce stdout". The cost is that a failed write leaves no trace.
**Approved**: pending

**Decision**: The headless check lives in this command as well as in the shell hook and the socket path.
**Rationale**: The source comment explains that guarding here means a headless drop file is never written even when the command is invoked directly or the daemon was down, so none can be quarantined and replayed into a phantom session.
**Approved**: pending

**Decision**: `oauth_account_email` is resolved when the hook fires.
**Rationale**: A drop file can sit in the directory through an update, a migration, a reboot or a stopped daemon; the sessions upsert keeps the first OAuth stamp, so resolving at drain time would bill the whole backlog to whoever is logged in then.
**Approved**: pending

**Decision**: The OAuth token is recovered by walking up the process tree rather than read from the environment.
**Rationale**: Claude Code scrubs `CLAUDE_CODE_OAUTH_TOKEN` from the environment it hands hook commands; the environment value is kept only as a fallback when the walk fails.
**Approved**: pending

**Decision**: Claude's pid is found by an injected closure when `--ppid` is absent.
**Rationale**: The registered command does not pass `--ppid`; the closure defaults to `ProcessEnv.claudePid(aboveHookParent:)`, which looks at the hook's parent (skipping one shell) and accepts it only by process name, and tests inject it to avoid depending on the real process tree.
**Approved**: pending

**Decision**: `buildEnvelope` is public and pure over the supplied environment and stdin for `hook_data`, while `context` is still captured from the live process.
**Rationale**: The type comment says this keeps the headless-drop and `term_session_id` behavior unit-testable without mutating the process environment or redirecting stdin. The consequence is that the supplied environment does not drive the `context` groups, so a test cannot control them.
**Approved**: pending

**Decision**: Wire compatibility with the version 4 envelope is preserved by lifting `term_program` onto `hook_data` and by giving `SessionStart` a `pid`.
**Rationale**: The source comment names this "v4 wire-compat"; the value is 0 when Claude's pid is unknown so the key is always present for that event.
**Approved**: pending

**Decision**: Divergences from `HookEnvelopeBuilder`, the socket-path twin, are intentional or inherited and are recorded here: this command does not require a `session_id`; it checks headless by environment only (the builder also checks the daemon's working directory); it treats only `1` and `true` as true for `CLAUDECODE` and `CLAUDE_YOLO` where the builder uses `RawSetting.bool`, which also accepts `yes` and `on` and the false words; it includes `argv`, `cwd` and `pid` in `context.process` where the builder omits them; and it walks for the token before using the environment value where the builder prefers the forwarded environment value.
**Rationale**: The two builders are described in their own comments as producing the same context shape, and the differences follow from where each runs (a short-lived hook process versus a daemon). A port MUST pick one behavior per side deliberately.
**Approved**: pending

**Decision**: The drop file is written with the file system's default permissions, not owner-only.
**Rationale**: The envelope holds the OAuth login email, `PATH`, `HOME`, `argv` and user ids, so owner-only permissions (0600 on the file, 0700 on the directory) may be warranted; the source sets none today and this is recorded as an open choice.
**Approved**: pending
