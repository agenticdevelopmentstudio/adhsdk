
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

**Separation of concerns.** The module holds only the vocabulary, labels, guard and one mirrored constant. Judging problems (bad HTTP states, failed and stuck deploys, platform streaks) stays in the server file, and the client renders the server's verdicts.

**Unit test coverage.** The module's own test checks that `dns` is present with the label `"DNS"` and that every source has a label. The row-building logic's test checks the guard on `"cloudflare-pages"` and the source filter's default seed. No test covers the full order, the guard's rejection cases, the stuck-deploy threshold, or parity with the server file.

**Explicit error handling.** The guard returns `false` for any non-member rather than throwing, and its predicate type makes callers branch on the result.

**Data integrity.** The label map's type guarantees every union member has a label in the reference implementation. Nothing ties the order list to the vocabulary, and nothing checks the client against the server mirror, so a source added on one side only reaches the screen as an empty label.

