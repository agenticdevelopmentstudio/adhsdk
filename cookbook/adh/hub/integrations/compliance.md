
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | Security |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | Reliability |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |

`separation-of-concerns` passes: `integrations.ts`/`wire.ts` contain zero UI or presentation code — both
files are a plain request-builder layer consumed by a separate presentation layer, per the module's own
top-of-file comment. `unit-test-coverage` is `failed`: none of `integrationsApi`'s twenty methods, nor
`decodeOAuthStateClaims`/`isOAuthStateFresh`, has a test file adjacent to `integrations.ts`/`wire.ts`
anywhere in this checkout — the closest exercise of `decodeOAuthStateClaims`/`isOAuthStateFresh` is an
indirect one, through a consumer component's own test (`IntegrationsOAuthCallback.test.tsx`), which is
outside this component's given sources. `explicit-error-handling` passes: every failure either throws
`AuthHttpError` (via the shared `authedFetch`) or is the explicit `isNotFound`-gated `null` return in
`getProviderConfig`/`getProviderConfigById`; nothing in this file catches and discards an error.
`input-sanitization` is `partial`: `decodeOAuthStateClaims`'s grammar and field-type checks
(`decode-state-claims-grammar`, `decode-state-claims-field-validation`) are real input validation, and
`isOAuthStateFresh` adds a documented freshness check on top — but neither is authoritative
(`decode-state-claims-never-verifies-signature`), and every write method (`putProviderConfig`,
`createProviderConfig`, `connect`, and the rest) forwards its caller-supplied body with no client-side shape
or charset validation of its own, deferring entirely to the backend. `secure-storage` is `partial`: the OAuth
client secret and GitHub App private key are never returned in plaintext by this client (`secrets-are-write-only`),
and `integrationsApi` itself persists nothing (`no-client-side-cache`) — but the deliverability
webhook secret is passed through unredacted on every read that carries it
(**webhook-secret-visibility-after-mint**).
`idempotent-operations` is `partial`: `adoptInstallations` is explicitly documented safe to call more than
once (`adopt-installations-idempotent`), but `rotateWebhookSecret` is explicitly *not* idempotent by design
(each call mints a new secret), and `connect` sends every repeat call with no idempotency key
(**connect-repeat-call-ordering**). `error-response-handling` is `partial`: every call exposes a status and
optional code for the caller to branch on, and two specific codes are documented by name in this client's own
comments (`404` → `null` for the two get-by-id lookups, `503` → "no worker" for `sync`), but every other
method offers no per-code handling beyond the generic `AuthHttpError` propagation.

