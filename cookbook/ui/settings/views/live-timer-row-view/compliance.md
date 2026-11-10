
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Separation-of-concerns is passed: the row only renders a model and reports stop, the clock is injected and scheduling lives in the separate ticker. Unit-test-coverage is passed: `LiveTimerRowViewTests.swift` covers title and subtitle, hidden subtitle, the clock, a backwards clock, update, stop, identifiers, ticker delivery and idempotent start, and origin tooltips.

