
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | Access Patterns |
| [adc.check.access-patterns.offline-behavior](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/df7f401a-39be-5c60-bab4-85dd95bd1ab1) | failed | Access Patterns |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` **passed**: `organizations.ts`/`members.ts` contain zero UI or
presentation code, `wire.ts` is a type-only file, and `index.ts`'s own comment describes the module
as the public surface of a data domain, consumed by a separate presentation layer.
`explicit-error-handling` **passed**: nothing in either file swallows an error — every failure
either throws `AuthHttpError` (via the shared `authedFetch`) or one of the two hand-authored
friendly `Error`s this recipe documents. `unit-test-coverage` **failed**: no `__tests__` directory
or `*.test.ts` file exists next to `organizations.ts`/`members.ts` in this checkout, and the
consumer feature tests found elsewhere in the repository (`NewOrganizationModal.test.tsx`,
`orgRenameSavePath.test.tsx`) mock `@adh-sdk/data/organizations` wholesale rather than
exercising this module's own request-building or error-mapping logic — none of the requirements
above is exercised by a dedicated test in this checkout. `server-side-authorization` **passed**:
neither module performs a client-side permission check of any kind, per
`authorization-enforced-server-side`, deferring the workspace-kind and field-level authorization
splits, the archive role set, and the roster membership gate entirely to the backend.
`input-sanitization` **partial**: no file client-side validates `slug`/`name`/`description`
character set or length before sending; the backend's own uniqueness constraint and validation are
the sole authority this client deliberately relies on rather than duplicating (see Edge Cases).
`error-response-handling` **passed**: `rethrowConflict`/`isConflict` and the plain `AuthHttpError`
propagation consistently distinguish a slug conflict (`create`/`rename`), a handle-taken conflict
(`restore`), and every other failure, on every method. `retry-with-backoff` **failed**: no file
retries a failed organizations/roster request beyond the inherited 401-refresh-and-retry-once,
which is a different, cross-cutting auth concern (see `auth-client`), not a retry of this domain's
own operations. `offline-behavior` **failed**: neither module defines an offline-cache-first read
path or a queued-write-when-offline behavior; every operation is a live round-trip that fails
outright when the network is unavailable. `idempotent-operations` **partial**: `rename`'s PATCH is
a plain field update with no stated idempotency guarantee of its own (unlike the sibling Ecosystems
client's documented locked-value diff), and `create`/`restore` have no idempotency key on the
client side — a client-level retry of either (were one ever added) could not safely be
distinguished from a genuine duplicate request. `data-minimization` **passed**: every organization
field this component reads or writes is administrative metadata, and the roster's personal fields
(`email`, `displayName`) are already nulled server-side outside the caller's own ecosystem before
this client ever sees them. `no-hardcoded-strings` **failed**: the three hand-authored conflict
messages this recipe documents are fixed English with no lookup table or locale parameter in either
file (see Localization) — a plain, honestly-reported gap, not a hidden one.

