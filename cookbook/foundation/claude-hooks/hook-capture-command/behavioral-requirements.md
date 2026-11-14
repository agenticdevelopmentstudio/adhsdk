
### Entry point and exit status

- **exit-status-zero**: `run` MUST return 0 on every path: a missing event flag, a tracked-out event, a malformed payload and a failed drop-file write alike.
- **event-flag-required**: `run` MUST write nothing and return 0 when the arguments carry no `--event` value or an empty one.
- **no-stdout**: The command MUST NOT write to standard output or standard error.
- **write-failure-swallowed**: `run` MUST swallow any error thrown while writing the drop file and still return 0.
- **flag-parsing**: The argument parser MUST accept only `--key value` pairs, where a value is the next argument and does not begin with `--`; positional arguments and `--key=value` forms are ignored.
- **duplicate-flag-last-wins**: When the same `--key` appears more than once, the argument parser MUST keep the later value.
- **ppid-flag-optional**: `--ppid` MAY be omitted; the registered command does not pass it.

### Envelope content

- **headless-not-tracked**: `buildEnvelope` MUST return nil, so that no drop file is written, when the supplied environment contains the key `ADH_SDK_HEADLESS` with any value, including an empty one.
- **envelope-keys**: A built envelope MUST contain the keys `event`, `timestamp`, `hook_data`, `context`, `account_email` and `oauth_account_email`.
- **event-verbatim**: The `event` value MUST be the `--event` string unchanged.
- **timestamp-format**: The `timestamp` MUST be the current time as an ISO 8601 internet date-time string in UTC at whole-second precision.
- **hook-data-from-stdin**: `hook_data` MUST be the stdin payload parsed as a JSON object, and MUST be an empty object when stdin is empty, is not valid JSON, or parses to something other than an object.
- **term-program-lifted**: `hook_data.term_program` MUST be set from `TERM_PROGRAM` in the supplied environment, or to the empty string when absent; it overwrites any payload key of that name.
- **term-session-id-lifted**: `hook_data.term_session_id` MUST be set from `TERM_SESSION_ID` in the supplied environment, or to the empty string when absent, so an app can jump to the exact tab or pane even when the daemon was down.
- **session-start-pid**: For the event `SessionStart` only, `hook_data.pid` MUST be set to Claude's pid, or 0 when no pid is known; for every other event the key MUST NOT be added.
- **ppid-resolution**: Claude's pid MUST be the integer parsed from `--ppid` when that parses, otherwise the result of the injected `claudePid` closure, otherwise unknown; a non-numeric `--ppid` falls through to `claudePid`.
- **account-email**: `account_email` MUST be the result of the injected `accountName` closure called with the recovered OAuth token, or with nil when no token was recovered (the closure decides what nil maps to).
- **token-recovery**: The OAuth token passed to `accountName` MUST be recovered by walking up the process tree from this process's parent, falling back to `CLAUDE_CODE_OAUTH_TOKEN` in the supplied environment when the walk finds none, because Claude Code scrubs that variable from the environment it hands hook commands.
- **oauth-email-at-capture**: `oauth_account_email` MUST be the result of the injected `oauthEmail` closure, called while the hook fires and not deferred to the drain, because the sessions upsert keeps the first OAuth stamp and a backlog would otherwise be attributed to whoever is logged in at the drain.

### Context snapshot

- **context-groups**: `context` MUST group process facts under the keys `claude`, `process`, `system`, `shell`, `session` and `terminal`; every group except `process` and `system` MUST be omitted when it would be empty.
- **context-omits-unset**: An environment variable that is unset or the empty string MUST NOT appear in `context`.
- **context-claude-booleans**: `context.claude.running` (from `CLAUDECODE`) and `context.claude.yolo` (from `CLAUDE_YOLO`) MUST be true only for the value `1` or the value `true` in any letter case, and false for any other non-empty value.
- **context-claude-strings**: `context.claude` MUST also carry `entrypoint` (`CLAUDE_CODE_ENTRYPOINT`), `exec_path` (`CLAUDE_CODE_EXECPATH`) and `project_dir` (`CLAUDE_PROJECT_DIR`) as strings when set.
- **context-process**: `context.process` MUST carry `argv` (this process's arguments without the program name), `cwd` (the empty string when the working directory cannot be read), `pid`, `ppid`, `uid`, `euid` and `gid`; `ppid` MUST be the resolved Claude pid, or this process's parent pid when Claude's pid is unknown.
- **context-system**: `context.system` MUST carry `hostname`, `os` (the system name and release separated by one space) and `arch` (the machine type), and MUST be an empty object when the system call fails.
- **context-shell-session-terminal**: `context.shell` MUST carry `shell`, `shlvl` (only when it parses as an integer), `lang` and `path`; `context.session` MUST carry `user`, `home`, `logname`, `tmpdir` and `pwd`; `context.terminal` MUST carry `term`, `term_program`, `term_version`, `term_session_id` and `lc_terminal`, each only when set.
- **context-from-live-process**: The `claude`, `shell`, `session` and `terminal` groups MUST be read from the live process environment, not from the `environment` argument; only `hook_data`, the headless check and the token fallback are read from the supplied environment.

### Concurrency and persistence

- **independent-invocations**: Each invocation MUST be self-contained and hold no state between calls; the type has no stored properties, so concurrent hook processes do not coordinate through it.
- **drop-delegated**: The envelope MUST be handed to `HookDropWriter.writeDropFile` with the directory chosen by `HookDropWriter.dropDirectory` for the supplied configuration and environment.

