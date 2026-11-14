
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |

`separation-of-concerns` passes: the module only judges data it is handed and takes the clock as an argument, leaving probing, persistence, routing and rendering to other files. `unit-test-coverage` passes: `live-view.test.ts` covers every exported function and its boundaries; only the final `down` fallback and the empty-environment mapping are traced directly to source. `good-test-properties` passes: the tests use fixed timestamps and explicit `nowMs`, no real timers, and one concern per `it`. `fault-tolerance` passes: every malformed date has a defined result and no function throws.

`no-hardcoded-strings` is partial: the module builds the English `detail` text (`"down"`, `"HTTP <statusCode>"`) with no localization mechanism; the other strings are enum values, not text.
