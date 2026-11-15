
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |

**Separation of concerns.** The module is one pure parsing function with no React, DOM or I/O. Presentation choices, such as empty-label fallbacks and lowercasing, stay with the calling components.

**Unit test coverage.** There is no `url.test.ts`. `row-detail.test.ts` reaches `hostOf` only indirectly through `rowDetail` titles, and no test asserts the fallback, empty-host or port behavior.

**Explicit error handling.** The parse error is caught on purpose and mapped to a documented fallback, so nothing throws. The catch is bare, though: the error is dropped without logging, and the return value cannot tell a caller whether parsing failed (host-of-failure-indistinguishable).

**Graceful degradation.** Unparseable input still produces a usable label (the original string) instead of an exception or a blank, so board rows render when a URL is malformed.

