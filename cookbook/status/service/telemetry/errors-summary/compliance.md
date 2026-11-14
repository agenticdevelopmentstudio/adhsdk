
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |

The function holds one rule and nothing else: it takes no storage, network or clock, so
`separation-of-concerns` passes. `telemetry-errors-summary.test.ts` covers the split, the ordering and
cap, the unjudged row and the empty case, so `unit-test-coverage` passes; the falsy-count sort path
has no test. A pure function returns the same result for the same input, which is
`idempotent-operations`.

