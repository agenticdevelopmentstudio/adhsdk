
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`separation-of-concerns` passes because the types only name things and resolve which directory exists; creating directories, registering with launchd and opening the keychain stay with callers. `unit-test-coverage` fails because no test targets these types directly: the only test that touches them is `ADKDIdentifiersTests`, which uses them as the comparison side of a collision check, so directory resolution, `writeSupportFile` and the legacy paths have no assertion.

