
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| process-liveness-001 | unique-match, claude-identity (test: testFindsTheOneClaudeInADirectory) | One real child launched as `claude` in a temp directory; `claudePid(inCwd:)` of that directory | the child's pid |
| process-liveness-002 | unique-match, claude-identity (test: testAnotherProcessInTheDirectoryIsNotClaude) | A non-`claude` process in the directory | nil |
| process-liveness-003 | unique-ambiguous (test: testTwoClaudesInOneDirectoryAreAmbiguous) | Two `claude` children in the directory | nil (and the first alone gave its pid) |
| process-liveness-004 | unique-no-realpath-unrelated (test: testAnUnrelatedProcessesDirectoryIsNeverResolved) | Pids 10, 11, 12 in `/Volumes/share`, `/Users/me/app`, `/Users/me/other`; 11 and 12 are claude; target `/Users/me/app`, then `/Users/me/elsewhere` | 11, then nil; `canonical` never called with `/Volumes/share` |
| process-liveness-005 | unique-two-passes, canonical-path (test: testAClaudeFoundOnlyThroughItsResolvedPathStillMatches) | Pids 20, 21 both in `/tmp/x`; only 20 is claude; target `/private/tmp/x`; `canonical` adds `/private` to `/tmp/` paths | 20 |
| process-liveness-006 | unique-ambiguous, unique-two-passes (test: testTwoClaudesMatchingOnlyThroughTheirResolvedPathsAreAmbiguous) | Pids 30, 31 both claude in `/tmp/x`; target `/private/tmp/x` | nil |
| process-liveness-007 | unique-two-passes (test: testOnlyProcessesInTheDirectoryAreAskedIfTheyAreClaude) | Pids 40, 41, 42; only 41 is in the target directory | 41, and `isClaude` was asked only about 41 |
| process-liveness-008 | session-file-pid-match, session-file-bad (test: testSessionFileIsReadOnlyForItsOwnPid) | Data `{"pid":4242,"sessionId":"abc"}`; pid 4242, then pid 4243; then an empty `sessionId`; then `not json` | "abc"; nil; nil; nil |
| process-liveness-009 | session-file-path (test: testSessionFileIsFoundUnderTheProcessesConfigDirectory) | A file `sessions/777.json` in a temp config directory; `CLAUDE_CONFIG_DIR` set to it; `currentSessionId(ofPid: 777, ...)` | "from-config-dir" |
| process-liveness-010 | headless-entrypoint, headless-kind-ignored (no test in source; derived from the doc comment) | Session file with entrypoint `sdk-cli`; then `cli` with argv `claude -p x` | true; false (the file outranks the arguments) |
| process-liveness-011 | headless-argv (no test in source) | No session file; argv `claude -p ping`; argv `node cli.js --print ping` | true; true |
| process-liveness-012 | headless-after-separator, headless-default (no test in source) | No session file; argv `claude -- -p`; argv `claude`; nil argv | false; false; false |
| process-liveness-013 | attachment-unknown (test: testTerminalAttachmentIsUnknownForAProcessThatIsNotClaude) | `terminalAttachment(ofPid: 0)` and of the test runner's own pid | nil; nil |
| process-liveness-014 | live-list-empty, live-list-failed | `liveClaudeProcesses()`; the result depends on the host, so assert only its shape | nil only if the pid scan itself failed; otherwise an array (empty when no `claude` runs) |
| process-liveness-015 | canonical-fallback | `canonicalPath("/no/such/path")` | `/no/such/path` |
| process-liveness-016 | claude-identity, claude-identity-desktop (no test in source; derived from the doc comment) | Launch paths `/Applications/Claude.app/Contents/MacOS/Claude`, `/usr/local/bin/Claude`, `/opt/claude/bin/tool` and `/usr/local/bin/claude` | not Claude (case differs); not Claude (case differs); Claude (accepted false positive: a `/claude/` component); Claude |
| process-liveness-017 | headless-argv (no test in source) | No session file; argv `claude --print=x`; argv `claude -pv`; argv `claude --model -p` | false; false; true |

The requirements `claude-identity-desktop`, `live-list-session-keeps`, `live-cwd-empty`, `cwd-bounded`, `enumeration-headroom` and `attachment-tty` need a real process or a kernel record and have no unit vector in the source; a port should add integration checks for them.

