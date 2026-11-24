
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |

The contract separates concerns cleanly: the protocol and value types hold no UI, storage or network code, and platform specifics reach it only through the type-erased anchor. `AccountsTests.swift` now covers `AccountUser.initials`, the weak anchor, `AccountState` equality, construction without validation, and the hidden Signup row for a conformer with no signup URL (AC-001 to AC-008, AC-011 to AC-013). Coverage is partial: AC-009 (`onChange` single slot) and AC-010 (`restore()` idempotence) are protocol contracts with no implementation in this source, only stub conformers, so they are skipped. The source makes no log calls, so personal data in `AccountUser` is not written to logs here.

