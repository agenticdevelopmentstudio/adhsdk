
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| detached-process-001 | spawn-payload-fd3, spawn-environment, spawn-reparent | A script recording its stdin, environment and parent pid; `testTheCommandGetsThePayloadAndEnvironmentAndHangsOffLaunchd` | The command read the payload, saw only the given environment, and its parent pid was 1 |
| detached-process-002 | spawn-nonexistent-command | An executable path that does not exist; `testANonexistentCommandStillReturnsAtOnce` | `spawn` returns at once without hanging |
| detached-process-003 | lock-contended, lock-release | Acquire twice for one session, release, acquire again; `testASecondFeedForTheSameSessionIsRefusedUntilTheFirstEnds` | Second acquire is nil until the first is released, then succeeds |
| detached-process-004 | lock-session-sanitised, lock-file-name | A session id with path separators and non-ASCII scalars; `testASessionIDNeverEscapesTheLockDirectory` | The directory holds one file, `<name>-statusline-feed-______x__.lock`, for session id `../../x/é`; the test passes `name: "stenographer"`, so the file is `stenographer-statusline-feed-______x__.lock` |
| detached-process-005 | lock-unguarded-fallback | A lock directory that does not exist or is not writable; `testAnUnwritableLockDirectoryDoesNotStopTheFeed` | `acquire` returns a lock, not nil |
| detached-process-006 | spawn-trampoline | A command run with the single argument `a b'c$d` (derived from the positional-parameter script; no test covers it) | The command receives that argument as one unchanged word |
| detached-process-007 | lock-session-sanitised | Session ids of 128 and of 129 ASCII letters `a`, derived from the source (no test covers it) | The 128-scalar id appears whole in the file name; the 129-scalar id is cut to its first 128, so both name the same lock file when the first 128 scalars match |
| detached-process-008 | spawn-payload-fd3, spawn-environment | `stdin` empty `Data` and an empty `environment`, derived from the source (no test covers it) | The command sees immediate end of input and has no environment variables |
