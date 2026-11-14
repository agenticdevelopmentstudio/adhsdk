
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: spawning and the per-session lock are each one small type with no knowledge of what is fed. unit-test-coverage is partial: `DetachedProcessTests` covers the payload, the reparenting, the lock's contention, sanitising and fallback, but nothing exercises a failed `posix_spawn`, a failed payload write or a 128-scalar session id.

