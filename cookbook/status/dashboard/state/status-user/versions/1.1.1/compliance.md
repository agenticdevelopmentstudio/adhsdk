
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | passed | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | failed | reliability |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | security |

**separation-of-concerns** passes. The adapter only reshapes the result, and fetch and cache semantics live in one query function in `header-auth.ts`.

**unit-test-coverage** is partial. `header-auth.test.ts` covers `fetchStatusUser` for 200 with a user, 200 with null, 500 and a network failure. Nothing tests the adapter itself or the query options (retry, stale time, keeping cached data).

**explicit-error-handling** passes. Non-OK responses throw with the HTTP status, and network errors propagate instead of turning into a sign-out. The adapter's choice not to expose the error is a documented projection, not a swallowed failure.

**error-recovery** and **graceful-degradation** pass. Transient failures retry 3 times with backoff while the last-known session keeps being shown.

**timeout-handling** fails. The request has no timeout or abort signal, so a hung `/auth/me` stays pending indefinitely.

**secure-storage** passes. The credential is an httpOnly cookie that the client never reads, and the user record is held only in memory.

