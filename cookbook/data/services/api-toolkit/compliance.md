
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | security |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | security |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | access-patterns |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | failed | access-patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | access-patterns |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | failed | reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | internationalization |

The files are pure logic and headless hooks with no JSX or DOM access, and `server.ts` is separated from the client barrel, so separation-of-concerns passes. Unit-test-coverage passes because `conformanceVectors.test.ts` and `conformanceVectors.test.tsx` cover vectors 1 to 10, with `matchEndpoints.test.ts`, `tone.test.ts`, `exposure.test.ts`, `editability.test.ts`, `edits.test.ts`, `useCrudResource.test.tsx`, and `exitGuardChannel.test.tsx` beside them. Error handling is partial: status normalization, the `error` state, and the fail-closed gate are explicit, but the unguarded `fetch` call in `executeRequest` leaves transport failure to the caller. Server-side-authorization passes because the exposure gate is documented as presentation only and the server re-checks every request. Secure-transport is partial because `buildRequest` issues only same-origin `/api` requests and TLS comes from the hosting page. Timeout configuration and retry fail because `executeRequest` sets no timeout, no abort signal, and no retry; the single retry-on-401 lives in `@adh-sdk/auth`. Error-recovery fails for the same transport path. Data-integrity passes through the `listSeq` stale-response guard and the loud slug collision error. No-hardcoded-strings is partial because the token placeholder and the collision message are English literals.

