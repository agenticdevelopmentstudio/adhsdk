
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |

**Separation of concerns.** The module holds only aggregation and correlation rules, with no I/O or rendering. The key derivation is owned by the shared canon package, and the staleness rule by the row model.

**Unit test coverage.** The module's test suite covers every status bucket, stale demotion, platform ordering, the no-target, Vercel, Railway and Cloudflare correlation paths, newest-first sorting, terminal selection and failure counting.

**Explicit error handling.** Unparseable clocks in the demotion path are caught by a finite-value guard that fails closed, not by an exception.

**Data integrity.** A single shared key function keeps client and server correlation in agreement. Every deploy is counted in `total`, so demoted and canceled rows are never lost from the count.

**Graceful degradation.** A missing probe interval falls back to the 600 000 ms floor. An endpoint without a deploy target yields empty results rather than a guess.

