
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

**Unit Test Coverage**: `use-board.dom.test.tsx` covers verbatim pass-through, the absence of `localStorage` writes, server-side removal propagating, live-frame refetch, the `stale`, `frozen` and `no-data` verdicts, the fresh-board pass-through, and agreement between `usePortfolioIndicator` and `GlobalPanel` on a stale or wedged board. `board-staleness.test.ts` covers the threshold functions. The initial-load, HTTP-error and retry paths are not asserted by the hook's own tests.

**Separation of Concerns**: Transport sits behind `StatusApiClient`, caching and polling behind React Query, the staleness rules and thresholds in `lib/board-staleness.ts`, and the clock in `useNow`; the hook only composes them and applies the verdict in one place.

**Explicit Error Handling**: HTTP failures throw a descriptive `Error`, parse failures propagate, and both surface through `error` and `reason: "unavailable"`; nothing is swallowed.

**Graceful Degradation**: When the stream is down the poll keeps the board current; when the API or the monitor fails the hook degrades to `board: null` with a cause instead of showing a retained verdict as current.

**Timeout Handling**: The hook sets no request timeout. A hung read does not leave a stale verdict on screen because the verdict is clock-driven, but the request itself is bounded only by the transport or a later cancel.

**Data Integrity**: The three clock fields are checked and fail closed, but the rest of the response body is cast to `Board` without runtime validation; shape conformance relies on the server contract and the compile-time drift guard in `board-types-parity.test.ts`.

