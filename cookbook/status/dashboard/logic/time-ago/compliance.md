
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |

`unit-test-coverage` passes: `time-ago.test.ts` asserts every bucket and every bucket
boundary. `separation-of-concerns` passes: the file only formats, and it leaves the clock
to `useNow` and the surrounding wording to the components. `good-test-properties` passes:
the tests use a fixed `BASE` instant and no real clock, so they are fast, isolated and
repeatable. `explicit-error-handling` is partial: an unparseable timestamp is not checked
and instead comes out as the visible string `NaNd`, which is never thrown or reported to
the caller, and no test covers that path.

