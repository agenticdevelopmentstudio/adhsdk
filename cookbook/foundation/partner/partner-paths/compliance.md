
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes because the type only computes locations; creating, reading and removing files is left to callers such as the guidelines installer. `unit-test-coverage` is partial: `PartnerProcessConfigurationTests` covers `pathsDeriveFromHomeAndToken` for the MCP config and skill file locations, and other suites use the type as a fixture, but no test asserts the system prompt, jobs, reviews or skills directory locations.

