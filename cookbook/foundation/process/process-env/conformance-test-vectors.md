
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| process-env-001 | environment-snapshot, env-parse | `environment(forPid:)` on the current process (test: testEnvironmentForCurrentProcessContainsExecTimeVars) | non-nil, and holds `HOME` or `PATH` |
| process-env-002 | parent-pid | `parentPid(of:)` on the current process (test: testParentPidOfCurrentProcessIsValid) | a pid greater than 1 |
| process-env-003 | token-walk | `oauthTokenWalkingUp(from:)` on the current process (test: testOauthTokenWalkingUpDoesNotCrash) | returns without trapping, nil or a token |
| process-env-004 | claude-pid-shell-skip, claude-pid-seams | Fake table: 600 is `sh` with parent 500; 500 is `claude`. `claudePid(aboveHookParent: 600)` (test: testClaudePidSkipsTheShellThatRanTheHookLine) | 500 |
| process-env-005 | claude-pid-direct, claude-pid-name-check | Table: 500 is `claude`; `claudePid(aboveHookParent: 500)`. Then table: 600 is `zsh` with parent 500, 500 is `node`; `claudePid(aboveHookParent: 600)` (test: testClaudePidAcceptsADirectClaudeParentAndNode) | 500 and 500 |
| process-env-006 | claude-pid-name-check | Table: 600 is `zsh` with parent 400, 400 is `login`; `claudePid(aboveHookParent: 600)` (test: testClaudePidIsNilWhenTheChainIsNotClaude) | nil |
| process-env-007 | claude-pid-name-check | Empty table; `claudePid(aboveHookParent: 600)` (test: testClaudePidIsNilWhenTheChainIsNotClaude) | nil |
| process-env-008 | process-names | `processNames(of:)` on the current process (test: testProcessNamesOfThisProcessIncludeItsExecutable) | contains the last component of the first argument |
| process-env-009 | token-cache-ceiling | After `resetCacheForTesting()`, look up 512 distinct pids starting at 2000000 (above the kernel pid ceiling) (test: testCacheStaysAtOrBelowItsCeilingUnderABurstOfDistinctPids) | `cachedTokenCountForTesting` is at most 128 |
| process-env-010 | token-cache-ceiling, token-cache-negative | After reset, look up 64 distinct pids from 2000000 (test: testEvictionOnlyStartsOnceTheCeilingIsReached) | `cachedTokenCountForTesting` equals 64 |
| process-env-011 | token-cache-hit, token-cache-negative | After reset, look up pid 2000000 once, then 50 more times (test: testRepeatedLookupsOfOnePidCacheOneEntry) | `cachedTokenCountForTesting` equals 1 |
| process-env-012 | unreadable-is-nil, token-walk-bounds | `environment(forPid: 2000000)`; `oauthTokenWalkingUp(from: 1)` (no source test) | nil; nil |
| process-env-013 | process-names-unreadable | `processNames(of: 2000000)` (no source test) | empty set |
| process-env-014 | token-boundary, token-boundary-uncached | After reset, `oauthTokenWalkingUp(from: 2000000, below: 2000000)` (no source test) | nil, and `cachedTokenCountForTesting` still equals 0 |
| process-env-015 | cache-test-seam | After reset, `cachedTokenCountForTesting` (no source test) | 0 |
| process-env-016 | claude-pid-shell-orphan, claude-pid-seams | Fake table: 600 is `sh` with no parent; `claudePid(aboveHookParent: 600)` (no source test) | nil |

Vectors 012 to 016 are derived from the source and are covered by `ProcessEnvTests.swift` and `ProcessEnvCacheTests.swift`. The requirements `token-memory-only`, `env-duplicate-key`, `argv-count`, `utf8-lossy`, `token-empty-value`, `token-cache-ttl`, `token-cache-thread-safe` and the real-token branch of `token-walk` have no vector: the parser is private and the source has no test that builds a launch-data buffer, and the 30-second clock cannot be advanced from outside. The source's own comments state each behavior and a port should add a parser test with a handcrafted buffer.

