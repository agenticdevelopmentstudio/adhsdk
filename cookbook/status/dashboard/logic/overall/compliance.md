
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

Separation-of-concerns passes: the rollup is a pure, framework-free function in `src/lib`, apart from the components that display status and from the fetch code that loads `StatusResponse`. Unit-test-coverage passes: `overall.test.ts` checks each of the four return values, including the all-down boundary. Explicit-error-handling passes because the function has no failure path to hide: it neither catches nor throws, and a malformed argument that gets past the type system fails loudly with a `TypeError`. The client copy duplicates the server's `monitor/overall.ts` without the server's `publicOverall` step. That is recorded under Design Decisions and Edge Cases and is not a compliance failure.

