
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| detached-process-001 | spawn-payload-fd3, spawn-environment, spawn-reparent | A script recording its stdin, environment and parent pid; `testTheCommandGetsThePayloadAndEnvironmentAndHangsOffLaunchd` | The command read the payload, saw only the given environment, and its parent pid was 1 |
| detached-process-002 | spawn-nonexistent-command | An executable path that does not exist; `testANonexistentCommandStillReturnsAtOnce` | `spawn` returns at once without hanging |
| detached-process-003 | lock-contended, lock-release | Acquire twice for one session, release, acquire again; `testASecondFeedForTheSameSessionIsRefusedUntilTheFirstEnds` | Second acquire is nil until the first is released, then succeeds |
| detached-process-004 | lock-session-sanitised, lock-file-name | A session id with path separators and non-ASCII scalars; `testASessionIDNeverEscapesTheLockDirectory` | The directory holds one file, `stenographer-statusline-feed-______x__.lock`, for session id `../../x/é` |
| detached-process-005 | lock-unguarded-fallback | A lock directory that does not exist or is not writable; `testAnUnwritableLockDirectoryDoesNotStopTheFeed` | `acquire` returns a lock, not nil |
| detached-process-006 | spawn-trampoline | A command run with the single argument `a b'c$d` (derived from the positional-parameter script; no test covers it) | The command receives that argument as one unchanged word |

