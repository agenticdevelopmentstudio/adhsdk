
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

separation-of-concerns passes: derivation is pure; clocks, parsing and splitting are shared utilities and the caller supplies `now`. unit-test-coverage passes: `BillingDerivationTests` covers splitting, the cutoff boundary, sleep, open and closed final runs, lead-in, out-of-order, unparseable and malformed inputs, and fractional stamps.

