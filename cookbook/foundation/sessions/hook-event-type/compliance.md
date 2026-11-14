
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: the enum classifies event types and names tables, while ingestion, schema creation and state storage live in `EventIngestStore` and `SessionSchema`, and registration lives in the installer. unit-test-coverage is partial: `HookEventTypeTests` asserts `tableName`, `isActivity` and the case count, and `EventIngestStoreTests` covers an ambient event end to end, but no test calls `setsTurnState` or `subagentClock` directly or pins the sets' members. The registration claim in the type's doc comment is the open question on `registration-list`.

