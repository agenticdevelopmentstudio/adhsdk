
| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`separation-of-concerns` passes because the extension does one thing, resolving a
window to the top of its parent chain, and leaves the decision of which command to
run to its callers. `unit-test-coverage` fails because the source has no test
beside it: no test file in the apple packages mentions `commandOwner`,
so the vectors above are derived from the body and doc comment alone.

