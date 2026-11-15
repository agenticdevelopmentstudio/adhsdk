
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | user-safety |

separation-of-concerns passes: the file holds two shapes and a factory; session state is the daemon's and terminal injection is the app's. unit-test-coverage is partial: `OversightActionDTOsConformanceTests` covers vectors 001 to 003 and 006 to 011, vector 012 is `testV012_resultForFailedHasEmptyStatusAndTheMessage` in `OversightActionServiceTests`, and vector 013 is `testV013_actOnFindingNon2xxHasEmptyStatusAndRouteErrorOrHTTPCode` in `StenographerHTTPClientTests`. Vectors 004 and 005 are skipped because the consumer that gates injection on `actionable` and on the injector's terminal support is app code that these DTOs do not contain. safe-defaults passes: the `blocked` target is non-actionable with empty fields, so the absence of data never reads as permission to act.

