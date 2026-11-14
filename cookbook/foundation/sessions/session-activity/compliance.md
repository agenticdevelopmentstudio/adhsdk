
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | internationalization |

Separation of concerns passes: the file holds only the derivation, with no storage, transport or drawing, and the macOS icon view consumes the resolved case. Unit-test coverage is partial: every branch of `derive` and `turnActivity` is asserted, but only through `SessionWatcherSession.activity` in the macOS test target, and no test sits beside the Core file or calls the two static functions directly. The `"stop"` and `" Stop"` cases in session-activity-009 and the unknown event in session-activity-008 have no test. No hardcoded user-facing strings exist: the only literals are hook event names and raw values.

