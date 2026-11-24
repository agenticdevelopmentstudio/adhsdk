
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | partial | performance |

`separation-of-concerns` passes: the type only builds the command, its environment and its limit; running, draining and stopping the process belong to `CommandRunner`. `unit-test-coverage` is partial: `ReadOnlyGitConformanceTests.swift` covers every vector except 005 (the five-second timeout needs real time to pass, so it is skipped); `GitContextFingerprintTests` also covers the trimmed and untrimmed forms through its caller. `timeout-handling` passes with a fixed 5-second limit and a stopped child. `explicit-error-handling` is partial: failures are surfaced as the empty string by contract, which is lossy by design and cannot tell a failure from empty output. `main-thread-freedom` is partial: the call blocks its calling thread for up to 5 seconds and relies on callers to keep it off the main thread.

