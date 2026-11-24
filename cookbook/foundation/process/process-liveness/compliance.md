
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.performance.resource-efficiency](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d5fe7b8e-1051-5581-b2c5-1adae8fdd5fc) | passed | performance |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |

`separation-of-concerns` passes: the type only reads the process table and a session file and answers questions; deciding what a missing process means is left to the caller. `unit-test-coverage` passes: every vector has a test in `ProcessLivenessTests.swift` (vectors 008 to 017 are the conformance additions, with the identity vector run against real copies of `sleep`); the pid scan, the directory read and the terminal-device test beyond those vectors need a kernel record and are left to integration checks. `graceful-degradation` passes: every kernel failure becomes nil or a skipped process and a bad scan is told apart from an empty one. `resource-efficiency` passes: the scan is user-only, the cheaper kernel path runs first and the real-path lookup is limited to `claude` processes. `explicit-error-handling` is partial: failures are returned as nil or skipped, which callers must read correctly, and nothing is logged.

