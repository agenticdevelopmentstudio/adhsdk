
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |

separation-of-concerns passes: the file declares shapes and their wire spelling only; evaluation, rendering, validation, storage and the LLM call live in the daemon. unit-test-coverage passes: `OversightScriptDTOConformanceTests` has one test for each of vectors 001 to 016, including the unknown-type errors, the `op` key spelling, the fixed-key independence from the key strategy and `OversightProviderSelection`. data-integrity passes because decoding is strict: an unknown discriminator or enum raw value fails loudly instead of producing a partial script.

