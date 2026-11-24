
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | Access Patterns |
| [adc.check.access-patterns.offline-behavior](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/df7f401a-39be-5c60-bab4-85dd95bd1ab1) | failed | Access Patterns |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | Reliability |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |

`separation-of-concerns` **passed**: `EcosystemsDataSource` is a pure I/O
boundary the module never bypasses; topics compose via the
`EcosystemTopicProvider` protocol rather than subclassing or reaching into
each other's state, and the web client keeps wire shapes (`wire.ts`)
separate from the UI-facing `Ecosystem` type. `explicit-error-handling`
**passed**: every catch on both platforms either re-maps a specific error
(`HubError.notFound`→`.empty`, `HubError.conflict`→`.validation`,
`isNotFound`→`null`, a 409→`rethrowConflict`) or wraps/rethrows
unconditionally (`HubError.wrap`) — no path silently swallows a failure.
`unit-test-coverage` **partial**: 33 of the 51 conformance vectors
(`ecosystems-019` through `-051`) are covered by passing web tests in
`ecosystems.test.ts`, `ecosystem-features.test.tsx` and
`use-workspace-default-ecosystem.test.tsx`, one test per vector. Vectors
`ecosystems-001` through `-018` describe the Apple `EcosystemsModule` and
`Ecosystem` type, which the web client has no equivalent of; they are
exercised by `EcosystemsModuleTests.swift` (root listing, manageability gate,
topic dispatch, settings save/delete, child-ecosystem recursion, create-form
validation and prefix resolution) and are `it.skip` placeholders in the web
suite, so no web test counts them. `error-response-handling`
**passed**: `isNotFound`/`isConflict` and `HubError.notFound`/`.conflict`
consistently distinguish "missing" from "already exists" from every other
failure on both platforms, and `ecosystemIdForSlug` explicitly rethrows a
non-404 rather than treating it as license to fall back
(ecosystems-035). `retry-with-backoff` **failed**: no file in
either implementation retries a failed ecosystems/identifiers request —
the underlying `authedJson`'s 401-refresh-and-retry-once is a different,
cross-cutting auth concern (see [adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)), not a retry of this
domain's own operations. `offline-behavior` **failed**: neither
implementation defines an offline-cache-first read path or a
queued-write-when-offline behavior; every operation is a live round-trip
that fails outright when the network is unavailable.
`idempotent-operations` **partial**: the feature client is idempotent on
both mutating paths — `remove` treats an already-gone row (404) as success,
and `provision` of an already-active key is a backend no-op — and
`ecosystemsApi.update`'s PUT is
documented as idempotent by the backend's own locked-value diff (sending
an unchanged `slug` is a no-op, per the source's `addressPatchMoves`
comment), but `create` has no idempotency key on either platform — a
client-level retry of a create (were one ever added) could not safely be
distinguished from a genuine duplicate request without one.
`input-sanitization` **partial**: `Slug.pattern`/`FormValidator` (Apple)
validate the slug's character set client-side, and `addressLeaf` is a
pure slice with no validation of its own by design (see Edge Cases); the
server's unique-address constraint and `id`-vs-leaf assertion are the
real authority on both platforms, which this component deliberately
relies on rather than duplicating. `data-minimization` **passed**: every
field this component reads or writes is ecosystem/product metadata, apart from
the `loginAllowedEmails` email addresses, which are contact details the owner chose to
list and are needed to decide who may sign in, and the provisioner principal id, an
opaque id. `no-hardcoded-strings` **failed**: every
user-facing string this ingredient documents (labels, warnings, validation
messages) is fixed English with no lookup table or locale parameter on
either platform (see Localization) — a plain, honestly-reported gap, not
a hidden one. `fault-tolerance` **partial**: `useApplyFeatureChange`
keeps going past a failed removal and reports it by name rather than
aborting, and `FeatureSubscriptionTier` is an open string so an unknown
tier cannot break parsing; but the feature mutation hooks accept a
nullable `ecosystemId` and send it unguarded (a known gap) (see #requirements/features-mutation-null-id-unguarded).

