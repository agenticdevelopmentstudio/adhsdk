
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: the holder only binds keys to defaults; the key set, defaults and storage are injected or shared. unit-test-coverage is partial: `BillingUserSettingsConformanceTests` in `AgenticDeveloperHubSDKCoreTests` covers vectors 001 to 007 against an in-memory settings store. Vector 008 is skipped: the holder is `@MainActor`, so off-thread use is rejected by the compiler and cannot be exercised by a running test.

