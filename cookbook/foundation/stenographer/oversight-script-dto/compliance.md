
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |

separation-of-concerns passes: the file declares shapes and their wire spelling only; evaluation, rendering, validation, storage and the LLM call live in the daemon. unit-test-coverage is partial: the daemon's `ScriptPredicateTests` and `ScriptStoreTests` exercise the types through evaluation and the store (including the predicate round trip), but no test targets the unknown-type errors, the `op` key spelling, the fixed-key independence from the key strategy or `OversightProviderSelection` directly, so vectors 003, 006, 007, 012 and 014 follow from the source with no test of their own. data-integrity passes because decoding is strict: an unknown discriminator or enum raw value fails loudly instead of producing a partial script.

