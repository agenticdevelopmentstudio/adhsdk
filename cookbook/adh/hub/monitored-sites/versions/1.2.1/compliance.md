
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | failed | Access Patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | failed | Reliability |

`separation-of-concerns` passes: `monitored-sites.ts`/`wire.ts` contain zero UI or presentation code —
both files are the public data-domain surface consumed by the separate Dashboards presentation layer.
`unit-test-coverage` is `partial`: of the twelve exported functions plus three mappers,
`monitored-sites.test.ts` covers only the three mappers (`toGroup`, `toSite`, `toEndpoint`); none of
`listGroups`/`createGroup`/`updateGroup`/`deleteGroup`/`listSites`/`createSite`/`updateSite`/`deleteSite`/`listEndpoints`/`createEndpoint`/`updateEndpoint`/`deleteEndpoint`
has a dedicated test in this checkout. `explicit-error-handling` passes: nothing in this file swallows an
error — every failure either throws `AuthHttpError` (via the shared `authedFetch`) or propagates
unmodified. `server-side-authorization` passes: the module contains no client-side permission check of any
kind, per `owner-scoping-server-side`, deferring owner/workspace scoping entirely to the backend.
`error-response-handling` is `partial`: every call exposes a status and optional code for the caller to
branch on, but no function in this file offers per-code handling of its own (no `rethrowConflict`, no
`isNotFound`/`isConflict` branch) — every failure surfaces as the generic `AuthHttpError` propagation.
`pagination-support` fails: `listGroups`, `listSites`, and `listEndpoints` all return unpaginated
collections with no limit/cursor parameter, against a backend the source's own comment documents as
capping generic-CRUD lists at 500 rows, with no truncation signal to the caller. `graceful-degradation`
fails: unlike a sibling client's documented fallback constant, this module offers no fallback of any kind
when a call fails — every failure is an unhandled rejection with no degraded-but-functional path.

