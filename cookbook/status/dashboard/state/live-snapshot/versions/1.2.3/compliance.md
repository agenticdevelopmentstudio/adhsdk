
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | passed | reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | reliability |
| [adc.check.performance.resource-efficiency](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d5fe7b8e-1051-5581-b2c5-1adae8fdd5fc) | passed | performance |

**Unit Test Coverage**: The tests cover `isSameSnapshot`, stream open and snapshot ingestion, the schedule frame, the manual-check spinner and its long backstop, the absence of an immediate re-read after a started check, and the `CLOSED` versus `CONNECTING` reconnect paths. Nothing asserts `liveError`, `offline`, `disconnected`, `blind`, overlapping checks, or two-client isolation.

**Separation of Concerns**: Transport sits behind `StatusApiClient`, caching behind React Query, and board derivation in `useBoard`. This module only moves snapshots and connection state.

**Explicit Error Handling**: Poll failures are recorded in `liveError` and surfaced. Malformed frames are dropped by declared design, and a failed manual check is folded into the not-started path with no signal to the caller.

**Graceful Degradation and Error Recovery**: A dead stream falls back to the poll with an immediate re-read, and a permanently closed stream is recreated every 3 s while referenced.

**Idempotent Operations**: `ingestOnce` folds re-delivered and duplicated frames exactly once across all mounted hooks and StrictMode double effects.

**Timeout Handling**: The check spinner is bounded by `CHECK_SAFETY_MS`, but neither request has a client timeout.

**Resource Efficiency**: One ref-counted connection per client, the poll gated off while streaming, and `reconnect` kept as a GET so retry loops never trigger a provider fan-out.

