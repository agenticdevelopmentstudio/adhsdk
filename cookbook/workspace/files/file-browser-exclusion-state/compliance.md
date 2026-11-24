
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | performance |

The type does one thing, holds a boolean and reports its changes, and leaves
persistence to the owner and display to the file browser view, so it meets
separation-of-concerns. A search of the package's tests finds no test that
constructs it, so unit-test-coverage fails; the conformance vectors above are
derived from the source and no test asserts them yet. The object does no
blocking work (a property assignment and one closure call), which meets
main-thread-freedom.

