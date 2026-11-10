
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | partial | performance |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | failed | reliability |

The module separates transport (the injected `StatusApiClient`), request shaping (the two fetch helpers) and caching (the React Query hook), which satisfies separation of concerns. No test exercises this module's own code; the only related test mocks `fetchUnconfigured` wholesale, so unit-test coverage fails. Every non-ok response becomes a thrown `Error` carrying the status and is surfaced to callers through promise rejection or query error state, so errors are explicit rather than swallowed. The caching strategy is deliberate (browser cache bypassed, 60 s client stale window, server 30 s cache bypassed on demand) but only partial, because an arm made while a fetch is in flight can be lost, leaving the next fetch cache-served contrary to the documented latch contract. No timeout is set on either request and React Query's abort signal is not forwarded, so a hung request stays pending indefinitely.

