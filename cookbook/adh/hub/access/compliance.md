
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |

`separation-of-concerns` passes: `access.ts` and `wire.ts` hold no UI code, and `index.ts` is
the public surface of a data domain consumed by a separate presentation layer.
`unit-test-coverage` is partial: `access.test.ts` and `access-target.test.ts` exercise every
operation, the fallback list, the refresh retry and the status and code carry-through, but
nothing asserts the `has_more` rejection in `listFeatures`, the row projection of
`listFeatures` and `listSubjects`, the multi-page walk of `listRoles`, or the empty-string
`itemId` omission in `effective`; vectors 031 to 035 are derived from the source for those.
`explicit-error-handling` passes: nothing in the module swallows an error, and every failure
throws either the shared HTTP error or a plain `Error` the module or its pager raises.
`server-side-authorization` passes: the module performs no client-side permission check and
defers membership, the admin-only role edit and the manage-verb rule to the backend.
`error-response-handling` is partial: every call exposes a status and optional code, but only
the `listFeatures` comment documents a per-status contract (a 404 meaning the backend predates
the route), the fallback is the caller's, and no other operation offers per-code handling.
`graceful-degradation` is partial: `ACCESS_FEATURES` is a documented escape hatch, but
degradation is opt-in by the caller and no other operation offers a fallback.

