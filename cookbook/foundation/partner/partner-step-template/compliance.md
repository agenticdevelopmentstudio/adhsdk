
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |

`separation-of-concerns` passes because the type only substitutes and quotes text; deciding what values to supply and running the command belong to the callers. `unit-test-coverage` passes: `PartnerModelsTests` covers vectors 001-006 and `PartnerStepTemplateConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Partner/PartnerStepTemplateConformanceTests.swift`) covers 007-014. `input-sanitization` is partial: values reach a terminal step as one quoted word, but a Claude-step prompt receives them as written by design, and the type is not a general sanitizer.

