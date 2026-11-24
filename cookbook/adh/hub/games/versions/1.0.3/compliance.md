
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | Access Patterns |
| [adc.check.access-patterns.offline-behavior](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/df7f401a-39be-5c60-bab4-85dd95bd1ab1) | failed | Access Patterns |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | failed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | Reliability |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` **passed**: the wire types (`GameWire`,
`GameDefinitionWire`) are kept distinct from the client-facing `Game`/
`GameDefinition` types, and both column crossings are held in one set of
functions (`gameFromWire`/`gameToWire`/`definitionFromWire`/
`definitionToWire`) rather than repeated at each call site; the generic
`childApi` factory keeps transport shape separate from the three row
types it serves. `explicit-error-handling` **passed**: no path in this
module silently drops a failure — every error either matches a specific
remap (`rethrowConflict`'s message test, `textToJson`'s `clientRefusal`)
or propagates unchanged; nothing is caught and discarded.
`unit-test-coverage` **partial**: `games.test.ts` exercises `gamesApi`'s
full surface (list scoping, `forEcosystem`, create/update body-vs-query
scoping, conflict mapping, delete's id-encoding) and both column crossings
exhaustively, but never exercises `childApi`'s `update` or `delete` for
any of the three child collections, and never exercises
`child-create-update-no-conflict-mapping`'s no-remap behavior directly.
`error-response-handling` **partial**: the module distinguishes a
"duplicate slug" conflict from every other error by message content in
exactly two functions (`gamesApi.create`/`update`); it never distinguishes
a `404` from any other status anywhere (there is no `isNotFound`-style
branch in this file, unlike `hub-domain-ecosystems`'s `ecosystemsApi.get`),
and the three `childApi` clients distinguish nothing at all.
`retry-with-backoff` **failed**: no file in this module retries a failed
request; the underlying `authedFetch`'s one-refresh-then-retry is a
401-specific auth waterfall (see `auth-client`), not a retry of this
domain's own operations. `offline-behavior` **failed**: this module
defines no offline-cache-first read path and no queued-write-when-offline
behavior; every call is a live round trip that fails outright when the
network is unavailable. `timeout-handling` **failed**: no call in this
module sets a timeout or passes an `AbortSignal`; a hung request hangs
until the underlying `fetch` itself resolves or rejects.
`idempotent-operations` **partial**: every `update`/PUT in this module
sends the full replacement state, which is naturally idempotent to repeat;
no `create`/POST carries an idempotency key, so a client-level retry of a
create (were one ever added) could not distinguish a genuine duplicate
request from a second, different create — the module currently avoids the
question entirely by never retrying. `input-sanitization` **partial**:
`textToJson` enforces JSON-parseability before a `jsonb` write and
`emptyToNull` trims text before the null crossing, but every closed-set
field this module sends (`characterNames`, `status`, `eventLog`,
`trigger`, `operation`) is passed through with no client-side check
against its own closed set, relying entirely on the backend's database
`check` constraints. `data-minimization` **passed**: every field this
module reads or writes is game/definition/effect/mapping catalog
metadata; its own header comment states the deliberate exclusion of the
schema's player-state tables. `no-hardcoded-strings` **failed**: every
user-facing string this module produces (the conflict message, the two
JSON-refusal messages) is fixed English with no lookup table or locale
parameter (see Localization) — a plain, honestly-reported gap, not a
hidden one.

