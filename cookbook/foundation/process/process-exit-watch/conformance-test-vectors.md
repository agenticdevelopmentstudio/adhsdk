
`ProcessExitWatchConformanceTests.swift` tests this type directly, skipping vectors 001, 009 and 012 with a reason; `CommandRunner`'s tests also exercise it through the runner. The vectors below follow the code and its doc comments, and a port should assert them with a short-lived child such as `/usr/bin/true` and a sleeping child.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| process-exit-watch-001 | install-before-launch | Create the watch for a process that is already running | The precondition fails with "ProcessExitWatch must be installed before run()" (a failed precondition ends the process, so this needs an exit test such as Swift Testing `#expect(processExitsWith:)` or a subprocess harness) |
| process-exit-watch-002 | handler-installed, wait-signalled | Create the watch, launch `/usr/bin/true`, call `waitForExit(timeout: 5)` | true, well before the 5 seconds |
| process-exit-watch-003 | wait-timeout | Create the watch, launch a child that sleeps 30 seconds, call `waitForExit(timeout: 0.2)` | false after about 0.2 seconds |
| process-exit-watch-004 | wait-sticky, wait-already-exited | After vector 002 returned true, call `waitForExit(timeout: 0)` and `waitForExit(timeout: 10)` | true both times, immediately |
| process-exit-watch-005 | wait-zero-timeout | Create the watch, launch a sleeping child, call `waitForExit(timeout: 0)` | false without blocking |
| process-exit-watch-006 | stop-terminate-first, stop-result | Launch a child that sleeps 30 seconds and call `stop(_:)` | true, within `terminationGrace`, and the child is gone |
| process-exit-watch-007 | stop-kill-second, stop-result, grace-value | Launch a shell that traps and ignores SIGTERM and sleeps, call `stop(_:)` | true after about 2 seconds (the first grace lapsed, SIGKILL ended it) |
| process-exit-watch-008 | stop-already-exited | After the child exited and `waitForExit` returned true, call `stop(_:)` | true at once, and no signal is sent |
| process-exit-watch-009 | stop-false-is-real, stop-worst-case | A process that neither dies on SIGTERM nor on SIGKILL (blocked in an uninterruptible wait). Manual or inspection-only: no portable setup produces one, so run it by hand against a read on a hung network mount, or inspect the code path | `stop(_:)` returns false after about 4 seconds, plus signal time |
| process-exit-watch-010 | exit-recorded-once-seen | Launch `/usr/bin/true`, sleep 1 second, then call `waitForExit(timeout: 0)` | true |
| process-exit-watch-011 | handler-replaces | Set a termination handler on the process, create the watch, launch, wait | `waitForExit` returns true and the earlier handler is not called |
| process-exit-watch-012 | no-status-api | Inspect the public interface | no member returns an exit code or a termination reason |

The requirement `concurrent-waiters` is an open question and has no vector.

