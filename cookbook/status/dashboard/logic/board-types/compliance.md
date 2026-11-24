
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

The module contains only the wire contract, with fetching, derivation and rendering in other modules, so separation-of-concerns passes. `board-types-parity.test.ts` pins every exported type to the server by mutual assignability and checks the indicator mapping, so unit-test-coverage passes. Data-integrity is partial: the parity guard runs at compile time only, `pnpm test` transpiles without typechecking, and no runtime check rejects a payload that does not match the types, so an unknown union member reaches the UI unchecked.

