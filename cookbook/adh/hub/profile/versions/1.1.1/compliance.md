
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | failed | Access Patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | failed | Access Patterns |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |

`separation-of-concerns` passes: `profile.ts`/`usage.ts`/`wire.ts` contain zero UI or presentation
code — all three files are, per `index.ts`'s own comment, the public surface of a data domain
consumed by a separate presentation layer (the Settings > Profile editor and the public UserCard).
`unit-test-coverage` is `partial`: `profile.test.ts` exercises `listSocialLinks`, `listAddresses`
(list and encoding only), `createSocialLink`, `updateSocialLink`, and `deleteSocialLink` with six
assertions, but `createAddress`, `updateAddress`, `deleteAddress`, `getPrivacyGrants`,
`setPrivacyGrant`, `resolvePrivacyLevel`, and every export in `usage.ts` have no dedicated test
anywhere in this checkout. `explicit-error-handling` passes: nothing in these three files swallows
an error — every failure either propagates from `authedJson`/`authedRequest` unmodified or is a
compile-time-only constraint (the wire types); per `violation-handling-inherited`, no `try`/`catch`
anywhere in `profile.ts`/`usage.ts` intercepts a rejection. `secure-storage` passes: this module
persists nothing of what it handles to any client-side store, per `no-client-side-storage-of-
sensitive-fields` — there is no insecure (or secure) storage of these fields to evaluate, only their
complete absence from any store. `error-response-handling` is `failed`: no function in
`profile.ts`/`usage.ts` maps any HTTP status to a friendlier error or a documented fallback (no
`isNotFound`/`isConflict`/`rethrowConflict` call anywhere in these two files); every failure surfaces
as the generic error `authedJson`/`authedRequest` throws, with zero per-status branching. 
`pagination-support` is `failed`: `listSocialLinks`, `listAddresses`, and `getUsageSummary` all
return unpaginated collections with no limit or cursor parameter and no truncation signal to the
caller. `data-minimization` passes: every write body carries exactly the caller-writable fields
`write-shapes-exclude-server-managed-fields` names, with the server managing identity, tenancy,
ownership, and sync fields; no extra field is collected or appended by this module. `no-pii-in-logs`
passes trivially: none of the three given sources contains a single logging call, so no PII can
leak through logging here.

