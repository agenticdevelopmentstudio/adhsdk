
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | performance |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | partial | security |

Separation of concerns is passed: transport, account lookups and rendering are injected, and the process spawning and locking sit in their own types. Unit-test coverage is partial: tests cover `feed`, `run` in both modes, `parentPID`, `FeedLock` and `DetachedProcess`, but none calls `feedOnce`, `detachFeed` or `injected`, so vectors `capture-022` to `capture-031` have no test yet. Graceful degradation is passed because a refused post becomes a drop file, a missing lock file becomes a no-op, a failed detach becomes an in-process feed and `--capture-only` always exits 0. Timeout handling is passed because the whole feed is bounded by a 20 second deadline and each step has its own. Main-thread freedom is passed because the feed runs on a global queue and the render returns before a detached feed starts. Token lifecycle is partial: the token is recovered per invocation and never written to a file, but it travels through the detached feed's environment, and the source states no limit on how long that process lives beyond the 20 second deadline.

