
The source has no `RaceBox` test file. The vectors come from the code and its doc comments; the rows that name a test are the existing tests of its two callers, which exercise the same race through `withSignInDeadline` and `MailIntegrationService.stop(timeout:)`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| race-box-001 | first-finish-wins, is-finished-flag | New `RaceBox<Int>`; call `finish(.success(1))` | Returns `true`; `isFinished` is `true`; `value()` returns `1` |
| race-box-002 | later-finish-ignored | After race-box-001, call `finish(.success(2))` then `finish(.failure(E))` | Both return `false`; `value()` still returns `1` |
| race-box-003 | value-waits, release-all-waiters, value-delivers-outcome | New box; start three tasks each awaiting `value()`; then `finish(.success(7))` | All three tasks return `7`; `finish` returned `true` |
| race-box-004 | failure-is-an-outcome, value-delivers-outcome | New box; a task awaits `value()`; `finish(.failure(E))` | The awaiting task throws `E`; a later `finish(.success(1))` returns `false` |
| race-box-005 | value-after-settle, value-repeatable | Settled box holding `.success(5)`; call `value()` twice | Both calls return `5` without suspending |
| race-box-006 | winner-decided-atomically | New box; 100 tasks each call `finish` with a distinct value at once | Exactly one call returns `true`; `value()` returns the value of that caller |
| race-box-007 | value-register-atomic | New box; one task calls `value()` while another calls `finish` at the same moment, repeated many times | Every `value()` returns the winning outcome; none hangs and none crashes with a double resume |
| race-box-008 | losers-not-awaited, release-all-waiters | A box raced by a work task that never returns and a timer that calls `finish(.failure(timeout))`. Source test: `deadlineIsPromptEvenWhenTheOperationIgnoresCancellation` in `GoogleOAuthTests.swift` | `value()` throws the timeout error promptly; the work task is still suspended |
| race-box-009 | first-finish-wins | Work and timer both race; the work finishes first with `.success(42)`. Source test: `deadlineReturnsOperationResult` | `value()` returns `42`; the timer's later `finish` returns `false` and cancels nothing |
| race-box-010 | never-settled-never-returns | New box; a task awaits `value()`; no `finish` is ever called | The task stays suspended; `isFinished` stays `false` |
| race-box-011 | value-not-cancellable | New box; a task awaits `value()` and is cancelled; no `finish` is called | The task stays suspended; it ends only when some `finish` wins |
| race-box-012 | resume-outside-lock | A waiter's continuation calls `isFinished` and `value()` as soon as it resumes | Both return at once; no deadlock |
| race-box-013 | first-finish-wins, losers-not-awaited | `MailIntegrationService.stop(timeout: .milliseconds(200))` with a sync that outlives the timeout. Source test: the stop-bound test in `MailIntegrationServiceTests.swift` | `stop` returns after at least 150 ms and under 5 s, not when the sync ends |

