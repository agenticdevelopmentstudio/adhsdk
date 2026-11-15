
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | reliability |

**Separation of Concerns**: The hook has no presentation code. The base path and transport live in `StatusApiClient`, caching and the state machine in React Query, periodic refresh in `useRefreshAll`, and rendering in `SelfCheckBanner` and `computeSelfCheck`.

**Unit Test Coverage**: There is no `use-integrations.test.ts` or `use-integrations.dom.test.tsx` beside the hook. The `Dashboard` and `OverviewTab` DOM tests replace the module with a mock, so its own fetch and error paths never run in any test.

**Explicit Error Handling**: A non-ok status, a network rejection and a JSON parse failure all reject the query function and surface through the query's `error`, so none is swallowed. The server's error-body detail is not read, and neither caller renders `error`.

**Timeout Handling**: The hook sets no timeout and passes no abort signal. A hung request leaves the query fetching, but the cache entry just stays pending and nothing is left inconsistent.

