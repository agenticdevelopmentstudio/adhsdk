
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

**Separation of concerns.** The module holds only the vocabulary, labels, order and guard. Judging problems (bad HTTP states, failed and stuck deploys, platform streaks) stays in the server file, and the client renders the server's verdicts.

**Unit test coverage.** Every conformance vector has a passing test in the module's own test suite: the full order and label map, the guard's accept and reject cases, the absence of the stuck-deploy threshold from the client, and parity with the server file (the test imports the server module and compares the exports).

**Explicit error handling.** The guard returns `false` for any non-member rather than throwing, and its predicate type makes callers branch on the result.

**Data integrity.** The label map's type guarantees every union member has a label in the reference implementation. Nothing in the type system ties the order list to the vocabulary, but a parity test compares the client's vocabulary, labels and order with the server's, so a source added on one side only fails that test instead of reaching the screen as an empty label.

