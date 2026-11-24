
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes because the types only hold values; routes, coding strategy and clamping belong to the HTTP client, `StenographerWire` and the daemon. `unit-test-coverage` is partial because `StenographerPreferenceDTOsTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Stenographer/StenographerPreferenceDTOsTests.swift`) covers every vector except stenographer-preference-dt-os-012 (public initializers used from another module), which is skipped: the test target imports the module with `@testable`, so a unit test cannot show that the initializers are public.

