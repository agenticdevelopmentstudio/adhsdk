
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | security |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | partial | security |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | access-patterns |

Each of the five Apple files has one clear responsibility (data shapes,
shared notes sub-rail, and three thin per-collection topic providers that
each only render/dispatch and delegate persistence to the injected
`InvitationsDataSource`), and the web side splits wire types from the
request-shaping client the same way — **separation-of-concerns** passes.
**unit-test-coverage** is partial: `InvitationsTopicsTests.swift` exercises
all three Apple topics and the shared notes rail with twelve test methods,
but no test file exists anywhere in this repo for `invitations.ts`/`wire.ts`,
and grepping the repo turns up no consumer of `invitationsApi` either — its
own consumer, and any tests for it, live outside this repo.
**explicit-error-handling** is partial: the Apple side wraps every error
uniformly through `HubError.wrap`, and three of the web side's four methods
handle their own failure path explicitly, but `preview`'s bare `fetch` call
is not guarded against a network-level failure despite the source's own
"Never throws" doc comment — the
**preview-network-failure-rejects** requirement. **secure-storage** passes: neither
`invitations.ts` nor `wire.ts` stores the `password`, `token`, or
`refreshToken` values they handle — they are forwarded and returned only,
per **token-and-password-handling** — so this component itself never needs,
and never uses, platform secure storage. **token-lifecycle** is partial: the
web client receives a `token`/`refreshToken` pair from `accept` and
`registerWithInvite`, but neither issues, refreshes, nor rotates them
itself, and lifetime/rotation policy is not defined anywhere in these two
given files — that responsibility belongs to the caller's own token store.
**no-pii-in-logs** passes trivially: none of the seven given sources
contains a single logging call, so no PII can leak through logging here.
**data-minimization** passes: every DTO and form on both platforms carries
only the fields its own screen or endpoint needs (contact fields, note
content, or the four `registerWithInvite` fields), with no superfluous data
collected. **error-response-handling** is partial: the Apple side handles
every `InvitationsDataSource` failure identically via `HubError`, but the
three divergent web strategies documented under **Error states** mean a
caller of `invitations.ts` cannot assume one uniform error shape across its
four methods.

