
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | partial | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |

`separation-of-concerns` passes: the function only judges an already-computed list, leaving probing and debounce to `integrations.ts` and `self-check-stability.ts` and rendering to the dashboard. `unit-test-coverage` fails: no test file for `self-check.ts` exists, and the rule it owns, once duplicated in the dashboard, is now covered by no assertion. `good-test-properties` is partial: the function is pure and trivially testable, so it would be fast and isolated, but there is no test to confirm it. `fault-tolerance` passes: the function is total over any well-typed array and never throws, including for an empty one.

