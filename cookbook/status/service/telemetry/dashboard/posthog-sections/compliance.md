
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.access-patterns.rate-limit-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/aed555ee-66e3-5f99-88ab-24674ed5c789) | partial | Access Patterns |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |

Query building, shaping and transport are separate, with pure shapers and a closed set of interpolated values. The tests cover the traffic, dimension, vitals, health and detail shapers, the production filter, UTC, truncation, failure and the one-at-a-time rule; the paths loader, the row caps, the closed query inputs and the 45 second timeout are covered in `telemetry-posthog-sections-queries.test.ts`, so every vector has a test. Every query has a 45 second timeout. Concurrency is kept to one query at a time, which avoids the 503 but there is no retry or backoff here, so rate-limit handling is partial; a failed section is retried by the section cache on its own schedule.

