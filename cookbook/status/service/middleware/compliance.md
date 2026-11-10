
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.access-patterns.rate-limit-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/aed555ee-66e3-5f99-88ab-24674ed5c789) | passed | Access Patterns |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |

`server-side-authorization` passes: `tier` is set exclusively from the
injected `AuthGate`'s resolution, and `requireAdmin` compares only that
server-set context value — no header, cookie, or query parameter is ever
trusted as a tier claim. `secure-log-output` passes: the one log statement
in these two files (the hard-cap drop) carries only a count and a fixed
threshold, never a key, IP, or credential; `auth.ts` logs nothing at all.
`rate-limit-handling` passes: the pre-auth credential routes are capped
per-key with a fixed window, a defined `429` response, and a computed
`Retry-After` header a client can act on. `error-response-handling` passes:
every rejection in these two files resolves to one specific, distinguishable
status (`401`, `403`, `429`) with a JSON body, never a generic failure or a
silent pass-through. `separation-of-concerns` passes: `auth.ts` only
translates a gate's resolution into HTTP and never resolves a credential
itself; `rate-limit.ts` only counts requests and knows nothing about
authentication. `unit-test-coverage` passes: `auth-gate.test.ts` exercises
`requireAuth`'s 200/401 split directly, `rate-limit.int.test.ts` exercises
the limiter's cap, recovery, and IP-spoofing resistance, and
`auth.int.test.ts`/`api-tokens.int.test.ts` exercise `requireAdmin`'s 403
path end-to-end. `explicit-error-handling` is `partial`: every rejection
these two files themselves produce is explicit, but `requireAuth` does not
wrap its `await gate.authenticate(c.req)` call in a `try`/`catch`, so a
rejected gate promise (a dependency failure, not an unauthenticated caller)
propagates uncaught rather than being mapped to a specific status by this
file — a deliberate scope boundary per the `AuthGate` contract (see Edge
Cases), but still a case where this file itself does not produce the final
error response. `data-minimization` passes: `rate-limit.ts` retains only
the derived IP key and a count/reset timestamp per bucket — no request
body, path, or other request data is captured by the limiter — and `bearer`
returns a substring of one header with no further extraction.

