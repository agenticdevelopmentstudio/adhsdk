
### Payload-only build (http hook)

- **http-event-required**: The payload-only `build(event:payload:...)` MUST return nil when `event` is the empty string.
- **http-daemon-cwd-dropped**: The payload-only build MUST return nil, before reading any process environment, when the payload's `cwd` canonicalises to the daemon's own working directory, because the headless `claude` the daemon spawns inherits that directory and never sets its own.
- **http-daemon-cwd-guards**: The daemon-directory check MUST NOT apply when the daemon directory is the empty string or `/`, and MUST NOT apply when the payload has no `cwd` string.
- **http-env-recovery**: When the payload has a `cwd`, the build MUST locate the `claude` pid through the injected `claudePid` resolver for that `cwd`, read that pid's environment through the injected `environment` resolver, and pass the pid on as the `ppid`.
- **http-env-degrades**: When no `cwd`, no pid or no environment can be found, the build MUST continue with an empty environment and a `ppid` of 0, so the event is still built when the payload carries a `session_id`; token and terminal fields are then simply absent.

### Full build (socket or recovered environment)

- **event-required**: The full `build(event:ppid:env:payload:...)` MUST return nil when `event` is the empty string.
- **headless-env-dropped**: The full build MUST return nil when `env` contains the key `ADH_SDK_HEADLESS` with any value, including an empty one.
- **headless-before-session**: The headless check MUST run before the `session_id` check, so a headless event is dropped whether or not it carries a session.
- **hook-data-from-payload**: `hookData` MUST be the supplied parsed payload when given, otherwise the payload bytes parsed as a JSON object, and MUST be an empty object when the bytes are empty, invalid or not an object.
- **term-lifted**: `hookData.term_program` and `hookData.term_session_id` MUST be set from `TERM_PROGRAM` and `TERM_SESSION_ID` in `env`, each to the empty string when absent, overwriting any payload key of that name.
- **session-start-pid**: For the event `SessionStart` only, `hookData.pid` MUST be set to the supplied `ppid`.
- **session-id-required**: The full build MUST return nil when `hookData.session_id` is missing, not a string, or the empty string.
- **context-built**: The `context` of the result MUST be the value of `buildContext` for the same `ppid` and `env`.
- **timestamp-format**: The `timestamp` MUST be the current time as an ISO 8601 internet date-time string in UTC at whole-second precision, produced by the capture command's formatter.
- **token-recovery**: The token passed to `accountName` MUST be `CLAUDE_CODE_OAUTH_TOKEN` from `env` when that is non-empty, otherwise the token found by walking up the process tree from the `ppid`, because Claude Code scrubs the variable from the environment it hands hook commands.
- **account-email**: `accountEmail` MUST be the result of `accountName` called with that token.
- **oauth-email-at-capture**: `oauthAccountEmail` MUST be the result of `oauthEmail` called during the build, not at ingest, because an event may wait in a spool for a migration or in the drop directory across a reboot, and the sessions upsert keeps the first OAuth stamp.
- **result-fields**: The result MUST be a `ParsedEvent` carrying `eventType` (the event unchanged), `timestamp`, `hookData`, `context`, `accountEmail` and `oauthAccountEmail`.
- **ppid-range**: NEEDS REVIEW: Not implemented in source. When `env` has no non-empty `CLAUDE_CODE_OAUTH_TOKEN`, the full build converts the supplied `ppid` to a 32-bit integer for the token walk without a range check, so a `ppid` larger than the 32-bit range, which `parseWire` accepts from the wire, would trap; a test passing such a value would show whether the daemon aborts.

### Context

- **context-groups**: `buildContext` MUST group facts under `claude`, `process`, `system`, `shell`, `session` and `terminal`, omitting every group except `process` and `system` when it is empty.
- **context-omits-unset**: A variable that is absent or the empty string in `env` MUST NOT appear in `context`.
- **context-claude**: `context.claude` MUST carry `running` (from `CLAUDECODE`) and `yolo` (from `CLAUDE_YOLO`) as booleans, with the values `1`, `true`, `yes` and `on` read as true and `0`, `false`, `no` and `off` as false, case and surrounding whitespace ignored, and any other non-empty value read as false; and `entrypoint`, `exec_path` and `project_dir` as strings.
- **context-process-subset**: `context.process` MUST carry only `ppid`, `uid`, `euid` and `gid`, and MUST NOT carry `argv`, `cwd` or `pid`, because the hook-firing process has exited by ingest time and a hook script's argv is only its name and the event.
- **context-system**: `context.system` MUST be the capture command's system information: `hostname`, `os` and `arch`, or an empty object when the system call fails.
- **context-shell-session-terminal**: `context.shell` MUST carry `shell`, `shlvl` (only when an integer), `lang` and `path`; `context.session` MUST carry `user`, `home`, `logname`, `tmpdir` and `pwd`; `context.terminal` MUST carry `term`, `term_program`, `term_version`, `term_session_id` and `lc_terminal`, each only when set in `env`.

### Wire parsing

- **wire-separator**: `parseWire` MUST split the input at the first occurrence of the bytes newline, three hyphens, newline, taking everything before it as the header and everything after it as the payload, and MUST return nil when no separator exists.
- **wire-header-utf8**: `parseWire` MUST return nil when the header is not valid UTF-8.
- **wire-header-lines**: `parseWire` MUST split the header on newline keeping empty lines, MUST return nil when there are fewer than two lines, and MUST take the first line as the event and the second as the `ppid`.
- **wire-ppid-lenient**: The `ppid` line that does not parse as an integer MUST become 0.
- **wire-env-lines**: Every later non-empty header line MUST be split at its first `=` into key and value, so the value may itself contain `=`; a line without `=` MUST be skipped, and a repeated key keeps the last value.
- **wire-payload-verbatim**: The payload MUST be returned as the exact bytes after the separator, including when empty, and MAY itself contain the separator.
- **wire-empty-event**: An empty first line MUST be returned as an empty event string; rejection happens later, in `build`.

### Working-directory reference

- **daemon-cwd-once**: `daemonWorkingDirectory` MUST be the canonical form of the calling process's working directory, computed once at first access and not updated afterwards; a daemon changes into its support directory early in start-up, before first read.

### Environment cache

- **cache-ttl**: `HookEnvCache` MUST serve a cached value for three seconds after it was stored and MUST resolve again once that time has passed.
- **cache-pid-key**: `pid(inCwd:)` MUST key its entries by the canonical form of the working directory, so two spellings of one existing directory share an entry (a path that does not exist canonicalises to itself).
- **cache-nil-pid**: `pid(inCwd:)` MUST cache a nil result as well as a pid, and MUST delegate resolution to `ProcessLiveness.claudePid(inCwd:)`, which returns nil rather than guess when more than one `claude` shares the directory.
- **cache-empty-env**: `env(forPid:)` MUST cache the empty dictionary when the read fails, so a transient failure does not trigger a rescan on every render.
- **cache-eviction**: When either map holds more than 128 entries after an insert, `HookEnvCache` MUST remove the expired entries; unexpired entries are never evicted by that rule.
- **cache-thread-safety**: Every access to both maps MUST happen under one lock; the resolution on a miss MUST run outside the lock, so two concurrent misses for one key may both resolve and the later store wins.
- **default-resolvers**: The default `claudePid` and `environment` resolvers of the payload-only build MUST be the cache; tests inject their own resolvers and bypass it.

