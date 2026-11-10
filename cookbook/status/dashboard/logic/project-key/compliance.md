
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

**Separation of concerns.** The module owns only project identity and de-duplication. It knows nothing about environments, domains, React state or the network; the provider, review modal, picker and bulk-ignore surfaces import it instead of formatting keys themselves.

**Unit test coverage.** No test file in `status-web` exercises `projectKeyOf` or `uniqueByProject`, so first-seen ordering and key format are unverified by tests.

**Explicit error handling.** Both functions are total over their typed inputs and have no failure path to handle; nothing is caught or swallowed.

