
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Separation-of-concerns is passed: the list only arranges rows and decides when the ticker runs; row rendering and scheduling are in the row view and ticker. Unit-test-coverage is partial: `LiveTimerListViewTests.swift` covers the empty message, stop visibility, row reuse, stop reporting, ticking only while seen and the no-window case; the real occlusion notification is not exercised.

