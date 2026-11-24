
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |

`separation-of-concerns` passes because the type only records and diffs ids; sending the push and deciding when it landed stay with the host. `unit-test-coverage` passes: `AIConfigPushLedgerTests` (`AIConfigPushLedgerTests.swift`) covers the first push, a dropped configuration, an unresolved configuration, a removal, key independence, malformed-id skipping, ordering, the stored format, a nil `removedConfigIds` and configs winning over removals. `AIConfigPushLedgerTests` covers the first push, a dropped configuration, an unresolved configuration, a removal and key independence; malformed-id skipping, ordering, the stored format and a nil `removedConfigIds` have no test. `idempotent-operations` passes because recording the same landed sync twice leaves the same stored set.

