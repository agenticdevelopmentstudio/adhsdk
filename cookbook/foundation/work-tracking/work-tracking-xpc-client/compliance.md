
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | reliability |

Separation of concerns passes: the client only translates the service interface to transport calls and wire coding; rules are the daemon's and the transport is injected. Unit coverage is partial: vectors 001 through 014, 016 and 017 are tested, by `WorkTrackingXPCClientTests` and `WorkTrackingXPCClientConformanceTests` (`WorkTracking/WorkTrackingXPCClientConformanceTests.swift`). Vector 015 is skipped: `WorkTrackingPreferences` holds only a Bool, a `[String]` and an Int, so no value of it can fail to encode. Timeout handling is partial: the two calls whose daemon answer is known to stall carry an explicit 15-second wait with the reason documented, but `status()` and `spans(since:limit:)` pass `.none` and leave the wait to the transport, which may be unbounded. Retry with backoff is not checked: the client never retries by design (`retries: 0`), see the no-retry design decision.

