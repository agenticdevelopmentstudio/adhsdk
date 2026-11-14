
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | passed | privacy-and-data |

`separation-of-concerns` passes: the store holds state, scopes and notification, while defaults, normalisation, storage access and DOM mapping sit in `appearance.ts` and the pre-paint module, shared with the pre-paint script. `unit-test-coverage` is `partial`: the scope tests, `AppearanceScope.test.tsx` and `clearAppearance.test.ts` cover scoping, OS following and clearing, but no test covers the hook, `set` merging, the server snapshot, the missing-`matchMedia` guards or a failing `localStorage`. `explicit-error-handling` is `partial`: storage failures are swallowed deliberately and with a comment, and neither the store nor the helpers signal them, though the in-memory state stays correct. `graceful-degradation` passes: a missing `matchMedia`, a missing `addEventListener` and an unavailable `localStorage` all fall back to the OS-light or in-memory behavior without throwing. `data-retention-policy` passes: the cache is removed on sign-out by design and its lifetime is stated.

