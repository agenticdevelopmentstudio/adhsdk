
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |

The module holds only the wire contract, with transport, selection and rendering in other modules, so separation-of-concerns passes. Unit-test-coverage is partial: live-types-001, 002, 003, 007 and 008 have passing tests, while live-types-004, 005, 006 and 009 are skipped because they are compile-time facts (type assignability and the client/server parity guard in `read-types-parity.test.ts`) that vitest cannot exercise at runtime; `tsc` enforces them. Data-integrity is partial because the parity guard is a typecheck, and no runtime check rejects a mismatched payload. Graceful-degradation passes: the server always sends every snapshot field and the freshness verdict, and consumers read the verdict rather than derive it.
