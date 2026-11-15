
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | performance |

**Separation of concerns.** The DTOs have no runtime dependencies, the ports are pure interfaces, the adapters each own one backend, and the composition root is the only place that picks adapters.

**Unit test coverage.** Partial: `local-cache.test.ts` covers `parseSnapshot` for round-trip, empty, malformed JSON and wrong-shape inputs. No test covers `liveSource`, `tursoSource`, the `localCache` I/O wrapper or the composition root.

**Explicit error handling.** Partial: the sources turn non-2xx responses into named `Error`s, and the cache turns every failure into `null` or a no-op. However, `localCache.save` drops write failures with no signal, which the source documents as intended.

**Graceful degradation.** The cached snapshot covers the gap before the first poll and during a brief outage, and the SSR guard keeps server render safe.

**Data integrity.** Partial: stored snapshots pass a top-level shape gate, but source responses are cast without validation, and the web and server copies of the DTOs have no mechanism keeping them in sync. Both are recorded as open questions under Behavioral Requirements.

**Caching strategy.** A single versioned key holds the latest snapshot. Every successful read overwrites it, and live data always takes precedence over the cache.

