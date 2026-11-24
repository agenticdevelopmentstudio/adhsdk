
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | failed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

`separation-of-concerns` passes: `ApplicationsDataSource` isolates every network call behind a
protocol `ApplicationsTopic` depends on but never implements, and the wire/domain model split
(`ApplicationsModels.swift`'s `Codable` types vs. the non-`Codable` `CrudPermissions`/
`TableGrant`/`SchemaGrant`) keeps the API's exact shape out of the domain layer. `unit-test-coverage`
passes: `ApplicationsTopicTests.swift` exercises every operation with a fake data source, including
the rename/re-home sequence, the reveal-once/expiry mechanic, and multiple failure paths.
`explicit-error-handling` passes: every throwing path in `ApplicationsTopic` routes through
`HubError.wrap(_:)` or a specific `catch HubError.conflict`/`.notFound` mapping — nothing is
silently discarded. `secure-storage` passes: no plaintext token secret is ever written to disk,
`UserDefaults`, or the Keychain — `revealedSecrets` is transient, in-memory, and actively
self-expiring. `no-hardcoded-strings` fails outright — see Localization; there is no localization
mechanism anywhere in these three files. `error-recovery` fails: none of the three files retries,
backs off, or queues a failed call — every `ApplicationsDataSource`/`BucketsDataSource` invocation
is a single `try await` that throws straight through to the caller on any failure, transient or
not. `data-integrity` is `partial`: individual writes are internally consistent (each
`setSchemaGrants` call replaces the array atomically from the caller's point of view, and
`table-grant-ceiling-enforcement` validates cross-field consistency before a save), but see the
grants-write-last-writer-wins requirement — the whole-list read-modify-write pattern has no
protection against two overlapping writers silently discarding one another's changes.

