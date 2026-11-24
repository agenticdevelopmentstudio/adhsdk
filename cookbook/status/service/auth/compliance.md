
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.secure-authentication](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1d5c23d5-9a26-57fb-a23d-358271e4204a) | passed | Security |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | passed | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | failed | Security |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |

`secure-authentication` passes: GitHub OAuth 2.0 authorization-code flow,
implemented as a confidential (server-side) client — the `client_secret` is
exchanged only in `exchangeCode`'s server-to-server POST and never reaches
the browser, per the source's own comment. This check's PKCE requirement is
scoped to public clients; a confidential client authenticating with a
server-held secret is the case PKCE exists to substitute for, so its
absence here does not violate the check. `server-side-authorization`
passes: tier/role resolution happens entirely in `authenticate` and the
external `requireAdmin` binding, never trusted from the client.
`secure-storage` passes for what these five files themselves do: passwords
are bcrypt-hashed before crossing into storage, never held or returned
plaintext beyond one call; the `AuthStore` port's own documented contract
(external) states only a session token's sha256 is persisted, never the
raw value. `input-sanitization` passes: the only external strings these
files evaluate as more than opaque comparison values (`code`, `state`,
GitHub profile fields) are never interpolated into a query, shell command,
or rendered markup. `secure-transport` passes: every outbound GitHub call
targets a hardcoded `https://` origin. `secure-log-output` passes trivially
— per Logging, there is no log output to leak anything into.
`token-lifecycle` fails as written: the session cookie's `maxAge` is a
fixed 30 days, and neither the session cookie nor the `sts_` API token has
a refresh-rotation mechanism in these files — both are long-lived,
revocable credentials, not the short-lived-with-rotation shape this check
requires; see the Design Decisions entry above for the tradeoff, recorded
as fact rather than defended. `separation-of-concerns` passes: `port.ts`
defines the contract, `default-adapter.ts` the one implementation,
`github.ts` and `password.ts` are independent concerns the adapter and
external routes call into, and the Hono-status-code translation lives one
layer up, outside all five files. `unit-test-coverage` passes: the
sibling `test/` suite exercises the gate's resolution order
(`auth-gate.test.ts`, `auth.int.test.ts`), the GitHub OAuth flow including
its concurrency race and timeout (`github-oauth.int.test.ts`), and edge
cases (`auth-edge.int.test.ts`). `explicit-error-handling` is `partial`:
every GitHub HTTP failure maps to a specific status, but a failed
`/user/emails` fetch is not surfaced as an error at all — it silently
degrades to a `null` email and a synthetic account, a deliberate choice
(see Edge Cases) rather than an oversight, but it is still a case where a
dependency failure produces no distinguishable signal from "GitHub simply
has no public email for this user." `timeout-configuration` passes:
`ghFetch` bounds every outbound GitHub call with `AbortSignal.timeout`,
configurable via `config.github.fetchTimeoutMs`. `no-pii-in-logs` passes
the same way `secure-log-output` does — there is no log output in these
files to carry PII.

