
Vectors `capture-001` to `capture-006`, `capture-008`, `capture-009` and `capture-016` are named for tests in `HookCaptureTests` and `DetachedProcessTests`; the rest, including `capture-022` to `capture-031`, are derived from the source, because no test calls `feedOnce`, `detachFeed` or `injected`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| capture-001 | feed-drop-on-refusal, feed-drop-directory, feed-post (test `testAFeedTheDaemonRefusesIsDroppedInTheConfigurationsDirectory`) | `feed` with payload `{"session_id":"sl-1","cwd":"/nonexistent-dir"}`, `post` returning false, configuration `adkd`, environment `ADKD_DROP_DIR` set to a fresh directory | The drop directory holds exactly one file; it parses as a JSON object whose `event` is `StatusLine` |
| capture-002 | feed-post, feed-no-drop-on-accept (test `testAFeedTheDaemonAcceptsLeavesNoDropFile`) | `feed` with the same payload, `post` recording and returning true, configuration `stenographer`, `STENOGRAPHER_DROP_DIR` set to a path that does not exist | `post` was called once with the event `StatusLine`; the drop path still does not exist |
| capture-003 | capture-only-exit, capture-only-no-render (test `testCaptureOnlySkipsTheRenderAndExitsZero`) | `run` with `captureOnly` true, `post` returning true, `render` that sets a flag and returns 7 | Returns 0; the flag is unset |
| capture-004 | run-status, feed-always, detach-helper-only (test `testARenderReturnsItsOwnStatusAndStillFeeds`) | `run` with `captureOnly` false, `render` returning 3, `post` that records and returns true, from a test process that is not the helper | Returns 3; `post` was called, because the feed ran in-process |
| capture-005 | feed-lock (test `testTheFeedLockIsNamedForTheConfiguration`) | `FeedLock.acquire` with session `s`, name `adkd` | A file `adkd-statusline-feed-s.lock` exists in the lock directory |
| capture-006 | feed-lock | `FeedLock.acquire` twice for one session and name while the first is held; then for another session | The second returns nil for the same session and a lock for the other (`DetachedProcessTests.testASecondFeedForTheSameSessionIsRefusedUntilTheFirstEnds`); `feedOnce` for that session posts nothing |
| capture-007 | feed-unlocked | `feedOnce` with payload `not json` and `post` recording | `post` called once; no lock file created |
| capture-008 | parent-pid-live | `parentPID` with the variable set to `4242` (test `testTheWalkStartsFromTheDispatchersParent`) | 4242 |
| capture-009 | parent-pid-fallback | `parentPID` with an empty environment; with the variable `1`; with `junk` (same test) | The process's own parent pid in each case |
| capture-010 | parent-pid-fallback | `parentPID` with the variable `0`, then `-5` | The process's own parent pid |
| capture-011 | injected-token | `injected` of `{A: 1}` with token nil | `{A: 1}` |
| capture-012 | injected-token | `injected` of `{A: 1, CLAUDE_CODE_OAUTH_TOKEN: old}` with token `new` | `{A: 1, CLAUDE_CODE_OAUTH_TOKEN: new}` |
| capture-013 | detach-helper-only | `detachFeed` with `hookBinaryPath` `/x/helper` and executable `/y/other-tool` | False; nothing started |
| capture-014 | detach-helper-only | `detachFeed` with executable nil | False |
| capture-015 | detach-command, detach-payload, detach-environment, detach-result | `detachFeed` with `hookBinaryPath` `/x/helper`, executable `/y/helper`, `statusLineArguments` `["statusline"]`, token `t`, parent 99 | `DetachedProcess.spawn` called with arguments `statusline --capture-only`, stdin the payload, an environment holding `CLAUDE_CODE_OAUTH_TOKEN` `t` and `CLAUDEHELPERS_STATUSLINE_PARENT_PID` `99`; the call returns the spawn result |
| capture-016 | detach-result (test `testANonexistentCommandStillReturnsAtOnce`, in `DetachedProcessTests`) | `DetachedProcess.spawn` of a nonexistent executable | Returns at once |
| capture-017 | token-carried | `run` with `captureOnly` true, environment `CLAUDE_CODE_OAUTH_TOKEN` `carried`, and a parent whose tree holds no token | The feed's injected environment carries `carried` |
| capture-018 | feed-deadline | `feedOnce` with a `post` that sleeps beyond 20 seconds | `feedOnce` returns after about 20 seconds and the lock file can be acquired again |
| capture-019 | feed-fingerprint | `feed` with a payload whose `cwd` is a git work tree and `post` capturing the payload | The posted payload is the output of `GitContextFingerprint.enriched` for the original payload |
| capture-020 | feed-drop-silent | `feed` with `post` false and a drop directory that cannot be created | Returns normally; no error; no file |
| capture-022 | token-walk-first | `run` with `captureOnly` true, environment `CLAUDE_CODE_OAUTH_TOKEN` `carried`, and a parent whose tree holds token `walked` | The token used is `walked` |
| capture-023 | token-carried-only-capture | `run` with `captureOnly` false, environment `CLAUDE_CODE_OAUTH_TOKEN` `carried`, and a parent whose tree holds no token | `render` receives a nil token; the variable is ignored |
| capture-024 | capture-only-no-print, capture-only-feeds-inline, capture-only-exit | `run` with `captureOnly` true and `post` recording | Nothing is written to standard output; the feed ran in-process through `feedOnce`; no second feed was detached; returns 0 |
| capture-025 | detach-first | `run` with `captureOnly` false where `detachFeed` reports true, then where it reports false | The first leaves `post` uncalled in this process; the second runs the feed in-process through `feedOnce` |
| capture-026 | feed-headless-skip | `feed` with environment `ADH_SDK_HEADLESS` set and `post` returning false | No drop file is written |
| capture-027 | feed-token-source | `feed` with a token `t` given and `post` returning false | The drop envelope's environment holds `CLAUDE_CODE_OAUTH_TOKEN` `t`; no process-tree walk is made by `feed` |
| capture-028 | feed-lock-release | `feedOnce` with a `post` that sleeps beyond the deadline, then a second `feedOnce` for the same session | The lock is free after the deadline and the second feed starts |
| capture-029 | token-walk | A process chain 17 hops deep with the token only on the 17th; and two walks from one start pid within 30 seconds | The first finds no token; the second reads the process table once |
| capture-030 | feed-own-thread | `feedOnce` with a `post` that records whether it ran on the calling thread | `post` ran on a global-queue thread, not the calling thread |
| capture-031 | sigpipe-ignored | `run` with a detached child that exits before draining its stdin | The process survives and the line was already rendered |
| capture-021 | render-before-feed, render-args | `run` with `captureOnly` false and a `render` that records its arguments and the time | `render` was given the payload and the recovered token (nil if none), and returned before `post` or `detachFeed` was called |

`post-injected`, `account-injected`, `no-daemon-client`, `detach-default-executable`, `feed-parse` and `parent-pid-variable` are verified by reading the signatures or by the vectors above rather than by a dedicated one; `feed-parse` by `capture-007` and `capture-001`, and `parent-pid-variable` by `capture-008`.

