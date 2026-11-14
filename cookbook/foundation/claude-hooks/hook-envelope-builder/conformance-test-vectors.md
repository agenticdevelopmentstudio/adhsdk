
No test in the repository exercises `HookEnvelopeBuilder` or `HookEnvCache` directly; the source states tests inject their own resolvers, and the vectors below are derived from the source. The context shape is shared with the capture command, whose tests are in `HookCaptureTests`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| builder-001 | event-required, http-event-required | `build` with event `""` (either overload) and a valid payload | nil |
| builder-002 | headless-env-dropped, headless-before-session | Full build for `SessionStart`, env `ADH_SDK_HEADLESS=1`, payload with a `session_id`; and again with the value empty and no `session_id` | nil both times |
| builder-003 | session-id-required | Full build, env empty, payload `{}`; payload `{"session_id":""}`; payload `{"session_id":5}` | nil for each |
| builder-004 | hook-data-from-payload, term-lifted, session-start-pid, result-fields | Full build for `SessionStart`, ppid 123, env `TERM_PROGRAM=iTerm.app`, `TERM_SESSION_ID=w0t1p0:U`, payload `{"session_id":"s1"}` | `eventType` `SessionStart`; `hookData.pid` 123, `term_program` `iTerm.app`, `term_session_id` `w0t1p0:U`, `session_id` `s1` |
| builder-005 | session-start-pid, term-lifted | Full build for `Stop`, env empty, payload `{"session_id":"s1"}` | `hookData.pid` absent; `term_program` and `term_session_id` are the empty string |
| builder-006 | token-recovery, account-email | Full build with env `CLAUDE_CODE_OAUTH_TOKEN=tok` and `accountName` that returns its argument | `accountEmail` is `tok` |
| builder-007 | account-email, oauth-email-at-capture | Defaults for both closures | `accountEmail` and `oauthAccountEmail` are the empty string |
| builder-008 | oauth-email-at-capture | `oauthEmail` returning `login@example.com` | `oauthAccountEmail` is `login@example.com` |
| builder-009 | http-daemon-cwd-dropped | Payload-only build with `daemonCwd` `/var/support` and payload `cwd` `/var/support` | nil; neither resolver is called |
| builder-010 | http-daemon-cwd-guards | Payload-only build with `daemonCwd` `/`, payload `cwd` `/`, `session_id` present, resolvers returning pid 9 and an empty env | An event is returned |
| builder-011 | http-env-recovery, http-env-degrades | Payload-only build with `claudePid` returning 9, `environment` returning `TERM_PROGRAM=Apple_Terminal`, payload with `cwd` and `session_id`, event `SessionStart` | `hookData.pid` 9; `context.process.ppid` 9; `context.terminal.term_program` `Apple_Terminal` |
| builder-012 | http-env-degrades | Payload-only build with both resolvers returning nil and a payload with `session_id` and `cwd` | An event with `context.process.ppid` 0 and no `terminal` group |
| builder-013 | http-env-degrades | Payload-only build with a payload that has a `session_id` and no `cwd` | The resolvers are not called; `ppid` 0 |
| builder-014 | context-claude | env `CLAUDECODE=yes`, `CLAUDE_YOLO=off`, `CLAUDE_CODE_ENTRYPOINT=cli` | `claude.running` true, `claude.yolo` false, `claude.entrypoint` `cli` |
| builder-015 | context-claude | env `CLAUDECODE=maybe` | `claude.running` false |
| builder-016 | context-groups, context-omits-unset | `buildContext` with an empty env | Keys are exactly `process` and `system` |
| builder-017 | context-omits-unset, context-shell-session-terminal | env `SHLVL=abc`, `LANG=` (empty), `HOME=/Users/a` | `shell` group absent; `session.home` `/Users/a` |
| builder-018 | context-process-subset | `buildContext` for ppid 7 | `process` has `ppid` 7, `uid`, `euid`, `gid` and no `argv`, `cwd` or `pid` |
| builder-019 | wire-separator, wire-header-lines, wire-payload-verbatim | `Stop`, newline, `55`, newline, `TERM=xterm`, newline, `---`, newline, `{"a":1}` | event `Stop`, ppid 55, env `TERM` `xterm`, payload bytes `{"a":1}` |
| builder-020 | wire-separator | Bytes with no newline-hyphen-newline separator | nil |
| builder-021 | wire-header-lines | `Stop`, newline, `---`, newline, payload (a one-line header) | nil |
| builder-022 | wire-ppid-lenient | Header lines `Stop` and `abc` | ppid 0 |
| builder-023 | wire-env-lines | Env lines `A=b=c`, `NOEQ`, an empty line, `A=d` | env is `A` = `d` only |
| builder-024 | wire-payload-verbatim | A payload that itself contains the separator | Returned unchanged |
| builder-025 | wire-header-utf8 | Header bytes that are not valid UTF-8 | nil |
| builder-026 | wire-empty-event | First line empty | event is the empty string; passing it to `build` returns nil |
| builder-027 | cache-ttl, cache-nil-pid, default-resolvers | Two `HookEnvCache.pid(inCwd:)` calls for one directory within three seconds | The underlying resolver runs once, including when it returned nil |
| builder-028 | cache-pid-key | `pid(inCwd:)` for an existing directory `/tmp/x` then for `/private/tmp/x` on macOS | One resolution |
| builder-029 | cache-empty-env | `env(forPid:)` twice within three seconds where the read fails | One read; both return the empty dictionary |
| builder-030 | cache-eviction | 128 distinct cwds resolved and left to expire (more than three seconds), then a 129th cwd resolved | The insert of the 129th takes the map past 128 entries, so the 128 expired entries are removed and only the 129th remains |
| builder-031 | cache-thread-safety | Concurrent `env(forPid:)` calls for different pids | No crash; each caller receives a dictionary |
| builder-032 | daemon-cwd-once | Read `daemonWorkingDirectory`, change the working directory, read again | The same value both times |
| builder-033 | timestamp-format | Any built event | `timestamp` matches `YYYY-MM-DDTHH:MM:SSZ` |
| builder-034 | context-built, context-system | Any built event | `context` equals `buildContext(event, ppid, env)` and `context.system` has `hostname`, `os`, `arch` |
| builder-035 | wire-payload-verbatim | A message whose payload after the separator is empty | The payload is empty `Data` |

SHOULD requirements: the document contains none. The open question on `ppid-range` has no vector because the behavior it asks about is undefined. The payload is parsed once on the http path and the parsed object is handed to the inner build; that is an internal efficiency detail, not a requirement.

