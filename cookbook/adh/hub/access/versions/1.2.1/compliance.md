
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |

`separation-of-concerns` passes: `access.ts`/`wire.ts` contain zero UI or presentation code — both the
module's own top comment and `index.ts`'s comment describe it as the public surface of a data domain,
consumed by a separate presentation layer. `unit-test-coverage` is `partial`: of `accessApi`'s ten
methods, only `listFeatures` has dedicated unit tests (`access.test.ts`'s comment says as much
explicitly — every other consumer test mocks this package wholesale); `listRoles`, `createRole`,
`updateRole`, `deleteRole`, `listAssignments`, `putAssignment`, `deleteAssignment`, `restrictItem`,
`restoreItem`, and `effective` have none in this checkout. `explicit-error-handling` passes: nothing
in this file swallows an error — every failure either throws `AuthHttpError` (via the shared
`authedFetch`) or the plain validation `Error` `listFeatures` raises itself. `server-side-authorization`
passes: the module contains no client-side permission check of any kind, per `authorization-enforced-server-side`,
deferring membership, admin-only role edits, and the manage-access verb requirement entirely to the
backend. `error-response-handling` is `partial`: every call exposes a status and optional code for the
caller to branch on, but only `listFeatures`'s doc comment describes a specific, documented fallback
contract for one status (a `404` meaning "this backend predates the route") — and even that fallback
is implemented by the caller, not by this module; the other nine methods offer no per-code handling
beyond the generic `AuthHttpError` propagation. `graceful-degradation` is `partial`: `ACCESS_FEATURES`
exists as an explicit, documented escape hatch for exactly this situation, but `listFeatures` does not
apply it itself — degradation is opt-in by the caller, not automatic within this component, and no
other method offers a fallback of any kind.

