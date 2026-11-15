
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | reliability |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

`separation-of-concerns` passes: the type only watches an exit and ends a process; collecting output and deciding what a timeout means belong to `CommandRunner` and the callers. `unit-test-coverage` is partial: `ProcessExitWatchConformanceTests.swift` covers vectors 002 to 008, 010 and 011; vectors 001 (a failed precondition ends the test process), 009 (no portable setup makes a process survive SIGKILL) and 012 (an inspection of the public interface) are skipped. `timeout-handling` passes: every wait takes a timeout and the stop sequence is bounded at two graces. `fault-tolerance` is partial: it works around the lost wake-up and reports an unkillable process, but concurrent waiters are not handled (the open question on `concurrent-waiters`). `explicit-error-handling` passes: an unkillable process is returned as false, and a caller error is a precondition.

