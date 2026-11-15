
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |

**Separation of Concerns**: The module holds no presentation and no data shaping. The base path and transport live in the API client, caching and the loading state machine in the shared cache, the message extraction in `errorMessage`, and the rendering in the analytics and errors views.

**Unit Test Coverage**: `use-dashboards.dom.test.tsx` beside the module exercises the poll-interval function, the error-state interval rule, the keep-previous behavior, the request paths, the error messages and focus refetch across all 20 conformance vectors.

**Explicit Error Handling**: A non-ok status, a network rejection and a JSON parse failure each reject the read function and surface through the read's `error`; none is swallowed, and the backend's message is carried when it has one.

**Timeout Handling**: The module sets no timeout and passes no abort signal, so a hung request leaves the read fetching until the browser ends it, though it leaves no inconsistent state behind.

**Graceful Degradation**: A failed refetch keeps the last good body on screen and drops the poll to the settled pace, so a failing backend is neither blanked nor hammered.

