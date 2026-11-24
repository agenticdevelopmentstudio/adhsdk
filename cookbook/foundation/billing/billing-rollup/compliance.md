
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

separation-of-concerns passes: rolling and entry rules live here while storage is the persistence contract, and rate, rounding, money and the local-day rule are shared types. unit-test-coverage passes: every conformance vector (17 of 17) has a test in `AgenticDeveloperHubSDKCoreTests/Billing/BillingRollupConformanceTests.swift`, run against the in-memory `InMemoryBillingPersistence`.
