
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |

**Separation of Concerns**: The hook contains no presentation or computation. The base path and transport live in `StatusApiClient`, caching and the state machine in React Query, the uptime arithmetic in the backend and `lib/uptime.ts`, and the rendering in `Dashboard` and `OverviewTab`.

**Unit Test Coverage**: There is no `use-uptime.test.ts` or `use-uptime.dom.test.tsx` beside the hook, and the component tests that reach it mock it out, so the hook's fetch, key and error path are not exercised by any test.

**Explicit Error Handling**: A non-ok status, a network rejection, and a JSON parse failure all reject the query function and surface through the query's `error`, so none is swallowed. The server's error-body detail is not read.

**Timeout Handling**: The hook sets no timeout and passes no abort signal. A hung request leaves the query fetching indefinitely, though it leaves no inconsistent state behind.

**Graceful Degradation**: A failed refetch keeps the last successful data, and both callers fall back to an empty service list when no data exists, so the dashboard renders without uptime rather than failing.

