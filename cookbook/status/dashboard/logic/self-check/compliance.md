
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

The module passes separation-of-concerns: it holds only the derivation from report to view, with rendering in `SelfCheckBanner.tsx` and fetching in the integrations hook. `self-check.test.ts` covers the loading null, the all-ok null, warn and error missing env with dedupe, the cron exclusion, the correlated collapse and a lone warning, so unit-test-coverage passes; the empty-array and ok-state-with-missing-env paths are untested but follow directly from the filter. The tests are small, deterministic and independent, each built from the `check` and `report` fixture factories, so good-test-properties passes. explicit-error-handling passes because the function is total over its typed input and has no error path to swallow; a malformed report is a typed caller precondition.

