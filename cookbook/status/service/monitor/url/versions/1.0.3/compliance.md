
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |

`unit-test-coverage` is `failed`: the given source tree contains no test file that imports
or exercises `hostOf` or `projectPageUrl` — `status-server/test/peer-base-url.test.ts` is the
only URL-related test file in that directory, and it covers a different module; every
behavior in this recipe is derived from reading `url.ts` directly and from tracing its three
call sites (`deploy-view.ts`, `sync.ts`, `routes/reads.ts`), not from a passing assertion.
`separation-of-concerns` passes: this file owns exactly one concern — deriving a display host
and a stable project-page link from a URL string — with no rendering, storage, or network
code of its own; the files that call it each keep their own concern (link assembly, monitor
retirement, DTO mapping) separate from the URL parsing itself. `explicit-error-handling`
passes: both functions wrap their only failure-prone operation, the `URL` constructor, in an
explicit `try`/`catch` with a defined fallback — the original input string — rather than
letting a malformed URL propagate an uncaught exception to the caller; the caught error
object is discarded, but the fallback it triggers is a deliberate, documented passthrough
(per `projectPageUrl`'s own doc comment), not a silently ignored failure.

