
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

**Separation of concerns.** The module owns only the vocabulary. Classification of deploy-backed kinds stays with the engine, and it re-exports rather than restating the engine's set.

**Unit test coverage.** No test file exercises `ENDPOINT_KINDS` or `isEndpointKind` in status-web. The re-exported `NON_DEPLOY_KINDS` is covered indirectly by the engine's `classify.test.ts`, which asserts `endpointNeedsWiring` for all six kinds.

**Explicit error handling.** The guard returns `false` for any non-member rather than throwing, and the result is typed as a predicate so callers must branch on it.

**Data integrity.** Within status-web the list, type and guard cannot drift apart. The status server restates the same list by hand with no parity test, and nothing checks that `NON_DEPLOY_KINDS` stays a subset of `ENDPOINT_KINDS`, so cross-package agreement rests on review.

