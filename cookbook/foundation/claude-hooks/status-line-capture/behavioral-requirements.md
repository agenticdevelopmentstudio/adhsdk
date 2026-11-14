
### Run

- **run-status**: `run` MUST return the render closure's exit status when `captureOnly` is false.
- **capture-only-exit**: `run` MUST return 0 when `captureOnly` is true, whatever the feed does, because a status line must never break Claude Code.
- **capture-only-no-render**: `run` MUST NOT call `render` when `captureOnly` is true.
- **capture-only-no-print**: `run` MUST print nothing when `captureOnly` is true.
- **sigpipe-ignored**: `run` MUST ignore the broken-pipe signal before doing anything else, so a child that exits before draining its stdin surfaces as a write error rather than killing the process before the line renders.
- **render-before-feed**: When `captureOnly` is false, `run` MUST call `render` before it starts the feed, and MUST flush standard output after `render` returns and before the feed starts.
- **render-args**: `run` MUST call `render` with the payload and the recovered token (nil when none was recovered).
- **feed-always**: When `captureOnly` is false, `run` MUST start a feed after the render whatever the render's status.
- **detach-first**: When `captureOnly` is false, `run` MUST first try to detach the feed, and MUST run the feed in-process, through `feedOnce`, only when detaching reports false.
- **capture-only-feeds-inline**: When `captureOnly` is true, `run` MUST run the feed in-process through `feedOnce`, and MUST NOT detach another.

### Token recovery

- **token-walk**: `run` MUST recover the OAuth token once per invocation by walking up the process tree from the parent pid (at most 16 hops, the `maxHops` default of `ProcessEnv.oauthTokenWalkingUp`; stopping at pid 1 or below; with a result cached per start pid for 30 seconds, the `ttl` of `ProcessEnv`), because Claude Code scrubs `CLAUDE_CODE_OAUTH_TOKEN` from the environment it hands the command.
- **token-carried**: When `captureOnly` is true and the walk finds no token, `run` MUST use `CLAUDE_CODE_OAUTH_TOKEN` from its own environment when that is non-empty, because a detached feed carries the token its renderer recovered for the time `claude` is gone.
- **token-walk-first**: A token found by the walk MUST take precedence over the carried one.
- **token-carried-only-capture**: When `captureOnly` is false, `run` MUST NOT use `CLAUDE_CODE_OAUTH_TOKEN` from its own environment as the recovered token.
- **injected-token**: `injected` MUST return the base environment unchanged when the token is nil, and otherwise a copy with `CLAUDE_CODE_OAUTH_TOKEN` set to the token, replacing any existing value.

### Parent pid

- **parent-pid-variable**: The parent-pid environment variable MUST be named `CLAUDEHELPERS_STATUSLINE_PARENT_PID`.
- **parent-pid-live**: `parentPID` MUST return the value of that variable when it parses as a 32-bit integer greater than 1.
- **parent-pid-fallback**: `parentPID` MUST return the process's own parent pid when the variable is absent, not an integer, or 1 or less (including 0 and negative values).

### Detached feed

- **detach-helper-only**: `detachFeed` MUST return false, and start nothing, when the executable path is nil or its last path component differs from the last path component of the configuration's `hookBinaryPath`, so an in-process test or a foreign host feeds in-process.
- **detach-command**: `detachFeed` MUST start the executable with the configuration's `statusLineArguments` followed by `--capture-only`.
- **detach-payload**: `detachFeed` MUST pass the payload on the detached process's standard input.
- **detach-environment**: `detachFeed` MUST pass the caller's environment with the token injected and `CLAUDEHELPERS_STATUSLINE_PARENT_PID` set to the decimal parent pid, because a detached feed has been reparented to launchd, so its own parent leads nowhere.
- **detach-result**: `detachFeed` MUST return what `DetachedProcess.spawn` returns.
- **detach-default-executable**: `detachFeed` MUST default the executable to the main bundle's executable path.

### Feed, one at a time

- **feed-parse**: `feedOnce` MUST read `session_id` from the payload when the payload is a JSON object with a string `session_id`.
- **feed-lock**: When the payload has a string `session_id`, `feedOnce` MUST acquire a `FeedLock` for that session and the configuration's `name`, and MUST return without feeding when another feed holds it, because the next render brings a newer snapshot.
- **lock-name-sanitised**: A feed lock's file name MUST keep at most the first 128 Unicode scalars of the session id and MUST replace every scalar that is not an ASCII letter, an ASCII digit or `-` with `_`, so a session id never escapes the lock directory.
- **feed-lock-release**: `feedOnce` MUST release the lock when the feed ends or its deadline passes, even when the queued work is still running, so a second feed for the session may overlap work the first has not finished; the overlap is accepted.
- **feed-unlocked**: When the payload is not a JSON object, or has no string `session_id`, `feedOnce` MUST feed without a lock.
- **feed-deadline**: `feedOnce` MUST wait for the feed no longer than `feedDeadline`, which MUST be 20 seconds, and MUST then return and release the lock even when the feed has not finished.
- **feed-own-thread**: `feedOnce` MUST run the feed on a global background queue, not on the calling thread.

### Feed

- **feed-fingerprint**: `feed` MUST add the git-context fingerprint to the payload by `GitContextFingerprint.enriched(payload:)` before the payload leaves the process, because the sample must be taken in the session's working directory at render time and drop-file ingest can be minutes later.
- **feed-post**: `feed` MUST send the enriched payload by `post` as the event `StatusLine`, and MUST do nothing further when `post` returns true.
- **feed-no-drop-on-accept**: `feed` MUST NOT write a drop file when `post` returns true.
- **feed-drop-on-refusal**: When `post` returns false, `feed` MUST build an envelope for the event `StatusLine` with the enriched payload on standard input, no `ppid` string, the environment with the token injected, and the injected `accountName` and `oauthEmail`, using `HookCaptureCommand.buildEnvelope`.
- **feed-drop-directory**: `feed` MUST write that envelope into the directory `HookDropWriter.dropDirectory` chooses for the configuration and the environment.
- **feed-headless-skip**: `feed` MUST write no drop file when `HookCaptureCommand.buildEnvelope` returns nil, which it does when the environment holds `ADH_SDK_HEADLESS`, so a headless `claude` is never tracked.
- **feed-drop-silent**: NEEDS REVIEW: Not implemented in source. A failure to write the drop file ends the feed with no signal (the write error is discarded by `try?`) and the event is lost; the source states no log, return value or counter for it, so evidence of whether the daemon needs to learn of lost events would settle it.
- **feed-token-source**: `feed` MUST inject the token it was given into the drop envelope's environment, and MUST NOT recover one itself.

### Transport and configuration

- **post-injected**: The caller MUST supply `post` as a `@Sendable` closure taking an event name and payload bytes and returning true on acceptance.
- **account-injected**: The caller MUST supply `accountName` as a `@Sendable` closure from an optional token to an account name; `oauthEmail` is `@Sendable` and defaults to the empty string.
- **no-daemon-client**: `StatusLineCapture` MUST NOT link a daemon client; every call to the daemon goes through `post`.

