
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |

**Unit Test Coverage**: `use-activity-history.dom.test.tsx` beside the hook covers disabled fetching, paging from the live tail's oldest row, the `before`/`beforeId` cursor pair, de-duplication, the MAX_AUTOPAGE_FETCHES budget, discarding history on disable, dropping a page that lands after a discard, error reporting without exhaustion, clearing the error on the next attempt, keeping the cursor after a failure, the shed-absorption guards (paged-only, OLD-end only, never `progress`, empty window as outage), and incoming-copy-wins replacement. The tests isolate the network by stubbing the global `fetch` that the default `useStatusApi()` client calls.

**Separation of Concerns**: The hook separates state management (useState for render-driven fields, useRef for stable-identity closures), side effects (shed absorption useEffect, cleanup on unmount), networking (fetch, timeout, abort), and data transformation (merge, sort). Each concern is addressable independently; a port can replace the networking layer without touching state logic.

