
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | partial | user-safety |

The namespace holds data and builds values; seeding, scheduling and storage live in the controller, coordinator and store, so separation of concerns passes. Tests assert the id list, the step names, the fix step's commit and no-push wording, the guidelines' tool names and range fallback, and the reset to default, and `PartnerJobDefaultsConformanceTests` (Core/Partner) covers all 17 vectors, including the other step fields, the 1800-second timer, the disabled default and the exact texts, so unit-test coverage passes. Known debt: the test `defaultsHaveTheTwoBuiltInJobs` asserts one job; its name is stale from before the general job was retired, and vector 001 follows its assertion. Safe defaults are partial: the job is disabled and the fix step never pushes, but the terminal step skips permission prompts by design.

