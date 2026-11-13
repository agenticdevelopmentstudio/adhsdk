
All vectors use a stopped clock unless they say the clock moves. Vectors marked "Derived" follow from the source arithmetic; the others come from `GmailRESTClientTests`, the only test file that exercises the pacer (`eachCallWaitsForTheQuotaItCosts` and `theBurstAllowanceGoesOutWithoutWaiting`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pacer-001 | burst-allowance-free, wait-formula, drain-advance | Test `theBurstAllowanceGoesOutWithoutWaiting`: rate 10, burst 10; `reserve(5)`, `reserve(5)`, `reserve(5)` | `.zero`, `.zero`, then 500 ms |
| pacer-002 | zero-burst, wait-formula, reserve-returns-wait | Test `eachCallWaitsForTheQuotaItCosts`: rate 5, burst 0; `reserve(1)` then `reserve(2)` | 200 ms, then 600 ms (the 2-unit call waits 0.2 s of backlog plus 0.4 s of its own) |
| pacer-003 | no-sleep, reserve-returns-wait | Derived: rate 5, burst 0, stopped clock; time one `reserve(5)` call | The call returns 1 s immediately; it does not suspend for that second |
| pacer-004 | shared-defaults, burst-allowance-free | Derived: rate 200, burst 200; `reserve(50)` four times | `.zero` each time |
| pacer-005 | shared-defaults, wait-formula | Derived: rate 200, burst 200; `reserve(50)` five times | The first four `.zero`; the fifth 250 ms |
| pacer-006 | idle-credit-capped, drain-advance | Derived: rate 10, burst 0; `reserve(10)` returns 1 s; clock then moves 5 s; `reserve(10)` | 1 s, because the stale backlog is replaced by the current time and credit is not banked |
| pacer-007 | zero-units | Derived: rate 10, burst 0; `reserve(10)` returns 1 s; then `reserve(0)` on the same instant | 1 s; `drainedAt` is unchanged |
| pacer-008 | zero-units, wait-never-negative | Derived: fresh pacer, rate 10, burst 0; `reserve(0)` | `.zero` |
| pacer-009 | nanosecond-rounding | Derived: rate 3, burst 0; `reserve(1)` | 333,333,333 ns on Swift; a port rounds to its own finest `Duration` resolution |
| pacer-010 | wait-never-negative | Derived: rate 10, burst 100; `reserve(5)` | `.zero`, not a negative duration |
| pacer-011 | clock-injected, clock-read-once | Derived: pass `now` as a closure that returns a fixed instant and counts calls; `reserve(1)` | One call to `now`; result is 1 unit divided by rate minus the burst time, floored at zero |
| pacer-012 | rate-precondition | Derived: construct with `unitsPerSecond` 0 | The process traps with "the pacer needs a positive rate" |
| pacer-013 | rate-precondition | Derived: construct with `burstUnits` -1 | The process traps with "the pacer needs a positive rate" |
| pacer-014 | serialised-reservations | Derived: rate 10, burst 0, stopped clock; ten concurrent `reserve(1)` from a task group | The returned waits are the ten distinct values 100 ms, 200 ms, up to 1 s, in some order |
| pacer-015 | reservation-final | Derived: rate 10, burst 0; `reserve(10)`, the caller is cancelled during its sleep, then `reserve(10)` on the same instant | 1 s, then 2 s; the first reservation's units are still counted |
| pacer-016 | cost-table, cost-type | Derived: read each `GmailQuotaCost` constant | profile 1, labelsList 1, historyList 2, messagesList 5, messagesGet 5, threadsGet 10, messagesBatchModify 50 |
| pacer-017 | shared-process-wide | Derived: read `GmailQuotaPacer.shared` twice | The same instance both times; a reservation made through one read is seen by the other |
| pacer-018 | units-nonnegative | Derived: rate 10, burst 0; `reserve(10)` returns 1 s; `reserve(-5)` | 500 ms: the unvalidated negative value shortened the backlog by half; this records the code, not a designed refund |

