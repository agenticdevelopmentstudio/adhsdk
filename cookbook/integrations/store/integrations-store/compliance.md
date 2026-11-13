
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |

The store separates concerns well: it holds only SQL and the keyed-upsert and tombstone rules, takes its database by injection, and leaves fetching, parsing, classification, scheduling and status recording to `GmailSyncWorker`, `MailIntegrationService` and the model types. Unit-test coverage is partial: `IntegrationsStoreTests` has 19 tests covering upserts, revival, query filters, ordering, paging, class and date tombstones, labels, connection lookup and cascade, chunked tombstones and the unknown-account error, but none covers a rollback, the action log error paths, a negative `limit` or `offset`, a delete of an unknown row, `deadlineExceeded` or a migration failure, so vectors store-002, store-022 and store-024 to store-033 are derived from the code. Explicit error handling is partial because every error surfaces and `updateSyncState` raises a typed error, but `finishActionLog` returns silently when no row matches. Idempotent operations pass because upserts are keyed and revive tombstones, and a repeated tombstone changes nothing. Data integrity passes because each public write is one transaction and the schema has unique indexes on the message and label keys.

