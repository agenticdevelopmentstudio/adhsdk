
Derived from `HookCaptureTests` where a test is named, and from the source otherwise.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| capture-001 | exit-status-zero, drop-delegated, envelope-keys, event-verbatim | `run` with arguments `--event Stop --ppid 5`, stdin `{"session_id":"s1"}`, the configuration's drop-directory variable pointing at a fresh directory, `oauthEmail` returning `login@example.com` (test `testRunWritesADropFileForTheEvent`) | Returns 0; exactly one `.json` file appears in the directory; its `event` is `Stop` and its `oauth_account_email` is `login@example.com` |
| capture-002 | event-flag-required, exit-status-zero | `run` with no arguments and empty stdin (test `testRunWithoutAnEventWritesNothingAndStillSucceeds`) | Returns 0; the drop directory is not created |
| capture-003 | event-flag-required | `run` with arguments `--event` and no value, or `--event ""` | Returns 0; nothing is written |
| capture-004 | term-program-lifted, term-session-id-lifted, session-start-pid, ppid-resolution | `buildEnvelope` for `SessionStart`, ppid string `123`, env `TERM_PROGRAM=iTerm.app`, `TERM_SESSION_ID=w1t12p0:UUID-9` (test `testEnvelopeCarriesTermSessionIdAndSessionStartPid`) | `hook_data.term_session_id` is `w1t12p0:UUID-9`, `term_program` is `iTerm.app`, `pid` is 123 |
| capture-005 | session-start-pid, term-session-id-lifted | `buildEnvelope` for `PreToolUse`, no ppid, empty env (test `testOnlySessionStartCarriesAPid`) | `hook_data.term_session_id` is the empty string and `hook_data.pid` is absent |
| capture-006 | headless-not-tracked | `buildEnvelope` for `SessionStart` with env `ADH_SDK_HEADLESS=1` (test `testHeadlessEventsAreNotTracked`) | Returns nil |
| capture-007 | headless-not-tracked | `buildEnvelope` with env `ADH_SDK_HEADLESS` set to the empty string | Returns nil (presence of the key, not its value, decides) |
| capture-008 | ppid-resolution, session-start-pid | `buildEnvelope` for `SessionStart`, ppid nil, `claudePid` returning 4242; then `claudePid` returning nil (test `testClaudesPidIsFoundWhenNoPpidFlagIsGiven`) | `hook_data.pid` is 4242, then 0 |
| capture-009 | ppid-resolution | `buildEnvelope` for `SessionStart`, ppid string `abc`, `claudePid` returning 4242 | `hook_data.pid` is 4242 (the non-numeric flag falls through) |
| capture-010 | account-email, oauth-email-at-capture | `buildEnvelope` with `accountName` returning `named@example.com` and `oauthEmail` returning `x@example.com` (test `testTheAccountLookupsAreInjected`) | `account_email` is `named@example.com` and `oauth_account_email` is `x@example.com` |
| capture-011 | hook-data-from-stdin | `buildEnvelope` with stdin empty, then stdin `not json`, then stdin `[1,2]` | In each case `hook_data` holds only the lifted keys `term_program` and `term_session_id` |
| capture-012 | flag-parsing | arguments `--event=Stop` | No `--event` value is found; `run` writes nothing and returns 0 |
| capture-013 | flag-parsing, event-flag-required | arguments `--event --ppid 5` | `--event` has no value because the next argument starts with `--`; nothing is written |
| capture-014 | context-claude-booleans | integration-only (reads the live process environment, which `buildEnvelope` does not take as an argument); live environment `CLAUDECODE=TRUE`, `CLAUDE_YOLO=0` | `context.claude.running` is true and `context.claude.yolo` is false |
| capture-015 | context-omits-unset, context-groups | integration-only (reads the live process environment); live environment with no `LC_TERMINAL` and an empty `TMPDIR` | `context.terminal` has no `lc_terminal` key and `context.session` has no `tmpdir` key |
| capture-016 | write-failure-swallowed, exit-status-zero | `run` with a drop-directory variable naming a path under a regular file | Returns 0, writes nothing, prints nothing |
| capture-017 | timestamp-format | any built envelope | `timestamp` matches `YYYY-MM-DDTHH:MM:SSZ` |
| capture-018 | context-process | `buildEnvelope` with ppid string `99` | `context.process.ppid` is 99; with ppid nil and `claudePid` nil it is this process's parent pid |
| capture-019 | token-recovery | `buildEnvelope` with an environment holding `CLAUDE_CODE_OAUTH_TOKEN=tok` and a process tree that yields no token | `accountName` is called with `tok` |
| capture-020 | token-recovery, account-email | `buildEnvelope` with no token in the tree and none in the environment | `accountName` is called with nil |
| capture-021 | context-system | any built envelope | `context.system` has string keys `hostname`, `os` (two words separated by one space) and `arch` |
| capture-022 | duplicate-flag-last-wins | arguments `--event Stop --event Start` | The event is `Start` |

SHOULD requirements: the document contains none, so no omission needs a rationale.
