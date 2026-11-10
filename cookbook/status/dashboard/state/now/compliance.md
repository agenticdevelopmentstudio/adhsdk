
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.performance.resource-efficiency](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d5fe7b8e-1051-5581-b2c5-1adae8fdd5fc) | passed | performance |

The hook does one thing — supply a stable, periodically refreshed timestamp — and leaves formatting and staleness logic to callers, so separation of concerns passes. There is no dedicated test file for `use-now.ts`; it is exercised only indirectly through `use-board.dom.test.tsx`, so unit test coverage is partial. Resource use passes: the timer is cleared on unmount and on interval change, and the coarse default limits re-renders, though every caller holds its own timer.

