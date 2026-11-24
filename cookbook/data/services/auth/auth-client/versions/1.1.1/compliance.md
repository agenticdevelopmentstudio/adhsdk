
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | Security |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`secure-storage` is **partial**: the refresh token is deliberately never
persisted client-side and the CSRF nonce/return-to path live in
short-lived `sessionStorage`, but the access token and cached user object
sit in plaintext `localStorage` with no encryption — an accepted SPA
tradeoff (see Privacy), not full conformance. `input-sanitization` is
**partial**: `safeReturnTo` strictly validates and normalizes its one
security-sensitive input (the return-to URL), but credentials, MFA codes,
and OAuth codes/identifiers pass through every request body unvalidated by
this client, relying entirely on the server. `explicit-error-handling`
**passed**: every failure path in these 11 files either throws a typed
`AuthHttpError`/`Error` the caller can branch on, or (in `report.ts`) is an
intentional fail-safe swallow of a telemetry sink's own failure — no path
silently drops a primary operation's error. `fault-tolerance` **passed**:
the refresh single-flight/generation/resurrection guards, the loser-recheck
window, and `exchangeSsoCode`'s bounded retry all exist specifically to keep
concurrent and transient-failure paths from corrupting session state.
`data-minimization` **passed**: the refresh token is never collected;
`ErrorContext` is typed scalars-only. `no-pii-in-logs` **passed**: every
`console.error` call logs only an `Error` object and a declared
scalar-only context, never a request body or token. `no-hardcoded-strings`
**failed**: every user-facing string in `labels.ts`, `mfa.ts`, and
`client.ts`'s fallbacks is hardcoded English with no lookup table or locale
parameter anywhere in this component (see Localization) — this is a plain,
honestly-reported gap in the source, not a hidden one.

`separation-of-concerns` passes because each of the eleven source files owns one concern with no overlap — `tokens.ts` token storage, `refresh.ts` the refresh single-flight, `sso.ts` SSO hint and return-to handling, `report.ts` the telemetry sink, `client.ts` the HTTP calls, `mfa.ts` and `account-security.ts` their endpoint families, `config.ts`, `labels.ts` and `types.ts` configuration, copy and shapes. `unit-test-coverage` is partial because `client.test.ts`, `refresh.test.ts`, `sso.test.ts`, `tokens.test.ts`, `report.test.ts`, `silent-restore.test.ts`, `link.test.ts` and `types.test.ts` in the auth package's `__tests__` directory cover the core flows, but `mfa.ts`, `account-security.ts` and `asBase.ts` have no dedicated test file.

