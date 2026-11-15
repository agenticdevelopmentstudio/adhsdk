
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

**Separation of Concerns**: The module holds shapes and four constants only; derivation lives on the server and layout in the pages.

**Unit Test Coverage**: `dashboard-types-parity.test.ts` covers all 10 vectors (`dtypes-001`, `002`, `003`, `009`, `012`, `015`, `016`, `017`, `018`, `025`): the four lists, the five agreeing types, the section and envelope key sets and the load-time exports. The module has no other behavior to test.

**Good Test Properties**: The parity test is deterministic, has no I/O and checks one thing per case.

**Data Minimization**: No shape carries a user identifier.

