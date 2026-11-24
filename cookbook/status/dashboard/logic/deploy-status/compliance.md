
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |

**Separation of concerns.** The module holds only vocabulary and mapping rules. Fetching, storage, demotion timing and display wording live in other modules.

**Unit test coverage.** `deploy-status.test.ts` covers both provider mappers and every `combinedStatus` branch, including the `unknown` precedence. `deploy-status-parity.test.ts` checks the full phase space against the server. `deployStatusInFlight` and `IN_FLIGHT_STATUSES` have no direct test in the given sources.

**Explicit error handling.** No function throws. Unrecognized provider strings map to `"building"` by design, with no log or signal at this layer. That is partial: the claim is bounded downstream by the confirmation window, not here.

**Data integrity.** The parity test keeps the browser and server from interpreting the same phases differently, and `unknown` can never be reported as in progress.

**Graceful degradation.** Unexpected provider values degrade to an in-flight reading that the dashboard later demotes, rather than to a crash or a false verdict.

