
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |

`separation-of-concerns` passes: `gamification.ts`/`wire.ts` contain no
UI-rendering import and no business logic beyond building a path,
choosing an HTTP verb, and shaping a body — a clean, single-purpose
data-access layer consumed by a separate features package.
`unit-test-coverage` fails: no test file exists anywhere in the
repository adjacent to `gamification.ts` or `wire.ts` (confirmed by
search), unlike this package's sibling `hub-domain-ecosystem-config`
client, whose Apple counterpart has a dedicated test file even though its
web clients are likewise untested. `explicit-error-handling` passes:
every method lets `authedJson`'s rejection propagate untouched — there is
no `catch` anywhere in either file to silently swallow, so nothing is
ever discarded. `input-sanitization` is partial: `enc()`
(`encodeURIComponent`) sanitizes every dynamic URL segment against path
injection, but no field-level validation (comparator/tier enum
membership, `lengthDays` 1..366, event-type field length ≤64 chars, or
the level ladder's "start at 0, strictly increasing" shape) happens in
this module — every one of those documented constraints is enforced
only by the TypeScript compiler at the call site or by the backend's 400
response, per `levels-ladder-shape-enforced-serverside` and
`event-type-input-length-precondition`. `error-response-handling` is
partial: every operation's documented status codes (400/404/409) are
recorded in this file's own comments, but the client does not translate
any of them into a caller-facing message of its own — see the
`error-propagation-unmodified` Design Decision above; a caller must read
the raw `AuthHttpError` itself to act on a specific status.

