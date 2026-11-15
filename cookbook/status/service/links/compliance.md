
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |

**Separation of Concerns**: The module has a single responsibility — generating canonical links from configuration. Public functions are pure (no side effects), take only what they need as parameters, and return simple data structures. Concerns like platform canonicalization are delegated to the monitor submodule.

**Unit Test Coverage**: `test/links.test.ts` covers vectors links-001 to links-015, one test per vector.

