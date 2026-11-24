
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | failed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | failed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

`separation-of-concerns` is `partial`: `MessagingDataSource` cleanly isolates every network call
behind a protocol `MessagingTopic` depends on but never implements, but `MessagingModels.swift`'s
`MessagingTemplate.placeholders` reaches back into `MessagingTopic.placeholders(in:)` — a model
type calling into its own controller type, the inverse of the usual dependency direction, even
though the source's own comment shows this was a deliberate choice to share one regex rather than
duplicate it. `unit-test-coverage` passes: `MessagingTopicTests.swift` exercises every operation
with a fake data source, including the subject-only-placeholder regression, both provider-status
banners, every send validation path, and the log list/detail/not-found paths. `explicit-error-
handling` passes: every throwing path other than `status(...)` routes through `HubError.wrap(_:)`
or a specific validation throw; the one place an error is swallowed (`status(...)`, via `try?`) is
a documented, signaled degradation (a fallback banner), not a silent loss. `no-hardcoded-strings`
fails outright — see Localization; there is no localization mechanism anywhere in either file.
`error-recovery` fails: neither file retries, backs off, or queues a failed call — every
`MessagingDataSource` invocation other than `status(...)` is a single `try await`/`try` that
throws straight through to the caller on any failure. `idempotent-operations` fails: nothing in
`send-invokes-data-source` attaches an idempotency key or otherwise guards against the same
`MessagingSend` being submitted twice by a retried or double-triggered save. `data-integrity` is
`partial`: the send path validates its own shape thoroughly before submitting (required fields,
placeholder coverage, JSON shape), but see **log-pagination** — `total` is
decoded from every log page and never checked, so a log with more entries than `logPageSize` gives
no signal that its display is incomplete.

