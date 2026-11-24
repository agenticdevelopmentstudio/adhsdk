
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |

**Separation of concerns.** The module owns only the selection rule; rendering, confirmation and deletion live in `StaleMonitorsBanner` and the API client.

**Unit test coverage.** `stale-monitors.test.ts` covers inclusion, the inclusive 7-day boundary, status and missing-onset exclusion, malformed timestamps, DNS neutrality, the status-code detail and sort order.

**Explicit error handling.** A malformed timestamp is handled by an explicit `Number.isFinite` guard rather than an exception or a silent pass-through.

**Data integrity.** A row is offered only on a parseable server-truth `downSince`, so no live monitor can be surfaced for deletion on data the function cannot judge.

**Graceful degradation.** Missing onset, unknown status or empty input yields fewer or no rows, never an error; the banner then renders nothing.

