
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

separation-of-concerns passes: validation and derivation orchestration live here while storage is the persistence contract and rate resolution, rounding and derivation are their own types. unit-test-coverage fails: only `BillingRate` (via `BillingRateResolutionTests`) is tested directly; no test in `AgenticDeveloperHubSDKCoreTests/Billing` calls `BillingStore` save, delete or `deriveSegments`.

