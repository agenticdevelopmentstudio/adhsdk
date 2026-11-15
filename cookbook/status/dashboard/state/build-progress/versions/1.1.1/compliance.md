
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.performance.progress-indication](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6ba6685b-9d35-5eb2-96e7-afbccd1e5848) | passed | performance |

The hook computes progress only; rendering lives in `BuildProgressBar` and filtering in `OverviewTab`, so concerns are separated. `use-build-progress.test.ts` covers the in-flight predicate, settle, server expiry, the absent client clock, the mixed cohort with the 2-second hold, and non-build rows; it does not cover hold cancellation by a new build, a row leaving the feed, or unmount cleanup, hence partial. The hook supplies determinate progress (completed/total, integer percent) for the build bar.

